import Foundation
import os.log

class LocalStorage {
    
    var notes = [Note]()
    
    init() {
        if let savedNotes = NSKeyedUnarchiver.unarchiveObject(withFile: Note.ArchiveURL.path) as? [Note] {
            notes = savedNotes
        }
        
        UserDefaults.standard.set(false, forKey: "notes_changed")
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
        
        UserDefaults.standard.set(isSuccessfullSave, forKey: "notes_changed")
        
        if isSuccessfullSave {
            os_log("Notes successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save note...", log: OSLog.default, type: .error)
        }
    }
}
