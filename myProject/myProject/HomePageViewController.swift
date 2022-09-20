//
//  ViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/16.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import AVFoundation

class HomePageViewController: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate,  UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate{
    
    @IBOutlet weak var invoiceNumberTextField: UITextField!
    @IBOutlet weak var invoiceDateTextField: UITextField!
    @IBOutlet weak var invoiceStoreTextField: UITextField!
    @IBOutlet weak var itemAndPriceTextView: UITextView!
    @IBOutlet weak var invoiceTotalPriceLabel: UILabel!
    
    var datePicker = UIDatePicker()
    
    var loadingDBView: UIView?
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        //loadingDBUIView.isHidden = true
        invoiceNumberTextField.clearButtonMode = .always
        invoiceStoreTextField.clearButtonMode = .always
        itemAndPriceTextView.isEditable = false
        invoiceTotalPriceLabel.text = "$0"
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(donePresser))
        toolbar.setItems([doneBtn], animated: true)
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        invoiceDateTextField.inputView = datePicker
        invoiceDateTextField.inputAccessoryView = toolbar
        invoiceDateTextField.placeholder = "選擇日期"
        
        let fullScreenSize = UIScreen.main.bounds.size
        loadingDBView = UIView(frame: CGRect(x: 0, y: 0, width: fullScreenSize.width, height: fullScreenSize.height))
        loadingDBView?.backgroundColor = .white
        view.addSubview(loadingDBView!)
        
        let loadingLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
        loadingLabel.center = CGPoint(x: fullScreenSize.width * 0.5, y: fullScreenSize.height * 0.5)
        loadingLabel.text = "Database is loading"
        loadingLabel.font = UIFont(name: "Helvetica-Light", size: 24)
        loadingLabel.textAlignment = .center
        loadingDBView?.addSubview(loadingLabel)
        
        NotificationCenter.default.addObserver(self, selector: #selector(dbReady), name: NSNotification.Name("DatabaseReady"), object: nil)
    }
    
    @objc func donePresser() {
        invoiceDateTextField.text = transformDatePickerToString(datePicker)
        view.endEditing(true)
    }
    
    @objc func dbReady() {
        print("Database is ready")
        loadingDBView?.isHidden = true
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("DatabaseReady"), object: nil)
    }
    @IBAction func touchResetButton(_ sender: UIButton) {
        // 可以提供reset button 一鍵清除
        invoiceNumberTextField.text = ""
        invoiceDateTextField.text = ""
        invoiceStoreTextField.text = ""
        itemAndPriceTextView.text = "(可留空)"
        invoiceTotalPriceLabel.text = "$0"
        
    }

  
    // 利用 @IBAction keyword 將這個method公開給interface builder
    // 按下儲存發票後執行
    @IBAction func storeInvoice(_ sender: UIButton) {
        
        let invoiceNumber = invoiceNumberTextField.text ?? ""
        let invoiceStore = invoiceStoreTextField.text ?? ""
        let invoiceDate = invoiceDateTextField.text ?? ""

        var alertControllerTitle = ""
        var alertControllerMessage = ""
        
        /* 檢查發票號碼格式 */
        if !invoiceNumberFormatCheck(invoiceNumber) {
            alertControllerTitle = "儲存失敗"
            alertControllerMessage = "發票號碼格式不符合"
        } else if !isUnique(invoiceNumber){
            alertControllerTitle = "儲存失敗"
            alertControllerMessage = "發票號碼已存在"
        } else {
            alertControllerTitle = "儲存成功"
            /* 新增發票, 加入到globalInvoiceArray */
            let addInvoice = Invoice(number: invoiceNumber, date: invoiceDate, storeName: invoiceStore, itemAndPrice: temporaryItemAndPrice)
            Invoice.globalInvoiceArray.append(addInvoice)
            let invoiceDB = MyDatabase()
            invoiceDB.addInvoiceToDB(addInvoice)
        }
        
        let alertController = UIAlertController(title: alertControllerTitle, message: alertControllerMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "確定", style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
        
        // 清空所有text, 初始化Date
        invoiceNumberTextField.text = ""
        invoiceDateTextField.text = ""
        invoiceStoreTextField.text = ""
        itemAndPriceTextView.text = "(可留空)"
        invoiceTotalPriceLabel.text = "$0"
        // 由於temporaryItemAndPrice是暫時的, 因此儲存發票後要清空
        temporaryItemAndPrice = []
    }
    
    // 按下新增品項後執行
    @IBAction func addItemAndPrice(_ sender: UIButton) {
        let alertController = UIAlertController(title: "新增品項數量金額", message: "請輸入資訊", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { textField in textField.placeholder = "品項" }
        alertController.addTextField { textField in textField.placeholder = "數量" }
        alertController.addTextField { textField in textField.placeholder = "金額" }
        
        alertController.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "確定", style: UIAlertAction.Style.default) { action in
            //點了確定後要做的事
            let itemString = alertController.textFields?[0].text ?? ""
            let amountString = alertController.textFields?[1].text ?? ""
            let priceString = alertController.textFields?[2].text ?? ""
            
            

                
            // 判斷價格是不是合法(Int && >=0)
            if let priceInt = Int(priceString), let amountInt = Int(amountString), priceInt >= 0, amountInt > 0 {
                print("輸入的品項為： \(itemString) \n 輸入的數量為： \(amountString) \n 輸入的金額為： \(priceString)")

                temporaryItemAndPrice.append(Item(itemName: itemString, amount: amountString, price: priceString))
                // "itemAndPriceTextView" in closure requires explicit use of "self"
                if self.itemAndPriceTextView.text == "(可留空)" {
                    self.itemAndPriceTextView.text = ""
                }
                self.itemAndPriceTextView.text += "品項: \(itemString) $\(priceString) x\(amountString)\n"
                
                var sum = 0
                for tempItem in temporaryItemAndPrice {
                    sum += Int(tempItem.price) ?? 0
                }
                self.invoiceTotalPriceLabel.text = "$" + String(sum)
            }
            
        })
        present(alertController, animated: true, completion: nil)
    }
    
    // 要build到裝置中才可使用camera
    @IBAction func openCamera(_ sender: UIBarButtonItem) {
        let vc = QRCodeScannerViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
}

