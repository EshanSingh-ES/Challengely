//
//  OnboardingView.swift
//  Challengely
//
//  Created by Eshan Singh on 29/07/25.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>
    @Namespace private var animation

    let steps = ["Welcome", "Interests", "Difficulty", "Name", "Summary"]
    let interestsList: [(name: String, icon: String)] = [
        ("Fitness", "figure.walk"),
        ("Creativity", "paintbrush"),
        ("Mindfulness", "brain.head.profile"),
        ("Learning", "book"),
        ("Social", "person.2")
    ]

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    // Progress Indicator (skip for Welcome)
                    if viewStore.currentStep > 0 {
                        HStack(spacing: 8) {
                            ForEach(1..<steps.count, id: \ .self) { idx in
                                Circle()
                                    .fill(idx <= viewStore.currentStep ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .matchedGeometryEffect(id: idx, in: animation)
                            }
                        }
                        .padding(.top, 24)
                        .animation(.spring(), value: viewStore.currentStep)
                    }
                    Spacer(minLength: 0)
                    ZStack {
                        switch viewStore.currentStep {
                        case 0:
                            // Welcome Screen
                            VStack(spacing: 32) {
                                Spacer()
                                Image(systemName: "trophy")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 64, height: 64)
                                    .foregroundColor(Color.blue)
                                    .padding(.bottom, 8)
                                Text("Welcome to \(Text("Challengely").foregroundColor(.blue))")
                                    .font(.system(size: 28, weight: .bold))
                                    .multilineTextAlignment(.center)
                                Text("Your daily dose of personalized challenges to help you grow and achieve your goals.")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                Spacer()
                                Button(action: { viewStore.send(.next) }) {
                                    Text("Get Started")
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 32)
                            }
                            .transition(.move(edge: .trailing))
                        case 1:
                            // Interests Grid (Pixel-perfect)
                            VStack(spacing: 0) {
                                Text("Choose your interests")
                                    .font(.system(size: 22, weight: .bold))
                                    .padding(.top, 32)
                                Text("Select at least 3 to personalize your challenges.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 24)
                                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                                LazyVGrid(columns: columns, spacing: 20) {
                                    ForEach(interestsList, id: \ .name) { interest in
                                        let isSelected = viewStore.interests.contains(interest.name.lowercased())
                                        Button(action: {
                                            viewStore.send(.toggleInterest(interest.name.lowercased()))
                                        }) {
                                            VStack(spacing: 12) {
                                                Image(systemName: interest.icon)
                                                    .font(.system(size: 32, weight: .medium))
                                                    .foregroundColor(isSelected ? .blue : .gray)
                                                Text(interest.name)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.black)
                                            }
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .padding(.vertical, 18)
                                            .background(Color.white)
                                            .cornerRadius(22)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 22)
                                                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
                                            )
                                            .shadow(color: isSelected ? Color.blue.opacity(0.10) : Color(.systemGray4).opacity(0.10), radius: 8, x: 0, y: 2)
                                        }
                                        .aspectRatio(1, contentMode: .fit)
                                    }
                                }
                                .padding(.horizontal, 24)
                                Spacer()
                            }
                            .background(Color(.systemGroupedBackground))
                            .safeAreaInset(edge: .bottom) {
                                Button(action: { viewStore.send(.next) }) {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                            }
                            .transition(.move(edge: .trailing))
                        case 2:
                            // Difficulty Custom Slider + Cards (Pixel-perfect)
                            VStack(spacing: 0) {
                                Text("Set Your Challenge Level")
                                    .font(.system(size: 22, weight: .bold))
                                    .padding(.top, 32)
                                Text("How tough do you want your challenges to be? You can always change this later.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 24)
                                CustomDifficultySlider(selected: viewStore.binding(get: \.difficulty, send: OnboardingFeature.Action.setDifficulty))
                                    .padding(.horizontal, 32)
                                    .padding(.bottom, 32)
                                VStack(spacing: 16) {
                                    ForEach(Difficulty.allCases, id: \ .self) { difficulty in
                                        let isSelected = viewStore.difficulty == difficulty
                                        Button(action: { viewStore.send(.setDifficulty(difficulty)) }) {
                                            HStack(spacing: 16) {
                                                Image(systemName: iconForDifficulty(difficulty))
                                                    .font(.system(size: 24, weight: .bold))
                                                    .foregroundColor(colorForDifficulty(difficulty))
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(difficulty.rawValue.capitalized)
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(.black)
                                                    Text(descriptionForDifficulty(difficulty))
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                            }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(18)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 18)
                                                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
                                            )
                                            .shadow(color: isSelected ? Color.blue.opacity(0.10) : Color(.systemGray4).opacity(0.10), radius: 8, x: 0, y: 2)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                Spacer()
                            }
                            .background(Color(.systemGroupedBackground))
                            .safeAreaInset(edge: .bottom) {
                                Button(action: { viewStore.send(.next) }) {
                                    Text("Complete Profile")
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                            }
                            .transition(.move(edge: .trailing))
                        case 3:
                            // Name Entry
                            VStack(spacing: 18) {
                                Text("What's your name?")
                                    .font(.system(size: 22, weight: .bold))
                                    .padding(.top, 8)
                                TextField("Enter your name", text: viewStore.binding(get: \.name, send: OnboardingFeature.Action.setName))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 24)
                                    .frame(height: 48)
                                Spacer()
                                Button(action: { viewStore.send(.next) }) {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                            .transition(.move(edge: .trailing))
                        case 4:
                            // Summary
                            VStack(spacing: 18) {
                                Text("You're all set! 🎉")
                                    .font(.system(size: 22, weight: .bold))
                                    .padding(.top, 8)
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Name:")
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text(viewStore.name)
                                    }
                                    HStack {
                                        Text("Interests:")
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text(viewStore.interests.map { $0.capitalized }.joined(separator: ", "))
                                    }
                                    HStack {
                                        Text("Difficulty:")
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text(viewStore.difficulty.rawValue.capitalized)
                                    }
                                }
                                .padding(.horizontal, 24)
                                Spacer()
                                Button(action: { viewStore.send(.next) }) {
                                    Text("Finish")
                                        .font(.system(size: 18, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                            }
                            .transition(.move(edge: .trailing))
                        default:
                            EmptyView()
                        }
                    }
                    .animation(.spring(), value: viewStore.currentStep)
                    if let error = viewStore.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 4)
                            .transition(.opacity)
                            .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { viewStore.send(.clearError) } }
                    }
                    Spacer(minLength: 0)
                    // Navigation Buttons
                    if viewStore.currentStep > 0 {
                        HStack {
                            if viewStore.currentStep > 1 && viewStore.currentStep < 4 {
                                Button(action: { viewStore.send(.back) }) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                            } else {
                                Spacer(minLength: 0)
                            }
                            Spacer()
                            Button(action: { viewStore.send(.skip) }) {
                                Text("Skip")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 8)
                        }
                    }
                }
            }
        }
    }
}

struct DifficultyDescriptionView: View {
    let difficulty: Difficulty
    var body: some View {
        switch difficulty {
        case .easy:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "leaf")
                    .foregroundColor(.green)
                VStack(alignment: .leading) {
                    Text("Easy")
                        .fontWeight(.semibold)
                    Text("Quick, simple tasks that fit perfectly into a busy day.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        case .medium:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "bolt")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Medium")
                        .fontWeight(.semibold)
                    Text("Engaging challenges that require some dedicated effort.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        case .hard:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "flame")
                    .foregroundColor(.red)
                VStack(alignment: .leading) {
                    Text("Hard")
                        .fontWeight(.semibold)
                    Text("Demanding tasks designed to truly push your limits.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

func iconForDifficulty(_ difficulty: Difficulty) -> String {
    switch difficulty {
    case .easy: return "leaf"
    case .medium: return "bolt"
    case .hard: return "flame"
    }
}
func colorForDifficulty(_ difficulty: Difficulty) -> Color {
    switch difficulty {
    case .easy: return .green
    case .medium: return .blue
    case .hard: return .red
    }
}
func descriptionForDifficulty(_ difficulty: Difficulty) -> String {
    switch difficulty {
    case .easy: return "Quick, simple tasks that fit perfectly into a busy day."
    case .medium: return "Engaging challenges that require some dedicated effort."
    case .hard: return "Demanding tasks designed to truly push your limits."
    }
}

struct CustomDifficultySlider: View {
    @Binding var selected: Difficulty
    let items: [Difficulty] = Difficulty.allCases
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let count = items.count
            let segmentWidth = width / CGFloat(count)
            ZStack(alignment: .topLeading) {
                // Track
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                    .padding(.top, 18)
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.blue.opacity(0.15), radius: 6, x: 0, y: 2)
                    .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                    .offset(x: CGFloat(items.firstIndex(of: selected) ?? 0) * segmentWidth + segmentWidth/2 - 16, y: 2)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selected)
                // Labels
                HStack(spacing: 0) {
                    ForEach(items, id: \ .self) { item in
                        Button(action: { selected = item }) {
                            Text(item.rawValue.capitalized)
                                .font(.system(size: 16, weight: selected == item ? .bold : .regular))
                                .foregroundColor(selected == item ? .black : Color(.systemGray))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(width: width, height: 44, alignment: .bottom)
                .padding(.top, 36)
            }
        }
        .frame(height: 80)
    }
}
