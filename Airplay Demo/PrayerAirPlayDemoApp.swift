//
//  PrayerAirPlayDemoApp.swift
//  Airplay Demo
//
//  Created on 5/5/26, all Glory goes to God.
//
//  Role in the dual-scene architecture:
//  This is the SwiftUI entry point. The body declares an empty WindowGroup —
//  it exists only so the App protocol is satisfied. The real scene work is
//  delegated to UIKit via @UIApplicationDelegateAdaptor: AppDelegate decides,
//  per scene-session role, whether to hand the OS a PhoneSceneDelegate or an
//  ExternalSceneDelegate. This split is the only way (as of iOS 17/18) to
//  declare an external-display scene from a SwiftUI app.
//

import SwiftUI

@main
struct PrayerAirPlayDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The actual UI for both scenes is constructed inside the scene
        // delegates. WindowGroup here is a no-op placeholder; the scene
        // delegate's window replaces whatever SwiftUI would have built.
        WindowGroup {
            EmptyView()
        }
    }
}
