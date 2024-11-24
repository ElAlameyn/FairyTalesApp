//
//  FairyTalesAppApp.swift
//  FairyTalesApp
//
//  Created by Artiom Kalinkin on 21.05.2024.
//

import SwiftUI
import ChaptersFeature
import SharedModels

@main
struct FairyTalesApp: App {
    var body: some Scene {
        WindowGroup {
                        ChaptersView(state: .init(chapters: Chapters.KnightStory.values))
//            ChaptersView(store: .init(initialState: .init(chapters: Chapters.KnightStory.values), reducer: {
//                SuccessChaptersReadReducer()
//            }))
        }
    }
}
