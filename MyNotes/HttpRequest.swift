import Foundation

class HttpRequest {
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
}
