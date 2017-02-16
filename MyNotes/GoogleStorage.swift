import UIKit
//TODO refactor
class GoogleStorage {
    
    var accessToken: String?
    var spreadsheetId: String?
    
    static let sharedInstance : GoogleStorage = {
        let instance = GoogleStorage()
        return instance
    }()
    
    func load() {
        if getSpreadsheetId() {
            loadData()
        }
    }
    
    func backupData(taskId : UIBackgroundTaskIdentifier?) {
        accessToken = getAccessToken()
        
        if let id = UserDefaults.standard.string(forKey: "spreadsheet_id") {
            spreadsheetId = id
            clearData()
            postData()
        } else if let id = createSpreadsheet() {
            spreadsheetId = id
            clearData()
            postData()
        }
        
        if taskId != nil {
            UIApplication.shared.endBackgroundTask(taskId!)
        }
    }
    
    private func getAccessToken() -> String? {
        var accessToken: String?
        if let refreshToken = UserDefaults.standard.string(forKey: "refresh_token") {
            let tokenEndpoint = "https://www.googleapis.com/oauth2/v4/token"
            let headers = ["Content-Type" : "application/x-www-form-urlencoded"]
            let params = "client_id=" + OAuthViewController.getClientId()! +
                "&refresh_token=" + refreshToken +
            "&grant_type=refresh_token"
            let body = params.data(using: String.Encoding.utf8)!
            
            let (data, _, _) = HttpRequest.request(path: tokenEndpoint, requestType: "POST", headers: headers, body: body)
            let json = JsonParser.parse(data: data!)
            accessToken = json?["access_token"] as? String
            UserDefaults.standard.set(accessToken, forKey: "access_token")
        }
        return accessToken
    }
    
    private func getSpreadsheetId() -> Bool {
        let path = "https://www.googleapis.com/drive/v3/files"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + UserDefaults.standard.string(forKey: "access_token")!]
        
        let (data, _, _) = HttpRequest.request(path: path, requestType: "GET", headers: headers, body: nil)
        let json = JsonParser.parse(data: data!)
        let files = json?["files"] as! [[String : AnyObject]]
        
        for item in files {
            if item["name"] as! String == "com.antonybrro.mynotes" {
                let id = item["id"] as? String
                UserDefaults.standard.set(id, forKey: "spreadsheet_id")
                return true
            }
        }
        return false
    }
    
    private func createSpreadsheet() -> String? {
        let path = "https://www.googleapis.com/drive/v3/files"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let parentId = createFolder()
        
        let params = ["mimeType" : "application/vnd.google-apps.spreadsheet",
                      "name" : "com.antonybrro.mynotes",
                      "parents" : [parentId]] as [String : Any]
        
        let body = JsonParser.parse(params: params)
        
        let (data, _, _) = HttpRequest.request(path: path, requestType: "POST", headers: headers, body: body!)
        let json = JsonParser.parse(data: data!)
        let spreadsheetId = json?["id"] as? String
        UserDefaults.standard.set(spreadsheetId, forKey: "spreadsheet_id")
        
        return spreadsheetId
    }
    
    private func createFolder() -> String {
        let path = "https://www.googleapis.com/drive/v3/files"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let params = ["mimeType" : "application/vnd.google-apps.folder",
                      "name" : "My notes",
                      "folderColorRgb" : "#FFFF4C"]
        
        let body = JsonParser.parse(params: params)
        
        let (data, _, _) = HttpRequest.request(path: path, requestType: "POST", headers: headers, body: body!)
        let json = JsonParser.parse(data: data!)
        let parentId = json?["id"] as? String
        
        return parentId!
    }
    
    private func clearData() {
        let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!)/values/A1:C1000:clear"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken!]
        
        let (_, _, _) = HttpRequest.request(path: path, requestType: "POST", headers: headers, body: nil)
    }
    
    private func postData() {
        if let savedNotes = NSKeyedUnarchiver.unarchiveObject(withFile: Note.ArchiveURL.path) as? [Note] {
            let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId!)/values/A1:C\(savedNotes.count)?valueInputOption=USER_ENTERED"
            let headers = ["Content-Type" : "application/json",
                           "Authorization" : "Bearer " + accessToken!]
            
            var notes = [[String]]()
            for note in savedNotes {
                notes.append([note.title, note.text, note.date])
            }
            
            let params = ["values" : notes]
            let body = JsonParser.parse(params: params)
            print(params)
            
            let (_, _, _) = HttpRequest.request(path: path, requestType: "PUT", headers: headers, body: body!)
            UserDefaults.standard.set(false, forKey: "notes_changed")
        }
    }
    
    private func loadData() {
        if let spreadsheetId = UserDefaults.standard.string(forKey: "spreadsheet_id") {
            if let accessToken = UserDefaults.standard.string(forKey: "access_token") {
                let path = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/A:C"
                let headers = ["Content-Type" : "application/json",
                               "Authorization" : "Bearer " + accessToken]
                
                let (data, _, _) = HttpRequest.request(path: path, requestType: "GET", headers: headers, body: nil)
                let json = JsonParser.parse(data: data!)
                
                let values = json?["values"] as? [[String]]
                if values != nil {
                    var notes = [Note]()
                    for note in values! {
                        notes.append(Note(title: note[0], text: note[1], date: note[2]))
                    }
                    
                    NSKeyedArchiver.archiveRootObject(notes, toFile: Note.ArchiveURL.path)
                    NotificationCenter.default.post(name: Notification.Name("loadDataNotify"), object: nil)
                }
            }
        }
    }
}
