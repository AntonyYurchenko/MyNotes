import UIKit
import os.log
import Speech

class NoteViewController: UIViewController, UITextViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var textView: UITextView!
    @IBOutlet var doneBarBtn: UIBarButtonItem!
    @IBOutlet weak var recordBtn: UIButton!
    
    var note: Note?
    let pulse = Pulse()
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ru"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngene = AVAudioEngine()
    
    // MARK: life-cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let background = UIImage(named: "BackgroundNoteView")!
        self.view.backgroundColor = UIColor(patternImage: background)
        
        textView.delegate = self
        speechRecognizer?.delegate = self
        navigationItem.rightBarButtonItem = nil
        recordBtn.isEnabled = false
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        SFSpeechRecognizer.requestAuthorization({ status in
            var buttonState = false
            
            switch status {
            case .authorized:
                buttonState = true
            case .denied:
                buttonState = false
            case .notDetermined:
                buttonState = false
            case .restricted:
                buttonState = false
            }
            
            DispatchQueue.main.async {
                self.recordBtn.isEnabled = buttonState
            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo
        let infoNSValue = info![UIKeyboardFrameBeginUserInfoKey] as! NSValue
        let kbSize = infoNSValue.cgRectValue.size
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0)
        textView.contentInset = contentInsets
        textView.scrollIndicatorInsets = contentInsets
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        textView.contentInset = contentInsets
        textView.scrollIndicatorInsets = contentInsets
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
        
        if let note = note {
            textView.text = String(note.title + note.text)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if note == nil {
            textView.becomeFirstResponder()
        }
        
        pulse.position = recordBtn.center
        self.view.layer.addSublayer(pulse)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        textView.resignFirstResponder()
        performSegue(withIdentifier: "unwindToNotesTable", sender: self)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        navigationItem.rightBarButtonItem = doneBarBtn
    }
    
    @IBAction func doneBarBtnTap(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
        navigationItem.rightBarButtonItem = nil
    }
    
    @IBAction func recordBtnTouchDown(_ sender: UIButton) {
        record()
        
        pulse.startPulse(radius: 200, duration: 0.5)
    }
    
    @IBAction func recordBtnTouchUp(_ sender: Any) {
        record()
        
        pulse.stopPulse()
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
    
    func record() {
        recordBtn.isEnabled = false
        
        if audioEngene.isRunning {
            audioEngene.stop()
            recognitionRequest?.endAudio()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Cant prepare audiosession")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngene.inputNode else {
            fatalError("inputNode is nil")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("recognitionRequest is nil")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            var text: String?
            
            if let resultString = result {
                text = resultString.bestTranscription.formattedString
                isFinal = resultString.isFinal
            }
            
            if error != nil || isFinal {
                if text != nil {
                    self.textView.text.append(text!+"\n")
                }
                
                self.audioEngene.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordBtn.isEnabled = true
            }
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) {
            buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngene.prepare()
        
        do {
            try audioEngene.start()
        } catch {
            print("Cant start engine")
        }
    }
}

extension NoteViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordBtn.isEnabled = true
        } else {
            recordBtn.isEnabled = false
        }
    }
}


