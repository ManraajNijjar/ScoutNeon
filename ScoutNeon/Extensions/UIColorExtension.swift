//
//  UIColorExtension.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 10/1/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import Foundation
import UIKit

public extension UIColor {
    convenience init(hex: String) {
        var cleanedHex = hex
        if hex.contains("#") {
            cleanedHex.remove(at: cleanedHex.startIndex)
        }
        let scanner = Scanner(string: cleanedHex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}
