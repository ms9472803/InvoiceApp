//
//  AppDelegate.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/16.
//

import UIKit
import FirebaseCore
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        /*self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = .white
        self.window!.rootViewController = HomePageViewController()
        self.window!.makeKeyAndVisible()*/
        
        // Override point for customization after application launch.
        //NotificationCenter.default.addObserver(self, selector: #selector(test), name: NSNotification.Name("DatabaseReady"), object: nil)
        
        
        FirebaseApp.configure()
        // 連結資料庫, 把資料庫上全部發票存進globalInvoiceArray
        // 匿名驗證
        Auth.auth().signInAnonymously() { (user, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        /*globalInvoiceArray = []
        for _ in 0...10 {
            let temp = InvoiceGenerator.invoiceRandomGenerator()
            if isUnique(temp.number) {
                globalInvoiceArray.append(temp)
            }
        }*/
        
        let invoiceDB = MyDatabase()
        //invoiceDB.upLoadToDB()
        invoiceDB.readFromDB()
        // 通知其他人更新頁面
        //NotificationCenter.default.post(name: NSNotification.Name("DatabaseReady"), object: nil, userInfo: nil)
       
        return true
    }
    
    /*@objc func test() {
        print(123)
    }*/

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

