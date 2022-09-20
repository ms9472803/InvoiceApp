//
//  ModifyInvoiceInfoViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/19.
//

import UIKit

var canModify = false


func addTextField(text: String) -> UITextField {
    let retTextField = UITextField(frame: CGRect(x: 0, y: 0, width: 150, height: 80))
    retTextField.text = text
    retTextField.textColor = .black
    retTextField.borderStyle = .bezel
    retTextField.clearButtonMode = .always
    return retTextField
}

func setTextFieldConstraint(view: UIView, textField: inout UITextField, centerXAnchorConstant: CGFloat, centerYAnchorConstant: CGFloat, widthAnchorConstant: CGFloat) {
    textField.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        textField.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: centerXAnchorConstant),
        textField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: centerYAnchorConstant),
        textField.widthAnchor.constraint(equalToConstant: widthAnchorConstant)
    ])
}

class ModifyInvoiceInfoViewController: UIViewController {

    var invoiceNumberTextField: UITextField!
    var invoiceStoreTextField: UITextField!
    var invoiceDateTextField: UITextField!
    var itemAndPriceTextView: UITextView!
    var storeInvoiceInfoButton: UIButton!
    //@IBOutlet weak var modifyItemButton: UIButton!
    
    let datePicker = UIDatePicker()
    
    @IBOutlet weak var modifyItemButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = "修改發票"

        
        /* 發票號碼 */
        var invoiceNumberLabel = addLabel(text: "發票號碼")
        view.addSubview(invoiceNumberLabel)
        setLabelConstraint(view: view, label: &invoiceNumberLabel, centerYAnchorConstant: -100, centerXAnchorConstant: -100)
        
        
        invoiceNumberTextField = addTextField(text: Invoice.invoiceShowCurrent.number)
        view.addSubview(invoiceNumberTextField)
        setTextFieldConstraint(view: view, textField: &invoiceNumberTextField, centerXAnchorConstant: -100, centerYAnchorConstant: 50, widthAnchorConstant: 150)
        
        
        /* 發票日期 */
        
        var invoiceDateLabel = addLabel(text: "發票日期")
        view.addSubview(invoiceDateLabel)
        setLabelConstraint(view: view, label: &invoiceDateLabel, centerYAnchorConstant: -50, centerXAnchorConstant: -100)
        
        
        invoiceDateTextField = addTextField(text: Invoice.invoiceShowCurrent.date)
        view.addSubview(invoiceDateTextField)
        setTextFieldConstraint(view: view, textField: &invoiceDateTextField, centerXAnchorConstant: -50, centerYAnchorConstant: 50, widthAnchorConstant: 150)
        
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(donePressed))
        toolbar.setItems([doneBtn], animated: true)
        
        invoiceDateTextField.inputAccessoryView = toolbar
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        invoiceDateTextField.inputView = datePicker
        
        
        /* 店名 */
        var invoiceStoreLabel = addLabel(text: "店名")
        view.addSubview(invoiceStoreLabel)
        setLabelConstraint(view: view, label: &invoiceStoreLabel, centerYAnchorConstant: 0, centerXAnchorConstant: -100)

        
        invoiceStoreTextField = addTextField(text: Invoice.invoiceShowCurrent.storeName)
        view.addSubview(invoiceStoreTextField)
        setTextFieldConstraint(view: view, textField: &invoiceStoreTextField, centerXAnchorConstant: 0, centerYAnchorConstant: 50, widthAnchorConstant: 150)
        
        
        /* 品項金額 */
        var invoiceItemAndPriceLabel = addLabel(text: "品項金額")
        view.addSubview(invoiceItemAndPriceLabel)
        setLabelConstraint(view: view, label: &invoiceItemAndPriceLabel, centerYAnchorConstant: 50, centerXAnchorConstant: -100)
        
        // 修改品項按鈕
        modifyItemButton.setTitle("點我修改", for: .normal)
        modifyItemButton.setTitleColor(.black, for: .normal)
        modifyItemButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        modifyItemButton.addTarget(nil, action: #selector(switchToModifyMode), for: .touchUpInside)
        self.view.addSubview(modifyItemButton)
        modifyItemButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            modifyItemButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: 50),
            modifyItemButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 50),
        ])
        
        // 儲存按鈕
        storeInvoiceInfoButton = UIButton()
        storeInvoiceInfoButton.setTitle("儲存", for: .normal)
        storeInvoiceInfoButton.setTitleColor(.black, for: .normal)
        storeInvoiceInfoButton.backgroundColor = .yellow
        storeInvoiceInfoButton.isEnabled = true
        storeInvoiceInfoButton.addTarget(self, action: #selector(storeModification), for: .touchUpInside)
        view.addSubview(storeInvoiceInfoButton)
        storeInvoiceInfoButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            storeInvoiceInfoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25),
            storeInvoiceInfoButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
        
    }
    
    @objc func donePressed() {
        invoiceDateTextField.text = transformDatePickerToString(datePicker)
        view.endEditing(true)
    }
    
    @objc func storeModification(_ sender: UIButton) {
        print("儲存")
        
        let invoiceNumber = invoiceNumberTextField.text ?? ""
        let invoiceStore = invoiceStoreTextField.text ?? ""
        let invoiceDate = invoiceDateTextField.text ?? ""

        var alertControllerTitle: String
        var alertControllerMessage: String?
        
        
        /* 檢查發票號碼格式 */
        if !invoiceNumberFormatCheck(invoiceNumber) || !invoiceDateFormatCheck(invoiceDate) {
            alertControllerTitle = "儲存失敗"
            alertControllerMessage = "發票格式不符合"
        } else {
            alertControllerTitle = "儲存成功"
            let invoiceDB = MyDatabase()
            invoiceDB.removeInvoiceFromDB(Invoice.invoiceShowCurrent.number)
            /* 修改發票 */
            let tempNumber = Invoice.invoiceShowCurrent.number
            Invoice.invoiceShowCurrent.number = invoiceNumber
            Invoice.invoiceShowCurrent.storeName = invoiceStore
            Invoice.invoiceShowCurrent.date = invoiceDate
            for i in 0..<Invoice.globalInvoiceArray.count {
                if tempNumber == Invoice.globalInvoiceArray[i].number {
                    Invoice.globalInvoiceArray[i].number = invoiceNumber
                    Invoice.globalInvoiceArray[i].storeName = invoiceStore
                    Invoice.globalInvoiceArray[i].date = invoiceDate
                }
            }
            invoiceDB.addInvoiceToDB(Invoice.invoiceShowCurrent)
        }
        
        
        let alertController = UIAlertController(title: alertControllerTitle, message: alertControllerMessage, preferredStyle: .alert)
        
        
        alertController.addAction(UIAlertAction(title: "確定", style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
        
    }
    
    @objc func switchToModifyMode() {
        canModify = true
        self.navigationController?.pushViewController(ItemAndPriceInfoViewController(), animated: true)
        
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
