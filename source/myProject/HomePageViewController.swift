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
        itemAndPriceTextView.backgroundColor = .secondarySystemBackground
        itemAndPriceTextView.layer.cornerRadius = 10
        itemAndPriceTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        itemAndPriceTextView.font = .systemFont(ofSize: 15)
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
        let loading = UIView(frame: CGRect(x: 0, y: 0, width: fullScreenSize.width, height: fullScreenSize.height))
        loading.backgroundColor = .systemBackground
        view.addSubview(loading)
        loadingDBView = loading

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = CGPoint(x: fullScreenSize.width * 0.5, y: fullScreenSize.height * 0.5 - 24)
        spinner.startAnimating()
        loading.addSubview(spinner)

        let loadingLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 250, height: 30))
        loadingLabel.center = CGPoint(x: fullScreenSize.width * 0.5, y: fullScreenSize.height * 0.5 + 24)
        loadingLabel.text = "載入中…"
        loadingLabel.font = .systemFont(ofSize: 16)
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.textAlignment = .center
        loading.addSubview(loadingLabel)
        
        // Core Data reads synchronously, so it is usually ready by app launch; if already ready, dismiss the loading screen right away
        if MyDatabase.isReady {
            dbReady()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(dbReady), name: MyDatabase.databaseReadyNotification, object: nil)
            // Safety net: prevent the screen from getting stuck on loading due to any unexpected issue
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
        // The reset button clears all fields in one tap
        invoiceNumberTextField.text = ""
        invoiceDateTextField.text = ""
        invoiceStoreTextField.text = ""
        itemAndPriceTextView.text = "(可留空)"
        invoiceTotalPriceLabel.text = "$0"
        
    }

  
    // The @IBAction keyword exposes this method to Interface Builder
    // Runs when the save-invoice button is tapped
    @IBAction func storeInvoice(_ sender: UIButton) {
        let invoiceNumber = invoiceNumberTextField.text ?? ""

        /* Check the invoice number format */
        guard invoiceNumberFormatCheck(invoiceNumber) else {
            showSimpleAlert(title: "儲存失敗", message: "發票號碼格式不符合")
            return
        }
        guard isUnique(invoiceNumber) else {
            showSimpleAlert(title: "儲存失敗", message: "發票號碼已存在")
            return
        }

        // Save only after a spending category has been chosen
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

        // Clear all fields
        invoiceNumberTextField.text = ""
        invoiceDateTextField.text = ""
        invoiceStoreTextField.text = ""
        itemAndPriceTextView.text = "(可留空)"
        invoiceTotalPriceLabel.text = "$0"
        // temporaryItemAndPrice is temporary and must be cleared after saving
        temporaryItemAndPrice = []

        showSimpleAlert(title: "儲存成功", message: "分類：\(category)")
    }

    private func showSimpleAlert(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "確定", style: .default))
        present(alertController, animated: true)
    }
    
    // Runs when the add-item button is tapped
    @IBAction func addItemAndPrice(_ sender: UIButton) {
        let alertController = UIAlertController(title: "新增品項數量金額", message: "請輸入資訊", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { textField in textField.placeholder = "品項" }
        alertController.addTextField { textField in textField.placeholder = "數量" }
        alertController.addTextField { textField in textField.placeholder = "金額" }
        
        alertController.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "確定", style: UIAlertAction.Style.default) { action in
            // Actions to perform after Confirm is tapped
            let itemString = alertController.textFields?[0].text ?? ""
            let amountString = alertController.textFields?[1].text ?? ""
            let priceString = alertController.textFields?[2].text ?? ""
            
            

                
            // Validate that the price is legal (Int && >=0)
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
    
    // The camera is only available when built and run on a device
    @IBAction func openCamera(_ sender: UIBarButtonItem) {
        let vc = QRCodeScannerViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
}

