//
//  FileHelpers.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 25.05.2024.
//

import Foundation

struct Directory {
    static let temporary = URL(filePath: NSTemporaryDirectory())
    static let foo = temporary
        .appendingPathComponent("foo")
        .appendingPathExtension("m4a")
}
