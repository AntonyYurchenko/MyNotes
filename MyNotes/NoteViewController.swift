import UIKit
import os.log

class NoteViewController: UIViewController, UITextViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet var doneBtn: UIBarButtonItem!
    var note: Note?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let background = UIImage(named: "BackgroundNoteView")!
        self.view.backgroundColor = UIColor(patternImage: background)
        
        noteTextView.delegate = self
        self.automaticallyAdjustsScrollViewInsets = false
        
        navigationItem.rightBarButtonItem = nil
    }
    
    // MARK: UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        navigationItem.rightBarButtonItem = doneBtn
    }
    
    // MARK: Bar Buttons Actions
    @IBAction func doneBarBtnTap(_ sender: UIBarButtonItem) {
        noteTextView.resignFirstResponder()
        navigationItem.rightBarButtonItem = nil
    }
    
    // MARK: life-cycle methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let note = note {
            noteTextView.text = String("\(note.title)\n\(note.text)")
        } else {
            //TODO Google why viewDidAppear not called
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.noteTextView.becomeFirstResponder()
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        noteTextView.resignFirstResponder()
        performSegue(withIdentifier: "unwindToNotesTable", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        //TODO Refactor string parsing
        if let text = noteTextView.text {
            if !text.isEmpty {
                var separatedText = [String]()
                for string in text.components(separatedBy: "\n") {
                    separatedText.append(string)
                }
                
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
            } else {
                return
            }
        }
    }
}

