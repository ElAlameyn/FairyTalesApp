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
struct ChapterFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var id = UUID()
        var playbackMode = LottiePlaybackMode.paused(at: .progress(0))
        var recognitionState = RecognitionFeature.State()
        var visibleText = AttributedString("")
        var matches = [String]()
        var animationName: String = ""
        
        init(chapter: Chapter) {
            self.visibleText = AttributedString(chapter.text)
            self.matches = chapter.matches
            self.animationName = chapter.animatinonName
        }
        
        enum Status {
            case startRecognition
            case stopRecognition
        }
    }
    
    enum Action: Equatable {
        case recordButtonTapped
        case recognitionFeature(RecognitionFeature.Action)
    }
    
    @Dependency(\.speechRecognizerClient) var speechRecognizer
    
    var body: some ReducerOf<Self> {
        
        Scope(state: \.recognitionState, action: \.recognitionFeature) {
            RecognitionFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .recordButtonTapped:
                return .run { [status = state.recognitionState.status] send  in
                    status == .stopRecognition ? await send(.recognitionFeature(.startRecording)) : await send(.recognitionFeature(.stopRecording))
                }
                
            case let .recognitionFeature(.getRecognized(words: word)):
                
                makeTextColored(recognizedWords: word)
                matchToAnimation(recognizedWords: word)
                
                func makeTextColored(recognizedWords: [Substring]) {
                    for word in recognizedWords {
                        let visibleWords = String(state.visibleText.characters)
                            .components(separatedBy: " ")
                        
                        for visibleWord in visibleWords {
                            if let range = visibleWord.range(of: word, options: .caseInsensitive) {
                                
                                let matchedWord = visibleWord[range].count
                                let fullCount = visibleWord.count
                                
                                if fullCount - matchedWord <= 3 {
                                    state.visibleText.range(of: visibleWord[...]).map {
                                        state.visibleText[$0].foregroundColor = .green
                                    }
                                }
                            }
                        }
                    }
                }
                
                func matchToAnimation(recognizedWords: [Substring]) {
                    for word in recognizedWords {
                        if state.matches.contains(where: { match in
                            match.caseInsensitiveCompare(word) == .orderedSame
                        }) {
                            state.playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                        }
                    }
                }
            case .recognitionFeature(_): break
            }
            return .none
        }   
        
    }
    
}

struct ChapterView: View {
    @State var isPressed = false
    
    var store: StoreOf<ChapterFeature>
    
    init(store: StoreOf<ChapterFeature>) {
        self.init(isInitedStore: false)
        self.store = store
    }
    
    init(isInitedStore: Bool = true) {
        store = .init(initialState: .init(chapter: .plantWasGrown), reducer: {
            ChapterFeature()
        })
        UIPageControl.appearance().currentPageIndicatorTintColor = .black
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.3)
    }
    
    
    var body: some View {
        
        VStack {
            LottieView(animation: .named(store.animationName))
                .playbackMode(store.playbackMode)
            
            Text(store.visibleText)
            
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
            
            Spacer().frame(height: 40)
            
            
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
