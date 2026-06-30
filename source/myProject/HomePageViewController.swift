//
//  ViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/16.
//

import UIKit
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
        
        // Core Data 為同步讀取，App 啟動時通常已就緒；若已就緒則直接解除 loading 畫面
        if MyDatabase.isReady {
            dbReady()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(dbReady), name: MyDatabase.databaseReadyNotification, object: nil)
            // 安全機制：避免任何意外導致畫面永遠卡在 loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.dbReady()
            }
        }
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

        /* 檢查發票號碼格式 */
        guard invoiceNumberFormatCheck(invoiceNumber) else {
            showSimpleAlert(title: "儲存失敗", message: "發票號碼格式不符合")
            return
        }
        guard isUnique(invoiceNumber) else {
            showSimpleAlert(title: "儲存失敗", message: "發票號碼已存在")
            return
        }

        // 選擇消費分類後再儲存
        let sheet = UIAlertController(title: "選擇消費分類", message: nil, preferredStyle: .actionSheet)
        for category in invoiceCategories {
            sheet.addAction(UIAlertAction(title: category, style: .default) { _ in
                self.saveInvoice(category: category)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        sheet.popoverPresentationController?.sourceView = sender
        sheet.popoverPresentationController?.sourceRect = sender.bounds
        present(sheet, animated: true)
    }

    private func saveInvoice(category: String) {
        let addInvoice = Invoice(number: invoiceNumberTextField.text ?? "",
                                 date: invoiceDateTextField.text ?? "",
                                 storeName: invoiceStoreTextField.text ?? "",
                                 itemAndPrice: temporaryItemAndPrice,
                                 category: category)
        Invoice.globalInvoiceArray.append(addInvoice)
        MyDatabase().addInvoiceToDB(addInvoice)

        // 清空所有欄位
        invoiceNumberTextField.text = ""
        invoiceDateTextField.text = ""
        invoiceStoreTextField.text = ""
        itemAndPriceTextView.text = "(可留空)"
        invoiceTotalPriceLabel.text = "$0"
        // temporaryItemAndPrice 是暫時的, 儲存後要清空
        temporaryItemAndPrice = []

        showSimpleAlert(title: "儲存成功", message: "分類：\(category)")
    }

    private func showSimpleAlert(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "確定", style: .default))
        present(alertController, animated: true)
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

