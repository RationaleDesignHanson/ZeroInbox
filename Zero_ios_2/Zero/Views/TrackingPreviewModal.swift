import SwiftUI
import SafariServices

/**
 * TrackingPreviewModal
 * Shows tracking information before opening carrier's tracking page
 * Framework-compliant: Shows "evidence" before action execution
 */

struct TrackingPreviewModal: View {
    let card: EmailCard
    let trackingNumber: String
    let carrier: String
    let trackingUrl: String
    @Binding var isPresented: Bool
    
    @State private var showingSafari = false
    @State private var copied = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Track Package")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Package tracking information")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                }
                
                Spacer()
                
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                        .font(.title2)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(DesignTokens.Opacity.textTertiary)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Package icon
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding()
                    
                    // Tracking details
                    VStack(spacing: 16) {
                        InfoRow(label: "Carrier", value: carrier.uppercased())
                        InfoRow(label: "Tracking Number", value: trackingNumber, copyable: true, onCopy: {
                            UIPasteboard.general.string = trackingNumber
                            copied = true
                            HapticFeedback.success()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        })
                        
                        if let orderNumber = card.suggestedActions?.first?.context?["orderNumber"] {
                            InfoRow(label: "Order", value: orderNumber)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            openTracking()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.forward.app")
                                Text("Open Tracking Page")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                        
                        if copied {
                            Text("✓ Tracking number copied")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
            }
            .background(Color(white: 0.98))
        }
        .sheet(isPresented: $showingSafari) {
            if let url = URL(string: trackingUrl) {
                SafariView(url: url)
            }
        }
    }
    
    private func openTracking() {
        showingSafari = true
        HapticFeedback.light()
        
        // Auto-dismiss after opening Safari
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    var copyable: Bool = false
    var onCopy: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body.monospaced())
                .foregroundColor(.primary)
            
            if copyable, let onCopy = onCopy {
                Button {
                    onCopy()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// Safari View wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// Haptic feedback helper
struct HapticFeedback {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

