//
//  ConsumptionAnalysisViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/25.
//

import UIKit
import Charts


class ConsumptionAnalysisViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    

    @IBOutlet weak var yearTextField: UITextField!
    var pieChartView: PieChartView!
    let monthToIndex: [String: Int] = ["01":0, "02":1, "03":2 , "04":3, "05":4, "06":5, "07":6, "08":7, "09":8 , "10":9, "11":10, "12":11]
    let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var consumptionOfMonth: [Int] = Array(repeating: 0, count: 12)
    var pieChartDataEntries: [PieChartDataEntry] = []
    var currentYear = "2022"
    
    /*var pickerView: UIPickerView!
    var pickerViewDataSize: Int = 0
    var pickerViewData = [String]()*/
    
    
    var pickerView = UIPickerView()
    
    let year = ["2022", "2021", "2020", "2019"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
 
        
        pieChartView = PieChartView(frame: CGRect(x: 50, y: 200, width: 250, height: 250))
        pieChartView.center = view.center
        pieChartView.entryLabelColor = .black
        pieChartView.legend.enabled = false
        pieChartView.chartDescription.text = "消費分析"
        
        
        
        //chartView.frame = CGRect(x: 0, y: 0, width: 100, height: 300)
        view.addSubview(pieChartView)
        drawPieChart()
        //pieChartView.setExtraOffsets (left: -15.0, top: 10.0, right:-15.0, bottom: -30.0)
        
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        /*NSLayoutConstraint.activate([
            pieChartView.widthAnchor.constraint(equalToConstant: 300)
        ])*/
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(donePresser))
        toolbar.setItems([doneBtn], animated: true)
        
        yearTextField.inputAccessoryView = toolbar
        yearTextField.inputView = pickerView
        yearTextField.textAlignment = .center
        yearTextField.placeholder = "選擇年份"
        yearTextField.text = currentYear
        
    }
    
    @objc func donePresser() {
        yearTextField.text = currentYear
        view.endEditing(true)
        drawPieChart()
    }
    
    func drawPieChart() {
        consumptionOfMonth = Array(repeating: 0, count: 12)
        pieChartDataEntries = []
        for invoice in Invoice.globalInvoiceArray {
            if invoice.date.prefix(4) != currentYear {
                continue
            }
            let month = invoice.date.prefix(7).suffix(2)
            consumptionOfMonth[monthToIndex[String(month)]!] += Int(invoice.totalPrice) ?? 0
        }

        for i in 0..<consumptionOfMonth.count {
            pieChartDataEntries.append(PieChartDataEntry(value: Double(consumptionOfMonth[i]), label: months[i], icon: nil, data: nil))
            //print(i, consumptionOfMonth[i])
        }
        
        let sum = consumptionOfMonth.reduce(0) {$0 + $1}
        pieChartView.centerText = "支出總和\n$" + String(sum)
        
        let set = PieChartDataSet(entries: pieChartDataEntries, label: "")
        // 設定區塊顏色, 呈現順序會跟Entries array一樣
        
        set.colors = ChartColorTemplates.joyful()
        
        // 點選圓餅後突出多少
        set.selectionShift = 10
        // 圓餅每個部分分隔間距
        set.sliceSpace = 5
        set.entryLabelColor = .black
        set.valueColors = [UIColor.black]
        
        // 設定是否要呈現數值在圓餅圖上
        //set.drawValuesEnabled = false
        let pieChartData = PieChartData(dataSet: set)
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 2
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = "%"
        pieChartData.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        pieChartView.data = pieChartData
        pieChartView.usePercentValuesEnabled = true
        
        set.valueFormatter = DefaultValueFormatter(formatter: pFormatter)
        
        /*pieChartView.legend.enabled = true
        let legend = pieChartView.legend
        legend.horizontalAlignment = .center
        legend.verticalAlignment = .bottom
        legend.orientation = .horizontal
        legend.font = UIFont(name: "HelveticaNeue-Light", size: 12)!*/
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return year.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return year[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentYear = year[row]
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
