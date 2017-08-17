//
//  AccountSetupViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/16/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import ChromaColorPicker

class AccountSetupViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var anonSwitch: UISegmentedControl!
    
    @IBOutlet weak var submitButton: UIButton!
    
    var userIDFromLogin: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let neatColorPicker = ChromaColorPicker(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        neatColorPicker.delegate = self //ChromaColorPickerDelegate
        neatColorPicker.padding = 5
        neatColorPicker.stroke = 3
        neatColorPicker.hexLabel.textColor = UIColor.white
        
        neatColorPicker.center = self.view.center
        
        view.addSubview(neatColorPicker)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func submitPressed(_ sender: Any) {
    }
    

}

extension AccountSetupViewController: ChromaColorPickerDelegate {
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        
    }
}
