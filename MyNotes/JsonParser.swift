import Foundation

class JsonParser {
    static func parse(data: Data) -> [String : AnyObject]? {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: AnyObject]
            return json
        } catch let error {
            print(error.localizedDescription)
        }
        return nil
    }
    
    static func parse(params: [String : Any]) -> Data? {
        do {
            let body = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            return body
        } catch let error {
            print(error.localizedDescription)
        }
        return nil
    }
}
