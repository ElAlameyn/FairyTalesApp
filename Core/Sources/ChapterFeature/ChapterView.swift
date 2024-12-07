//
//  ContentView.swift
//  FairyTalesApp
//
//  Created by Artiom Kalinkin on 21.05.2024.
//

import AVFoundation
import ComposableArchitecture
import Lottie
import Overture
import SharedModels
import SwiftUI
import RecognitionFeature

// TODO: Show success read state (confetti)
// TODO: Create constructor of fairy tales
// TODO: Make sliding

@Reducer
public struct ChapterFeature {
    
    public init() {}
    
    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id = UUID()
        public var animationIsFinished = false
        public var readingState = ReadingState.inProcess
        public var displayButtonStatus = RecognitionFeature.State.Status.stopRecognition
        public var playbackMode = LottiePlaybackMode.paused(at: .progress(0))
        public var visibleText = AttributedString("")
        public var matches = [String]()
        public var animationName: String = ""
        
        public init(chapter: Chapter) {
            self.visibleText = AttributedString(chapter.text)
            self.matches = chapter.matches
            self.animationName = chapter.animatinonName
        }
        
        public enum Status {
            case startRecognition
            case stopRecognition
        }
    }
    
    public enum Action: Equatable {
        case recordButtonTapped
        case successReadPage
        case makeTextColored(recognizedWords: [Substring])
        case matchToAnimation(recognizedWords: [Substring])
        case checkIfAllRead
        case didFinishAnimation
    }
    
    @Dependency(\.speechRecognizerClient) var speechRecognizer
    
    public var body: some ReducerOf<Self> {
        
        Reduce { state, action in
            switch action {
            case .recordButtonTapped: break
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
            case .didFinishAnimation:
                state.animationIsFinished = true
            }
            return .none
        }
    }
}

public struct ChapterView: View {
    @State var isPressed = false
    
    var store: StoreOf<ChapterFeature>
    
    public init(store: StoreOf<ChapterFeature>) {
        self.init(isInitedStore: false)
        self.store = store
    }
    
    public init(isInitedStore: Bool = true) {
        self.store = .init(initialState: .init(chapter: .plantWasGrown), reducer: {
            ChapterFeature()
        })
        UIPageControl.appearance().currentPageIndicatorTintColor = .black
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.3)
    }
    
    public var body: some View {
        ZStack {
            GeometryReader { proxy in
                VStack(spacing: 40) {
                    LottieView(animation: .named(store.animationName, bundle: .module))
                        .playbackMode(store.playbackMode)
                        .animationDidFinish { completed in
                            if completed {
                                store.send(.didFinishAnimation)
                            }
                        }
                        .frame(height: proxy.size.height / 2)
                    
                    Text(store.visibleText)
                        .multilineTextAlignment(.leading)
                
                }
                .frame(maxWidth: .infinity)
                .padding()
            
                Group {
                    if store.displayButtonStatus == .startRecognition {
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
