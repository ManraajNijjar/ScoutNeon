//
//  TitleTableViewCell.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/13/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit

class TitleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var starButton: UIButton!
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func starButtonPressed(_ sender: Any) {
        
    }
    

}
