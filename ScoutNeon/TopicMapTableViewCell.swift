//
//  TopicMapTableViewCell.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/14/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit

class TopicMapTableViewCell: UITableViewCell {

    @IBOutlet weak var mainLabel: UILabel!

    
    var topicId: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
