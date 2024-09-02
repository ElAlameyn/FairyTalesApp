//
//  FairyTalesTests.swift
//  FairyTalesTests
//
//  Created by Artiom Kalinkin on 31.08.2024.
//

import XCTest
import Dependencies
import ComposableArchitecture
@testable import FairyTales

final class FairyTalesTests: XCTestCase {
    
    @MainActor
    func testSpeechRecognitionAnimation() async throws {
        let store = TestStore(initialState: RecognitionFeature.State(chapter: .helloWorld)) {
            RecognitionFeature()
        }
        
        store.exhaustivity = .off
        
        await store.send(.startRecording) {
            $0.status = .startRecognition
        }
        
        for match in Chapter.helloWorld.matches {
            guard let range = store.state.text.range(of: match) else {
                XCTFail()
                return
            }
            XCTAssert(store.state.text[range].foregroundColor == .green)
        }
    }
    @MainActor
    func testSpeechRecognitionMatch() async throws {
        let store = TestStore(initialState: RecognitionFeature.State(chapter: .helloWorld)) {
            RecognitionFeature()
        }
        
        store.exhaustivity = .off

        await store.send(.startRecording) {
            $0.status = .startRecognition
        }
        
        XCTAssert(store.state.playbackMode != .paused(at: .progress(0)))
    }
    
}
