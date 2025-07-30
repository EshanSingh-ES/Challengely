//
//  OnboardingFeature.swift
//  Challengely
//
//  Created by Eshan Singh on 29/07/25.
//

import Foundation
import ComposableArchitecture

struct OnboardingFeature: Reducer {
    struct State: Equatable {
        var interests: Set<String> = []
        var difficulty: Difficulty = .medium
        var name: String = ""
        var currentStep: Int = 0
        var completed = false
        var error: String? = nil
    }

    enum Action: Equatable {
        case toggleInterest(String)
        case setDifficulty(Difficulty)
        case setName(String)
        case next
        case back
        case skip
        case clearError
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .toggleInterest(interest):
            if state.interests.contains(interest) {
                state.interests.remove(interest)
            } else {
                state.interests.insert(interest)
            }
            return .none

        case let .setDifficulty(level):
            state.difficulty = level
            return .none

        case let .setName(name):
            state.name = name
            return .none

        case .next:
            // Validation for each step
            switch state.currentStep {
            case 1:
                if state.interests.isEmpty {
                    state.error = "Please select at least one interest."
                    return .none
                }
            case 3:
                if state.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    state.error = "Please enter your name."
                    return .none
                }
            default:
                break
            }
            if state.currentStep < 4 {
                state.currentStep += 1
            } else {
                // Save preferences locally
                UserPreferences.save(interests: state.interests, difficulty: state.difficulty, name: state.name)
                ChallengeFeature.State.reset()
                state.completed = true
            }
            return .none

        case .back:
            if state.currentStep > 0 {
                state.currentStep -= 1
            }
            return .none

        case .skip:
            state.interests = ["fitness", "learning"]
            state.difficulty = .medium
            state.name = "Guest"
            UserPreferences.save(interests: state.interests, difficulty: state.difficulty, name: state.name)
            ChallengeFeature.State.reset()
            state.completed = true
            return .none

        case .clearError:
            state.error = nil
            return .none
        }
    }
}

enum Difficulty: String, CaseIterable, Codable, Equatable {
    case easy, medium, hard
}

// Add UserPreferences helper
struct UserPreferences {
    static func save(interests: Set<String>, difficulty: Difficulty, name: String) {
        UserDefaults.standard.set(Array(interests), forKey: "user_interests")
        UserDefaults.standard.set(difficulty.rawValue, forKey: "user_difficulty")
        UserDefaults.standard.set(name, forKey: "user_name")
    }
    static func load() -> (Set<String>, Difficulty, String) {
        let interests = Set(UserDefaults.standard.stringArray(forKey: "user_interests") ?? [])
        let difficulty = Difficulty(rawValue: UserDefaults.standard.string(forKey: "user_difficulty") ?? "medium") ?? .medium
        let name = UserDefaults.standard.string(forKey: "user_name") ?? "Guest"
        return (interests, difficulty, name)
    }
}
