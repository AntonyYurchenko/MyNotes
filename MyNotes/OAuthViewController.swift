import UIKit

class OAuthViewController : UIViewController, UIWebViewDelegate {
    
    // MARK: Properties
    let webView = UIWebView()
    let navigationBar = UINavigationBar()
    let redirectUri = "http://127.0.0.1:9004"
    var clientId : String?
    var accessTokenTaken = DispatchWorkItem {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        webView.scalesPageToFit = true
        view.addSubview(webView)
        view.addSubview(navigationBar)
        
        let navigationItem = UINavigationItem(title: "Google SignIn");
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(OAuthViewController.cancel))
        navigationItem.leftBarButtonItem = cancelItem;
        navigationBar.setItems([navigationItem], animated: false);
        
        if let id = OAuthViewController.getClientId() {
            clientId = id
            loadAuthorizationRequestURL()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let navigationBarHeight : CGFloat = 64
        navigationBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: navigationBarHeight)
        navigationBar.barTintColor =  UIColor(red: 247.0/255, green: 243.0/255, blue: 235.0/255, alpha: 1.0)
        webView.frame = CGRect(x: 0, y: navigationBarHeight, width: view.bounds.width, height: view.bounds.height)
    }
    
    func cancel() {
        dismiss(animated: true, completion: nil)
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
        
        UserDefaults.standard.register(defaults: ["UserAgent": "custom value"])

        self.webView.loadRequest(URLRequest(url: URL(string: authorizationEndpoint)!))
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url?.absoluteString {
            if url.contains(redirectUri + "/?code=4/") {
                let index = url.range(of: "code=")?.upperBound
                let code = url.substring(from: index!)
                
                getAccessToken(code)
            }
            
            if url.contains(redirectUri + "/?error") {
                dismiss(animated: true, completion: nil)
            }
        }
        return true
    }
    
    func getAccessToken(_ code: String) {
        let tokenEndpoint = "https://www.googleapis.com/oauth2/v4/token"
        let headers = ["Content-Type" : "application/x-www-form-urlencoded"]
        let grant_type = "authorization_code"
        let params = "code=" + code +
            "&client_id=" + clientId! +
            "&redirect_uri=" + redirectUri +
            "&grant_type=" + grant_type
        let body = params.data(using: String.Encoding.utf8)!
        
        HttpRequest.request(path: tokenEndpoint, requestType: "POST", headers: headers, body: body, handler: { data, response, error in
            let json = JsonParser.parse(data: data!) as! [String : AnyObject]
            let accessToken = json["access_token"] as? String
            let refreshToken = json["refresh_token"] as? String
            UserDefaults.standard.set(accessToken, forKey: "access_token")
            UserDefaults.standard.set(refreshToken, forKey: "refresh_token")
    
            self.accessTokenTaken.perform()
        })
    }
    
    
}
