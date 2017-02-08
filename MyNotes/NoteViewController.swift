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
        self.navigationController?.setToolbarHidden(true, animated: false)

        if let note = note {
            textView.text = String(note.title + note.text)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if note == nil {
//            textView.becomeFirstResponder()
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
        
        var distance = 0
        for _ in 0...5 {
            // create a square
            let square = UIView()
            createCircle(view: square)
//            square.frame = CGRect(x: recordBtn.center.x, y: recordBtn.center.y, width: 50, height: 10)
//            square.backgroundColor = UIColor.red
            self.view.addSubview(square)
            
            
            // for every y-value on the bezier curve
            // add our random y offset so that each individual animation
            // will appear at a different y-position
            let path = UIBezierPath()
            path.move(to: CGPoint(x: recordBtn.center.x, y: recordBtn.center.y))
            
//            path.addCurve(to: CGPoint(x: recordBtn.center.x, y: recordBtn.center.y - CGFloat(distance)),
//                          controlPoint1: CGPoint(x: recordBtn.center.x, y: recordBtn.center.y - CGFloat(distance)),
//                          controlPoint2: CGPoint(x: recordBtn.center.x, y: recordBtn.center.y - CGFloat(distance)))
            path.addLine(to: CGPoint(x: recordBtn.center.x, y: 400 + CGFloat(distance)))
            
            // create the animation
            let anim = CAKeyframeAnimation(keyPath: "position")
            anim.path = path.cgPath
            anim.repeatCount = Float.infinity
            anim.duration = 2.0
            
            // add the animation 
            square.layer.add(anim, forKey: "animate position along path")
            
            let opacity = CABasicAnimation(keyPath: "opacity")
            opacity.toValue = 0
            opacity.duration = 2.0
            opacity.repeatCount = Float.infinity
            
            // add the animation
            square.layer.add(opacity, forKey: "animate opacity along path")
            distance += 30
            
            let positionAnimation = CABasicAnimation(keyPath:"bounds.size.width")
            positionAnimation.toValue = 100
            positionAnimation.duration = 3.0
            positionAnimation.repeatCount = Float.infinity
            square.layer.add(positionAnimation, forKey: "bounds")
        }
    }

    @IBAction func recordBtnTouchUp(_ sender: Any) {
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
    
    func createCircle(view: UIView) {
        let shapeLayer = CAShapeLayer()
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: view.frame.maxX / 2, y: view.frame.maxY - 70),
                                      radius: CGFloat(30),
                                      startAngle: CGFloat(M_PI),
                                      endAngle:CGFloat(0),
                                      clockwise: true)
        
        shapeLayer.path = circlePath.cgPath
        
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor(red: 0, green: 205/255, blue: 1, alpha: 1).cgColor
        shapeLayer.lineWidth = 3
        
        view.layer.addSublayer(shapeLayer)
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


