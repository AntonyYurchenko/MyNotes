//
//  NotesTableViewController.swift
//  MyNotes
//
//  Created by Antony Yurchenko on 15/12/16.
//  Copyright © 2016 antonybrro. All rights reserved.
//

import UIKit
import os.log

class NotesTableViewController: UITableViewController {
    
    // MARK: Properties
    var notes = [Note]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let background = UIImage(named: "BackgroundTableView")!
        self.view.backgroundColor = UIColor(patternImage: background)
        
        navigationItem.leftBarButtonItem = editButtonItem
        
        
        if let savedNotes = loadNotes() {
            notes += savedNotes
        } else {
            loadSampleNotes()
        }
        
        if notes.count == 0 {
            loadSampleNotes()
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return notes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "NoteTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? NoteTableViewCell else {
            fatalError("The dequeue cell is not an instance of NoteTableViewCell")
        }
        
        let note = notes[indexPath.row]
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
            
            notes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {}
        
        saveNotes()
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
            
        case "AddNote":
            os_log("Adding a new note", log: OSLog.default, type: .debug)
            
        case "ShowAndEdit":
            guard let noteEditViewController = segue.destination as? NoteViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedNoteCell = sender as? NoteTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedNoteCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedNote = notes[indexPath.row]
            noteEditViewController.note = selectedNote
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    @IBAction func unwindToNoteList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? NoteViewController, let note = sourceViewController.note {
            
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                notes[selectedIndexPath.row] = note
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                let newIndexPath = IndexPath(row: notes.count, section: 0)
                notes.append(note)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            
            saveNotes()
        }
    }
    
    // MARK: Private Methods
    private func loadSampleNotes() {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "dd.MM.yy"
        
        let note = Note(title: "This is the sample note", text: "You can create your own notes with this app.\nAll your notes save in google sheets.", date: dateFormat.string(from: Date()))
        notes.append(note)
    }
    
    private func saveNotes() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(notes, toFile: Note.ArchiveURL.path)
        
        if isSuccessfulSave {
            os_log("Notes successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save note...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadNotes() -> [Note]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Note.ArchiveURL.path) as? [Note]
    }
}
