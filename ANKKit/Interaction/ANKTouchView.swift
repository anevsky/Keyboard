//
//  ANTouchView.swift
//  Keyboard
//
//  Created by  Alex Nevsky on 23.01.16.
//  Copyright © 2016 Alex Nevsky. All rights reserved.
//

import Foundation
import SwiftyJSON
import AVFoundation

public class ANKTouchView: UIView {
    
    public weak var delegate: ANKKeyboard?
    
    var letterTouchMap: Dictionary<String, Array<Dictionary<String, CGFloat>>>?
    var digitTouchMap: Dictionary<String, Array<Dictionary<String, CGFloat>>>?
    var specialCharTouchMap: Dictionary<String, Array<Dictionary<String, CGFloat>>>?
    
    var holdBackspace = false
    var prevX: CGFloat = CGFloat.max
    var moveDeletionInterval:CGFloat = 7
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initialize()
    }
    
    convenience init() {
        self.init(frame: CGRectZero)
        
        self.initialize()
    }
    
    func initialize() {
        self.multipleTouchEnabled = true
        self.loadLetterTouchModel()
        self.loadDigitTouchModel()
        self.loadSpecialCharTouchModel()
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        if self.holdBackspace {
            return
        }
        
        AudioServicesPlaySystemSound (1104)
        
        let currentPoint = touch.locationInView(self)
        let likelyKey = self.resolveTouch(currentPoint)
        
        self.delegate?.animateKey(likelyKey)
    }
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let currentPoint = touch.locationInView(self)
        
        if !self.holdBackspace {
            let likelyKey = self.resolveTouch(currentPoint)
            
            if likelyKey == "backspace" {
                self.holdBackspace = true
            }
            
            self.delegate?.animateKey(likelyKey)
        }
        else if prevX - currentPoint.x > CGFloat(moveDeletionInterval) {
            self.delegate?.keyPressed("backspace")
            self.prevX = currentPoint.x
            self.moveDeletionInterval = 3
        }
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let backspaceWasHolded = self.holdBackspace
        self.holdBackspace = false
        self.prevX = CGFloat.max
        
        guard let touch = touches.first else {
            return
        }
        
        if !backspaceWasHolded {
            let currentPoint = touch.locationInView(self)
            let likelyKey = self.resolveTouch(currentPoint)
            
            if touch.tapCount == 1 {
                self.delegate?.keyPressed(likelyKey)
            }
            else if likelyKey == "shift" && touch.tapCount == 2 {
                self.delegate?.shiftDoublePressed()
            }
            else if likelyKey == "space" && touch.tapCount > 1 {
                self.delegate?.spaceDoublePressed()
            }
            else if likelyKey == "backspace" && touch.tapCount == 2 {
                self.delegate?.backspaceDoublePressed()
            }
            else {
                self.delegate?.keyPressed(likelyKey)
            }
        }
    }
    
    public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        self.holdBackspace = false
        self.prevX = CGFloat.max
        
        guard let touch = touches!.first else {
            return
        }
        
        let currentPoint = touch.locationInView(self)
        print("touchesCancelled", currentPoint)
    }
    
    func resolveTouch(touchPoint: CGPoint) -> String {
        var likelyKey: String = ""
        var minDistance = CGFloat.max
        
        var lookingMap: Dictionary<String, Array<Dictionary<String, CGFloat>>>?
        switch (self.delegate?.activeLayout)! as LayoutType {
        case LayoutType.Letter:
            lookingMap = self.letterTouchMap!
        case LayoutType.Digit:
            lookingMap = self.digitTouchMap!
        case LayoutType.Special:
            lookingMap = self.specialCharTouchMap!
        }
        
        let modelName = UIDevice.currentDevice().modelName
        var shouldUseDeviceCoeficient = false
        let shouldUseOrientationCoeficient = self.delegate!.interfaceOrientation != UIInterfaceOrientation.Portrait
        var deviceCoeficient = 1.0
        var deviceYCoeficient = 0.0
        if modelName == "iPhone 6" || modelName == "iPhone 6s" {
            deviceCoeficient = 1.171875
            deviceYCoeficient = 6
            shouldUseDeviceCoeficient = true
        }
        else if modelName == "iPhone 6 Plus" || modelName == "iPhone 6s Plus" {
            deviceCoeficient = 1.29375
            deviceYCoeficient = 6
            shouldUseDeviceCoeficient = true
        }
        
        for (key, info):(String, Array) in lookingMap! {
            for coordinates in info {
                var x = coordinates["x"]!
                var y = coordinates["y"]!
                
                if shouldUseOrientationCoeficient {
                    x *= 1.755
                    
                    if modelName == "iPhone 6 Plus" || modelName == "iPhone 6s Plus" {
                        y *= 0.72
                    }
                    else {
                        y *= 0.75
                    }
                }
                
                if shouldUseDeviceCoeficient {
                    x *= CGFloat(deviceCoeficient)
                    
                    if !shouldUseOrientationCoeficient {
                        y -= CGFloat(deviceYCoeficient)
                    }
                }
                
                let difference = distanceSquared(touchPoint, to: CGPointMake(x, y))
                if (difference < minDistance) {
                    minDistance = difference
                    likelyKey = key
                }
            }
        }
        
//        print(String(format: "resolve touch: \(likelyKey), p: (%.1f, %.1f), d: %.1f", touchPoint.x, touchPoint.y, minDistance))
        
        return likelyKey
    }
    
    func distanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y);
    }
    
    func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(distanceSquared(from, to: to));
    }
    
    func loadLetterTouchModel() {
        self.loadTouchModel("qwerty_en_touch_model", layoutType: 0)
    }
    
    func loadDigitTouchModel() {
        self.loadTouchModel("123_touch_model", layoutType: 1)
    }
    
    func loadSpecialCharTouchModel() {
        self.loadTouchModel("spec_touch_model", layoutType: 2)
    }
    
    func loadTouchModel(name: String, layoutType: UInt) {
        let frameworkBundle = NSBundle(identifier: "com.alexnevsky.ANKKit")
        if let path = frameworkBundle!.pathForResource(name, ofType: "json") {
            do {
                let data = try NSData(contentsOfURL: NSURL(fileURLWithPath: path), options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: data)
                if json != JSON.null {
                    switch layoutType {
                    case 0:
                        self.letterTouchMap = (json["keys"].rawValue as? [String : Array])!
                    case 1:
                        self.digitTouchMap = (json["keys"].rawValue as? [String : Array])!
                    case 2:
                        self.specialCharTouchMap = (json["keys"].rawValue as? [String : Array])!
                    default:
                        self.letterTouchMap = (json["keys"].rawValue as? [String : Array])!
                    }
                }
                else {
                    NSLog("Could not get json from file, make sure that file contains valid json.")
                }
            } catch let error as NSError {
                NSLog(error.localizedDescription)
            }
        }
        else {
            NSLog("Invalid filename/path.")
        }
    }
}