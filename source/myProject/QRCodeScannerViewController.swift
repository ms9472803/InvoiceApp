//
//  QRCodeScannerViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/30.
//

import UIKit
import AVFoundation

class QRCodeScannerViewController: UIViewController, UIImagePickerControllerDelegate,  UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate {

    // Used for capturing photos / scanning QR codes
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    var addInvoice = Invoice(number: "", date: "", storeName: "", itemAndPrice: [])
    var leftQR = false
    var rightQR = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        requestCameraAccessAndSetup()
        // Do any additional setup after loading the view.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop capturing when leaving the page to avoid keeping the camera running / leaking the session
        stopCaptureSession()
    }

    // Check camera permission first to avoid accessing the camera and failing when not authorized
    private func requestCameraAccessAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraSetup()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.cameraSetup()
                    } else {
                        self?.showCameraPermissionAlert()
                    }
                }
            }
        default:
            showCameraPermissionAlert()
        }
    }

    private func showCameraPermissionAlert() {
        let alert = UIAlertController(title: "無法使用相機",
                                      message: "請至「設定」開啟相機權限後再試一次。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "關閉", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    func cameraSetup() {
        print("open camera")

        // Get the back camera to capture video
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get the camera device")
            return
        }

        do {
            // Add input / output first, then start capturing last (reversing the order would result in no captured frames)
            let input = try AVCaptureDeviceInput(device: captureDevice)
            guard captureSession.canAddInput(input) else {
                print("Failed to add camera input")
                return
            }
            captureSession.addInput(input)

            let captureMetadataOutput = AVCaptureMetadataOutput()
            guard captureSession.canAddOutput(captureMetadataOutput) else {
                print("Failed to add metadata output")
                return
            }
            captureSession.addOutput(captureMetadataOutput)
            // Set the delegate and use the default dispatch queue to run the callback
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

            // Initialize the video preview layer and add it as a sublayer of the view's layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.layer.bounds
            view.layer.addSublayer(previewLayer)
            videoPreviewLayer = previewLayer

            // Initialize the QR code frame to highlight the QR code
            let frameView = UIView()
            frameView.layer.borderColor = UIColor.green.cgColor
            frameView.layer.borderWidth = 2
            view.addSubview(frameView)
            view.bringSubviewToFront(frameView)
            qrCodeFrameView = frameView

            // startRunning() is a blocking call and must run on a background queue to avoid blocking the main thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            print(error)
            return
        }
    }

    private func stopCaptureSession() {
        guard captureSession.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // If metadataObjects is an empty array,
        // set our search frame's frame to zero and return
        if metadataObjects.isEmpty {
          qrCodeFrameView?.frame = CGRect.zero
          return
        }
        // If metadataObjects can be obtained and cast to AVMetadataMachineReadableCodeObject (barcode message)
        guard let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject else {
            return
        }

        // Check whether metadataObj's type is QR Code

        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            //  If the metadata matches the QR code metadata, update the search frame's frame
            if let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj) {
                qrCodeFrameView?.frame = barCodeObject.bounds
            }
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
        let storeUniformNumber = qrString.prefix(53).suffix(8) // Business uniform number
        
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
                    // Write to the local database to avoid losing data after restart
                    MyDatabase().addInvoiceToDB(self.addInvoice)
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
                    // Write to the local database to avoid losing data after restart
                    MyDatabase().addInvoiceToDB(self.addInvoice)
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
