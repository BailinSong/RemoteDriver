//
//  RemoteDriverApp.swift
//  RemoteDriver
//
//  Created by 宋柏霖 on 2022/7/6.
//

import SwiftUI

@main
struct RemoteDriverApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
