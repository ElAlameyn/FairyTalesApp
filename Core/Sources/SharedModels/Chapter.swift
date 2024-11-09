//
//  Chapter.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 04.09.2024.
//

import Foundation

public struct Chapter: Hashable {
    public var animatinonName: String = ""
    public var matches: [String]
    public var text: String
}

public enum ReadingState { case success, inProcess, alreadySet }

public extension Chapter {
    static let helloWorld = Self(matches: ["hello"], text: "hello world")
    static let plantWasGrown = Self(animatinonName: "plant_animation", matches: ["растение", "выросло"], text: "Растение выросло")
    static let sunAnimation = Chapter(animatinonName: "sun_animation", matches: ["свет"], text: "Да будет свет!")
}

public enum Chapters {}

public extension Chapters {
     enum One {
         public static let values = [
            Chapter(animatinonName: "open_window_animation", matches: ["окно"], text: "Я открыл окно"),
            Chapter(animatinonName: "sun_animation", matches: ["свет"], text: "Да будет свет!"),
            Chapter.plantWasGrown
        ]
    }
}
