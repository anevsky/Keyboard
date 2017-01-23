//
//  ANKeyboardBuilder.swift
//  Keyboard
//
//  Created by  Alex Nevsky on 23.01.16.
//  Copyright © 2016 Alex Nevsky. All rights reserved.
//

import Foundation

public class ANKKeyboardBuilder {
    
    public init() { }
    
    public func create(layoutId: String, nextKeyboardButton: UIButton, textDocumentProxy: UITextDocumentProxy, containerView: UIView) -> ANKKeyboard {
        let keyboard = ANKKeyboard(layoutId: layoutId, nextKeyboardButton: nextKeyboardButton, textDocumentProxy: textDocumentProxy, containerView: containerView)
        keyboard.setup()
        
        return keyboard
    }
}