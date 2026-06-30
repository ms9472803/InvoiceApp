//
//  SearchInvoiceViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/23.
//

import UIKit
import CoreAudio

var searchInvoiceArray: [Invoice] = []

@objcMembers class SearchInvoiceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // UI built programmatically (no storyboard)
    private let searchInvoiceTableView = UITableView(frame: .zero, style: .plain)
    private let keywordSearchTextField = UITextField()

    var totalSearchInvoice = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "搜尋"

        keywordSearchTextField.borderStyle = .roundedRect
        keywordSearchTextField.placeholder = "輸入店名或品項關鍵字"
        keywordSearchTextField.clearButtonMode = .always
        keywordSearchTextField.addTarget(self, action: #selector(searchEditingChanged(_:)), for: .editingChanged)
        keywordSearchTextField.translatesAutoresizingMaskIntoConstraints = false

        searchInvoiceTableView.register(UINib(nibName: "MyCustomTableViewCell", bundle: nil), forCellReuseIdentifier: "customCell")
        searchInvoiceTableView.delegate = self
        searchInvoiceTableView.dataSource = self
        searchInvoiceTableView.separatorStyle = .none
        searchInvoiceTableView.backgroundColor = .systemGroupedBackground
        searchInvoiceTableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(keywordSearchTextField)
        view.addSubview(searchInvoiceTableView)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            keywordSearchTextField.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            keywordSearchTextField.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            keywordSearchTextField.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),

            searchInvoiceTableView.topAnchor.constraint(equalTo: keywordSearchTextField.bottomAnchor, constant: 12),
            searchInvoiceTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchInvoiceTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchInvoiceTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }


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
    
    // Handle the UITableView appearance
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("按下發票")
        // Clear the cell's selected state
        searchInvoiceTableView.deselectRow(at: indexPath, animated: false)
        Invoice.invoiceShowCurrent = searchInvoiceArray[indexPath.row]
        self.navigationController?.pushViewController(InvoiceInfoViewController(), animated: true)
        //present(InvoiceInfoViewController(), animated: true)
        //invoiceIndex = indexPath.row
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchInvoiceArray.isEmpty {
            let keywordEmpty = keywordSearchTextField.text?.isEmpty ?? true
            tableView.setEmptyMessage(keywordEmpty ? "輸入關鍵字以搜尋發票" : "找不到符合的發票")
        } else {
            tableView.setEmptyMessage(nil)
        }
        return searchInvoiceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get the cell the tableView is currently using
        //let cellIdentifier = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as? MyCustomTableViewCell
        
        //dequeueReusableCell retrieves a reusable table cell from the queue by the given cell Identifier
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
    
    // Display the tableView header
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "總共 " + String(totalSearchInvoice) + " 張"
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
}
