import SwiftUI

struct ModelTuningSection: View {
    @Binding var showModelTuning: Bool
    @Binding var modelTemperature: Double
    @Binding var modelTopP: Double
    @Binding var modelMaxTokens: Double
    let defaultTemperature: Double
    let defaultTopP: Double
    let defaultMaxTokens: Double
    let onResetToDefaults: () -> Void

    var body: some View {
        DisclosureGroup(isExpanded: $showModelTuning) {
            VStack(alignment: .leading, spacing: 20) {
                // Temperature Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Temperature")
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.2f", modelTemperature))
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }

                    Slider(value: $modelTemperature, in: 0.0...2.0, step: 0.1)
                        .accentColor(.purple)

                    Text("Controls randomness. Lower is more focused, higher is more creative.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                // Top P Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Top P")
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.2f", modelTopP))
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }

                    Slider(value: $modelTopP, in: 0.0...1.0, step: 0.05)
                        .accentColor(.purple)

                    Text("Alternative to temperature. Lower = more deterministic.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                // Max Tokens Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Max Tokens")
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(modelMaxTokens))")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }

                    Slider(value: $modelMaxTokens, in: 50...2000, step: 50)
                        .accentColor(.purple)

                    Text("Maximum length of model responses.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                // Reset Button
                Button(action: onResetToDefaults) {
                    Text("Reset to Defaults")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 8)
        } label: {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.purple)
                Text("Model Tuning")
                    .foregroundColor(.white)
            }
        }
        .accentColor(.purple)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
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

        ModelTuningSection(
            showModelTuning: .constant(true),
            modelTemperature: .constant(0.7),
            modelTopP: .constant(0.9),
            modelMaxTokens: .constant(500),
            defaultTemperature: 0.7,
            defaultTopP: 0.9,
            defaultMaxTokens: 500,
            onResetToDefaults: {}
        )
        .padding()
    }
}
