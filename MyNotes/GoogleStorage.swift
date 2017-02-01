import UIKit

class GoogleStorage : Storage {
    
    // MARK: Properties
    var accessToken : String?
    var spreadsheetId : String?
    
    init() {
        accessToken = UserDefaults.standard.string(forKey: "access_token")!
        
        if let id = UserDefaults.standard.string(forKey: "spreadsheet_id") {
            spreadsheetId = id
            
            print(spreadsheetId)
        } else {
            createFolder()
        }
        
        //            updateSheetProperties()
    }
    
    func createFolder() {
        let path = "https://www.googleapis.com/drive/v3/files"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["mimeType" : "application/vnd.google-apps.folder",
                      "name" : "My notes ios",
                      "folderColorRgb" : "#FFFF4C"]
        
        let body = jsonParser(params: params)
        
        HttpRequest.postRequest(path: path, headers: headers, body: body!, handler: { data, response, error in
            let json = self.jsonParser(data: data!)
            let parentId = json?["id"] as? String
            
            self.createSpreadsheets(parentId: parentId!)
        })
    }
    
    func createSpreadsheets(parentId : String) {
        let path = "https://www.googleapis.com/drive/v3/files"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["mimeType" : "application/vnd.google-apps.spreadsheet",
                      "name" : "My notes",
                      "parents" : [parentId]] as [String : Any]
        
        let body = jsonParser(params: params)
        
        HttpRequest.postRequest(path: path, headers: headers, body: body!, handler: { data, response, error in
            let json = self.jsonParser(data: data!)
            self.spreadsheetId = json?["id"] as? String
            UserDefaults.standard.set(self.spreadsheetId, forKey: "spreadsheet_id")
            
            self.updateSheetProperties()
        })
    }
    
    //TODO Rename sheet
    func updateSheetProperties() {
        let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!):batchUpdate"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["requests" : [["updateSheetProperties" : ["properties" : ["title" : "Notes"]]]]]
        
        let body = jsonParser(params: params)
        
        HttpRequest.postRequest(path: path, headers: headers, body: body!, handler: { data, response, error in
            
        })
    }
    
    func jsonParser(data: Data) -> [String : Any]? {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any]
            return json
        } catch let error {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func jsonParser(params: [String : Any]) -> Data? {
        do {
            let body = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            return body
        } catch let error {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func load() -> [Note] {
        print(3)
        let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!)/values/A:C"
        
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        var notes = [Note]()

        HttpRequest.getRequest(path: path, headers: headers, handler: { data, response, error in
            let json = self.jsonParser(data: data!)
        
            let values = json?["values"] as! [[String]]
            
            for note in values {
                notes.append(Note(title: note[0], text: note[1], date: note[2]))
            }
            print(4)
        })
        
        return notes
    }
    
    func add(index : Int, note: Note) {
        let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!)/values/A\(index):C\(index)?valueInputOption=USER_ENTERED"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["values" : [[note.title, note.text, note.date]]]
        let body = jsonParser(params: params)
        
        HttpRequest.putRequest(path: path, headers: headers, body: body!, handler: { data, response, error in })
    }
    
    func update(index : Int, note : Note) {
        print("Google update")
    }
    
    func delete(index : Int) {
        print("Google delete")
    }
}
