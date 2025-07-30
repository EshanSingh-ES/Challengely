//
//  ChatAssistantView.swift
//  Challengely
//
//  Created by Eshan Singh on 29/07/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct ChatAssistantView: View {
    let store: StoreOf<ChatAssistantFeature>
    let challengeTitle: String
    let challengeIndex: Int
    let challengeDescription: String
    let challengeEstimatedTime: String
    let challengeDifficulty: Difficulty
    @FocusState private var isInputFocused: Bool
    @State private var inputHeight: CGFloat = 40
    let charLimit = 500
    @State private var lastSendTime = Date.distantPast

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(viewStore.messages) { msg in
                                HStack {
                                    if msg.role == .ai {
                                        Text("🤖 " + msg.text)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding()
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    } else {
                                        Text(msg.text)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding()
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(16)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                }
                                .id(msg.id)
                            }
                            if viewStore.isTyping {
                                TypingIndicatorView()
                                    .transition(.opacity)
                            }
                        }
                        .padding(.vertical)
                        .padding(.horizontal, 8)
                    }
                    .onChange(of: viewStore.messages.count) { _ in
                        withAnimation {
                            scrollView.scrollTo(viewStore.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                Divider()
                HStack(spacing: 12) {
                    // "+" button
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .foregroundColor(.gray)
                            .font(.system(size: 18, weight: .semibold))
                    }

                    // Rounded input box with character counter
                    ZStack(alignment: .trailing) {
                        TextField("Type your message...", text: viewStore.binding(
                            get: \.input,
                            send: ChatAssistantFeature.Action.updateInput
                        ), axis: .vertical)
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                .background(Color.white)
                        )
                        .overlay(
                            Text("\(viewStore.input.count)/\(charLimit)")
                                .font(.caption)
                                .foregroundColor(colorForCharCount(viewStore.input.count))
                                .padding(.trailing, 16),
                            alignment: .trailing
                        )
                    }

                    // Send button
                    Button(action: {
                        let trimmed = viewStore.input.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard !trimmed.isEmpty,
                              trimmed.count <= charLimit,
                              trimmed != viewStore.messages.last?.text
                        else { return }

                        let now = Date()
                        guard now.timeIntervalSince(lastSendTime) > 1.0 else { return }
                        lastSendTime = now

                        // Create current challenge object for AI
                        let currentChallenge = Challenge(
                            title: challengeTitle,
                            description: challengeDescription,
                            estimatedTime: challengeEstimatedTime,
                            difficulty: challengeDifficulty
                        )
                        
                        viewStore.send(.sendMessageWithChallenge(currentChallenge))
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 40)
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .disabled(viewStore.input.trimmingCharacters(in: .whitespaces).isEmpty || viewStore.input.count > charLimit)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                // Quick replies
                let lastUserMessage = viewStore.messages.last(where: { $0.role == .user })
                if let lastMessageText = lastUserMessage?.text, let suggestion = quickReply(for: lastMessageText), !suggestion.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestion, id: \.self) { reply in
                                Button(reply) {
                                    viewStore.send(.updateInput(reply))
                                    isInputFocused = true
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                    }
                }
            }
            .padding(.bottom, 4)
            .background(Color(.systemBackground))
            .onTapGesture { isInputFocused = false }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                isInputFocused = false
            }
            .onAppear {
                loadMessagesIfAvailable(viewStore: viewStore, challengeTitle: challengeTitle, challengeIndex: challengeIndex)
            }
            .onChange(of: viewStore.messages) { _ in
                saveMessagesIfNeeded(viewStore: viewStore, challengeTitle: challengeTitle, challengeIndex: challengeIndex)
            }
        }
    }
    func colorForCharCount(_ count: Int) -> Color {
        if count < charLimit * 3 / 4 { return .green }
        if count < charLimit { return .yellow }
        return .red
    }
    func quickReply(for last: String) -> [String]? {
        let lowercased = last.lowercased()

        if lowercased.contains("nervous") || lowercased.contains("start") {
            let responses = [
                "Start with just 5 minutes! Deep breathing is key. You've got this! 💪",
                "No worries! A small beginning is still progress.",
                "Take a deep breath — you’ve already taken the first step."
            ]
            return responses.shuffled()
        }

        if lowercased.contains("10 minutes") || lowercased.contains("distracted") || lowercased.contains("help") {
            let responses = [
                "That's totally normal! Try counting your breaths from 1 to 10.",
                "Stay present — distractions come and go.",
                "Acknowledge the thought, then gently return your focus to the breath."
            ]
            return responses.shuffled()
        }

        if lowercased.contains("completed") || lowercased.contains("finished") {
            let responses = [
                "Great job finishing the challenge! 🎉",
                "That’s awesome! Reflect on what went well.",
                "Well done — consistency is key!"
            ]
            return responses.shuffled()
        }

        if lowercased.contains("momentum") || lowercased.contains("day") {
            let responses = [
                "Amazing streak! 🔥 Tomorrow's challenge will be even better.",
                "Keep the streak going! Consider setting a reminder.",
                "Celebrate your progress — each day builds the habit!"
            ]
            return responses.shuffled()
        }

        if lowercased.contains("challenge") {
            let responses = [
                "Your challenge today is: \(challengeTitle) 🧘",
                "Today's goal is: \(challengeTitle) - \(challengeDescription)",
                "Get ready for: \(challengeTitle) (\(challengeEstimatedTime), \(challengeDifficulty.rawValue.capitalized) difficulty)"
            ]
            return responses.shuffled()
        }

        if !lowercased.isEmpty {
            let variants = ["Can you explain more?", "Interesting. Tell me more.", "Hmm, let's explore that."]
            return variants.shuffled()
        }
        return nil
    }
}

private func loadMessagesIfAvailable(viewStore: ViewStoreOf<ChatAssistantFeature>, challengeTitle: String, challengeIndex: Int) {
    let messages = ChatAssistantFeature.loadMessages(for: challengeTitle, challengeIndex: challengeIndex)
    if !messages.isEmpty {
        viewStore.send(.restoreMessages(messages))
    }
}

private func saveMessagesIfNeeded(viewStore: ViewStoreOf<ChatAssistantFeature>, challengeTitle: String, challengeIndex: Int) {
    ChatAssistantFeature.saveMessages(viewStore.messages, for: challengeTitle, challengeIndex: challengeIndex)
}

struct TypingIndicatorView: View {
    @State private var bounce = false
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(bounce ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).delay(Double(i) * 0.2).repeatForever(autoreverses: true), value: bounce)
            }
        }
        .onAppear { bounce = true }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
