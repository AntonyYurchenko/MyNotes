import UIKit
import WebKit

class OAuthViewController : UIViewController, WKNavigationDelegate {
    
    // MARK: Properties
    var webView : WKWebView!
    let redirectUri = "http://127.0.0.1:9004"
    var clientId : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: view.frame)
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        if let id = OAuthViewController.getClientId() {
            clientId = id
            loadAuthorizationRequestURL()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        performSegue(withIdentifier: "unwindToNotesTable", sender: self)
    }
    
    static func getClientId() -> String? {
        var clientId : String?
        let path = Bundle.main.path(forResource: "credentials", ofType: "json")
        let url = URL(fileURLWithPath : path!)
        do {
            let data = try Data(contentsOf: url, options: Data.ReadingOptions.mappedIfSafe)
            let json = JsonParser.parse(data: data)
            clientId = json?["client_id"] as? String
        } catch {
            print("error: \(error)")
        }
        
        return clientId
    }
    
    func loadAuthorizationRequestURL() {
        let host = "https://accounts.google.com"
        let endPoint = "/o/oauth2/v2/auth?"
        let scopes = "scope=https://www.googleapis.com/auth/spreadsheets%20https://www.googleapis.com/auth/drive"
        let redirect_uri = "&redirect_uri=" + redirectUri
        let response_type = "&response_type=code"
        let client_id = "&client_id=" + clientId!
        
        let authorizationEndpoint = host + endPoint + scopes + redirect_uri + response_type + client_id
        
        webView.customUserAgent = "my_notes"
        webView.load(URLRequest(url: URL(string: authorizationEndpoint)!))
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping ((WKNavigationActionPolicy) -> Void)) {
        if let url = navigationAction.request.url?.absoluteString {
            if url.contains(redirectUri + "/?code=4/") {
                let index = url.range(of: "code=")?.upperBound
                let code = url.substring(from: index!)
                
                getAccessToken(code)
            }
            
            if url.contains(redirectUri + "/?error") {
                self.navigationController!.popViewController(animated: true)
            }
        }
        
        decisionHandler(.allow)
    }
    
    func getAccessToken(_ code: String) {
        let tokenEndpoint = "https://www.googleapis.com/oauth2/v4/token"
        let headers = ["Content-Type" : "application/x-www-form-urlencoded"]
        let params = "code=" + code +
            "&client_id=" + clientId! +
            "&redirect_uri=" + redirectUri +
        "&grant_type=authorization_code"
        let body = params.data(using: String.Encoding.utf8)!
        
        HttpRequest.request(path: tokenEndpoint, requestType: "POST", headers: headers, body: body, handler: { data, response, error in
            let json = JsonParser.parse(data: data!)
            let accessToken = json?["access_token"] as? String
            let refreshToken = json?["refresh_token"] as? String
            UserDefaults.standard.set(accessToken, forKey: "access_token")
            UserDefaults.standard.set(refreshToken, forKey: "refresh_token")
            UserDefaults.standard.set(true, forKey: "is_google_sync")
            
            GoogleStorage.sharedInstance.getSpreadsheetId(isLoad: true)
            
            DispatchQueue.main.async {
                self.navigationController!.popViewController(animated: true)
            }
        })
    }
}
