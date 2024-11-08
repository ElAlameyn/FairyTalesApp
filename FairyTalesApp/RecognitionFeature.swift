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
    
    enum Action: Equatable {
        case startRecording
        case stopRecording
        case bind
        case getRecognized(words: [Substring])
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
                    for try await words in await speechRecognizer.recognizedSpeech() {
                        await send(.getRecognized(words: words))
                    }
                } catch: { error, send in
                    print("Binding audio error: ", error.localizedDescription)
                }
                
            case .getRecognized(words: _):
                return .none
                
            }
        }
    }

    
}
