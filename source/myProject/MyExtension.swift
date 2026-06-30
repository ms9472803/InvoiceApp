//
//  MyExtension.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/26.
//

import Foundation
import UIKit


// Keep extensions in a separate file
// check a String is Int or not
extension String {
    var isInt: Bool {
        return Int(self) != nil
    }
}

extension UITableView {
    // Show a centered placeholder message when the list has no data; pass nil to clear it.
    func setEmptyMessage(_ message: String?) {
        guard let message = message else {
            backgroundView = nil
            return
        }
        let label = UILabel()
        label.text = message
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        backgroundView = label
    }
}
