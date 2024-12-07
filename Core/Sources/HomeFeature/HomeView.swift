//
//  HomeView.swift
//
//
//  Created by Bravery on 23.11.2024.
//

import ComposableArchitecture
import SwiftUI
import ChaptersFeature

@Reducer
struct HomeFeature {
    public init() {}

    @ObservableState
    public struct State {
        public var chaptersState = ChaptersFeature.State(chapters: [])
        public init() {}
    }
    
    public enum Action {
        case chapters(ChaptersFeature.Action)
    }
}

struct HomeView: View {
    @State private var age = ""

    var card: some View {
        ZStack(alignment: .bottom) {
            Image("dragon_story", bundle: .module)
                .resizable()
                .scaledToFit()

            Color.black.opacity(0.3)

            Text("Dragon Story")
                .foregroundStyle(.white)
                .font(.headline)
                .padding(10)
        }
        .frame(width: 140, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Last Read")) {
                    ScrollView(.horizontal) {
                        card
                    }
                }
                .font(.title2)
                .bold()
                .foregroundStyle(.black)

                Section(header: Text("Your fairy tales")) {
                    HStack {
                        card
                        Spacer()
                        card
                    }

                    HStack {
                        card
                        Spacer()
                        card
                    }
                }
                .font(.title2)
                .bold()
                .foregroundStyle(.black)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Hello, User")
        }
    }
}

#Preview {
    HomeView()
}
