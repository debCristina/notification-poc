//
//  ContentView.swift
//  Notification_POC
//
//  Created by Débora Cristina Silva Ferreira on 05/10/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(LocationManager.self) private var locationManager
    var body: some View {
        VStack {
            Text(locationManager.localAtual)
            
            Button("Iniciar") {
                locationManager.startTracking()
            }
            
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
