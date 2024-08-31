//
//  FairyTalesTests.swift
//  FairyTalesTests
//
//  Created by Artiom Kalinkin on 31.08.2024.
//

import XCTest
@testable import FairyTales

final class FairyTalesTests: XCTestCase {

    func testExample() throws {
        
    }

    @MainActor
    func testSpeechRecognitionAnimation() throws {
        var model = RecognitionViewModel()
        
        model.speechRecognizer
            .recognizedWordsStream
//            .continuation
//            .yeild("Hello")
//            .continuation
        
    }

}
