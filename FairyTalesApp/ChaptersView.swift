//
//  ChaptersView.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 02.09.2024.
//

import ComposableArchitecture
import SwiftUI
import DequeModule

@Reducer
struct ChaptersFeature {
    @ObservableState
    struct State {
        var tab: UUID = .init()
        var isLoad = false
        var readingState = ReadingState.inProcess
        var dequeElements = Deque(Chapters.One.values.dropFirst())
        var chapters = IdentifiedArray(uniqueElements: [Chapters.One.values.first!])
    }

    enum Action {
        case tabChanged(UUID)
        case chapters(IdentifiedAction<UUID, ChapterFeature.Action>)
    }

    enum Cancel: Hashable { case foo }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .tabChanged: break
            case let .chapters(.element(id: _, action: action)):
                switch action {
                case .successReadPage:
                    if let element = state.dequeElements.popFirst() {
                        state.chapters.append(element)
                    }
                default: break
                }
            case .chapters: break
            }
            return .none
                
        }
        ._printChanges()
        .forEach(\.chapters, action: \.chapters, element: {
            ChapterFeature()
        })
            
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
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

#Preview {
    ChaptersView()
}
