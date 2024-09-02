//
//  Chapter.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 04.09.2024.
//

import Foundation

struct Chapter: Hashable {
    var animatinonName: String = ""
    var matches: [String]
    var text: String
}

extension Chapter {
    static let helloWorld = Self(matches: ["hello"], text: "hello world")
    static let plantWasGrown = Self(animatinonName: "plant_animation", matches: ["растение", "выросло"], text: "Растение выросло")
}


enum Chapters {}

extension Chapters {
    enum One {
        static let values = [
            Chapter(animatinonName: "open_window_animation", matches: ["окно"], text: "Я открыл окно"),
            Chapter(animatinonName: "sun_animation", matches: ["солнце"], text: "Солнце осветило комнату"),
            Chapter.plantWasGrown
        ]
    }
}
