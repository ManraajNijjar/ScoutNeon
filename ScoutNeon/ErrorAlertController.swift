//
//  ErrorAlertController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/16/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import Foundation
import UIKit

class ErrorAlertController {
    func displayAlert(title: String, message: String, view: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: nil))
        view.present(alert, animated: true, completion: nil)
    }
}
