import Foundation

class HttpRequest {
    static func getRequest(path: String, headers: [String: String], handler : @escaping (Data?, URLResponse?, Error?) -> Swift.Void) {
        var request = URLRequest(url: URL(string: path)!)
        request.httpMethod = "GET"
        
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: handler)
        task.resume()
    }
    
    static func postRequest(path: String, headers: [String: String], body: Data, handler : @escaping (Data?, URLResponse?, Error?) -> Swift.Void) {
        var request = URLRequest(url: URL(string: path)!)
        request.httpMethod = "POST"
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: handler)
        task.resume()
    }
    
    //TODO
    static func putRequest(path: String, headers: [String: String], body: Data, handler : @escaping (Data?, URLResponse?, Error?) -> Swift.Void) {
        var request = URLRequest(url: URL(string: path)!)
        request.httpMethod = "PUT"
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: handler)
        task.resume()
    }
}
