//
//  riskcheckApp.swift
//  riskcheck
//
//  Created by Madi Sharipov on 09.02.2025.
//

import SwiftUI

@main
struct riskcheckApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
