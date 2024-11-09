//
//  ContentView.swift
//  FairyTalesApp
//
//  Created by Artiom Kalinkin on 21.05.2024.
//

import AVFoundation
import ComposableArchitecture
import Dependencies
import Lottie
import Overture
import SharedModels
import SwiftUI

// TODO: Fix bug with double recognition
// TODO: Show success read state (confetti)
// TODO: Create constructor of fairy tales

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
        case makeTextColored(recognizedWords: [Substring])
        case matchToAnimation(recognizedWords: [Substring])
        case checkIfAllRead
    }
    
    @Dependency(\.speechRecognizerClient) var speechRecognizer
    
    var body: some ReducerOf<Self> {
        Scope(state: \.recognitionState, action: \.recognitionFeature) {
            RecognitionFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .recordButtonTapped:
                return .run { [status = state.recognitionState.status] send in
                    status == .stopRecognition
                        ? await send(.recognitionFeature(.startRecording))
                        : await send(.recognitionFeature(.stopRecording))
                }
                
            case let .recognitionFeature(.getRecognized(words: words)):
                // TODO: Write another reducer
                
                return .run { send in
                    await send(.makeTextColored(recognizedWords: words))
                    await send(.matchToAnimation(recognizedWords: words))
                }
                
            case .recognitionFeature: break
            case .successReadPage: break
            case let .makeTextColored(recognizedWords):
                for word in recognizedWords {
                    let visibleWords = String(state.visibleText.characters)
                        .getWords()

                    for visibleWord in visibleWords {
                        if let range = visibleWord.range(of: word, options: .caseInsensitive) {
                            let matchedWord = visibleWord[range].count
                            let fullCount = visibleWord.count

                            if fullCount - matchedWord <= 3 {
                                state.visibleText.range(of: visibleWord[...]).map {
                                    state.visibleText[$0].foregroundColor = .green
                                }
                                
                                if state.matches.containsCaseInsesitiveMatch(visibleWord) {
                                    state.playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                                }
                            }
                        }
                    }
                }
                
                return .run { await $0(.checkIfAllRead) }
                
            case let .matchToAnimation(recognizedWords):
                for word in recognizedWords {
                    if state.matches.containsCaseInsesitiveMatch(word) {
                        state.playbackMode = .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                    }
                }
            case .checkIfAllRead:
                let attributed = state.visibleText
                let ranges = String(attributed.characters)
                    .getWords()
                    .compactMap { attributed.range(of: $0) }
                
                for range in ranges {
                    if attributed[range].foregroundColor != .green {
                        return .none
                    }
                }
                
                return .run { send in await send(.successReadPage) }
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
        self.store = .init(initialState: .init(chapter: .plantWasGrown), reducer: {
            ChapterFeature()
        })
        UIPageControl.appearance().currentPageIndicatorTintColor = .black
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.3)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                VStack(spacing: 40) {
                    LottieView(animation: .named(store.animationName))
                        .playbackMode(store.playbackMode)
                        .frame(height: proxy.size.height / 2)

                    Text(store.visibleText)
                
                    Spacer().frame(height: proxy.size.height / 2.5)
                }
                .frame(maxWidth: .infinity)
                .padding()
            
                Group {
                    if store.recognitionState.status == .startRecognition {
                        Image(systemName: "waveform.circle")
                            .font(.system(size: recordIconSize))
                            .symbolEffect(.variableColor.iterative.hideInactiveLayers.reversing)
                    } else {
                        Image(systemName: "record.circle.fill")
                            .font(.system(size: recordIconSize))
                    }
                }
                .onTapGesture {
                    store.send(.recordButtonTapped, animation: .easeIn)
                }
                .foregroundStyle(.green)
                .symbolRenderingMode(.monochrome)
                .offset(y: proxy.size.height - bottomPadding)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private let recordIconSize: CGFloat = 60
private let bottomPadding: CGFloat = 120

#Preview {
    ChapterView(store: .init(initialState: .init(chapter: .sunAnimation), reducer: {
        EmptyReducer()
    }))
}

#Preview {
    ChapterView(store: .init(initialState: .init(chapter: .plantWasGrown), reducer: {
        EmptyReducer()
    }))
}
