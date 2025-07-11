//
//  SoulPetsApp.swift
//  SoulPets
//
//  Created by 宋友勇 on 2025/7/10.
//

import SwiftUI
import SwiftData

@main
struct SoulPetsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: ModelRegistration.models)
        }
    }
}
