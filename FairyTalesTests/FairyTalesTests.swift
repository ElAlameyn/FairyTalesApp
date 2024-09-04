//
//  FairyTalesTests.swift
//  FairyTalesTests
//
//  Created by Artiom Kalinkin on 31.08.2024.
//

import XCTest
import Dependencies
@testable import FairyTales

final class FairyTalesTests: XCTestCase {
    
    func testExample() throws { }
    
    
    @MainActor
    func testSpeechRecognitionAnimation() async throws {
        
        let chapter = Chapter.helloWorld
        let model = RecognitionViewModel(chapter: .helloWorld)
        await model.bind()
        
        
        for match in Chapter.helloWorld.matches {
            guard let range = model.text.range(of: match) else {
                XCTFail()
                return
            }
            XCTAssert(model.text[range].foregroundColor == .green)
            
        }
    }
    
    @MainActor
    func testSpeechRecognitionMatch() async throws {
        
        let chapter = Chapter.helloWorld
        let model = RecognitionViewModel(chapter: chapter)
        await model.bind()
        
        XCTAssert(model.playbackMode != .paused(at: .progress(0)))
    }
    
}
