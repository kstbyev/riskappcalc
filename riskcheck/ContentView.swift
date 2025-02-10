//
//  ContentView.swift
//  riskcheck
//
//  Created by Madi Sharipov on 09.02.2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        RiskCalculationView()
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
