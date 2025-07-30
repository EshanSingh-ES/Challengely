//
//  ChallengeFeature.swift
//  Challengely
//
//  Created by Eshan Singh on 29/07/25.
//

import Foundation
import ComposableArchitecture
import SwiftUI

struct ChallengeFeature: Reducer {
    struct State: Equatable, Codable {
        var challenges: [Challenge] = Challenge.samples
        var challengeIndex: Int = 0
        var currentChallenge: Challenge = Challenge.samples.first ?? Challenge(title: "No Challenge", description: "No challenge available.", estimatedTime: "0 min", difficulty: .easy)
        var status: ChallengeStatus = .locked
        var showConfetti = false
        var streak: Int = 0
        var timer: Int = 0 // seconds elapsed
        var timerStartDate: Date? = nil // new

        enum CodingKeys: String, CodingKey {
            case challengeIndex, status, streak, timer, timerStartDate
        }

        // Only persist minimal state, not the full challenge list
        func save() {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self) {
                UserDefaults.standard.set(data, forKey: "challenge_state")
            }
        }

        static func load(challenges: [Challenge] = Challenge.samples, overrideIndex: Int? = nil) -> State {
            if let data = UserDefaults.standard.data(forKey: "challenge_state"),
               let decoded = try? JSONDecoder().decode(State.self, from: data) {
                var state = decoded
                state.challenges = challenges
                if let idx = overrideIndex {
                    state.challengeIndex = idx
                }
                state.currentChallenge = challenges.indices.contains(state.challengeIndex) ? challenges[state.challengeIndex] : (challenges.first ?? Challenge(title: "No Challenge", description: "No challenge available.", estimatedTime: "0 min", difficulty: .easy))
                // Timer resume logic
                if state.status == .accepted, let start = state.timerStartDate {
                    let elapsed = Int(Date().timeIntervalSince(start))
                    state.timer += max(0, elapsed)
                    state.timerStartDate = Date() // reset start date to now for further ticking
                }
                return state
            }
            return State()
        }

        static func reset() {
            UserDefaults.standard.removeObject(forKey: "challenge_state")
        }
    }

    enum Action: Equatable {
        case reveal
        case accept
        case complete
        case reset
        case timerTick
        case nextChallenge
        case confettiFinished
        case refreshChallenge
        case startTimer
        case stopTimer
        case share
    }

    enum ChallengeStatus: String, Equatable, Codable {
        case locked
        case revealed
        case accepted
        case completed
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .reveal:
            state.status = .revealed
            state.save()
            return .none

        case .accept:
            state.status = .accepted
            state.timer = 0
            state.timerStartDate = Date()
            state.save()
            return .run { send in
                await send(.startTimer)
            }

        case .timerTick:
            if state.status == .accepted {
                state.timer += 1
                state.save()
            }
            return .none

        case .complete:
            state.status = .completed
            state.showConfetti = true
            state.streak += 1
            state.timerStartDate = nil
            state.save()
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            return .none

        case .confettiFinished:
            state.showConfetti = false
            return .none

        case .reset:
            state.status = .locked
            state.timer = 0
            state.showConfetti = false
            state.timerStartDate = nil
            state.save()
            return .none

        case .nextChallenge:
            if !state.challenges.isEmpty {
                state.challengeIndex = (state.challengeIndex + 1) % state.challenges.count
                state.currentChallenge = state.challenges[state.challengeIndex]
            } else {
                state.currentChallenge = Challenge(title: "No Challenge", description: "No challenge available.", estimatedTime: "0 min", difficulty: .easy)
            }
            state.status = .locked
            state.timer = 0
            state.showConfetti = false
            state.timerStartDate = nil
            state.save()
            return .none

        case .refreshChallenge:
            return .send(.nextChallenge)
        case .startTimer:
            return .run { send in
                while true {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    await send(.timerTick)
                }
            }
            .cancellable(id: "challenge.timer", cancelInFlight: true)

        case .stopTimer:
            return .cancel(id: "challenge.timer")
        case .share:
            return .none
        }
    }
}

struct Challenge: Equatable {
    var title: String
    var description: String
    var estimatedTime: String
    var difficulty: Difficulty

    static let samples: [Challenge] = [
        Challenge(
            title: "30-Minute Mindfulness Walk",
            description: "Go for a walk outdoors and focus on your breathing and surroundings.",
            estimatedTime: "30 min",
            difficulty: .medium
        ),
        Challenge(
            title: "Write a Poem",
            description: "Express your thoughts in a short poem about your day.",
            estimatedTime: "15 min",
            difficulty: .easy
        ),
        Challenge(
            title: "Reach Out to a Friend",
            description: "Send a message to someone you haven't talked to in a while.",
            estimatedTime: "10 min",
            difficulty: .easy
        )
    ]
}
