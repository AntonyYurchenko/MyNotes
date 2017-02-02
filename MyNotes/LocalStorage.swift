import Foundation
import os.log

class LocalStorage : Storage {
    
    var notes = [Note]()
    
    init() {
        if let savedNotes = NSKeyedUnarchiver.unarchiveObject(withFile: Note.ArchiveURL.path) as? [Note] {
            notes += savedNotes
        } else {
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "dd.MM.yy"
            
            let note = Note(title: "This is the sample note", text: "You can create your own notes with this app.", date: dateFormat.string(from: Date()))
            
            notes.append(note)
        }
    }
    
    func load(handler: @escaping (_ : [Note]?) -> Void) {
        handler(notes)
    }
    
    func add(index : Int, note: Note) {
        notes.append(note)
        
        save()
    }
    
    func update(index : Int, note : Note) {
        notes[index] = note
        
        save()
    }
    
    func delete(index: Int) {
        notes.remove(at: index)
        
        save()
    }
    
    private func save() {
        let isSuccessfullSave = NSKeyedArchiver.archiveRootObject(notes, toFile: Note.ArchiveURL.path)
        
        if isSuccessfullSave {
            os_log("Notes successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save note...", log: OSLog.default, type: .error)
        }
    }
}
