import Foundation

class HttpRequest {
    static func request(path: String, requestType: String, headers: [String: String]?, body: Data?, handler : @escaping (Data?, URLResponse?, Error?) -> Swift.Void) {
        var request = URLRequest(url: URL(string: path)!)
        request.httpMethod = requestType
        
        if let header = headers {
            for (key, value) in header {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: handler)
        task.resume()
    }
}
