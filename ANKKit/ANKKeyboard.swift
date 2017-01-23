//
//  ANKeyboard.swift
//  Keyboard
//
//  Created by  Alex Nevsky on 23.01.16.
//  Copyright © 2016 Alex Nevsky. All rights reserved.
//

import Foundation
import SwiftyJSON
import SnapKit

public enum LayoutType: UInt {
    case Letter
    case Digit
    case Special
}

public class ANKKeyboard {
    
    public let touchView: ANKTouchView
    public weak var containerView: UIView?
    public weak var textDocumentProxy: UITextDocumentProxy?
    public var activeLayout = LayoutType.Letter
    
    let layoutId: String
    
    let keyboardContainerView = UIView()
    var letterContainerView: UIView?
    var digitContainerView: UIView?
    var specialCharContainerView: UIView?
    
    let nextKeyboardButton: UIButton
    let buttons = NSMutableSet()
    
    var capsLockOn: Bool
    var capsOn: Bool
    var shiftButton: UIButton?
    var shiftImageView: UIImageView?
    var backspaceButton: UIButton?
    var spaceButton: UIButton?
    
    var themeNumber: UInt = 1
    
    var interfaceOrientation = UIInterfaceOrientation.Unknown
    
    init(layoutId: String, nextKeyboardButton: UIButton, textDocumentProxy: UITextDocumentProxy, containerView: UIView) {
        self.layoutId = layoutId
        self.nextKeyboardButton = nextKeyboardButton
        self.textDocumentProxy = textDocumentProxy
        self.containerView = containerView
        
        self.capsOn = true
        self.capsLockOn = false
        
        let touchView = ANKTouchView()
        self.touchView = touchView
        
        self.interfaceOrientation = self.detectInterfaceOrientation()
        
        self.setupLayout()
        self.resolveActiveLayout()
        self.resolveCaps()
    }
    
    public func setup() {
        self.touchView.delegate = self
        
        self.containerView?.addSubview(self.touchView)
        self.touchView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.containerView!)
        }
    }
    
    func setupLayout() {
        self.keyboardContainerView.userInteractionEnabled = false
        self.touchView.addSubview(self.keyboardContainerView)
        self.keyboardContainerView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.touchView)
        }
        
        self.setupKeyboardBackground()
    }
    
    func setupKeyboardBackground() {
        self.themeNumber = UInt(arc4random_uniform(9)) + 1
        
        let backgroundImage = UIImage(named: "w\(themeNumber)", inBundle: NSBundle(identifier: "com.alexnevsky.ANKKit"), compatibleWithTraitCollection: nil)
        let backgroundImageView = UIImageView.init(image: backgroundImage)
        backgroundImageView.userInteractionEnabled = false
        backgroundImageView.contentMode = .ScaleAspectFill
        
        self.keyboardContainerView.addSubview(backgroundImageView)
        backgroundImageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.keyboardContainerView)
        }
    }
    
    func setupLetterLayout() {
        if (self.letterContainerView == nil) {
            self.letterContainerView = UIView()
            
            self.letterContainerView!.userInteractionEnabled = false
            self.keyboardContainerView.addSubview(self.letterContainerView!)
            self.letterContainerView!.snp_makeConstraints { (make) -> Void in
                make.edges.equalTo(self.keyboardContainerView)
            }
            
            self.setupKeyLayout("qwerty_en_keyboard_layout", containerView: self.letterContainerView!)
        }
    }
    
    func setupDigitLayout() {
        if (self.digitContainerView == nil) {
            self.digitContainerView = UIView()
            
            self.digitContainerView!.userInteractionEnabled = false
            self.keyboardContainerView.addSubview(self.digitContainerView!)
            self.digitContainerView!.snp_makeConstraints { (make) -> Void in
                make.edges.equalTo(self.keyboardContainerView)
            }
            
            self.setupKeyLayout("123_keyboard_layout", containerView: self.digitContainerView!)
        }
    }
    
    func setupSpecialCharLayout() {
        if (self.specialCharContainerView == nil) {
            self.specialCharContainerView = UIView()
            
            self.specialCharContainerView!.userInteractionEnabled = false
            self.keyboardContainerView.addSubview(self.specialCharContainerView!)
            self.specialCharContainerView!.snp_makeConstraints { (make) -> Void in
                make.edges.equalTo(self.keyboardContainerView)
            }
            
            self.setupKeyLayout("spec_keyboard_layout", containerView: self.specialCharContainerView!)
        }
    }
    
    func setupKeyLayout(name: String, containerView: UIView) {
        let modelName = UIDevice.currentDevice().modelName
        var shouldUseDeviceCoeficient = false
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
        
        let frameworkBundle = NSBundle(identifier: "com.alexnevsky.ANKKit")
        if let path = frameworkBundle!.pathForResource(name, ofType: "json") {
            do {
                let data = try NSData(contentsOfURL: NSURL(fileURLWithPath: path), options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: data)
                if json != JSON.null {
                    
                    for (_, row):(String, JSON) in json["rows"] {
                        let rowTitles = (row["keys"].rawValue as? [String])!
                        var rowX = row["x"].float!
                        var rowY = row["y"].float!
                        var keyPadding = row["key_padding"].float!
                        var keyWidth = row["key_width"].float!
                        var keyHeight = row["key_height"].float!
                        
                        if shouldUseDeviceCoeficient {
                            rowX *= Float(deviceCoeficient)
                            rowY -= Float(deviceYCoeficient)
                            keyPadding *= Float(deviceCoeficient)
                            keyWidth *= Float(deviceCoeficient)
                            keyHeight *= Float(deviceCoeficient)
                        }
                        
                        if self.interfaceOrientation != UIInterfaceOrientation.Portrait {
                            rowX *= 1.775
                            rowY *= 0.75
                            keyPadding *= 1.775
                            keyWidth *= 1.775
                            
                            if modelName == "iPhone 6 Plus" || modelName == "iPhone 6s Plus" {
                                keyHeight *= 0.72
                            }
                            else {
                                keyHeight *= 0.75
                            }
                        }
                        
                        let rowButtons = self.createButtons(rowTitles, backgroundImageName: "key_light_background", systemKey: false)
                        self.buttons.addObjectsFromArray(rowButtons)
                        
                        let rowParams = [
                            "x" : rowX,
                            "y" : rowY,
                            "padding" : keyPadding,
                            "width" : keyWidth,
                            "height" : keyHeight
                        ]
                        self.addRowConstraints(rowButtons, containingView: containerView, params: rowParams)
                    }
                    
                    let specialKeys = json["special_keys"];
                    for (key, value) in specialKeys {
                        var backgroundImageName: String? = "key_dark_background"
                        if key == "space" {
                            backgroundImageName = "key_light_background"
                        }
                        
                        let specialButton = createButtons([key], backgroundImageName: backgroundImageName!, systemKey: true).first
                        
                        if (key == "globus") {
                            specialButton!.setBackgroundImage(nil, forState: .Normal)
                        }
                        
                        var x = (value["x"].rawValue as? Float)!
                        var y = (value["y"].rawValue as? Float)!
                        var keyWidth = (value["width"].rawValue as? Float)!
                        var keyHeight = (value["height"].rawValue as? Float)!
                        
                        if self.interfaceOrientation != UIInterfaceOrientation.Portrait {
                            x *= 1.775
                            y *= 0.75
                            keyWidth *= 1.775
                            
                            if modelName == "iPhone 6 Plus" || modelName == "iPhone 6s Plus" {
                                keyHeight *= 0.72
                            }
                            else {
                                keyHeight *= 0.75
                            }
                        }
                        
                        if shouldUseDeviceCoeficient {
                            x *= Float(deviceCoeficient)
                            y -= Float(deviceYCoeficient)
                            keyWidth *= Float(deviceCoeficient)
                            keyHeight *= Float(deviceCoeficient)
                        }
                        
                        containerView.addSubview(specialButton!)
                        specialButton!.snp_makeConstraints { (make) -> Void in
                            make.width.equalTo(keyWidth)
                            make.height.equalTo(keyHeight)
                            make.leading.equalTo(containerView).offset(x)
                            make.top.equalTo(containerView).offset(y)
                        }
                        
                        let frontImageName: String?
                        switch key {
                        case "shift":
                            self.shiftButton = specialButton!
                            frontImageName = "shift_uppercase"
                        case "backspace":
                            self.backspaceButton = specialButton!
                            frontImageName = "backspace"
                        case "globus":
                            frontImageName = "globus"
                        case "space":
                            self.spaceButton = specialButton!
                            frontImageName = nil
                        default:
                            frontImageName = nil
                        }
                        
                        if (frontImageName != nil) {
                            let frontImage = UIImage(named: frontImageName!, inBundle: NSBundle(identifier: "com.alexnevsky.ANKKit"), compatibleWithTraitCollection: nil)?.imageWithRenderingMode(.AlwaysTemplate)
                            
                            let frontImageView = UIImageView.init(image:frontImage)
                            frontImageView.contentMode = .ScaleAspectFit
                            
                            if key == "shift" {
                                self.shiftImageView = frontImageView
                            }
                            
                            specialButton!.addSubview(frontImageView)
                            frontImageView.snp_makeConstraints { (make) -> Void in
                                make.center.equalTo(specialButton!)
                            }
                            
                            specialButton!.setTitleColor(UIColor.clearColor(), forState: .Normal)
                        }
                        
                        self.buttons.addObject(specialButton!)
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
    
    func createButtons(titles: [String], backgroundImageName: String, systemKey: Bool) -> [UIButton] {
        var buttons = [UIButton]()
        
        for title in titles {
            let button = UIButton(type: .Custom) as UIButton
            button.setTitle(title, forState: .Normal)
            
            if !systemKey {
                button.titleLabel?.font = UIFont.systemFontOfSize(21)
            }
            else {
                if #available(iOSApplicationExtension 8.2, *) {
                    button.titleLabel?.font = UIFont.systemFontOfSize(15, weight: UIFontWeightLight)
                }
                else {
                    // Fallback on earlier versions
                    button.titleLabel?.font = UIFont.systemFontOfSize(14)
                }
            }
            
            switch self.themeNumber {
            case 1:
                button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            case 2:
                button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            case 3:
                let backgroundImage = UIImage(named: backgroundImageName, inBundle: NSBundle(identifier: "com.alexnevsky.ANKKit"), compatibleWithTraitCollection: nil)!.resizableImageWithCapInsets(UIEdgeInsetsMake(19.0, 13.0, 20.0, 17.0), resizingMode: .Stretch)
                button.setBackgroundImage(backgroundImage, forState: .Normal)
                button.setTitleColor(UIColor.blackColor(), forState: .Normal)
            case 4:
                button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            case 5:
                button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            case 6:
                button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            case 7:
                let backgroundImage = UIImage(named: backgroundImageName, inBundle: NSBundle(identifier: "com.alexnevsky.ANKKit"), compatibleWithTraitCollection: nil)!.resizableImageWithCapInsets(UIEdgeInsetsMake(19.0, 13.0, 20.0, 17.0), resizingMode: .Stretch)
                button.setBackgroundImage(backgroundImage, forState: .Normal)
                button.setTitleColor(UIColor.blackColor(), forState: .Normal)
            case 8:
                button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            case 9:
                button.setTitleColor(UIColor.blackColor(), forState: .Normal)
            default:
                let backgroundImage = UIImage(named: backgroundImageName, inBundle: NSBundle(identifier: "com.alexnevsky.ANKKit"), compatibleWithTraitCollection: nil)!.resizableImageWithCapInsets(UIEdgeInsetsMake(19.0, 13.0, 20.0, 17.0), resizingMode: .Stretch)
                button.setBackgroundImage(backgroundImage, forState: .Normal)
                button.setTitleColor(UIColor.blackColor(), forState: .Normal)
            }
            
            button.enabled = false
            button.translatesAutoresizingMaskIntoConstraints = false
            
            buttons.append(button)
        }
        
        return buttons
    }
    
    func addRowConstraints(buttons: [UIButton], containingView: UIView, params: [String:Float]) {
        for (index, button) in buttons.enumerate() {
            containingView.addSubview(button)
            
            button.snp_makeConstraints { (make) -> Void in
                make.width.equalTo(params["width"]!)
                make.height.equalTo(params["height"]!)
                make.top.equalTo(containingView).offset(params["y"]!);
                
                if index == 0 {
                    make.leading.equalTo(containingView).offset(params["x"]!);
                }
                else {
                    make.leading.equalTo(buttons[index - 1].snp_trailing).offset(params["padding"]!)
                }
            }
        }
    }
    
    @objc public func animateKey(title: String) {
        if !(title.lowercaseString == "abc"
            || title.lowercaseString == "123"
            || title.lowercaseString == "#+="
            || title.lowercaseString == "shift"
            || title.lowercaseString == "globus"
            || title.lowercaseString == "backspace")
        {
            var targetButton: UIButton?
            
            for button in self.buttons {
                let buttonTitle = button.titleLabel!!.text
                if buttonTitle?.lowercaseString == title.lowercaseString {
                    targetButton = button as? UIButton
                }
            }
            
            if (targetButton != nil) {
                let transformFactor: CGFloat = 1.2
                UIView.animateWithDuration(0.2, animations: {
                    targetButton!.transform = CGAffineTransformScale(CGAffineTransformIdentity, transformFactor, transformFactor)
                    }, completion: {(_) -> Void in
                        targetButton!.transform =
                            CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)
                })
            }
        }
    }
    
    public func keyPressed(title: String) {
        switch title {
        case "shift":
            self.shiftPressed()
        case "globus":
            self.globePressed()
        case "backspace":
            self.backspacePressed()
        case "return":
            self.returnPressed()
        case "space":
            self.spacePressed()
        case "ABC":
            self.activeLayout = LayoutType.Letter
            self.resolveActiveLayout()
        case "123":
            self.activeLayout = LayoutType.Digit
            self.resolveActiveLayout()
        case "#+=":
            self.activeLayout = LayoutType.Special
            self.resolveActiveLayout()
        default:
            (self.textDocumentProxy as! UIKeyInput).insertText(self.capsOn ?
                title.uppercaseString : title.lowercaseString)
            
            if !self.capsLockOn && self.capsOn {
                self.shiftPressed()
            }
        }
    }
    
    func resolveActiveLayout() {
        self.buttons.removeAllObjects()
        
        switch self.activeLayout {
        case LayoutType.Letter:
            self.showLetterLayout()
        case LayoutType.Digit:
            self.showDigitLayout()
        case LayoutType.Special:
            self.showSpecialCharLayout()
        }
    }
    
    func showLetterLayout() {
        self.setupLetterLayout()

        self.letterContainerView?.userInteractionEnabled = true
        self.letterContainerView?.hidden = false
        
        self.digitContainerView?.userInteractionEnabled = false
        self.digitContainerView?.hidden = true
        
        self.specialCharContainerView?.userInteractionEnabled = false
        self.specialCharContainerView?.hidden = true
    }
    
    func showDigitLayout() {
        self.setupDigitLayout()
        
        self.letterContainerView?.userInteractionEnabled = false
        self.letterContainerView?.hidden = true
        
        self.digitContainerView?.userInteractionEnabled = true
        self.digitContainerView?.hidden = false
        
        self.specialCharContainerView?.userInteractionEnabled = false
        self.specialCharContainerView?.hidden = true
    }
    
    func showSpecialCharLayout() {
        self.setupSpecialCharLayout()
        
        self.letterContainerView?.userInteractionEnabled = false
        self.letterContainerView?.hidden = true
        
        self.digitContainerView?.userInteractionEnabled = false
        self.digitContainerView?.hidden = true
        
        self.specialCharContainerView?.userInteractionEnabled = true
        self.specialCharContainerView?.hidden = false
    }
    
    func globePressed() {
        self.nextKeyboardButton.sendActionsForControlEvents(.TouchUpInside)
    }
    
    func shiftPressed() {
        self.capsOn = !self.capsOn
        self.capsLockOn = false
        
        self.resolveCaps()
    }
    
    public func shiftDoublePressed() {
        self.capsLockOn = !self.capsLockOn
        
        if !self.capsLockOn {
            self.capsOn = false
        }
        else {
            self.capsOn = true
        }
        
        self.resolveCaps()
    }
    
    func backspacePressed() {
        (self.textDocumentProxy as! UIKeyInput).deleteBackward()
    }
    
    public func backspaceDoublePressed() {
        let text = self.textDocumentProxy?.documentContextBeforeInput
        
        if text != nil {
            let lastSpaceIndex = text!.rangeOfString(" ", options: .BackwardsSearch)?.startIndex
            if lastSpaceIndex != nil {
                self.deleteBackwardTimes((lastSpaceIndex?.distanceTo((text?.endIndex)!))! - 1)
            }
            else {
                (self.textDocumentProxy as! UIKeyInput).deleteBackward()
            }
        }
    }
    
    func deleteBackwardTimes(num: Int) {
        for _ in 0...num {
            (self.textDocumentProxy as! UIKeyInput).deleteBackward()
        }
    }
    
    func spacePressed() {
        (self.textDocumentProxy as! UIKeyInput).insertText(" ")
    }
    
    public func spaceDoublePressed() {
        (self.textDocumentProxy as! UIKeyInput).deleteBackward()
        (self.textDocumentProxy as! UIKeyInput).insertText(". ")
    }
    
    func returnPressed() {
        (self.textDocumentProxy as! UIKeyInput).insertText("\n")
    }
    
    func resolveCaps() {
        if self.capsLockOn {
            self.capsUp()
        }
        else if self.capsOn {
            self.capsUp()
        }
        else {
            self.capsDown()
        }
    }
    
    func capsUp() {
        for button in self.buttons {
            let buttonTitle = button.titleLabel!!.text
            if !(buttonTitle?.lowercaseString == "space"
                || buttonTitle?.lowercaseString == "return")
            {
                let text = buttonTitle!.uppercaseString
                button.setTitle("\(text)", forState: .Normal)
            }
        }
        
        if self.shiftImageView != nil {
            if self.capsLockOn {
                self.shiftImageView!.image = UIImage(named: "shift_always_uppercase", inBundle: NSBundle(identifier: "com.alexnevsky.ANKKit"), compatibleWithTraitCollection: nil)!.imageWithRenderingMode(.AlwaysTemplate)
            }
            else {
                self.shiftImageView!.image = UIImage(named: "shift_uppercase", inBundle: NSBundle(identifier: "com.alexnevsky.ANKKit"), compatibleWithTraitCollection: nil)!.imageWithRenderingMode(.AlwaysTemplate)
            }
        }
    }
    
    func capsDown() {
        for button in self.buttons {
            let buttonTitle = button.titleLabel!!.text
            if !(buttonTitle?.lowercaseString == "abc")
            {
                let text = buttonTitle!.lowercaseString
                button.setTitle("\(text)", forState: .Normal)
            }
        }
        
        if self.shiftImageView != nil {
            self.shiftImageView!.image = UIImage(named: "shift_lowercase", inBundle: NSBundle(identifier: "com.alexnevsky.ANKKit"), compatibleWithTraitCollection: nil)!.imageWithRenderingMode(.AlwaysTemplate)
        }
    }
    
    func alphaImage(image:UIImage, value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        
        let ctx = UIGraphicsGetCurrentContext();
        let area = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height);
        
        CGContextScaleCTM(ctx, 1, -1);
        CGContextTranslateCTM(ctx, 0, -area.size.height);
        CGContextSetBlendMode(ctx, .Multiply);
        CGContextSetAlpha(ctx, value);
        CGContextDrawImage(ctx, area, image.CGImage);
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    
    func detectInterfaceOrientation() -> UIInterfaceOrientation {
        let isPortrait = UIScreen.mainScreen().bounds.size.width < UIScreen.mainScreen().bounds.size.height
        
        if isPortrait {
            return UIInterfaceOrientation.Portrait
        }
        else {
            return UIInterfaceOrientation.LandscapeLeft
        }
    }
    
    public func updateInterfaceOrientation() {
        let currentInterfaceOrientation = self.detectInterfaceOrientation()
        
        if currentInterfaceOrientation != self.interfaceOrientation {
            self.interfaceOrientation = currentInterfaceOrientation
            
            self.letterContainerView?.removeFromSuperview()
            self.digitContainerView?.removeFromSuperview()
            self.specialCharContainerView?.removeFromSuperview()
            
            self.letterContainerView = nil
            self.digitContainerView = nil
            self.specialCharContainerView = nil
            
            switch self.activeLayout as LayoutType {
            case LayoutType.Letter:
                self.setupLetterLayout()
            case LayoutType.Digit:
                self.setupDigitLayout()
            case LayoutType.Special:
                self.setupSpecialCharLayout()
            }
            
            self.resolveCaps()
        }
    }
}