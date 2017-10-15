//
//  MessageTableViewCell.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/11/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    let firebaseController = FirebaseController.sharedInstance
    
    var messageId: String!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func filterButtonPressed(_ sender: Any) {
        firebaseController.setMessageToFiltered(messageKey: messageId)
    }
    
    

}
