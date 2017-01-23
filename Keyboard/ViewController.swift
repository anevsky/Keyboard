//
//  ViewController.swift
//  Keyboard
//
//  Created by  Alex Nevsky on 23.01.16.
//  Copyright © 2016 Alex Nevsky. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    @IBOutlet weak var backgroundImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let blurEffect = UIBlurEffect(style:.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = self.backgroundImageView.bounds;
        self.backgroundImageView.addSubview(blurView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

