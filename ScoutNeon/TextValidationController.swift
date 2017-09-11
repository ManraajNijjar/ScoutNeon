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
    
    init() {
        validator.characterSet = NSCharacterSet.alphanumerics

        
    }
    
    //Generate a Singleton instance of the TwitterAPIController
    class func sharedInstance() -> TextValidationController {
        struct Singleton {
            static var sharedInstance = TextValidationController()
        }
        return Singleton.sharedInstance
    }
}
