import UIKit
import os.log

func CreateStorage() -> LocalStorage {
    if UserDefaults.standard.bool(forKey: "is_google_sync") {
        return GoogleStorage()
    } else {
        return LocalStorage()
    }
}

class NotesTableViewController: UITableViewController {
    
    // MARK: Properties
    var storage = CreateStorage()
    @IBOutlet weak var signInBarBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let background = UIImage(named: "BackgroundTableView")!
        self.view.backgroundColor = UIColor(patternImage: background)
        navigationItem.rightBarButtonItem = editButtonItem
        
        if UserDefaults.standard.bool(forKey: "is_google_sync") {
            //TODO remove comment (debug only)
//            navigationItem.leftBarButtonItem = nil
        } else {
            navigationItem.leftBarButtonItem = signInBarBtn
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setToolbarHidden(false, animated: false)
        navigationItem.rightBarButtonItem?.isEnabled = !storage.notes.isEmpty
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return storage.notes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "NoteTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? NoteTableViewCell else {
            fatalError("The dequeue cell is not an instance of NoteTableViewCell")
        }
        
        let note = storage.notes[indexPath.row]
        cell.setNote(note)
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            storage.delete(index: indexPath.row )
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            navigationItem.rightBarButtonItem?.isEnabled = !storage.notes.isEmpty
        }
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
            
        case "googleOAuth":
            os_log("Sign in with Google", log: OSLog.default, type: .debug)
            
        case "AddNote":
            os_log("Adding a new note", log: OSLog.default, type: .debug)
            
        case "EditNote":
            guard let noteEditViewController = segue.destination as? NoteViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedNoteCell = sender as? NoteTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedNoteCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedNote = storage.notes[indexPath.row]
            noteEditViewController.note = selectedNote
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    @IBAction func unwindToNotesTable(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? NoteViewController, let note = sourceViewController.note {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                let oldNote = storage.notes[selectedIndexPath.row]
                
                //TODO check how to compare two objects by fields
                if oldNote.title != note.title ||
                    oldNote.text != note.text ||
                    oldNote.date != note.date {
                    storage.update(index: selectedIndexPath.row, note: note)
                    tableView.reloadRows(at: [selectedIndexPath], with: .none)
                }
            } else {
                let newIndexPath = IndexPath(row: storage.notes.count, section: 0)
                storage.add(index: newIndexPath.row, note:  note)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        } else if let sourceViewController = sender.source as? OAuthViewController {
            
            if sourceViewController.successLogIn {
                UserDefaults.standard.set(sourceViewController.successLogIn, forKey: "is_google_sync")
                storage = CreateStorage()
            }
        }
    }
}
