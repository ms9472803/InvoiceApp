//
//  MyCustomTableViewCell.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/26.
//

import UIKit

@objc class MyCustomTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var storeLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var totalPriceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        numberLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        numberLabel.textColor = .label
        storeLabel.font = .systemFont(ofSize: 15)
        storeLabel.textColor = .secondaryLabel
        dateLabel.font = .systemFont(ofSize: 15, weight: .medium)
        dateLabel.textColor = .secondaryLabel
        totalPriceLabel.font = .systemFont(ofSize: 17, weight: .bold)
        totalPriceLabel.textColor = .systemBlue
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 卡片式留白
        contentView.frame = bounds.inset(by: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
