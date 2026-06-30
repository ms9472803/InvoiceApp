//
//  InvoiceInfoViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/18.
//

import UIKit

func addLabel(text: String) -> UILabel {
    let retLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 80))
    retLabel.text = text
    retLabel.textColor = .label
    retLabel.font = UIFont.systemFont(ofSize: 20)
    retLabel.textAlignment = .center
    return retLabel
}


func setLabelConstraint(view: UIView, label: inout UILabel, centerYAnchorConstant: CGFloat, centerXAnchorConstant: CGFloat) {
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        label.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: centerYAnchorConstant),
        label.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: centerXAnchorConstant)
    ])
}

@objcMembers class InvoiceInfoViewController: UIViewController {
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    // Use ! for elements wired from a nib file; otherwise ? is typically used
    var selectedInvoiceNumberLabel: UILabel?
    var selectedInvoiceStoraNameLabel: UILabel?
    var selectedInvoiceDateLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground

        title = "發票資訊"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "修改", style: .plain, target: self, action: #selector(goModify))

        /* Invoice number */
        var invoiceNumberLabel = addLabel(text: "發票號碼")
        view.addSubview(invoiceNumberLabel)
        setLabelConstraint(view: view, label: &invoiceNumberLabel, centerYAnchorConstant: -100, centerXAnchorConstant: -100)

        // Extract into a function, passing label and constants as parameters to wrap up the code below
        
        
        selectedInvoiceNumberLabel = addLabel(text: Invoice.invoiceShowCurrent.number)
        guard var numberLabel = selectedInvoiceNumberLabel else {
            return
        }
        view.addSubview(numberLabel)
        setLabelConstraint(view: view, label: &numberLabel, centerYAnchorConstant: -100, centerXAnchorConstant: 50)
        

        /* Invoice date */
        var invoiceDateLabel = addLabel(text: "發票日期")
        view.addSubview(invoiceDateLabel)
        setLabelConstraint(view: view, label: &invoiceDateLabel, centerYAnchorConstant: -50, centerXAnchorConstant: -100)
        
        
        selectedInvoiceDateLabel = addLabel(text: Invoice.invoiceShowCurrent.date)
        guard var dateLabel = selectedInvoiceDateLabel else {
            return
        }
        view.addSubview(dateLabel)
        setLabelConstraint(view: view, label: &dateLabel, centerYAnchorConstant: -50, centerXAnchorConstant: 50)
        
        /* Store name */
        var invoiceStoreLabel1 = addLabel(text: "店名")
        view.addSubview(invoiceStoreLabel1)
        setLabelConstraint(view: view, label: &invoiceStoreLabel1, centerYAnchorConstant: 0, centerXAnchorConstant: -100)
        
        selectedInvoiceStoraNameLabel = addLabel(text: Invoice.invoiceShowCurrent.storeName)
        guard var storeNameLabel = selectedInvoiceStoraNameLabel else {
            return
        }
        view.addSubview(storeNameLabel)
        setLabelConstraint(view: view, label: &storeNameLabel, centerYAnchorConstant: 0, centerXAnchorConstant: 50)
        
        
        /* Items and prices */
        var invoiceItemAndPriceLabel = addLabel(text: "品項金額")
        view.addSubview(invoiceItemAndPriceLabel)
        setLabelConstraint(view: view, label: &invoiceItemAndPriceLabel, centerYAnchorConstant: 50, centerXAnchorConstant: -100)


        // View item and price details
        let itemAndPriceInfoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        itemAndPriceInfoButton.setTitle("點我查看", for: .normal)
        itemAndPriceInfoButton.setTitleColor(.systemBlue, for: .normal)
        itemAndPriceInfoButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        itemAndPriceInfoButton.addTarget(nil, action: #selector(goItemAndPriceInfo), for: .touchUpInside)
        self.view.addSubview(itemAndPriceInfoButton)
        itemAndPriceInfoButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            itemAndPriceInfoButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: 50),
            itemAndPriceInfoButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: 50),
        ])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        selectedInvoiceNumberLabel?.text = Invoice.invoiceShowCurrent.number
        selectedInvoiceStoraNameLabel?.text = Invoice.invoiceShowCurrent.storeName
        selectedInvoiceDateLabel?.text = Invoice.invoiceShowCurrent.date
        
    }
    
    @objc func goItemAndPriceInfo() {
        canModify = false
        self.navigationController?.pushViewController(ItemAndPriceInfoViewController(), animated: true)
        //present(ItemAndPriceInfoViewController(), animated: true, completion: nil)
    }
    
    
    @objc func goModify() {
        self.navigationController?.pushViewController(ModifyInvoiceInfoViewController(), animated: true)
    }
}
