//
//  NotesTableViewController.swift
//  MyNotes
//
//  Created by Antony Yurchenko on 15/12/16.
//  Copyright © 2016 antonybrro. All rights reserved.
//

import UIKit
import os.log

func CreateStorage(_ isLocal : Bool) -> Storage {
    if isLocal {
        return LocalStorage()
    } else {
        return GoogleStorage()
    }
}
class NotesTableViewController: UITableViewController {
    
    // MARK: Properties
    var notes = [Note]()
    var storage : Storage?
    let indicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        indicator.isUserInteractionEnabled = false
        indicator.frame = self.view.bounds
        indicator.color = UIColor.darkGray
        view.addSubview(indicator)
        indicator.startAnimating()
    
        let background = UIImage(named: "BackgroundTableView")!
        self.view.backgroundColor = UIColor(patternImage: background)
        
        navigationItem.leftBarButtonItem = editButtonItem
        
        googleSignIn()
    }
    
    func googleSignIn() {
        
        let oauthViewController = OAuthViewController()
        
        if oauthViewController.getRefreshToken() {
            oauthViewController.accessTokenTaken = {
                self.storage = CreateStorage(false)
                self.storage?.load(handler: { note in
                    self.storage?.load(handler: { note in
                        self.continueLoad(note)
                    })
                })
            }
            return
        }
        
        let alert = UIAlertController(title: "Google Sign in", message: "Do you want sign in\n to Google?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: { action in
            self.storage = CreateStorage(true)
            self.storage?.load(handler: { note in
                self.continueLoad(note)
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            
            self.present(oauthViewController, animated: true, completion: nil)
            
            oauthViewController.accessTokenTaken = {
                oauthViewController.dismiss(animated: true, completion: nil)
                
                self.storage = CreateStorage(false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.storage?.load(handler: { note in
                        self.storage?.load(handler: { note in
                            self.continueLoad(note)
                        })
                    })
                }
            }
            oauthViewController.cancelFunc = { _ in
                
                oauthViewController.dismiss(animated: true, completion: nil)
                
                self.storage = CreateStorage(true)
                self.storage?.load(handler: { note in
                    self.continueLoad(note)
                })
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func continueLoad(_ note: [Note]?) {
        if let savedNotes = note {
            notes += savedNotes
            print(notes.count)
            print("123")
            indicator.stopAnimating()
            self.tableView.reloadData()
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
            
            storage?.delete(index: indexPath.row + 1)
        } else if editingStyle == .insert {}
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
                
                storage?.update(index: selectedIndexPath.row + 1, note: note)
            } else {
                let newIndexPath = IndexPath(row: notes.count, section: 0)
                notes.append(note)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
                
                storage?.add(index: newIndexPath.row + 1, note:  note)
            }
        }
    }
}
