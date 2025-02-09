//
//  ZFBApp.swift
//  ZFB
//
//  Created by 陈杰豪 on 9/2/2025.
//

import SwiftUI

@main
struct ZFBApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
