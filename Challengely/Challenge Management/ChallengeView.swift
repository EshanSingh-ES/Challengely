import Foundation
import SwiftUI
import ComposableArchitecture
import UIKit

struct ChallengeView: View {
    let store: StoreOf<ChallengeFeature>
 
    @State private var animateReveal = false
    @State private var timer: Timer? = nil
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Streak: \(viewStore.streak) 🔥")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                viewStore.send(.nextChallenge)
                            }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            .accessibilityLabel("Next Challenge")
                        }
                        .padding(.horizontal)

                        Text("Today's Challenge")
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, 8)

                        if viewStore.status == .completed {
                            VStack(spacing: 40) {
                                Spacer(minLength: 32)

                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 72))
                                    .foregroundColor(.yellow)

                                Text("Challenge Completed!")
                                    .font(.custom("Outfit", size: 32).weight(.bold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                VStack(spacing: 20) {
                                    Text("Daily Challenge")
                                        .font(.custom("Outfit", size: 18))
                                        .foregroundColor(.gray)

                                    Text(viewStore.currentChallenge.title)
                                        .font(.custom("Outfit", size: 24).weight(.semibold))
                                        .foregroundColor(.blue)
                                        .multilineTextAlignment(.center)

                                    HStack(spacing: 8) {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.orange)
                                        Text("Current Streak: \(viewStore.streak) days")
                                            .font(.custom("Outfit", size: 16))
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(24)
                                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
                                .padding(.horizontal)

                                Button(action: {
                                    generateShareImage(viewStore: viewStore)
                                    showingShareSheet = true
                                }) {
                                    Label("Share Your Achievement", systemImage: "square.and.arrow.up")
                                        .font(.custom("Outfit", size: 18).weight(.semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.blue)
                                        .cornerRadius(14)
                                }
                                .padding(.horizontal)

                                Button("Next Challenge") {
                                    viewStore.send(.nextChallenge)
                                }
                                .font(.custom("Outfit", size: 16))
                                .padding(.top, 8)

                                Spacer(minLength: 24)
                            }
                            .frame(maxHeight: .infinity)
                            .multilineTextAlignment(.center)
                        }

                        if viewStore.status == .revealed || viewStore.status == .accepted {
                            VStack(alignment: .center, spacing: 24) {
                                VStack {
                                    Text(viewStore.currentChallenge.title)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top)

                                Text(viewStore.currentChallenge.description)
                                    .font(.system(size: 18))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                HStack(spacing: 18) {
                                    Label(viewStore.currentChallenge.estimatedTime, systemImage: "clock")
                                        .font(.footnote)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.gray.opacity(0.15))
                                        .clipShape(Capsule())

                                    Label {
                                        Text(viewStore.currentChallenge.difficulty.rawValue.capitalized)
                                            .font(.footnote)
                                            .foregroundColor(.green)
                                    } icon: {
                                        Image(systemName: "target")
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .padding(.top, viewStore.status == .completed ? 10 : 0)
                            .frame(minHeight: 400)
                            .background(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
                                    .shadow(color: .blue.opacity(0.04), radius: 36, x: 0, y: 16)
                            )
                            .padding(.horizontal)
                            .transition(.scale)

                            if viewStore.status == .accepted {
                                VStack(spacing: 8) {
                                    Text("Timer: \(formatTime(viewStore.timer))")
                                        .font(.headline)
                                    ProgressView(value: Double(viewStore.timer), total: 1800) // 30 min max
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .padding(.horizontal)
                                    Button("Mark as Completed") {
                                        viewStore.send(.complete)
                                        viewStore.send(.stopTimer)
                                    }
                                    .foregroundColor(.green)
                                    .padding(.top, 8)
                                }
                            }
                        }

                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }

                if viewStore.status == .locked {
                    VStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) { animateReveal = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewStore.send(.reveal)
                                animateReveal = false
                            }
                        }) {
                            Text("Reveal")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom))
                }

                if viewStore.status == .revealed {
                    VStack {
                        Spacer()
                        Button(action: {
                            viewStore.send(.accept)
                            viewStore.send(.startTimer)
                        }) {
                            Text("Accept Challenge")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom))
                }

                if viewStore.showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                viewStore.send(.confettiFinished)
                            }
                        }
                }
            }
            .refreshable {
                viewStore.send(.refreshChallenge)
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(activityItems: [image])
                }
            }
        }
    }

    func generateShareImage(viewStore: ViewStoreOf<ChallengeFeature>) {
        let renderer = ImageRenderer(content: ShareableChallengeView(
            challengeTitle: viewStore.currentChallenge.title,
            streak: viewStore.streak,
            difficulty: viewStore.currentChallenge.difficulty
        ))
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            shareImage = image
        }
    }

    func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct ShareableChallengeView: View {
    let challengeTitle: String
    let streak: Int
    let difficulty: Difficulty
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                
                Text("Challenge Completed!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Challenge Info
            VStack(spacing: 16) {
                Text("Daily Challenge")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Text(challengeTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    Label("\(difficulty.rawValue.capitalized)", systemImage: "target")
                        .font(.system(size: 14))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                    
                    Label("\(streak) days", systemImage: "flame.fill")
                        .font(.system(size: 14))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
            
            // App branding
            VStack(spacing: 4) {
                Text("Challengely")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("Build daily habits, one challenge at a time")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(32)
        .frame(width: 300, height: 400)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Placeholder ConfettiView
struct ConfettiView: View {
    @State private var animate = false
    let emojis = ["🎉", "🎊", "✨", "🎈"]

    var body: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { i in
                Text(emojis.randomElement()!)
                    .font(.system(size: 48))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: animate ? UIScreen.main.bounds.height : -50
                    )
                    .opacity(0.8)
                    .animation(.easeIn(duration: Double.random(in: 1.0...1.5)), value: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}
