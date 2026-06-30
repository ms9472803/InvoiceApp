//
//  ItemAndPriceInfoViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/19.
//

import UIKit
import SwiftUI

class ItemAndPriceInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var itemAndPriceTableView: UITableView!
    
    @IBOutlet weak var addItemButton: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
        
        let fullScreenSize = UIScreen.main.bounds.size
        itemAndPriceTableView = UITableView(frame: CGRect(x: 0, y: 30, width: fullScreenSize.width, height: fullScreenSize.height-20))
        itemAndPriceTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        itemAndPriceTableView.delegate = self
        itemAndPriceTableView.dataSource = self
        itemAndPriceTableView.separatorStyle = .singleLine
        view.addSubview(itemAndPriceTableView)
        itemAndPriceTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            itemAndPriceTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            itemAndPriceTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            itemAndPriceTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            itemAndPriceTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        if canModify == true {
            title = "編輯品項"
            addItemButton.isHidden = false
        } else {
            title = "品項資訊"
            addItemButton.isHidden = true
        }
    }
    
    
    /* Swipe left to delete an item */
    func tableView(_ tableView: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if canModify == true {
            let deleteAction = UIContextualAction(style: .destructive, title: "刪除") { (action, view, completionHandler) in
                print("刪除")
  
                let invoiceDB = MyDatabase()
                invoiceDB.removeInvoiceFromDB(Invoice.invoiceShowCurrent.number)
                
                
     
            outer: for i in 0..<Invoice.globalInvoiceArray.count {
                        // First find which invoice it is
                if Invoice.globalInvoiceArray[i] == Invoice.invoiceShowCurrent {
                    Invoice.globalInvoiceArray[i].itemAndPrice = Invoice.globalInvoiceArray[i].itemAndPrice.filter { $0.itemName != Invoice.invoiceShowCurrent.itemAndPrice[indexPath.row].itemName }
                            break
                        }
                    }
                
                
                /*for i in invoiceShowCurrent.itemAndPrice {
                    print(i.itemName, i.amount, i.price)
                }*/
                
                Invoice.invoiceShowCurrent.itemAndPrice.remove(at: indexPath.row)
                invoiceDB.addInvoiceToDB(Invoice.invoiceShowCurrent)
                tableView.reloadData()
                completionHandler(true)
            }
            return UISwipeActionsConfiguration(actions: [deleteAction])
        } else {
            return nil
        }
    }
    
    
    @IBAction func addItemButton(_ sender: UIButton) {
        let alertController = UIAlertController(title: "新增品項數量金額", message: "請輸入資訊", preferredStyle: UIAlertController.Style.alert)
        
        alertController.addTextField { textField in textField.placeholder = "品項" }
        alertController.addTextField { textField in textField.placeholder = "數量" }
        alertController.addTextField { textField in textField.placeholder = "金額" }
        
        alertController.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "確定", style: UIAlertAction.Style.default) { action in
            // What to do after tapping OK
                
            let itemString = alertController.textFields?[0].text ?? ""
            let amountString = alertController.textFields?[1].text ?? ""
            let priceString = alertController.textFields?[2].text ?? ""
            
            // Check whether the price is valid (Int && >=0)
            if let priceInt = Int(priceString), let amountInt = Int(amountString), priceInt >= 0, amountInt > 0 {
                print("輸入的品項為： \(itemString) \n 輸入的數量為： \(amountString) \n 輸入的金額為： \(priceString)")
                Invoice.invoiceShowCurrent.itemAndPrice.append(Item(itemName: itemString, amount: amountString, price: priceString))
                
                let invoiceDB = MyDatabase()
                invoiceDB.removeInvoiceFromDB(Invoice.invoiceShowCurrent.number)
                for i in 0..<Invoice.globalInvoiceArray.count {
                    if Invoice.globalInvoiceArray[i] == Invoice.invoiceShowCurrent {
                        Invoice.globalInvoiceArray[i].itemAndPrice = Invoice.invoiceShowCurrent.itemAndPrice
                        invoiceDB.addInvoiceToDB(Invoice.globalInvoiceArray[i])
                        break
                    }
                }

            }

            self.itemAndPriceTableView.reloadData()
        })
        present(alertController, animated: true, completion: nil)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Invoice.invoiceShowCurrent.itemAndPrice.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) //dequeueReusableCell retrieves a reusable table cell from the queue by the given cell identifier
        var itemAndPriceInfo = ""
        let item = Invoice.invoiceShowCurrent.itemAndPrice[indexPath.row]
        itemAndPriceInfo += "品項: \(item.itemName) ; 數量: \(item.amount) ; 金額: $\(item.price)\n"
        
        cell.textLabel?.text = itemAndPriceInfo
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("修改品項", indexPath.row)

        let modifyItem = Invoice.invoiceShowCurrent.itemAndPrice[indexPath.row]
        // Clear the cell's selected state
        tableView.deselectRow(at: indexPath, animated: false)
        if !canModify {
            return
        }
        
        
        let alertController = UIAlertController(title: "修改品項數量金額", message: "請輸入資訊", preferredStyle: UIAlertController.Style.alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "品項"
            textField.text = modifyItem.itemName
        }
        alertController.addTextField {
            textField in textField.placeholder = "數量"
            textField.text = modifyItem.amount
        }
        alertController.addTextField {
            textField in textField.placeholder = "金額"
            textField.text = modifyItem.price
        }
        
        alertController.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "確定", style: UIAlertAction.Style.default) { action in
            
            let itemString = alertController.textFields?[0].text ?? ""
            let amountString = alertController.textFields?[1].text ?? ""
            let priceString = alertController.textFields?[2].text ?? ""
                
            // Check whether the price is valid (Int && >=0)
            if let priceInt = Int(priceString), let amountInt = Int(amountString), priceInt >= 0, amountInt > 0 {

                print("輸入的品項為： \(itemString) \n 輸入的數量為： \(amountString) \n 輸入的金額為： \(priceString)")
                Invoice.invoiceShowCurrent.itemAndPrice[indexPath.row] = Item(itemName: itemString, amount: amountString, price: priceString)
                let invoiceDB = MyDatabase()
                invoiceDB.removeInvoiceFromDB(Invoice.invoiceShowCurrent.number)
                for i in 0..<Invoice.globalInvoiceArray.count {
                    if Invoice.globalInvoiceArray[i] == Invoice.invoiceShowCurrent {
                        Invoice.globalInvoiceArray[i].itemAndPrice = Invoice.invoiceShowCurrent.itemAndPrice
                        invoiceDB.addInvoiceToDB(Invoice.globalInvoiceArray[i])
                        break
                    }
                }
            }
            self.itemAndPriceTableView.reloadData()
        })
        present(alertController, animated: true, completion: nil)
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
