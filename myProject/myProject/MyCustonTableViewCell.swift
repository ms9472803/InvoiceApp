//
//  MyCustonTableViewCell.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/26.
//

import UIKit

class MyCustonTableViewCell: UITableViewCell {

    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var numberLabel: UILabel!
    @IBOutlet var storeLabel: UILabel!
    @IBOutlet var totalPriceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
