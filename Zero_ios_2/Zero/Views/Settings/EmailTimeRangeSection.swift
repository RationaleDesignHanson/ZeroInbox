import SwiftUI

struct EmailTimeRangeSection: View {
    @Binding var emailTimeRange: Int
    @Binding var showTimeRangePicker: Bool

    private let timeRangeOptions = [
        (value: 7, label: "Last 7 days"),
        (value: 14, label: "Last 14 days"),
        (value: 30, label: "Last 30 days"),
        (value: 60, label: "Last 60 days"),
        (value: 90, label: "Last 90 days")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                Text("Email Time Range")
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    withAnimation {
                        showTimeRangePicker.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(timeRangeLabel)
                            .foregroundColor(.white.opacity(0.7))
                        Image(systemName: showTimeRangePicker ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            if showTimeRangePicker {
                VStack(spacing: 8) {
                    ForEach(timeRangeOptions, id: \.value) { option in
                        Button(action: {
                            emailTimeRange = option.value
                            withAnimation {
                                showTimeRangePicker = false
                            }
                            HapticService.shared.lightImpact()
                        }) {
                            HStack {
                                Text(option.label)
                                    .foregroundColor(.white)
                                Spacer()
                                if emailTimeRange == option.value {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                emailTimeRange == option.value
                                    ? Color.purple.opacity(0.2)
                                    : Color.white.opacity(0.05)
                            )
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var timeRangeLabel: String {
        timeRangeOptions.first { $0.value == emailTimeRange }?.label ?? "Last \(emailTimeRange) days"
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

        EmailTimeRangeSection(
            emailTimeRange: .constant(30),
            showTimeRangePicker: .constant(true)
        )
        .padding()
    }
}
