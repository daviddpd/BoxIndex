//
//  ContentView.swift
//  BoxIndex
//
//  Created by David P. Discher on 3/2/26.
//

import SwiftUI

private enum RootTab: Hashable {
    case containers
    case scanQR
    case scanLabel
    case backup
}

struct ContentView: View {
    @State private var selectedTab: RootTab = .containers
    @State private var containerSearchText = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            ContainersHomeView(searchText: $containerSearchText)
                .tabItem {
                    Label("Containers", systemImage: "shippingbox")
                }
                .tag(RootTab.containers)

            ScanQRTabView()
                .tabItem {
                    Label("QR", systemImage: "qrcode.viewfinder")
                }
                .tag(RootTab.scanQR)

            ScanLabelTabView { recognizedText in
                containerSearchText = recognizedText
                selectedTab = .containers
            }
            .tabItem {
                Label("Label", systemImage: "text.viewfinder")
            }
            .tag(RootTab.scanLabel)

            BackupView()
                .tabItem {
                    Label("Backup", systemImage: "square.and.arrow.down.on.square")
                }
                .tag(RootTab.backup)
        }
    }
}
