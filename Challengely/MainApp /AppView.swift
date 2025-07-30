//
//  AppView.swift
//  Challengely
//
//  Created by Eshan Singh on 29/07/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct ChallengeChatKey: Equatable {
    let title: String
    let index: Int
    let description: String
    let estimatedTime: String
    let difficulty: Difficulty
}

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: \.hasCompletedOnboarding) { viewStore in
            if viewStore.state {
                TabView {
                    ChallengeView(store: store.scope(state: \.challenge, action: AppFeature.Action.challenge))
                        .tabItem {
                            Label("Today", systemImage: "sun.max")
                        }

                    WithViewStore(store, observe: 
                        { state in 
                            let challenge = state.challenge.currentChallenge
                            return ChallengeChatKey(
                                title: challenge.title, 
                                index: state.challenge.challengeIndex,
                                description: challenge.description,
                                estimatedTime: challenge.estimatedTime,
                                difficulty: challenge.difficulty
                            )
                        }
                    ) { challengeInfoViewStore in
                        ChatAssistantView(
                            store: store.scope(state: \.chat, action: AppFeature.Action.chat),
                            challengeTitle: challengeInfoViewStore.state.title,
                            challengeIndex: challengeInfoViewStore.state.index,
                            challengeDescription: challengeInfoViewStore.state.description,
                            challengeEstimatedTime: challengeInfoViewStore.state.estimatedTime,
                            challengeDifficulty: challengeInfoViewStore.state.difficulty
                        )
                        .tabItem {
                            Label("Chat", systemImage: "message")
                        }
                    }

                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                }
            } else {
                OnboardingView(store: store.scope(state: \.onboarding, action: AppFeature.Action.onboarding))
            }
        }
        .onAppear {
            ViewStore(store, observe: \.hasCompletedOnboarding).send(.checkOnboardingStatus)
            let challengeViewStore = ViewStore(store.scope(state: \.challenge, action: AppFeature.Action.challenge), observe: { $0 })
            if challengeViewStore.status == .accepted {
                challengeViewStore.send(.startTimer)
            }
        }
    }
}
