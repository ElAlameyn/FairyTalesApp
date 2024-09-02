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
        let store = TestStore(initialState: ChapterFeature.State(chapter: .helloWorld)) {
            ChapterFeature()
        }
        
        store.exhaustivity = .off
        
        await store.send(.recognitionFeature(.startRecording)) {
            $0.recognitionState.status = .startRecognition
        }
        
        await store.skipReceivedActions()
        
        for match in Chapter.helloWorld.matches {
            guard let range = store.state.visibleText.range(of: match) else {
                XCTFail()
                return
            }
            XCTAssert(store.state.visibleText[range].foregroundColor == .green)
        }
    }
    @MainActor
    func testSpeechRecognitionMatch() async throws {
        let store = TestStore(initialState: ChapterFeature.State(chapter: .helloWorld)) {
            ChapterFeature()
        }
        
        store.exhaustivity = .off
        
        await store.send(.recognitionFeature(.startRecording)) {
            $0.recognitionState.status = .startRecognition
        }
        
        await store.skipReceivedActions()
        
        XCTAssert(store.state.playbackMode != .paused(at: .progress(0)))
    }
    
}
