//
//  ChaptersView.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 02.09.2024.
//

import ChapterFeature
import ComposableArchitecture
import DequeModule
import RecognitionFeature
import SharedModels
import SwiftUI

@Reducer
public struct ChaptersFeature {
    public init() {}
    
    @ObservableState
    public struct State {
        public var tab: UUID
        public var isLoad = false
        public var readingState = ReadingState.inProcess
        public var dequeElements: Deque<ChapterFeature.State>
        public var chapters: IdentifiedArray<UUID, ChapterFeature.State>
        public var recognitionState = RecognitionFeature.State()
        
        public init(chapters: [Chapter]) {
            let values = chapters.map(ChapterFeature.State.init(chapter:))
            let idsArray = IdentifiedArray(uniqueElements: [values.first!])
            self.chapters = idsArray
            self.dequeElements = Deque(values.dropFirst())
            self.tab = idsArray.ids.first!
        }
    }
    
    public enum Action {
        case chapters(IdentifiedAction<UUID, ChapterFeature.Action>)
        case recognitionFeature(RecognitionFeature.Action)
        case onAppear
    }
    
    public enum Cancel: Hashable { case foo }
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.recognitionState, action: \.recognitionFeature) {
            RecognitionFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .chapters(.element(id: id, action: action)):
                switch action {
                case .recordButtonTapped:
                    return .send(.recognitionFeature(.toggle))
                
                case .didFinishAnimation:
                    if let id = state.chapters.last?.id  {
                        state.tab = id
                    }
                    
                case .successReadPage:
                    if var chapter = state.chapters[id: id], chapter.readingState != .success {
                        if let element = state.dequeElements.popFirst() {
                            state.chapters.append(element)
                            
                            if chapter.animationIsFinished {
                                state.tab = element.id
                            }
                        }
                        chapter.readingState = .success
                        chapter.displayButtonStatus = .stopRecognition
                        
                        state.chapters[id: id] = chapter

                        return .send(.recognitionFeature(.stopRecording))
                    }
                default: break
                }
            case .chapters: break
            case let .recognitionFeature(.getRecognized(words: words)):
                return .merge(
                    .send(.chapters(.element(id: state.tab, action: .makeTextColored(recognizedWords: words)))),
                    .send(.chapters(.element(id: state.tab, action: .matchToAnimation(recognizedWords: words))))
                )
            case .recognitionFeature(.startRecording):
                state.chapters[id: state.tab]?.displayButtonStatus = .startRecognition
            case .recognitionFeature(.stopRecording):
                state.chapters[id: state.tab]?.displayButtonStatus = .stopRecognition
            case .recognitionFeature: break
            case .onAppear:
                return .send(.recognitionFeature(.bind))
            }
            return .none
        }
        .forEach(\.chapters, action: \.chapters, element: {
            ChapterFeature()
        })
        ._printChanges()
    }
}

@Reducer
public struct SuccessChaptersReadReducer {
    public init() {}
    
    public var body: some Reducer<ChaptersFeature.State, ChaptersFeature.Action> {
        Reduce { state, action in
            if case let .chapters(.element(id: _, action: action)) = action {
                if case .recordButtonTapped = action {
                    if let element = state.dequeElements.popFirst() {
                        state.chapters.append(element)
                        state.tab = element.id
                    }
                }
            }
            return .none
        }
    }
}
    
public struct ChaptersView: View {
    @Bindable var store: StoreOf<ChaptersFeature>
    @State var selection: UUID = .init()
        
    public init(state: ChaptersFeature.State) {
        self.store = .init(initialState: state) {
            ChaptersFeature()
        }
    }
    
    public init(store: StoreOf<ChaptersFeature>) {
        self.store = store
    }
        
    public var body: some View {
        TabView(selection: $selection) {
            ForEach(store.scope(state: \.chapters, action: \.chapters)) { localStore in
                ChapterView(store: localStore)
                    .tag(localStore.state.id)
            }
        }
        .transition(.slide)
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: store.tab) { _, newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                withAnimation(.easeIn) {
                    selection = newValue
                }
            })
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

#Preview {
    ChaptersView(state: .init(chapters: Chapters.One.values))
}
