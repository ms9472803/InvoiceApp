//
//  MyDatabase.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/26.
//

import Foundation
import FirebaseCore
import FirebaseDatabase

@objcMembers class MyDatabase: NSObject {
    var db = Database.database().reference()
    
    
    // 跟db有關的抽成一個class, 把db放進class當成是member
    // 把所有global裡的發票上傳到db, 用途: 隨機產生一些發票上傳db時用到
    func upLoadToDB() {
        // i, j如果不是index, 可以訂有意義的名字
        for i in Invoice.globalInvoiceArray {
            // reuse
            db.child("myInvoiceData/invoiceNumber: " + i.number + "/date").setValue(i.date)
            db.child("myInvoiceData/invoiceNumber: " + i.number + "/storeName").setValue(i.storeName)
            for j in i.itemAndPrice {
                db.child("myInvoiceData/invoiceNumber: " + i.number + "/itemAndPrice: " + j.itemName + "/amount").setValue(j.amount)
                db.child("myInvoiceData/invoiceNumber: " + i.number + "/itemAndPrice: " + j.itemName + "/price").setValue(j.price)
            }
        }
        
    }

    // focus在function的設計
    // 加入一張發票到db
    func addInvoiceToDB(_ invoice: Invoice) {
        db.child("myInvoiceData/invoiceNumber: " + invoice.number + "/date").setValue(invoice.date)
        db.child("myInvoiceData/invoiceNumber: " + invoice.number + "/storeName").setValue(invoice.storeName)
        for item in invoice.itemAndPrice {
            db.child("myInvoiceData/invoiceNumber: " + invoice.number + "/itemAndPrice: " + item.itemName + "/amount").setValue(item.amount)
            db.child("myInvoiceData/invoiceNumber: " + invoice.number + "/itemAndPrice: " + item.itemName + "/price").setValue(item.price)
        }
    }

    // 移除db中發票號碼為invoiceNumber的發票
    func removeInvoiceFromDB(_ invoiceNumber: String) {
        db.child("myInvoiceData/invoiceNumber: " + invoiceNumber).setValue(nil)
    }

    // 從db中讀資料到globalInvoiceArray中
    func readFromDB() {
        db.removeAllObservers()
        db.observe(.value) { snapshot in
            Invoice.globalInvoiceArray = []
            
            // 不要force unwrapped 改成 as?, ***盡量避免, 不然會crash***
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                // child is Snap (myInvoiceData)
                // child.value is optional
                
                for readInvoice in child.value as! [String: AnyObject] {
                    //print("*",readInvoice.key) // invoiceNumber: AA12345678
                    var invoiceDate = ""
                    var invoiceStoreName = ""
                    var itemAndPrice: [Item] = []
                    for invoiceField in readInvoice.value as! [String: AnyObject] {
                        // date, storeName, itemAndPrice
                        if invoiceField.key.prefix(12) == "itemAndPrice" {
                            // itemAndPrice
                            var itemName = "", itemAmount = "", itemPrice = ""
                            var index = invoiceField.key.firstIndex(of: ":") ?? invoiceField.key.endIndex
                            index = invoiceField.key.index(index, offsetBy: 2)
                            //print(invoiceField.key[index...])
                            itemName = String(invoiceField.key[index...])
                            
                            for item in invoiceField.value as! [String: AnyObject] {
                                // enum 訂起來 , type string
                                if item.key == "price" {
                                    itemPrice = item.value as! String
                                }
                                if item.key == "amount" {
                                    itemAmount = item.value as! String
                                }
                                //print("**", item.key, item.value)
                            }
                            itemAndPrice.append(Item(itemName: itemName, amount: itemAmount, price: itemPrice))
                        }
                        else if invoiceField.key == "date" {
                            invoiceDate = invoiceField.value as! String
                        }
                        else if invoiceField.key == "storeName" {
                            invoiceStoreName = invoiceField.value as! String
                        }

                    }
                    //let invoice = Invoice(number: String(readInvoice.key.suffix(10)), date: invoiceDate, storeName: invoiceStoreName, itemAndPrice: itemAndPrice)
                    //print(invoice.transformToInfo())
       
                    Invoice.globalInvoiceArray.append(Invoice(number: String(readInvoice.key.suffix(10)), date: invoiceDate, storeName: invoiceStoreName, itemAndPrice: itemAndPrice))
                    //print(globalInvoiceArray.count)
                }
                //print(globalInvoiceArray.count)
                NotificationCenter.default.post(name: NSNotification.Name("DatabaseReady"), object: nil, userInfo: nil)
                
            }
        }
        
    }

}
