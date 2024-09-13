//
//  ChaptersView.swift
//  FairyTales
//
//  Created by Artiom Kalinkin on 02.09.2024.
//

import SwiftUI
import ComposableArchitecture


@Reducer
struct ChaptersFeature {
    @ObservableState
    struct State {
        var isChanged = false
        var tab: UUID = .init()
        var chapters: IdentifiedArray<UUID, ChapterFeature.State> = IdentifiedArray(uniqueElements: Chapters.One.values.map(ChapterFeature.State.init(chapter:)))
    }
    
    enum Action {
        case tabChanged(UUID)
        case foo
        case chapters(IdentifiedAction<UUID,ChapterFeature.Action>)
    }
        
    enum Cancel: Hashable { case foo }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
//            case .tabChanged(_):
//                return .send(.foo).debounce(id: Cancel.foo, for: 0.05, scheduler: DispatchQueue.main)
            case .tabChanged(_):
                if !state.isChanged {
                    state.isChanged = true
                    return .send(.foo)
                }
            case .foo:
                state.isChanged = false
                print("Final")
            case .chapters(_): break
            }
            return .none
        }
        .forEach(\.chapters, action: \.chapters, element: {
            ChapterFeature()
        })
    }
}


struct ChaptersView: View {
    
    @Bindable var store: StoreOf<ChaptersFeature> = .init(initialState: .init()) {
        ChaptersFeature()
    }
    
    var body: some View {
        TabView(selection: $store.tab.sending(\.tabChanged)) {
            ForEachStore(store.scope(state: \.chapters, action: \.chapters)) { store in
                ChapterView(store: store)
                    .tag(store.state.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

#Preview {
    ChaptersView()
}
