import UIKit

class WebViewController : UIViewController, UIWebViewDelegate {
    
    // MARK: Properties
    var tabBar = UITabBar()
    var webView : UIWebView = UIWebView()
    let tokenEndpoint = "https://www.googleapis.com/oauth2/v4/token"
    let redirect_uri = "http://127.0.0.1:9004"
    var client_id : String?
    var accessToken : String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadClientId()
        
        tabBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 50)
        tabBar.backgroundColor = UIColor.white
        view.addSubview(tabBar)
        
        webView.delegate = self
        webView.frame = CGRect(x: 0, y: 45, width: view.bounds.width, height: view.bounds.height - 45)
        webView.autoresizingMask = UIViewAutoresizing.flexibleWidth
        webView.scalesPageToFit = true
        view.addSubview(webView)
        
        loadAddressURL()
    }
    
    func loadClientId() {
        let path = Bundle.main.path(forResource: "credentials", ofType: "json")
        let url = URL(fileURLWithPath : path!)
        do {
            let data = try Data(contentsOf: url, options: Data.ReadingOptions.mappedIfSafe)
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    client_id = json["client_id"] as? String
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
            
        } catch {
            print("error: \(error)")
        }
    }
    
    func createAuthorizationEndpoint() -> URL {
        let host = "https://accounts.google.com"
        let endPoint = "/o/oauth2/v2/auth?"
        let scopes = "scope=email%20profile%20https://www.googleapis.com/auth/spreadsheets"
        let redirect_uri = "&redirect_uri=" + self.redirect_uri
        let response_type = "&response_type=code"
        let client_id = "&client_id=" + self.client_id!
        
        let authorizationEndpoint = host + endPoint + scopes + redirect_uri + response_type + client_id
        
        return URL(string: authorizationEndpoint)!
    }
    
    func loadAddressURL() {
        UserDefaults.standard.register(defaults: ["UserAgent": "custom value"])
        let authorizationEndpoint = createAuthorizationEndpoint()
        webView.loadRequest(URLRequest(url: authorizationEndpoint))
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url?.absoluteString {
            
            if url.contains(redirect_uri + "/?code=4/") {
                let index = url.range(of: "code=")?.upperBound
                let code = url.substring(from: index!)
                
                makeHTTPPostRequest(path: tokenEndpoint, code: code)
            }
        }
        
        return true
    }
    
    private func makeHTTPPostRequest(path: String, code: String) {
        var request = URLRequest(url: URL(string: path)!)
        
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let grant_type = "authorization_code"
        let params = "code=" + code +
            "&client_id=" + client_id! +
            "&redirect_uri=" + redirect_uri +
            "&grant_type=" + grant_type
        
        request.httpBody = params.data(using: String.Encoding.utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                    self.accessToken = json["access_token"] as? String
                    self.createTable()
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
        })
        
        task.resume()
        self.dismiss(animated: true, completion: nil)
    }
    
    func createTable() {
        var request = URLRequest(url: URL(string: "https://sheets.googleapis.com/v4/spreadsheets")!)
        
        request.httpMethod = "POST"
        request.addValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        
        let params = ""
        request.httpBody = params.data(using: String.Encoding.utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
        })
        
        task.resume()
    }
}
