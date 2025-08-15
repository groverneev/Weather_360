//
//  Weather_360App.swift
//  Weather 360
//
//  Created by Neev Grover on 8/15/25.
//

import SwiftUI

@main
struct Weather_360App: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .environmentObject(themeManager)
        }
    }
}
