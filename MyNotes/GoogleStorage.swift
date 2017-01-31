import UIKit

class GoogleStorage : Storage {
    
    // MARK: Properties
    public var accessToken = ""
    
    init() {
        accessToken = UserDefaults.standard.string(forKey: "access_token")!
    }

    func load() -> [Note] {
        return [Note]()
    }
    
    func add(_ note: Note) {
        let path = "https://sheets.googleapis.com/v4/spreadsheets"
        let headers = ["Content-Type" : "application/json",
                       "Authorization" : "Bearer " + accessToken]
        
        let params = ["properties" : ["title" : "MyNotes"],
                      "sheets" : ["properties" : ["title" : "Notes"]]]
        do {
            let body = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            HttpRequest.postRequest(path: path, headers: headers, body: body, handler: { data, responde, error in

            })
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func update(index : Int, note : Note) {
        print("Google update")
    }
    
    func delete(index : Int) {
        print("Google delete")
    }
}
