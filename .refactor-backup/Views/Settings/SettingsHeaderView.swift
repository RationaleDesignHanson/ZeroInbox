import SwiftUI

struct SettingsHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "gear")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.9))

            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
        }
        .padding(.top, 40)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.3),
                Color(red: 0.2, green: 0.1, blue: 0.4)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        SettingsHeaderView()
    }
}
