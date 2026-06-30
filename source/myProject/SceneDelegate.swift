//
//  SceneDelegate.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/16.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Build the window and tab bar entirely in code (no storyboard)
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeTabBarController()
        self.window = window
        window.makeKeyAndVisible()
    }

    private func makeTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            navController(HomePageViewController(), title: "新增發票", systemImage: "plus.app"),
            navController(TableViewController(), title: "顯示發票", systemImage: "folder"),
            navController(BonusViewController(), title: "確認中獎", systemImage: "star.square.fill"),
            navController(ConsumptionAnalysisViewController(), title: "消費分析", systemImage: "chart.pie")
        ]
        return tabBarController
    }

    private func navController(_ root: UIViewController, title: String, systemImage: String) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImage), tag: 0)
        return nav
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
