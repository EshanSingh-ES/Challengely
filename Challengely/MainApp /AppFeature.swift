//
//  AppFeature.swift
//  Challengely
//
//  Created by Eshan Singh on 29/07/25.
//

import Foundation
import ComposableArchitecture

struct AppFeature: Reducer {
    struct State: Equatable {
        var onboarding = OnboardingFeature.State()
        var challenge = ChallengeFeature.State.load()
        var chat = ChatAssistantFeature.State()
        var hasCompletedOnboarding = false
    }

    enum Action {
        case onboarding(OnboardingFeature.Action)
        case challenge(ChallengeFeature.Action)
        case chat(ChatAssistantFeature.Action)
        case checkOnboardingStatus
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.onboarding, action: /Action.onboarding) {
            OnboardingFeature()
        }
        Scope(state: \.challenge, action: /Action.challenge) {
            ChallengeFeature()
        }
        Scope(state: \.chat, action: /Action.chat) {
            ChatAssistantFeature()
        }
        Reduce { state, action in
            switch action {
            case .onboarding(let onboardingAction):
                if case .next = onboardingAction, state.onboarding.completed {
                    state.hasCompletedOnboarding = true
                }
                if case .skip = onboardingAction {
                    state.hasCompletedOnboarding = true
                }
                return .none
            case .challenge(.complete):
             
                let challengeTitle = state.challenge.currentChallenge.title
                let challengeIndex = state.challenge.challengeIndex
                return .send(.chat(.challengeCompleted(challengeTitle: challengeTitle, challengeIndex: challengeIndex)))
            case .challenge(.nextChallenge):
             
                let challengeTitle = state.challenge.challenges[(state.challenge.challengeIndex + 1) % state.challenge.challenges.count].title
                let challengeIndex = (state.challenge.challengeIndex + 1) % state.challenge.challenges.count
                ChatAssistantFeature.clearMessages(for: challengeTitle, challengeIndex: challengeIndex)
                return .none
            case .challenge(.reset):
               
                let challengeTitle = state.challenge.currentChallenge.title
                let challengeIndex = state.challenge.challengeIndex
                ChatAssistantFeature.clearMessages(for: challengeTitle, challengeIndex: challengeIndex)
                return .none
            case .checkOnboardingStatus:
                let (_, _, name) = UserPreferences.load()
                state.hasCompletedOnboarding = !name.isEmpty && name != "Guest"
                return .none
            default:
                return .none
            }
        }
    }
}
