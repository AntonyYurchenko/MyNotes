import UIKit
import os.log

class NoteViewController: UIViewController, UITextViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var textView: UITextView!
    @IBOutlet var doneBarBtn: UIBarButtonItem!
    var note: Note?
    
    // MARK: life-cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let background = UIImage(named: "BackgroundNoteView")!
        self.view.backgroundColor = UIColor(patternImage: background)
        
        textView.delegate = self
        self.automaticallyAdjustsScrollViewInsets = false
        
        navigationItem.rightBarButtonItem = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let note = note {
            textView.text = String(note.title + note.text)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if note == nil {
            textView.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        textView.resignFirstResponder()
        performSegue(withIdentifier: "unwindToNotesTable", sender: self)
    }
    
    // MARK: UITextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        navigationItem.rightBarButtonItem = doneBarBtn
    }
    
    // MARK: Bar Buttons Actions
    @IBAction func doneBarBtnTap(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
        navigationItem.rightBarButtonItem = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let text = textView.text {
            if !text.isEmpty {
                parseText(text)
            } else {
                return
            }
        }
    }
    
    //TODO Refactor string parsing
    func parseText(_ text: String) {
        var separatedText = [String]()
        for string in text.components(separatedBy: "\n") {
            separatedText.append(string)
        }
        
        var title = String()
        
        for element in separatedText {
            if !element.isEmpty {
                title += element
                if let index = separatedText.index(of: element) {
                    separatedText.remove(at: index)
                }
                break
            } else {
                title += element + "\n"
                if let index = separatedText.index(of: element) {
                    separatedText.remove(at: index)
                }
            }
        }
        
        var text = String()
        for string in separatedText {
            text.append("\n" + string)
        }
        
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "dd.MM.yy"
        let date = dateFormat.string(from: Date())
        
        note = Note(title: title, text: text, date: date)
    }
}

