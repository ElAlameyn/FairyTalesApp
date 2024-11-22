//
//  RecognitionFeature.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 02.09.2024.
//

import ComposableArchitecture
import Core
import SwiftUI

@Reducer
public struct RecognitionFeature {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        public var text: String = ""
        public var status = Status.stopRecognition
        
        public init() {}
        
        public enum Status {
            case startRecognition
            case stopRecognition
        }
    }
    
    public enum Action: Equatable {
        case startRecording
        case stopRecording
        case toggle
        case bind
        case getRecognized(words: [Substring])
    }
    
    @Dependency(\.speechRecognizerClient) var speechRecognizer
    
    enum CancelBindingRecognition { case cancelIfInFlight }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startRecording:
                state.status = .startRecognition
                return .run { send in
                    await speechRecognizer.startRecognition()
                    await send(.bind)
                }
                .merge(with: .cancel(id: CancelBindingRecognition.cancelIfInFlight))
            case .stopRecording:
                state.status = .stopRecognition
                return .run { _ in
                    await speechRecognizer.stopRecognition()
                }
            case .toggle:
                return state.status == .stopRecognition ? .send(.startRecording) : .send(.stopRecording)
            case .bind:
                return .run { send in
                    for try await words in await speechRecognizer.recognizedSpeech() {
                        await send(.getRecognized(words: words))
                    }
                } catch: { error, _ in
                    print("Binding audio error: ", error.localizedDescription)
                }
                .cancellable(id: CancelBindingRecognition.cancelIfInFlight)
                
            case .getRecognized(words: _):
                return .none
            }
        }
    }
}
