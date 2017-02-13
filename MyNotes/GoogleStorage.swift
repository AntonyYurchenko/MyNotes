import UIKit
//TODO refactor
class GoogleStorage {
    
    // MARK: Properties
    var accessToken : String?
    var spreadsheetId : String?
    
    init() {

        if let accessTokenOpt = UserDefaults.standard.string(forKey: "access_token") {
            accessToken = accessTokenOpt
            getSpreadsheetId()
        }
//        
//        if let id = UserDefaults.standard.string(forKey: "spreadsheet_id") {
//            spreadsheetId = id
//            getAccessToken()
//        } else {
//            createFolder()
//        }
    }
    
    func createFolder() {
        let path = "https://www.googleapis.com/drive/v3/files"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["mimeType" : "application/vnd.google-apps.folder",
                      "name" : "My notes",
                      "folderColorRgb" : "#FFFF4C"]
        
        let body = JsonParser.parse(params: params)
        
        HttpRequest.request(path: path, requestType: "POST", headers: headers, body: body!, handler: { data, response, error in
            let json = JsonParser.parse(data: data!)
            let parentId = json?["id"] as? String
            
            self.createSpreadsheets(parentId: parentId!)
        })
    }
    
    func createSpreadsheets(parentId : String) {
        let path = "https://www.googleapis.com/drive/v3/files"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["mimeType" : "application/vnd.google-apps.spreadsheet",
                      "name" : "com.antonybrro.mynotes",
                      "parents" : [parentId]] as [String : Any]
        
        let body = JsonParser.parse(params: params)
        
        HttpRequest.request(path: path, requestType: "POST", headers: headers, body: body!, handler: { data, response, error in
            let json = JsonParser.parse(data: data!)
            self.spreadsheetId = json?["id"] as? String
            UserDefaults.standard.set(self.spreadsheetId, forKey: "spreadsheet_id")
            print("createSpreadsheets", self.spreadsheetId!)

//            self.updateSheetProperties()
        })
    }
    
    //TODO Rename sheet
    func updateSheetProperties() {
        let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!):batchUpdate"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["requests" : [["updateSheetProperties" : ["properties" : ["title" : "Notes"]]]]]
        
        let body = JsonParser.parse(params: params)
        
        HttpRequest.request(path: path, requestType: "POST", headers: headers, body: body!, handler: { data, response, error in
            
        })
    }
    
    func getAccessToken() {
        if let refreshToken = UserDefaults.standard.string(forKey: "refresh_token") {
            let tokenEndpoint = "https://www.googleapis.com/oauth2/v4/token"
            let headers = ["Content-Type" : "application/x-www-form-urlencoded"]
            let params = "client_id=" + OAuthViewController.getClientId()! +
                "&refresh_token=" + refreshToken +
            "&grant_type=refresh_token"
            let body = params.data(using: String.Encoding.utf8)!
            
            HttpRequest.request(path: tokenEndpoint, requestType: "POST", headers: headers, body: body, handler: { data, response, error in
                let json = JsonParser.parse(data: data!)
                let accessToken = json?["access_token"] as? String
                UserDefaults.standard.set(accessToken, forKey: "access_token")
                self.load()
            })
        }
    }
    
    func getSpreadsheetId() {
        let path = "https://www.googleapis.com/drive/v3/files"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        HttpRequest.request(path: path, requestType: "GET", headers: headers, body: nil, handler: { data, response, error in
            let json = JsonParser.parse(data: data!)
            let files = json?["files"] as! [[String : AnyObject]]
            
            for item in files {
                if item["name"] as! String == "com.antonybrro.mynotes" {
                    let spreadsheetId = item["id"] as? String
                    print(spreadsheetId)
                    UserDefaults.standard.set(spreadsheetId, forKey: "spreadsheet_id")
                    break;
                }
            }
        })
    }
    
    func addToSheet(index : Int, note : Note) {
        let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!)/values/A\(index + 1):C\(index + 1)?valueInputOption=USER_ENTERED"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["values" : [[note.title, note.text, note.date]]]
        let body = JsonParser.parse(params: params)
        
        HttpRequest.request(path: path, requestType: "PUT", headers: headers, body: body!, handler: { data, response, error in })
    }
    
    func load() {
        if spreadsheetId != nil {
            let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!)/values/A:C"
            
            let headers = ["Content-Type" : "application/json",
                           "Authorization" : "Bearer " + accessToken!]
            
            HttpRequest.request(path: path, requestType: "GET", headers: headers, body: nil, handler: { data, response, error in
                
                let json = JsonParser.parse(data: data!)
                //TODO how to update data?
                let values = json?["values"] as? [[String]]
                if values != nil {
                    for (index, note) in (values?.enumerated())! {
//                        if super.notes.count <= index
//                        {
//                            super.add(index: index, note: Note(title: note[0], text: note[1], date: note[2]))
//                        } else {
//                            let localNote = super.notes[index]
//                            let newNote = Note(title: note[0], text: note[1], date: note[2])
//                            
//                            if localNote != newNote {
//                                super.notes[index] = Note(title: note[0], text: note[1], date: note[2])
//                            }
//                        }
                    }
                }
            })
        }
    }
    
    func delete(index : Int) {
        let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!):batchUpdate"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["requests" : [["deleteDimension" : ["range" : ["dimension" : "ROWS",
                                                                     "startIndex" : index,
                                                                     "endIndex" : index + 1]]]]]
        let body = JsonParser.parse(params: params)
        
        HttpRequest.request(path: path, requestType: "POST", headers: headers, body: body!, handler: { data, response, error in })
    }
}
