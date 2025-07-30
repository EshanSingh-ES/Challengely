import SwiftUI

struct ProfileView: View {
    let interests: Set<String>
    let difficulty: Difficulty
    let name: String

    init() {
        let (interests, difficulty, name) = UserPreferences.load()
        self.interests = interests
        self.difficulty = difficulty
        self.name = name
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding(.top, 32)
                Text(name)
                    .font(.title)
                    .fontWeight(.bold)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Interests:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(interests.map { $0.capitalized }.joined(separator: ", "))
                    }
                    HStack {
                        Text("Difficulty:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(difficulty.rawValue.capitalized)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
} 