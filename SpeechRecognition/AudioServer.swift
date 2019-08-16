//
//  AudioServer.swift
//  SpeechRecognition
//
//  Created by Vitor Mendes on 16/08/19.
//  Copyright © 2019 Vitor Mendes. All rights reserved.
//

import Speech

class AudioServer: NSObject, SFSpeechRecognizerDelegate {
    
    public static let share = AudioServer()
    
    var speechRecognizer: SFSpeechRecognizer?
    var request:SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let language =  "pt-BR"
    var audioEngine = AVAudioEngine()
    var speacherText:String? = nil
    
    override private init(){
        super.init()
        setupSpeech(completion: { success in })
    }
    
    public func setupSpeech(completion: @escaping(Bool) -> Void){
        //        micphoneButton.isEnabled = false  //2
        speechRecognizer?.delegate = self  //3
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            var isButtonEnabled = false
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            //            OperationQueue.main.addOperation() {
            //                self.micphoneButton.isEnabled = isButtonEnabled
            completion(isButtonEnabled)
            //            }
        }
    }
    
    var timer : Timer?
    var counter = 0
    
    @IBAction private func killTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func prozessTimer() {
        counter += 1
        if self.counter >= 5{
            self.killTimer()
        }
        
    }
    
    static func audioRecorder(_ filePath: URL) -> AVAudioRecorder {
        let recorderSettings: [String : AnyObject] = [
            AVSampleRateKey: 44100.0 as AnyObject,
            AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey: 2 as AnyObject,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue as AnyObject
        ]
        let audioRecorder = try! AVAudioRecorder(url: filePath, settings: recorderSettings)
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        return audioRecorder
    }
    
    var isloading = false
    
    var start = false
    
    
    public func startRecording(completion: @escaping(_ isFinal: Bool, _ getText: String) -> Void) {
        if !isloading {
            speechRecognizer = nil
            request = nil
            recognitionTask = nil
            audioEngine = AVAudioEngine()
            speacherText = nil
            isloading = false
            start = false
            timer = nil
            counter = 0
            isloading = true
            if start {
                self.audioEngine.inputNode.removeTap(onBus: 0)
            }
            start = true
            self.killTimer()
            counter = 0
            timer = Timer.scheduledTimer(timeInterval:1, target:self, selector:#selector(prozessTimer), userInfo: nil, repeats: true)
            speacherText = nil
            DispatchQueue.global(qos: .background).async {
                debugPrint("\(#function)")
                
                
                
                
                let audioSession = AVAudioSession.sharedInstance()
                
                do {
                    
                    try audioSession.setCategory(AVAudioSession.Category.playAndRecord,mode: .default)
                    try audioSession.setMode(AVAudioSession.Mode.spokenAudio)
                    
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                    
                    //            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.interruptSpokenAudioAndMixWithOthers])
                    //            try audioSession.setMode(.measurement)
                    //            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    
                } catch  {
                    debugPrint("Audio session initialization error: \(error.localizedDescription)")
                }
                
                let recordingFormat = self.audioEngine.inputNode.outputFormat(forBus: 0)
                
                self.audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
                    self.request?.append(buffer)
                    if self.counter >= 5{
                        DispatchQueue.main.async{
                            if(self.speacherText == nil){
                                self.isloading = false
                                completion(true," ")
                                return
                            }
                        }
                    }
                }
                
                self.request = SFSpeechAudioBufferRecognitionRequest()
                guard let request = self.request else {
                    self.stopRecording()
                    // self.audioEngine.inputNode.removeTap(onBus: 0)
                    return
                }
                request.shouldReportPartialResults = true
                
                debugPrint("language: \(self.language)")
                self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: self.language))
                guard let recognizer = self.speechRecognizer else {
                    assert(false, "Failed to create the speech recognizer")
                    return
                }
                
                self.recognitionTask = recognizer.recognitionTask(with: request, resultHandler: { (result, error) in
                    var isFinal = false
                    
                    if let result = result {
                        let recording = result.bestTranscription.formattedString
                        self.speacherText = recording
                        isFinal = result.isFinal
                        DispatchQueue.main.async {
                            self.isloading = false
                            completion(isFinal,recording)
                        }
                    }
                    
                    if error != nil || isFinal {
                        if(error != nil){
                            print("isto nao e um teste " + error!.localizedDescription)
                        }
                        self.audioEngine.inputNode.removeTap(onBus: 0)
                    }
                })
                
                self.audioEngine.prepare()
                do {
                    try self.audioEngine.start()
                    self.isloading = false
                }
                catch {
                    debugPrint("Error: \(error)")
                    self.isloading = false
                }
            }
        }
    }
    
    
    
    public func stopRecording(){
        self.killTimer()
        debugPrint("\(#function)")
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        
        recognitionTask?.cancel()
        recognitionTask = nil
        request = nil
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        //        micphoneButton.isEnabled = available
        print("SFSpeechRecognizer, availabilityDidChange available = \(available)")
    }
    
}


