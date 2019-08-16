//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by Vitor Mendes on 16/08/19.
//  Copyright © 2019 Vitor Mendes. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AudioServer.share.startRecording { isFinal,text  in
            self.textView.text = text
        }
    }


}

