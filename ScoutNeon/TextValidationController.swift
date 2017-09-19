//
//  TextValidationController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/26/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import Foundation
import Validation

class TextValidationController{
    var validator = Validation()
    static let sharedInstance = TextValidationController()
    
    init() {
        validator.characterSet = NSCharacterSet.alphanumerics
    }
    
}
