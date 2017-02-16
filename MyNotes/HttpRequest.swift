import Foundation

class HttpRequest {
    static func request(path: String, requestType: String, headers: [String: String]?, body: Data?) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        var request = URLRequest(url: URL(string: path)!)
        request.httpMethod = requestType
        
        if let header = headers {
            for (key, value) in header {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        request.httpBody = body
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}
