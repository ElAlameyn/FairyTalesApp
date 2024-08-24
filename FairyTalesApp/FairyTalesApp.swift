//
//  FairyTalesAppApp.swift
//  FairyTalesApp
//
//  Created by Artiom Kalinkin on 21.05.2024.
//

import SwiftUI

@main
struct FairyTalesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(RecognitionViewModel())
        }
    }
}
