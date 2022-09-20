//
//  SearchInviceViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/23.
//

import UIKit
import CoreAudio

var searchInvoiceArray: [Invoice] = []

@objcMembers class SearchInviceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet var searchInvoiceTableView: UITableView!
    @IBOutlet var keywordSearchTextField: UITextField!
    
    var totalSearchInvoice = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "搜尋"
        
        searchInvoiceTableView.register(UINib(nibName: "MyCustomTableViewCell", bundle: nil), forCellReuseIdentifier: "customCell")
        
        //searchInvoiceTableView.register(MyCustonTableViewCell.self, forCellReuseIdentifier: "customCell")
        searchInvoiceTableView.delegate = self
        searchInvoiceTableView.dataSource = self
        searchInvoiceTableView.separatorStyle = .none
        
        //searchInvoiceArray = [Invoice(number: "12345678", date: "123", storeName: "123", itemAndPrice: [])]
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    
    override func viewWillAppear(_ animated: Bool) {
        searchInvoiceArray = []
        totalSearchInvoice = searchInvoiceArray.count
        searchInvoiceTableView.reloadData()
    }
    
    @IBAction func searchEditingChanged(_ sender: UITextField) {
        searchInvoiceArray = []
        let keyword = keywordSearchTextField.text ?? ""
        searchInvoiceArray = keywordSearch(keyword)
        totalSearchInvoice = searchInvoiceArray.count
        searchInvoiceTableView.reloadData()
    }
    
    // 處理UITableView外觀
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("按下發票")
        // 取消cell的選取狀態
        searchInvoiceTableView.deselectRow(at: indexPath, animated: false)
        Invoice.invoiceShowCurrent = searchInvoiceArray[indexPath.row]
        self.navigationController?.pushViewController(InvoiceInfoViewController(), animated: true)
        //present(InvoiceInfoViewController(), animated: true)
        //invoiceIndex = indexPath.row
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchInvoiceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // 取得 tableView 目前使用的 cell
        //let cellIdentifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as? MyCustomTableViewCell
        
        //dequeueReusableCell 以指定的cell Identifier取得queue中可再利用的表格cell
        //cell.textLabel?.text = "發票號碼 " + selectedInvoiceArray[indexPath.row].number
        
        
        
        cell?.numberLabel.text = searchInvoiceArray[indexPath.row].number
        cell?.dateLabel.text = searchInvoiceArray[indexPath.row].date
        cell?.totalPriceLabel.text = "$" + searchInvoiceArray[indexPath.row].totalPrice
        cell?.storeLabel.text = searchInvoiceArray[indexPath.row].storeName
        if searchInvoiceArray[indexPath.row].storeName.isEmpty {
            cell?.storeLabel.text = "(無店名)"
        }
        
        

        
        return cell!
    }
    
    // 顯示tableView header
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "總共 " + String(totalSearchInvoice) + " 張"
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
}
