import SwiftUI
import PencilKit

struct SignatureCanvasView: View {
    @SwiftUI.Environment(\.presentationMode) var presentationMode
    @Binding var signatureImage: UIImage?

    @State private var drawing = PKDrawing()
    @State private var showClearAlert = false

    var onSave: ((UIImage) -> Void)?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Instructions
                VStack(spacing: 8) {
                    Text("Sign below")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Use your finger or Apple Pencil to sign")
                        .font(.caption)
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(DesignTokens.Opacity.glassLight))

                // Canvas - Add explicit frame and ensure it's interactive
                CanvasViewRepresentable(drawing: $drawing)
                    .frame(height: 400) // Explicit height
                    .background(Color.white)
                    .cornerRadius(DesignTokens.Radius.card)
                    .padding()
                    .allowsHitTesting(true) // Ensure touches are captured

                // Action Buttons
                HStack(spacing: 16) {
                    // Clear Button
                    Button {
                        showClearAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
                        .foregroundColor(.red)
                        .cornerRadius(DesignTokens.Radius.button)
                    }

                    // Save Button
                    Button {
                        saveSignature()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Signature")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(DesignTokens.Radius.button)
                    }
                    .disabled(drawing.bounds.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Sign Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                    }
                }
            }
            .alert("Clear Signature?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    drawing = PKDrawing()
                }
            } message: {
                Text("This will erase your signature. You can draw it again.")
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Logger.info("📝 Canvas ready for new signature", category: .app)
        }
    }

    func saveSignature() {
        // Generate image from canvas
        let bounds = drawing.bounds

        // Create image with proper bounds
        let imageSize = CGSize(
            width: max(bounds.width, 400),
            height: max(bounds.height, 200)
        )

        let image = drawing.image(from: bounds.isEmpty ? CGRect(origin: .zero, size: imageSize) : bounds, scale: 2.0)

        // Save to SignatureManager
        SignatureManager.shared.saveSignatureImage(image)

        // Update binding
        signatureImage = image

        // Call completion handler
        onSave?(image)

        // Haptic feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        Logger.info("Signature saved successfully", category: .app)

        // Dismiss
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Canvas View Representable
struct CanvasViewRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()

        // Configure the canvas for drawing
        canvasView.drawingPolicy = .anyInput // Allow both finger and Apple Pencil
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        canvasView.isUserInteractionEnabled = true

        // Set default tool (black pen for signatures)
        let tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.tool = tool

        // Set initial drawing
        canvasView.drawing = drawing

        // Set up delegate to track drawing changes
        canvasView.delegate = context.coordinator

        // Disable zoom for cleaner signature experience
        canvasView.minimumZoomScale = 1.0
        canvasView.maximumZoomScale = 1.0

        // Allow drawing to become scrollable if needed
        canvasView.alwaysBounceVertical = false
        canvasView.alwaysBounceHorizontal = false

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Only update if the drawing changed externally (e.g., clear button)
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }

        // Ensure canvas can receive touches after updates
        if !context.coordinator.didBecomeFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                context.coordinator.didBecomeFirstResponder = true
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        var didBecomeFirstResponder = false

        init(drawing: Binding<PKDrawing>) {
            self._drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Update the binding whenever the user draws
            drawing = canvasView.drawing
            Logger.debug("📝 Drawing changed - bounds: \(canvasView.drawing.bounds)", category: .app)
        }
    }
}

// MARK: - Preview
struct SignatureCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        SignatureCanvasView(signatureImage: .constant(nil))
    }
}
