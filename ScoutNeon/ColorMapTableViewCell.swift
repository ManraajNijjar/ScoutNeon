//
//  ColorMapTableViewCell.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/14/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import ChromaColorPicker

class ColorMapTableViewCell: UITableViewCell {

    @IBOutlet weak var mainLabel: UILabel!
    
    var chromaPicker: ChromaColorPicker!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
