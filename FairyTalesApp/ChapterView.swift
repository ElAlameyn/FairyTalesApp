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
        var readingState = ReadingState.inProcess
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
        case successReadPage
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
                
            case let .recognitionFeature(.getRecognized(words: words)):
                // TODO: Write another reducer 
               let allPagesRead = StateChanger<Self>
                    .makeTextColored(recognizedWords: words, coloredWord: { word in
                        StateChanger<State>.matchToAnimation(recognizedWords: [word[...]]).apply(&state)
                    })
                
                    .map(.matchToAnimation(recognizedWords: words))
                    .flatMap { state in
                        let attributed = state.visibleText
                        let ranges = attributed.characters
                            .split(separator: " ")
                            .map(String.init)
                            .compactMap { attributed.range(of: $0) }
                        
                        for range in ranges {
                            if attributed[range].foregroundColor != .green {
                                return false
                            }
                        }

                        return true
                    }(&state)
                
                if allPagesRead {
                    guard state.readingState != ReadingState.success else { return .none }
                    
                    state.readingState = ReadingState.success
                    return .run { send in await send(.successReadPage) }
                }
                
            case .recognitionFeature(_): break
            case .successReadPage: break
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

