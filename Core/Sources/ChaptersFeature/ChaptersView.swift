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
        init(chapters: [Chapter]) {
            let values = chapters.map(ChapterFeature.State.init(chapter:))
            let idsArray = IdentifiedArray(uniqueElements: [values.first!])
            self.chapters = idsArray
            self.dequeElements = Deque(values.dropFirst())
            self.tab = idsArray.ids.first!
        }
        
        private static let values = Chapters.One.values.map(ChapterFeature.State.init(chapter:))
    }
    
    public enum Action {
        case tabChanged(UUID)
        case chapters(IdentifiedAction<UUID, ChapterFeature.Action>)
        case recognitionFeature(RecognitionFeature.Action)
    }
    
    public enum Cancel: Hashable { case foo }
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.recognitionState, action: \.recognitionFeature) {
            RecognitionFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .tabChanged(value):
                state.tab = value
            case let .chapters(.element(id: id, action: action)):
                switch action {
                case .recordButtonTapped: 
                    return .send(.recognitionFeature(.toggle))
                    
                case .successReadPage:
                    if state.chapters[id: id]?.readingState != .success {
                        if let element = state.dequeElements.popFirst() {
                            state.chapters.append(element)
                            state.tab = element.id
                        }
                        state.chapters[id: id]?.readingState = .success
                        state.chapters[id: id]?.status = .stopRecognition

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
                state.chapters[id: state.tab]?.status = .startRecognition
            case .recognitionFeature(.stopRecording):
                state.chapters[id: state.tab]?.status = .stopRecognition
            case .recognitionFeature(_): break
            }
            return .none
        }
        .forEach(\.chapters, action: \.chapters, element: {
            ChapterFeature()
        })
        ._printChanges()
    }
}
    
public struct ChaptersView: View {
    @Bindable var store: StoreOf<ChaptersFeature> = .init(
        initialState: .init(chapters: Chapters.One.values)
    ) {
        ChaptersFeature()
    }
        
    @State var selection: UUID = .init()
        
    public init() {}
        
    public var body: some View {
        TabView(selection: $selection) {
            ForEach(store.scope(state: \.chapters, action: \.chapters)) { localStore in
                ChapterView(store: localStore)
                    .tag(localStore.state.id)
            }
        }
        .transition(.slide)
        .onChange(of: selection) { _, newValue in
            store.send(.tabChanged(newValue))
        }
        .onChange(of: store.tab) { _, newValue in
            withAnimation(.easeIn) {
                selection = newValue
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

#Preview {
    ChaptersView()
}
