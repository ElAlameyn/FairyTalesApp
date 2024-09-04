//
//  Chapter.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 04.09.2024.
//

import Foundation

struct Chapter {
    var matches: [String]
    var text: String
}

extension Chapter {
    static let helloWorld = Self(matches: ["hello"], text: "hello world")
}
