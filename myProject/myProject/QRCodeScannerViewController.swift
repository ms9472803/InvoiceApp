//
//  QRCodeScannerViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/30.
//

import UIKit
import AVFoundation

class QRCodeScannerViewController: UIViewController, UIImagePickerControllerDelegate,  UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate {

    // 拍照掃QR用的
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    var addInvoice = Invoice(number: "", date: "", storeName: "", itemAndPrice: [])
    var leftQR = false
    var rightQR = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cameraSetup()
        
        // Do any additional setup after loading the view.
    }

    
    // 要build到裝置中才可使用camera, 有bug
    func cameraSetup() {
        print("open camera")

        // 取得後置鏡頭來擷取影片
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            
            // 開始影片的擷取
            captureSession.startRunning()
            
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            // 設定委派並使用預設的調度佇列來執行回呼（call back）
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            // 初始化影片預覽層，並將其作為子層加入 viewPreview 視圖的圖層中
            videoPreviewLayer?.isHidden = false
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            
            // 初始化 QR Code 框來突顯 QR code
            qrCodeFrameView = UIView()

            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
            
        } catch {
            print(error)
            return
        }
        
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // 如果 metadataObjects 是空陣列
        // 那麼將我們搜尋框的 frame 設為 zero，並且 return
        if metadataObjects.isEmpty {
          qrCodeFrameView?.frame = CGRect.zero
          return
        }
        // 如果能夠取得 metadataObjects 並且能夠轉換成 AVMetadataMachineReadableCodeObject（條碼訊息）
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        // 判斷 metadataObj 的類型是否為 QR Code
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            //  如果 metadata 與 QR code metadata 相同，則更新搜尋框的 frame
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            if let value = metadataObj.stringValue {
                if value.first == "*" {
                    qrCodeRightToInvoiceFormat(value)
                    rightQR = true
                } else {
                    qrCodeLeftToInvoiceFormat(value)
                    leftQR = true
                }

               
            }
        }
        
    }
    
    func qrCodeLeftToInvoiceFormat(_ qrString: String) {
        let invoiceNumber = qrString.prefix(10)
        
        let invoiceDate = qrString.prefix(17).suffix(7)
        let year = String((Int(invoiceDate.prefix(3)) ?? 0) + 1911)
        let month = invoiceDate.suffix(4).prefix(2)
        let day = invoiceDate.suffix(2)
        let date = year + "-" + month + "-" + day
        let storeUniformNumber = qrString.prefix(53).suffix(8) //統一編號
        
        let splitQRString = qrString.components(separatedBy: ":")
        
        let index = splitQRString.count - 2
        let tempItem = Item(itemName: splitQRString[index-2], amount: splitQRString[index-1], price: splitQRString[index])
        
        addInvoice.number = String(invoiceNumber)
        addInvoice.date = date
        addInvoice.storeName = String(storeUniformNumber)

        let containTempItem = addInvoice.itemAndPrice.contains(where: { item in
            if item.itemName == tempItem.itemName {
                return true
            } else {
                return false
            }
        })
        if !containTempItem {
            addInvoice.itemAndPrice.append(tempItem)
        }
        
        
        print(addInvoice.transformToInfo())
        
        let alertController = UIAlertController(title: "左邊QRCode ok", message: nil, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel) { action in
            if self.rightQR && self.leftQR {
                self.dismiss(animated: true)
                print(self.addInvoice.transformToInfo())
                if isUnique(self.addInvoice.number) {
                    Invoice.globalInvoiceArray.append(self.addInvoice)
                }
            }
        })
        present(alertController, animated: true, completion: nil)
        
    }
    
    func qrCodeRightToInvoiceFormat(_ qrString: String) {
        let str = String(qrString.suffix(qrString.count - 2))
        let splitStr = str.split(separator: ":")

        for i in stride(from: 2, to: splitStr.count, by: 3) {
            
            let tempItem = Item(itemName: String(splitStr[i-2]), amount: String(splitStr[i-1]), price: String(splitStr[i]))
            let containTempItem = addInvoice.itemAndPrice.contains(where: { item in
                if item.itemName == tempItem.itemName {
                    return true
                } else {
                    return false
                }
            })
            if !containTempItem {
                addInvoice.itemAndPrice.append(tempItem)
            }
        }
        
        let alertController = UIAlertController(title: "右邊QRCode ok", message: nil, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel) { action in
            if self.rightQR && self.leftQR {
                self.dismiss(animated: true)
                print(self.addInvoice.transformToInfo())
                
                if isUnique(self.addInvoice.number) {
                    Invoice.globalInvoiceArray.append(self.addInvoice)
                }
            }
        })
        present(alertController, animated: true, completion: nil)
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
