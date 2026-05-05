//
//  PhoneSceneDelegate.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  Owns the phone's UIWindow. When iOS connects a UIWindowSceneSessionRoleApplication
//  scene, this delegate builds a window rooted in PhoneRootView and injects the
//  shared PrayerSession.shared via .environmentObject so that state stays in sync
//  with whatever the TV scene is rendering.
//

import UIKit
import SwiftUI

final class PhoneSceneDelegate: NSObject, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let root = PhoneRootView()
            .environment(PrayerSession.shared)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: root)
        window.makeKeyAndVisible()
        self.window = window
    }
}
