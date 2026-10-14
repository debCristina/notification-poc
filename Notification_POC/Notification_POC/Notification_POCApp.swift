//
//  Notification_POCApp.swift
//  Notification_POC
//
//  Created by Débora Cristina Silva Ferreira on 05/10/26.
//

import SwiftUI

@main
struct Notification_POCApp: App {
    @State private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
        }
    }
}


