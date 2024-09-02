//
//  ContentView.swift
//  FairyTalesApp
//
//  Created by Artiom Kalinkin on 21.05.2024.
//

import SwiftUI
import AVFoundation
import Dependencies
import Lottie
import Overture
import ComposableArchitecture


@Reducer
struct RecognitionFeature {
    @ObservableState
    struct State: Equatable {
        var playbackMode = LottiePlaybackMode.paused(at: .progress(0))
        var text: AttributedString = ""
        var status = Status.stopRecognition
        var matches = [String]()
        
        init(chapter: Chapter) {
            self.text = AttributedString(chapter.text)
            self.matches = chapter.matches
        }
        
        enum Status {
            case startRecognition
            case stopRecognition
        }
    }
    
    enum Action {
        case recordButtonTapped
        case startRecording
        case stopRecording
        case bind
        case getRecognized(word: Substring)
    }
    
    @Dependency(\.speechRecognizerClient) var speechRecognizer
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            
            switch action {
            case .recordButtonTapped:
                return .run { [status = state.status] send  in
                    status == .stopRecognition ? await send(.startRecording) : await send(.stopRecording)
                }
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
                
            case let .getRecognized(word: word):
                
                makeTextColored(recognizedWord: word)
                matchToAnimation(recognizedWord: word)

                func makeTextColored(recognizedWord: Substring) {
                    if let range = state.text.range(of: recognizedWord, options: .caseInsensitive) {
                        state.text[range].foregroundColor = .green
                    }
                }
                
                func matchToAnimation(recognizedWord: Substring) {
                    if state.matches.contains(where: { match in
                        match.caseInsensitiveCompare(recognizedWord) == .orderedSame
                    }) {
                        state.playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                    }
                }
            }
            return .none
        }
    }
}

struct ChapterView: View {
    @State var isPressed = false
    
    let store: StoreOf<RecognitionFeature> = .init(initialState: .init(chapter: .plantWasGrown)) {
        RecognitionFeature()._printChanges()
    }
    
    
    var body: some View {
        VStack {
            
            LottieView(animation: .named("plant_animation"))
                .playbackMode(store.playbackMode)
            
            Text(store.text)
            
            Spacer()
                .frame(height: 30)
            
            Circle()
                .frame(width: 40, height: 40)
                .scaleEffect(isPressed ? 1.5 : 1)
                .transition(.scale)
                .foregroundStyle(.red)
                .onTapGesture {
                    withAnimation {
                        isPressed.toggle()
                    }
                    store.send(.recordButtonTapped)
                }
                .overlay {
                    if isPressed {
                        Circle()
                            .foregroundStyle(.white)
                            .transition(.scale)
                            .frame(width: 25, height: 25)
                    }
                }
            
            
            Spacer()
            
        }
        .padding()
    }
}

#Preview {
    ChapterView()
}


// MARK: - For future time

//
//var recordingButton: some View {
//    Button(recordTitle) {
//        buttonDisabled = true
//        recordTitle = recordTitle == "Start recording" ? "Stop recording" : "Start recording"
//        Task {
//            if await recorder.isRecording {
//                await recorder.stopRecording()
//            } else {
//                await recorder.startRecording()
//            }
//            buttonDisabled = false
//        }
//    }
//    .animation(.easeIn)
//    .disabled(buttonDisabled)
//}
//
//var playRecorded: some View {
//    Button("Play recorded video") {
//        try! audioSession.setForPlayback()
//        player.replaceCurrentItem(with: .init(url: Directory.foo))
//        player.play()
//    }
//}
