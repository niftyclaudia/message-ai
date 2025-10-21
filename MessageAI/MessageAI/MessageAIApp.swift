//
//  MessageAIApp.swift
//  MessageAI
//
//  Created by Claudia Lucia Alban on 10/20/25.
//

import SwiftUI
import FirebaseCore

@main
struct MessageAIApp: App {
    
    init() {
        // Configure Firebase on app launch
        do {
            try FirebaseService.shared.configure()
        } catch {
            print("❌ Firebase configuration error: \(error.localizedDescription)")
            // In production, might want to show user-facing error
            // For now, app can still launch but Firebase features won't work
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
