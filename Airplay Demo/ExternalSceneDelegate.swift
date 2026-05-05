//
//  ExternalSceneDelegate.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  Owns the TV's UIWindow. iOS hands us this scene whenever an external
//  display becomes available in app-controlled mode (i.e. AirPlay to an
//  Apple TV with this app running). The window is sized to the external
//  screen's native bounds — typically 1920x1080 landscape — and is wholly
//  separate from the phone's window. The two share state via the singleton
//  PrayerSession; that's the only coupling between them.
//
//  Why this matters:
//  Without this delegate, iOS would fall back to plain Screen Mirroring,
//  which gives the TV a literal pixel copy of the portrait phone UI —
//  a portrait box wedged into a landscape TV with massive empty bars on
//  either side. The whole point of this demo is to avoid that by giving
//  the TV its own scene with a layout that fills the screen.
//

import UIKit
import SwiftUI

final class ExternalSceneDelegate: NSObject, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let root = TVRootView()
            .environment(PrayerSession.shared)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: root)
        window.isHidden = false
        self.window = window
    }
}
