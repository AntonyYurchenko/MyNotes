import UIKit
import os.log
import Speech

class NoteViewController: UIViewController, UITextViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var textView: UITextView!
    @IBOutlet var doneBarBtn: UIBarButtonItem!
    @IBOutlet weak var recordBtn: UIButton!
    
    var note: Note?
    
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
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        navigationItem.rightBarButtonItem = doneBarBtn
    }
    
    @IBAction func doneBarBtnTap(_ sender: UIBarButtonItem) {
        textView.resignFirstResponder()
        navigationItem.rightBarButtonItem = nil
    }
    
    @IBAction func recordBtnTouchDown(_ sender: UIButton) {
        record()
    }
    
    @IBAction func recordBtnTouchUp(_ sender: UIButton) {
        record()
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
            print("Не удалось настроить аудиосессию")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngene.inputNode else {
            fatalError("Аудио движок не имеет входного узла")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Не могу создать экземпляр запроса")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) {
            result, error in
            
            var isFinal = false
            
            if result != nil {
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngene.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngene.prepare()
        
        do {
            try audioEngene.start()
        } catch {
            print("Не удается стартонуть движок")
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


