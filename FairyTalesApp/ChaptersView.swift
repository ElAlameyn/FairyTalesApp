//
//  ChaptersView.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 02.09.2024.
//

import ComposableArchitecture
import SwiftUI
import DequeModule
import SharedModels

@Reducer
struct ChaptersFeature {
    @ObservableState
    struct State {
        var tab: UUID = .init()
        var isLoad = false
        var readingState = ReadingState.inProcess
        var dequeElements = Deque(values.dropFirst())
        var chapters = IdentifiedArray(uniqueElements: [values.first!])
        
        private static let values = Chapters.One.values.map(ChapterFeature.State.init(chapter:))
    }

    enum Action {
        case tabChanged(UUID)
        case chapters(IdentifiedAction<UUID, ChapterFeature.Action>)
    }

    enum Cancel: Hashable { case foo }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .tabChanged(value):
                state.tab = value
            case let .chapters(.element(id: id, action: action)):
                switch action {
                case .successReadPage:
                    if state.chapters[id: id]?.readingState != .success {
                        if let element = state.dequeElements.popFirst() {
                            state.chapters.append(element)
                            state.tab = element.id
                        }
                        state.chapters[id: id]?.readingState = .success
                        
                        return .send(.chapters(.element(id: id, action: .recognitionFeature(.stopRecording))))
                    }
                default: break
                }
            case .chapters: break
            }
            return .none
        }
        .forEach(\.chapters, action: \.chapters, element: {
            ChapterFeature()
        })
        ._printChanges()
            
    }
}

struct ChaptersView: View {
    @Bindable var store: StoreOf<ChaptersFeature> = .init(initialState: .init()) {
        ChaptersFeature()
    }

    @State var selection: UUID = .init()

    var body: some View {
        TabView(selection: $selection) {
            ForEach(store.scope(state: \.chapters, action: \.chapters)) { localStore in
                ChapterView(store: localStore)
                    .tag(localStore.state.id)
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            store.send(.tabChanged(newValue))
        }
        .onChange(of: store.tab, { oldValue, newValue in
            withAnimation {
                selection = newValue
            }
        })
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

#Preview {
    ChaptersView()
}
