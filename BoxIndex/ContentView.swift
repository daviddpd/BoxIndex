//
//  ContentView.swift
//  BoxIndex
//
//  Created by David P. Discher on 3/2/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ContainersHomeView()
                .tabItem {
                    Label("Containers", systemImage: "shippingbox")
                }

            BackupView()
                .tabItem {
                    Label("Backup", systemImage: "square.and.arrow.down.on.square")
                }
        }
    }
}
