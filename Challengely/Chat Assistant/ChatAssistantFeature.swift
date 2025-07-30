//
//  ChatAssistantFeature.swift
//  Challengely
//
//  Created by Eshan Singh on 29/07/25.
//

import Foundation
import Foundation
import ComposableArchitecture

struct ChatAssistantFeature: Reducer {
    struct State: Equatable {
        var messages: [ChatMessage] = []
        var input: String = ""
        var isTyping = false
        // Context tracking
        var lastMatchedIntent: String? = nil
        var fallbackCount: Int = 0
    }

    enum Action: Equatable {
        case updateInput(String)
        case sendMessage
        case sendMessageWithChallenge(Challenge)
        case receiveAI(String)
        case typingFinished
        case challengeCompleted(challengeTitle: String, challengeIndex: Int)
        case restoreMessages([ChatMessage])
        case saveMessagesForChallenge(String, Int) // new action
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .updateInput(text):
            state.input = text
            return .none

        case .sendMessage:
            guard !state.input.trimmingCharacters(in: .whitespaces).isEmpty else { return .none }
            let userText = state.input
            state.messages.append(ChatMessage(role: .user, text: userText))
            state.input = ""
            state.isTyping = true

            let (aiResponse, matchedIntent) = AIResponseGenerator.response(for: userText, context: state.lastMatchedIntent, currentChallenge: nil)
            if matchedIntent == nil {
                state.fallbackCount += 1
            } else {
                state.fallbackCount = 0
            }
            state.lastMatchedIntent = matchedIntent

            return .run { send in
                try await Task.sleep(nanoseconds: 1_500_000_000)
                await send(.receiveAI(aiResponse))
                await send(.typingFinished)
            }

        case let .sendMessageWithChallenge(challenge):
            guard !state.input.trimmingCharacters(in: .whitespaces).isEmpty else { return .none }
            let userText = state.input
            state.messages.append(ChatMessage(role: .user, text: userText))
            state.input = ""
            state.isTyping = true

            let (aiResponse, matchedIntent) = AIResponseGenerator.response(for: userText, context: state.lastMatchedIntent, currentChallenge: challenge)
            if matchedIntent == nil {
                state.fallbackCount += 1
            } else {
                state.fallbackCount = 0
            }
            state.lastMatchedIntent = matchedIntent

            return .run { send in
                try await Task.sleep(nanoseconds: 1_500_000_000)
                await send(.receiveAI(aiResponse))
                await send(.typingFinished)
            }

        case let .receiveAI(text):
            state.messages.append(ChatMessage(role: .ai, text: text))
            return .none

        case .typingFinished:
            state.isTyping = false
            return .none

        case let .challengeCompleted(challengeTitle, challengeIndex):
            state.isTyping = true
            Self.clearMessages(for: challengeTitle, challengeIndex: challengeIndex)
            state.messages = [] // Clear in-memory messages for UI
            return .run { send in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await send(.receiveAI("How did that feel? What was the hardest part?"))
                await send(.typingFinished)
            }
        case let .restoreMessages(messages):
            state.messages = messages
            state.fallbackCount = 0
            state.lastMatchedIntent = nil
            return .none
        case let .saveMessagesForChallenge(challengeTitle, challengeIndex):
            Self.saveMessages(state.messages, for: challengeTitle, challengeIndex: challengeIndex)
            return .none
        }
    }

    static func chatKey(for challengeTitle: String, challengeIndex: Int) -> String {
        return "chatMessages_" + challengeTitle.replacingOccurrences(of: " ", with: "_") + "_" + String(challengeIndex)
    }

    static func saveMessages(_ messages: [ChatMessage], for challengeTitle: String, challengeIndex: Int) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(messages) else { return }
        let key = chatKey(for: challengeTitle, challengeIndex: challengeIndex)
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clearMessages(for challengeTitle: String, challengeIndex: Int) {
        let key = chatKey(for: challengeTitle, challengeIndex: challengeIndex)
        UserDefaults.standard.removeObject(forKey: key)
    }

    static func loadMessages(for challengeTitle: String, challengeIndex: Int) -> [ChatMessage] {
        let key = chatKey(for: challengeTitle, challengeIndex: challengeIndex)
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([ChatMessage].self, from: data)) ?? []
    }
}

enum MessageRole: String, Codable {
    case user
    case ai
}

struct ChatMessage: Equatable, Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let text: String

    init(id: UUID = UUID(), role: MessageRole, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }

    enum CodingKeys: String, CodingKey {
        case id, role, text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.role = try container.decode(MessageRole.self, forKey: .role)
        self.text = try container.decode(String.self, forKey: .text)
    }
}

struct AIResponseGenerator {
    struct Trigger {
        let intent: String
        let keywords: [String]
        let responses: [String]
        let matchAll: Bool
    }

    static let triggers: [Trigger] = [
        Trigger(
            intent: "challenge_query",
            keywords: ["what", "challenge", "today", "current"],
            responses: [
                "Today's challenge is: a 30-minute mindfulness walk 🌿",
                "Your challenge for today: take a mindful walk for 30 minutes! 🚶‍♂️",
                "How about a 30-minute mindfulness walk for today's challenge? 🌱"
            ],
            matchAll: false
        ),
        Trigger(
            intent: "nervousness",
            keywords: ["nervous"],
            responses: [
                "Start with just 5 minutes! Deep breathing is key. You've got this! 💪",
                "It's okay to feel nervous. Try some deep breaths and start small!",
                "Nervous? Remember, every step counts. Begin gently and be kind to yourself."
            ],
            matchAll: false
        ),
        Trigger(
            intent: "distraction",
            keywords: ["distracted"],
            responses: [
                "That's totally normal! Try counting your breaths from 1 to 10, then repeat.",
                "If you're distracted, gently bring your focus back to your breath.",
                "Distractions happen! Notice them, then return to your walk."
            ],
            matchAll: false
        )
    ]

    static let fallbackResponses = [
        "Interesting thought! Stay focused and keep moving forward 💫",
        "I'm here to help! Can you tell me more?",
        "Could you rephrase that? I'm listening."
    ]

    static func response(for userInput: String, context: String?, currentChallenge: Challenge?) -> (String, String?) {
        let lowercased = userInput.lowercased()
        
        // Check for challenge query first
        if lowercased.contains("what") && (lowercased.contains("challenge") || lowercased.contains("today") || lowercased.contains("current")) {
            if let challenge = currentChallenge {
                let responses = [
                    "Your challenge today is: \(challenge.title) 🎯",
                    "Today's challenge: \(challenge.title) - \(challenge.description) 💪",
                    "You're working on: \(challenge.title) (\(challenge.estimatedTime), \(challenge.difficulty.rawValue.capitalized) difficulty) 🌟"
                ]
                return (responses.randomElement() ?? responses[0], "challenge_query")
            } else {
                return ("I don't have information about your current challenge. Try checking the Today tab! 📱", "challenge_query")
            }
        }
        
        for trigger in triggers {
            let matches: Bool
            if trigger.matchAll {
                matches = trigger.keywords.allSatisfy { lowercased.contains($0) }
            } else {
                matches = trigger.keywords.contains { lowercased.contains($0) }
            }
            if matches {
                let response = trigger.responses.randomElement() ?? trigger.responses[0]
                return (response, trigger.intent)
            }
        }
        // Fallback logic: rotate responses based on fallback count in context
        let fallbackIndex: Int
        if let context = context, context == "fallback" {
            fallbackIndex = 1
        } else {
            fallbackIndex = 0
        }
        let response = fallbackResponses.randomElement() ?? fallbackResponses[0]
        return (response, nil)
    }
}
