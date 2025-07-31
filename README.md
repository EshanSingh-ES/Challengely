# Challengely 🎯

A daily habit-building app that presents users with personalized challenges and provides AI-powered chat support to help them stay motivated and complete their goals.

[![Watch the demo](https://img.youtube.com/vi/CZRlb1J2_l0/0.jpg)](https://youtu.be/CZRlb1J2_l0)


## 📱 Features

- **Daily Challenges**: Curated challenges with varying difficulty levels
- **Progress Tracking**: Streak counting and timer-based completion
- **AI Chat Assistant**: Contextual support and motivation
- **State Persistence**: Resume challenges after app relaunch
- **Social Sharing**: Beautiful shareable images for completed challenges
- **Haptic Feedback**: Immersive completion feedback

## 🏗️ Architecture

### Tech Stack
- **SwiftUI** - Modern declarative UI framework
- **The Composable Architecture (TCA)** - State management
- **UserDefaults** - Local persistence
- **UIKit Integration** - Native sharing and haptics

### Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AppFeature    │    │ ChallengeFeature│    │ ChatAssistant   │
│   (Root State)  │◄──►│   (Challenge   │    │   Feature       │
│                 │    │    Logic)       │    │   (AI Chat)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AppView       │    │ ChallengeView   │    │ ChatAssistant   │
│   (Tab View)    │    │   (Challenge    │    │   View          │
│                 │    │    UI)          │    │   (Chat UI)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### State Management with TCA

We chose **The Composable Architecture (TCA)** for its:

- **Predictable State Updates**: Single source of truth with immutable state
- **Testability**: Pure functions and isolated side effects
- **Composability**: Modular features that can be combined
- **Time Travel Debugging**: Built-in debugging capabilities

#### State Flow
```
User Action → Feature Action → Reducer → State Update → UI Update
```

## 🚀 Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation
1. Clone the repository:
```bash
git clone https://github.com/yourusername/Challengely.git
cd Challengely
```

2. Open `Challengely.xcodeproj` in Xcode

3. Build and run on iOS Simulator or device

### Dependencies
The project uses Swift Package Manager with the following dependencies:
- **ComposableArchitecture** - State management
- **SwiftUI** - UI framework (built-in)

## 🧪 Testing

### Unit Tests
```bash
# Run all tests
xcodebuild test -scheme Challengely -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Manual Testing Scenarios
1. **Challenge Flow**:
   - Reveal challenge → Accept → Complete
   - Verify timer persistence after app relaunch
   - Test streak counting

2. **Chat Integration**:
   - Ask "What's my challenge?" → Verify accurate response
   - Test chat persistence per challenge
   - Verify chat clearing on challenge completion

3. **State Persistence**:
   - Start challenge → Quit app → Relaunch → Verify state restored
   - Complete challenge → Verify chat cleared

## 💾 State Management Approach

### Why TCA?
- **Single Source of Truth**: All app state in one place
- **Immutable Updates**: Predictable state changes
- **Side Effect Isolation**: Async operations don't affect state directly
- **Composability**: Features can be combined and reused

### State Structure
```swift
struct AppFeature: Reducer {
    struct State {
        var challenge: ChallengeFeature.State
        var chat: ChatAssistantFeature.State
        var onboarding: OnboardingFeature.State
    }
}
```

### Persistence Strategy
- **UserDefaults**: For simple key-value data
- **Challenge State**: Index, status, timer, streak
- **Chat Messages**: Per challenge with unique keys
- **User Preferences**: Interests, difficulty, name

## ⚡ Performance Optimizations

### 1. **Lazy Loading**
- Chat messages loaded only when tab is accessed
- Challenge state restored on-demand

### 2. **Efficient State Updates**
- Minimal state changes trigger UI updates
- Computed properties avoid unnecessary recalculations

### 3. **Memory Management**
- Chat messages cleared after challenge completion
- Timer cancellable to prevent memory leaks
- Image rendering optimized for sharing

### 4. **UI Performance**
- SwiftUI's declarative updates
- Efficient list rendering with identifiable items
- Smooth animations with proper state management

## 🤖 Chat Implementation Details

### Architecture
The chat system uses a **context-aware AI** that understands:
- Current challenge state (locked, revealed, accepted, completed)
- Challenge details (title, description, difficulty, time)
- User conversation history
- Intent matching for relevant responses

### Key Design Decisions

#### 1. **Challenge-Aware Responses**
```swift
// AI receives actual challenge data
let (aiResponse, matchedIntent) = AIResponseGenerator.response(
    for: userText, 
    context: state.lastMatchedIntent, 
    currentChallenge: challenge
)
```

#### 2. **Unique Chat Storage**
```swift
// Each challenge instance has unique chat
static func chatKey(for challengeTitle: String, challengeIndex: Int) -> String {
    return "chatMessages_" + challengeTitle.replacingOccurrences(of: " ", with: "_") + "_" + String(challengeIndex)
}
```

#### 3. **Intent-Based Responses**
- **Challenge Queries**: "What's my challenge?" → Real challenge info
- **Motivation**: Nervous/distracted responses
- **Completion**: Celebration and reflection prompts

#### 4. **Context Persistence**
- Chat history saved per challenge
- Automatic restoration on tab switch
- Clearing on challenge completion

### Chat Flow
```
User Message → Intent Detection → Context-Aware Response → Save to Storage
```

### AI Response Categories
1. **Challenge Information**: Real-time challenge details
2. **Motivational Support**: Encouragement and tips
3. **Progress Tracking**: Streak and completion feedback
4. **Fallback Responses**: Generic helpful responses

## 📊 Data Flow

### Challenge State Management
```
User Action → ChallengeFeature → Persist State → Restore on Launch
```

### Chat State Management
```
User Message → ChatAssistantFeature → AI Response → Save Messages → Restore on Tab Switch
```

### Cross-Feature Communication
```
Challenge Complete → AppFeature → ChatAssistantFeature → Clear Chat → New Challenge
```

## 🔧 Key Implementation Highlights

### 1. **Timer Persistence**
- Stores `timerStartDate` for accurate resume
- Calculates elapsed time on app relaunch
- Automatic timer restart for ongoing challenges

### 2. **Chat Context Awareness**
- AI knows current challenge details
- Responses based on actual challenge state
- Unique storage per challenge instance

### 3. **State Restoration**
- Challenge progress preserved across app launches
- Chat history restored for current challenge
- Timer resumes from correct position

### 4. **Social Sharing**
- Beautiful shareable images with challenge details
- Native iOS share sheet integration
- High-quality rendering for social media

## 🎯 Future Enhancements

- **Push Notifications**: Reminder system for challenges
- **Cloud Sync**: Cross-device progress sync
- **Analytics**: Challenge completion insights
- **Custom Challenges**: User-defined challenges
- **Community Features**: Share and discover challenges

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support, email support@challengely.com or create an issue in this repository.

---

**Built with ❤️ using SwiftUI and The Composable Architecture** 
