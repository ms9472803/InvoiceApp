//
//  BobusViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/20.
//

import UIKit

class BonusViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var bonusTableView: UITableView!
    @IBOutlet weak var bonusMonthLabel: UILabel!
    
    @IBOutlet weak var backMonthButton: UIButton!
    @IBOutlet weak var forwardMonthButton: UIButton!
    @IBOutlet weak var bonusNumberTextField: UITextField!
    @IBOutlet weak var bonusNumberTextView: UITextView!
    var backMonthButtonTitle = "\u{2190}"
    var forwardMonthButtonTitle = "\u{2192}"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        bonusTableView.register(UINib(nibName: "MyCustomTableViewCell", bundle: nil), forCellReuseIdentifier: "customCell")
        bonusTableView.delegate = self
        bonusTableView.dataSource = self
        bonusTableView.separatorStyle = .none
        
        bonusTableViewHeader = bonusMonthLabel.text!
        
        backMonthButton.setTitle(backMonthButtonTitle, for: .normal)
        forwardMonthButton.setTitle(forwardMonthButtonTitle, for: .normal)
        bonusNumberTextField.clearButtonMode = .always
        bonusNumberTextView.isEditable = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //selectedInvoiceArrayByBonus = []
        
        /*for invoice in globalInvoiceArray {
            if invoice.currentBonusCheck(bonusTableViewHeader) != "0" {
                selectedInvoiceArrayByBonus.append(invoice)
            }
        }*/
        
        bonusNumberTextView.text = ""
        if let jackpotNumber = jackpotNumberArray[bonusTableViewHeader] {
            for number in jackpotNumber {
                bonusNumberTextView.text += number.suffix(8) + "\n"
            }
        }
        
        bonusTableView.reloadData()
    }
    
    /*/* 顯示tableView header */
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        bonusTableViewHeader
    }*/
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("按下發票")
        
        // 取消cell的選取狀態
        bonusTableView.deselectRow(at: indexPath, animated: false)
        
        
        Invoice.invoiceShowCurrent = selectedInvoiceArrayByBonus[indexPath.row]
        self.navigationController?.pushViewController(InvoiceInfoViewController(), animated: true)
        /*
        // 設定選取的發票index, 讓invoiceInfoView呈現出來
        invoiceIndex = indexPath.row
        print(invoiceIndex)
        //goInvoiceInfo()*/
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedInvoiceArrayByBonus.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as? MyCustomTableViewCell
        
        cell?.numberLabel.text = selectedInvoiceArrayByBonus[indexPath.row].number
        cell?.dateLabel.text = selectedInvoiceArrayByBonus[indexPath.row].date
        cell?.totalPriceLabel.text = "獎金: " + selectedInvoiceArrayByBonus[indexPath.row].currentBonusCheck(bonusTableViewHeader)
        cell?.storeLabel.text = selectedInvoiceArrayByBonus[indexPath.row].storeName
        if selectedInvoiceArrayByBonus[indexPath.row].storeName.isEmpty {
            cell?.storeLabel.text = "(無店名)"
        }
        
        
        return cell!
    }
    
    
    
    @IBAction func selectedMonth(_ sender: UIButton) {
        selectedInvoiceArrayByBonus = []
        bonusTableView.reloadData()
        
        bonusNumberTextField.text = ""
        let curSelectedMonth = bonusMonthLabel.text?.suffix(5)
        let curSelectedYear = bonusMonthLabel.text?.prefix(4)
        if let title = sender.currentTitle {
            switch title {
            // 往左按鈕 月份往前
            case backMonthButtonTitle:
                let backCircularSelectedMonth = ["01-02": "11-12", "03-04": "01-02", "05-06": "03-04", "07-08": "05-06", "09-10": "07-08", "11-12": "09-10"]
                if let month = curSelectedMonth, let year = curSelectedYear {
                    var updateYear = String(year)
                    if month == "01-02" {
                        var intUpdateYear = Int(updateYear) ?? 0
                        intUpdateYear -= 1
                        updateYear = String(intUpdateYear)
                    }
                    
                    bonusMonthLabel.text = "\(updateYear), " + backCircularSelectedMonth[String(month)]!
                }

            // 往右按鈕 月份往後
            case forwardMonthButtonTitle:
                let forwardCircularSelectedMonth = ["01-02": "03-04", "03-04": "05-06", "05-06": "07-08", "07-08": "09-10", "09-10": "11-12", "11-12":  "01-02"]
                if let month = curSelectedMonth, let year = curSelectedYear {
                    var updateYear = String(year)
                    if month == "11-12" {
                        var intUpdateYear = Int(updateYear) ?? 0
                        intUpdateYear += 1
                        updateYear = String(intUpdateYear)
                    }
                    
                    bonusMonthLabel.text = "\(updateYear), " + forwardCircularSelectedMonth[String(month)]!
                }
            default:
                print("title not match")
            }
        }
        
        bonusTableViewHeader = bonusMonthLabel.text!
        
        bonusNumberTextView.text = ""
        if let jackpotNumber = jackpotNumberArray[bonusTableViewHeader] {
            for number in jackpotNumber {
                bonusNumberTextView.text += number.suffix(8) + "\n"
            }
        }
        
    }
    
    
    @IBAction func addBonusNumber(_ sender: UIButton) {
        print("新增中獎號碼")
        //jackpotNumberArray[bonusTableViewHeader]?.append("AA11111111")
        
        var alertControllerTitle = ""
        var alertControllerMessage = ""
        let bonusNumber = bonusNumberTextField.text ?? ""
        
        /* 檢查發票號碼格式 */
        if !bonusNumberFormatCheck(bonusNumber) {
            alertControllerTitle = "儲存失敗"
            alertControllerMessage = "發票號碼格式不符合"
        } else {
            var bonusNumberIsUnique = true
            if let currentMonthBonusNumber = jackpotNumberArray[bonusTableViewHeader] {
                for i in currentMonthBonusNumber {
                    if i == bonusNumber {
                        alertControllerTitle = "新增失敗"
                        alertControllerMessage = "號碼已存在"
                        bonusNumberIsUnique = false
                    }
                }
            }

            if bonusNumberIsUnique == true {
                alertControllerTitle = "新增成功"
                if jackpotNumberArray[bonusTableViewHeader] != nil {
                    jackpotNumberArray[bonusTableViewHeader]!.append(bonusNumber)
                } else {
                    jackpotNumberArray[bonusTableViewHeader] = [bonusNumber]
                }
                
                bonusNumberTextView.text = ""
                if let jackpotNumber = jackpotNumberArray[bonusTableViewHeader] {
                    for number in jackpotNumber {
                        bonusNumberTextView.text += number.suffix(8) + "\n"
                    }
                }
                
                //bonusTableView.reloadData()
            }
        }
        let alertController = UIAlertController(title: alertControllerTitle, message: alertControllerMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "確定", style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
        
        
    }
    
    @IBAction func checkBonus(_ sender: UIButton) {
        selectedInvoiceArrayByBonus = []
        for invoice in Invoice.globalInvoiceArray {
            if invoice.currentBonusCheck(bonusTableViewHeader) != "0" {
                selectedInvoiceArrayByBonus.append(invoice)
            }
        }
        bonusTableView.reloadData()
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

