import SwiftUI

/// Temporary placeholder shown until the app shell (tab bar + screens) lands in Phase 2.
struct RootView: View {
    private let flashcards = Color(red: 0.965, green: 0.663, blue: 0.231) // #F6A93B
    private let mining = Color(red: 0.353, green: 0.627, blue: 1.0)       // #5AA0FF

    var body: some View {
        ZStack {
            LinearGradient(colors: [flashcards, mining],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [flashcards, mining],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)

                Text("Traki")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))

                Text("Time tracker for language learners")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    RootView()
}
