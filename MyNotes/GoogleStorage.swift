import UIKit

class GoogleStorage : LocalStorage {
    
    // MARK: Properties
    var accessToken : String?
    var spreadsheetId : String?
    let semaphore = DispatchSemaphore(value: 0)
    
    override init() {
        super.init()
        if let accessTokenOpt = UserDefaults.standard.string(forKey: "access_token") {
            accessToken = accessTokenOpt
        }
    
        if let id = UserDefaults.standard.string(forKey: "spreadsheet_id") {
            spreadsheetId = id
            print(spreadsheetId!)
        }
    }
    
    func createFolder() {
        let path = "https://www.googleapis.com/drive/v3/files"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["mimeType" : "application/vnd.google-apps.folder",
                      "name" : "My notes ios",
                      "folderColorRgb" : "#FFFF4C"]
        
        let body = JsonParser.parse(params: params)
        
        HttpRequest.request(path: path, requestType: "POST", headers: headers, body: body!, handler: { data, response, error in
            let json = JsonParser.parse(data: data!)
            let parentId = json?["id"] as? String
            
            self.createSpreadsheets(parentId: parentId!)
        })
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    func createSpreadsheets(parentId : String) {
        let path = "https://www.googleapis.com/drive/v3/files"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["mimeType" : "application/vnd.google-apps.spreadsheet",
                      "name" : "My notes",
                      "parents" : [parentId]] as [String : Any]
        
        let body = JsonParser.parse(params: params)
        
        HttpRequest.request(path: path, requestType: "POST", headers: headers, body: body!, handler: { data, response, error in
            let json = JsonParser.parse(data: data!)
            self.spreadsheetId = json?["id"] as? String
            UserDefaults.standard.set(self.spreadsheetId, forKey: "spreadsheet_id")
            print("createSpreadsheets", self.spreadsheetId!)
            self.semaphore.signal()
            self.updateSheetProperties()
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
                let json = JsonParser.parse(data: data!) as! [String : AnyObject]
                let accessToken = json["access_token"] as? String
                UserDefaults.standard.set(accessToken, forKey: "access_token")
                
                self.semaphore.signal()
            })
            
            _ = semaphore.wait(timeout: .distantFuture)
        }
    }
    
    override func load(handler: @escaping (_ : [Note]?) -> Void) {
        if spreadsheetId != nil {
            let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!)/values/A:C"
            
            let headers = ["Content-Type" : "application/json",
                           "Authorization" : "Bearer " + accessToken!]
            var notes = [Note]()
            
            HttpRequest.request(path: path, requestType: "GET", headers: headers, body: nil, handler: { data, response, error in
                
                let json = JsonParser.parse(data: data!)
                
                let values = json?["values"] as? [[String]]
                if values != nil {
                    for note in values! {
                        notes.append(Note(title: note[0], text: note[1], date: note[2]))
                    }
                }
                
                handler(notes)
            })
        }
    }
    
    override func add(index : Int, note: Note) {
        let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!)/values/A\(index + 1):C\(index + 1)?valueInputOption=USER_ENTERED"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["values" : [[note.title, note.text, note.date]]]
        let body = JsonParser.parse(params: params)
        
        print(note.title, note.text, note.date)
        
        HttpRequest.request(path: path, requestType: "PUT", headers: headers, body: body!, handler: { data, response, error in })
    }
    
    override func update(index : Int, note : Note) {
        add(index: index, note: note)
    }
    
    override func delete(index : Int) {
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
