//
//  ViewController.swift
//  MyNotes
//
//  Created by Antony Yurchenko on 15/12/16.
//  Copyright © 2016 antonybrro. All rights reserved.
//

import UIKit
import os.log

class NoteViewController: UIViewController, UITextViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var noteTextView: UITextView!
    var doneBarBtn: UIBarButtonItem!
    var saveBarBtn: UIBarButtonItem!
    var cancelBarBtn: UIBarButtonItem!
    var note: Note?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let background = UIImage(named: "BackgroundNoteView")!
        self.view.backgroundColor = UIColor(patternImage: background)
        
        noteTextView.delegate = self
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        if let note = note {
            navigationItem.title = "Note"
            doneBarBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(NoteViewController.doneBarBtnTap))
            noteTextView.text = String("\(note.title)\n\(note.text)")
        } else {
            saveBarBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(NoteViewController.saveBarBtnTap))
            saveBarBtn.isEnabled = false
            cancelBarBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(NoteViewController.cancelBarBtnTap))
            
            navigationItem.setRightBarButton(saveBarBtn, animated: false)
            navigationItem.setLeftBarButton(cancelBarBtn, animated: false)
        }
    }
    
    // MARK: UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        // MARK: Temp solution
        if navigationItem.rightBarButtonItem !== nil {
            return
        }
        
        navigationItem.setRightBarButton(doneBarBtn, animated: true)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if navigationItem.rightBarButtonItem === saveBarBtn {
            saveBarBtn.isEnabled = !textView.text.isEmpty
        }
    }
    
    // MARK: Bar Buttons Actions
    func doneBarBtnTap() {
        self.view.endEditing(true)
        navigationItem.rightBarButtonItem = nil
    }
    
    func saveBarBtnTap() {
        self.view.endEditing(true)
        
        performSegue(withIdentifier: "unwindToNoteList", sender: self)
    }
    
    func cancelBarBtnTap() {
        self.view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: life-cycle methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        var separatedText = [String]()
        if let text = noteTextView.text {
            for string in text.components(separatedBy: "\n") {
                separatedText.append(string)
            }
        }
        
        // TODO: Logic for title? text?
        var title = separatedText[0]
        separatedText.remove(at: 0)
        
        var text = String()
        for string in separatedText {
            text.append(string + "\n")
        }
        if !separatedText.isEmpty {
            text.remove(at: text.index(before: text.endIndex))
        } else {
            title = noteTextView.text
        }
        
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "dd.MM.yy"
        let date = dateFormat.string(from: Date())
        
        note = Note(title: title, text: text, date: date)
    }
    
    // MARK: Temp solution
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if navigationItem.rightBarButtonItem === nil {
            performSegue(withIdentifier: "unwindToNoteList", sender: self)
        }
    }
}

