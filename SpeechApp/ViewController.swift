//
//  ViewController.swift
//  SpeechApp
//
//  Created by mac on 3/2/20.
//  Copyright © 2020 Le An Nguyen. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate, UITextFieldDelegate, UITextViewDelegate {
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier:"en-us"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    var text1 = ""
    var text2 = ""

    var alert = UIAlertController()
    
    @IBOutlet weak var recBtn: UIButton!
    @IBOutlet weak var tf: UITextField!
    @IBOutlet weak var tf2: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tf.delegate = self
        tf2.delegate = self
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "record.png"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
        button.frame = CGRect(x: CGFloat(tf.frame.size.width - 25), y: CGFloat(5), width: CGFloat(25), height: CGFloat(25))
        button.addTarget(self, action: #selector(self.refresh), for: .touchUpInside)
        tf.rightView = button
        tf.rightViewMode = .always
        
        // Do any additional setup after loading the view.
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { status in
            var buttonState = false
            switch status {
            case .authorized:
                buttonState = true
                print("Permission received")
            case .denied:
                buttonState = false
                print("User did not give permission to use speech recognition")
            case .notDetermined:
                buttonState = false
                print("Speech recognition not allowed by user")
            case .restricted:
                buttonState = false
                print("Speech recognition not supported on this device")
            @unknown default:
                buttonState = false
                print("Unkown fatal error")
            }
            DispatchQueue.main.async {
                self.recBtn.isEnabled = buttonState
            }
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        print("RECORDING")
        
        var cursorPosition = 0
        if let selectedRange = self.tf.selectedTextRange {
            cursorPosition = self.tf.offset(from: self.tf.beginningOfDocument, to: selectedRange.start)
            print("\(cursorPosition)")
        }
        
        let text = self.tf.text!
        let selectedIndex = text.index(text.startIndex, offsetBy: cursorPosition)
        text1 = String(text[text.startIndex..<selectedIndex])
        text2 = String(text[selectedIndex..<text.endIndex])
        
        startRecording()
        alert = UIAlertController(title: "Recording", message: "", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            self.stopRecording()
        }))

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.stopRecording()
            self.tf.text = self.text1 + self.alert.message! + self.text2
        }))

        self.present(alert, animated: true)
    }

    func startRecording() {
        print("Recording started")
        
        if recognitionTask != nil { //used to track progress of a transcription or cancel it
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category(rawValue:
                convertFromAVAudioSessionCategory(AVAudioSession.Category.record)), mode: .default)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest() //read from buffer
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Could not create request instance")
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Can't start the engine")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { res, err in
            var isLast = false
            if let res = res {
//                let bestStr = self.text1 + res.bestTranscription.formattedString + self.text2
                self.alert.message = res.bestTranscription.formattedString
//                if self.tf.isEditing {
//                    self.tf.text = bestStr
//                }
//
//                if self.tf2.isEditing {
//
//                    self.tf2.text = bestStr
//                }

                isLast = (res.isFinal)
                
            }
            
            if err != nil || isLast {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.recBtn.setTitle("Record", for: .normal)
                print("Recording stopped")
            }
        }
    }
    
    fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
        return input.rawValue
    }
    
    fileprivate func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    @IBAction func recButtonClicked(_ sender: Any) {
        if audioEngine.isRunning {
            stopRecording()
            recBtn.setTitle("Record", for: .normal)
        } else {
            startRecording()
            var cursorPosition = 0
            if let selectedRange = self.tf.selectedTextRange {
                cursorPosition = self.tf.offset(from: self.tf.beginningOfDocument, to: selectedRange.start)
                print("\(cursorPosition)")
            }
            
            let text = self.tf.text!
            let selectedIndex = text.index(text.startIndex, offsetBy: cursorPosition)
            text1 = String(text[text.startIndex..<selectedIndex])
            text2 = String(text[selectedIndex..<text.endIndex])
            recBtn.setTitle("Stop", for: .normal)
        }
    }
    
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        if textField == tf {
//            var cursorPosition = 0
//            if let selectedRange = self.tf.selectedTextRange {
//                cursorPosition = self.tf.offset(from: self.tf.beginningOfDocument, to: selectedRange.start)
//                print("\(cursorPosition)")
//            }
//
//            let text = self.tf.text!
//            let selectedIndex = text.index(text.startIndex, offsetBy: cursorPosition)
//            text1 = String(text[text.startIndex..<selectedIndex])
//            text2 = String(text[selectedIndex..<text.endIndex])
//        }
//
//        if textField == tf2 {
//            var cursorPosition = 0
//            if let selectedRange = self.tf2.selectedTextRange {
//                cursorPosition = self.tf2.offset(from: self.tf2.beginningOfDocument, to: selectedRange.start)
//                print("\(cursorPosition)")
//            }
//
//            let text = self.tf2.text!
//            let selectedIndex = text.index(text.startIndex, offsetBy: cursorPosition)
//            text1 = String(text[text.startIndex..<selectedIndex])
//            text2 = String(text[selectedIndex..<text.endIndex])
//        }
//    }
}

