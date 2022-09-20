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
    retLabel.textColor = .black
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
    // !是有nib檔在拉過來的元件, 不是的話通常是用?
    var selectedInvoiceNumberLabel: UILabel?
    var selectedInvoiceStoraNameLabel: UILabel?
    var selectedInvoiceDateLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        

        title = "發票資訊"
        
        /* 發票號碼 */
        var invoiceNumberLabel = addLabel(text: "發票號碼")
        view.addSubview(invoiceNumberLabel)
        setLabelConstraint(view: view, label: &invoiceNumberLabel, centerYAnchorConstant: -100, centerXAnchorConstant: -100)
        
        // 抽成function, label, constant當作參數帶進去, 把下面的包起來
        
        
        selectedInvoiceNumberLabel = addLabel(text: Invoice.invoiceShowCurrent.number)
        guard var numberLabel = selectedInvoiceNumberLabel else {
            return
        }
        view.addSubview(numberLabel)
        setLabelConstraint(view: view, label: &numberLabel, centerYAnchorConstant: -100, centerXAnchorConstant: 50)
        

        /* 發票日期 */
        var invoiceDateLabel = addLabel(text: "發票日期")
        view.addSubview(invoiceDateLabel)
        setLabelConstraint(view: view, label: &invoiceDateLabel, centerYAnchorConstant: -50, centerXAnchorConstant: -100)
        
        
        selectedInvoiceDateLabel = addLabel(text: Invoice.invoiceShowCurrent.date)
        guard var dateLabel = selectedInvoiceDateLabel else {
            return
        }
        view.addSubview(dateLabel)
        setLabelConstraint(view: view, label: &dateLabel, centerYAnchorConstant: -50, centerXAnchorConstant: 50)
        
        /* 店名 */
        var invoiceStoreLabel1 = addLabel(text: "店名")
        view.addSubview(invoiceStoreLabel1)
        setLabelConstraint(view: view, label: &invoiceStoreLabel1, centerYAnchorConstant: 0, centerXAnchorConstant: -100)
        
        selectedInvoiceStoraNameLabel = addLabel(text: Invoice.invoiceShowCurrent.storeName)
        guard var storeNameLabel = selectedInvoiceStoraNameLabel else {
            return
        }
        view.addSubview(storeNameLabel)
        setLabelConstraint(view: view, label: &storeNameLabel, centerYAnchorConstant: 0, centerXAnchorConstant: 50)
        
        
        /* 品項金額 */
        var invoiceItemAndPriceLabel = addLabel(text: "品項金額")
        view.addSubview(invoiceItemAndPriceLabel)
        setLabelConstraint(view: view, label: &invoiceItemAndPriceLabel, centerYAnchorConstant: 50, centerXAnchorConstant: -100)
        
        
        // 看品項金額詳細資訊
        let itemAndPriceInfoButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        itemAndPriceInfoButton.setTitle("點我查看", for: .normal)
        itemAndPriceInfoButton.setTitleColor(.black, for: .normal)
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
    
    
    @IBAction func goModify(_ sender: UIButton) {
        self.navigationController?.pushViewController(ModifyInvoiceInfoViewController(), animated: true)
    }
}
