//
//  Collection+Extension.swift
//  FairyTales
//
//  Created by Bravery on 01.11.2024.
//

import Foundation

extension String {
    func getWords() -> [Substring] {
        self
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0[...] }
    }   
}

extension [String] {
    func containsCaseInsesitiveMatch<T: StringProtocol>(_ word: T) -> Bool {
        self.contains(where: { match in
            match.caseInsensitiveCompare(word) == .orderedSame
        })
    }
}
