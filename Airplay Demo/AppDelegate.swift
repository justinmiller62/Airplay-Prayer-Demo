//
//  AppDelegate.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  Routes incoming scene sessions to the correct delegate based on role.
//
//    UIWindowSceneSessionRoleApplication                  -> PhoneSceneDelegate
//    UIWindowSceneSessionRoleExternalDisplayNonInteractive -> ExternalSceneDelegate
//
//  iOS asks this method for a UISceneConfiguration each time it wants to
//  connect a new scene. The "external display non-interactive" role is the
//  whole point of this demo: it tells iOS that we want our own UIWindowScene
//  on the AirPlay receiver, rendered at the receiver's native size, instead
//  of the OS just mirroring the phone's screen.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {

        switch connectingSceneSession.role {
        case .windowExternalDisplayNonInteractive:
            // The TV scene. Configuration name must match the entry in
            // Info.plist's UIApplicationSceneManifest.
            let config = UISceneConfiguration(
                name: "External Display Configuration",
                sessionRole: connectingSceneSession.role
            )
            config.delegateClass = ExternalSceneDelegate.self
            return config

        default:
            // The phone (main app) scene. This is the default for any
            // UIWindowSceneSessionRoleApplication request.
            let config = UISceneConfiguration(
                name: "Phone Configuration",
                sessionRole: connectingSceneSession.role
            )
            config.delegateClass = PhoneSceneDelegate.self
            return config
        }
    }
}
