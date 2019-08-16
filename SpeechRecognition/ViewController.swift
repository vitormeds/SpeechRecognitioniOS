//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by Vitor Mendes on 16/08/19.
//  Copyright © 2019 Vitor Mendes. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        verifyMyc { result in
            if result {
                AudioServer.share.startRecording { text  in
                    self.textView.text = text
                }
            }
        }
    }
    
    func verifyMyc(onCompletion: @escaping (Bool) -> ()) {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            switch authStatus {
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
            onCompletion(isButtonEnabled)
            return
        }
    }


}

