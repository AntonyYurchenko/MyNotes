//
//  GoogleStorage.swift
//  MyNotes
//
//  Created by Antony Yurchenko on 1/30/17.
//  Copyright © 2017 antonybrro. All rights reserved.
//

import UIKit

class GoogleStorage : UIViewController, UIWebViewDelegate, Storage {
    
    // MARK: Properties
    let tabBar = UITabBar()
    let webView : UIWebView = UIWebView()
    let tokenEndpoint = "https://www.googleapis.com/oauth2/v4/token"
    let redirect_uri = "http://127.0.0.1:9004"
    var client_id = ""
    var accessToken = ""
    
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
                    client_id = json["client_id"] as! String
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
                
                let headers = ["Content-Type" : "application/x-www-form-urlencoded"]
                
                let grant_type = "authorization_code"
                let params = "code=" + code +
                    "&client_id=" + client_id +
                    "&redirect_uri=" + redirect_uri +
                    "&grant_type=" + grant_type
                
                let body = params.data(using: String.Encoding.utf8)!
                
                let json = makeHTTPPostRequest(path: tokenEndpoint, headers: headers, body: body)
                accessToken = json["access_token"] as! String
                
                dismiss(animated: true, completion: nil)
            }
        }
        
        return true
    }
    
    private func makeHTTPPostRequest(path: String, headers: [String: String], body: Data) -> [String: Any]  {
        var request = URLRequest(url: URL(string: path)!)
        request.httpMethod = "POST"
        
        for (key, value) in headers {
            print(value, key)
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        request.httpBody = body
        
        var responseData: Data? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            print(error)
            print(response)
            responseData = data
            
            semaphore.signal()
        })
        task.resume()
        
        semaphore.wait()
        
        var json = [String: Any]()
        
        if responseData != nil {
            do {
                if let jsonData = try JSONSerialization.jsonObject(with: responseData!, options: .mutableContainers) as? [String: Any] {
                    json = jsonData
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
        return json
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
            makeHTTPPostRequest(path: path, headers: headers, body: body)
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
