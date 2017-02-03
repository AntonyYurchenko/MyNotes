import Foundation

protocol Storage {    
    func load(handler : @escaping (_ : [Note]?) -> Swift.Void)
    func add(index : Int, note : Note)
    func update(index : Int, note : Note)
    func delete(index : Int)
}
