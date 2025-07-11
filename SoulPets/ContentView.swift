//
//  ContentView.swift
//  SoulPets
//
//  Created by 宋友勇 on 2025/7/10.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 主页标签
            PetsHomeView()
                .tabItem {
                    Label(LocalizedStringKey("Home"), systemImage: "house")
                }
            
            // 记录标签 (未来实现)
            Text(LocalizedStringKey("Records Coming Soon"))
                .tabItem {
                    Label(LocalizedStringKey("Records"), systemImage: "list.bullet.clipboard")
                }
            
            // 提醒标签 (未来实现)
            Text(LocalizedStringKey("Reminders Coming Soon"))
                .tabItem {
                    Label(LocalizedStringKey("Reminders"), systemImage: "bell")
                }
            
            // 体重标签 (未来实现)
            Text(LocalizedStringKey("Weight Coming Soon"))
                .tabItem {
                    Label(LocalizedStringKey("Weight"), systemImage: "scalemass")
                }
        }
        .accentColor(Color("AccentColor"))
    }
}

#Preview {
    ContentView()
}
