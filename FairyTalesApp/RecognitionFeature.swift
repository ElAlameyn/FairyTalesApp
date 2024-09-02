//
//  RecognitionFeature.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 02.09.2024.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct RecognitionFeature {
    @ObservableState
    struct State: Equatable {
        var text: String = ""
        var status = Status.stopRecognition
        
        enum Status {
            case startRecognition
            case stopRecognition
        }
    }
    
    enum Action {
        case startRecording
        case stopRecording
        case bind
        case getRecognized(word: Substring)
    }
    
    @Dependency(\.speechRecognizerClient) var speechRecognizer
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            
            switch action {
            case .startRecording:
                state.status = .startRecognition
                return .run { send in
                    await speechRecognizer.startRecognition()
                    await send(.bind)
                }
            case .stopRecording:
                state.status = .stopRecognition
                return .run { _ in
                    await speechRecognizer.stopRecognition()
                }
            case .bind:
                return .run { send in
                    for try await word in await speechRecognizer.recognizedSpeech() {
                        await send(.getRecognized(word: word))
                    }
                }
                
            case .getRecognized(word: _):
                return .none
                
            }
        }
    }

    
}
