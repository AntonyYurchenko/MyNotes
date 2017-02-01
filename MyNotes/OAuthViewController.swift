import UIKit

class OAuthViewController : UIViewController, UIWebViewDelegate {
    
    // MARK: Properties
    let webView : UIWebView = UIWebView()
    let redirect_uri = "http://127.0.0.1:9004"
    var client_id = ""
    var accessToken : ((String) -> Void)?
    var cancelFunc : (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadClientId()

        let screenBounds = UIScreen.main.bounds
        let navigationBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: screenBounds.width, height: 54))
        let navigationItem = UINavigationItem(title: "Google SignIn");
        let cancelItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: nil, action: #selector(OAuthViewController.cancel));
        navigationItem.leftBarButtonItem = cancelItem;
        navigationBar.setItems([navigationItem], animated: false);
        self.view.addSubview(navigationBar);
        
        let height = navigationBar.frame.size.height
        
        webView.delegate = self
        webView.frame = CGRect(x: 0, y: height, width: view.bounds.width, height: view.bounds.height - height)
        webView.autoresizingMask = UIViewAutoresizing.flexibleWidth
        webView.scalesPageToFit = true
        view.addSubview(webView)
        
        loadAddressURL()
    }
    
    func cancel() {
        cancelFunc!()
    }
    
    func loadClientId() {
        let path = Bundle.main.path(forResource: "credentials", ofType: "json")
        let url = URL(fileURLWithPath : path!)
        do {
            let data = try Data(contentsOf: url, options: Data.ReadingOptions.mappedIfSafe)
            if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                client_id = json["client_id"] as! String
            }
        } catch {
            print("error: \(error)")
        }
    }
    
    func createAuthorizationEndpoint() -> URL {
        let host = "https://accounts.google.com"
        let endPoint = "/o/oauth2/v2/auth?"
        let scopes = "scope=https://www.googleapis.com/auth/spreadsheets%20https://www.googleapis.com/auth/drive"
        let redirect_uri = "&redirect_uri=" + self.redirect_uri
        let response_type = "&response_type=code"
        let client_id = "&client_id=" + self.client_id
        
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
                
                let tokenEndpoint = "https://www.googleapis.com/oauth2/v4/token"
                let headers = ["Content-Type" : "application/x-www-form-urlencoded"]
                let grant_type = "authorization_code"
                let params = "code=" + code +
                    "&client_id=" + client_id +
                    "&redirect_uri=" + redirect_uri +
                    "&grant_type=" + grant_type
                let body = params.data(using: String.Encoding.utf8)!
                
                HttpRequest.postRequest(path: tokenEndpoint, headers: headers, body: body, handler: { data, response, error in
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any] {
                            self.accessToken!((json["access_token"] as? String)!)
                        }
                    } catch {
                        print("error: \(error)")
                    }
                })
            }
        }
        return true
    }
}
