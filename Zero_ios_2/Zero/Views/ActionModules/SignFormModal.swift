import SwiftUI

struct SignFormModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    var onSignComplete: ((String) -> Void)? // Callback with signature name

    @State private var signature = ""
    @State private var currentStep = 1 // 1 = Sign, 2 = Pay (if needed)
    @State private var paymentMethod = "Apple Pay"
    @State private var showSavedSignatureOption = false
    @State private var signatureImage: UIImage?
    @State private var showSignatureCanvas = false
    @State private var signatureMode: SignatureMode = .typed // typed or drawn
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPDFPreview = false
    @State private var previewPDFData: Data?
    @State private var recipientEmail = ""
    @State private var showEmailField = false

    var totalSteps: Int {
        if card.paymentAmount != nil && card.paymentAmount! > 0 {
            return 2 // Sign + Pay
        }
        return 1 // Just Sign
    }

    /// Check if signature is incomplete based on current mode
    var isSignatureIncomplete: Bool {
        switch signatureMode {
        case .typed:
            return signature.isEmpty
        case .drawn:
            return signatureImage == nil
        }
    }

    /// Extract "Why" section from card summary (modal-specific, plain text only)
    private var whySection: String? {
        let sections = SummaryParser.parse(card.summary)
        return sections.first(where: { $0.title == "Why" })?.content
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header bar
            ModalHeader(isPresented: $isPresented)

                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
                        // Step Progress
                        if totalSteps > 1 {
                            HStack(spacing: DesignTokens.Spacing.inline) {
                                ForEach(1...totalSteps, id: \.self) { step in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(step <= currentStep ? Color.white : Color.white.opacity(DesignTokens.Opacity.overlayMedium))
                                        .frame(height: 4)
                                }
                            }
                            .padding(.bottom, DesignTokens.Spacing.inline)
                        }

                        // Header
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                            Text(stepTitle)
                                .font(.title2.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)

                            Text(card.title)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSubtle)

                            if let kid = card.kid {
                                Text("For \(kid.name) - \(kid.grade)")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }

                            // Show Why section (modal-specific, plain text only)
                            if let why = whySection {
                                Text(why)
                                    .font(.subheadline)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .lineLimit(3)
                                    .padding(.top, 6)
                            }
                        }

                        Divider()
                            .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))
                        
                        // Step Content
                        if currentStep == 1 {
                            signatureStep
                        } else if currentStep == 2 {
                            paymentStep
                        }
                    }
                    .padding(DesignTokens.Spacing.card)
                }
            }
        }
    
    var stepTitle: String {
        switch currentStep {
        case 1: return "Step 1: Sign Permission Form"
        case 2: return "Step 2: Payment"
        default: return "Sign Permission Form"
        }
    }
    
    var signatureStep: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            // Use Saved Signature button (if available)
            if SignatureManager.shared.hasSignature() {
                Button {
                    // Load saved typed signature
                    if let savedName = SignatureManager.shared.getSavedSignature() {
                        signature = savedName
                        signatureMode = .typed
                        signatureImage = nil
                    }
                    // Load saved drawn signature image
                    if let savedImage = SignatureManager.shared.getSavedSignatureImage() {
                        signatureImage = savedImage
                        signatureMode = .drawn
                        signature = "" // Clear typed signature
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Use Saved Signature")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if let saved = SignatureManager.shared.getSavedSignature() {
                            Text(saved)
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        } else if SignatureManager.shared.getSavedSignatureImage() != nil {
                            Image(systemName: "scribble.variable")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                        }
                    }
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding()
                    .background(Color.blue.opacity(DesignTokens.Opacity.overlayMedium))
                    .cornerRadius(DesignTokens.Radius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.blue.opacity(DesignTokens.Opacity.overlayStrong), lineWidth: 1)
                    )
                }
            }

            // Signature Mode Toggle
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                Text("Signature Method")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                HStack(spacing: DesignTokens.Spacing.component) {
                    // Type button
                    Button {
                        withAnimation {
                            signatureMode = .typed
                            signatureImage = nil // Clear drawn signature
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "textformat.abc")
                                .font(.body)
                            Text("Type")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(signatureMode == .typed ? Color.blue.opacity(0.4) : Color.white.opacity(DesignTokens.Opacity.glassLight))
                        .cornerRadius(DesignTokens.Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(signatureMode == .typed ? Color.blue : Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: signatureMode == .typed ? 2 : 1)
                        )
                    }

                    // Draw button
                    Button {
                        withAnimation {
                            signatureMode = .drawn
                            signature = "" // Clear typed signature
                            showSignatureCanvas = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.tip")
                                .font(.body)
                            Text("Draw")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(signatureMode == .drawn ? Color.purple.opacity(0.4) : Color.white.opacity(DesignTokens.Opacity.glassLight))
                        .cornerRadius(DesignTokens.Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(signatureMode == .drawn ? Color.purple : Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: signatureMode == .drawn ? 2 : 1)
                        )
                    }
                }
            }

            // Typed Signature Field (only show when in typed mode)
            if signatureMode == .typed {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                    Text("Digital Signature")
                        .font(.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    ZStack(alignment: .leading) {
                        if signature.isEmpty {
                            Text("Type your full name")
                                .foregroundColor(DesignTokens.Colors.textSubtle)
                                .padding(.leading, DesignTokens.Spacing.section)
                        }
                        TextField("", text: $signature)
                            .padding()
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .autocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                    )

                    if !signature.isEmpty {
                        Text("✓ Signature: \(signature)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .italic()
                    }
                }
            }

            // Drawn Signature Preview (only show when in drawn mode)
            if signatureMode == .drawn {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                    HStack {
                        Text("Drawn Signature")
                            .font(.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)

                        Spacer()

                        // Re-draw button
                        if signatureImage != nil {
                            Button {
                                showSignatureCanvas = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                    Text("Re-draw")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(.purple)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(DesignTokens.Opacity.overlayLight))
                                .cornerRadius(DesignTokens.Spacing.inline)
                            }
                        }
                    }

                    if let image = signatureImage {
                        // Show signature preview
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(DesignTokens.Radius.button)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.green, lineWidth: 2)
                                )
                        }

                        Text("✓ Signature captured")
                            .font(.caption)
                            .foregroundColor(.green)
                            .italic()
                    } else {
                        // Prompt to draw
                        Button {
                            showSignatureCanvas = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil.tip.crop.circle")
                                    .font(.title2)
                                Text("Tap to Draw Your Signature")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color.white.opacity(DesignTokens.Opacity.glassUltraLight))
                            .cornerRadius(DesignTokens.Radius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(DesignTokens.Opacity.overlayStrong), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            )
                        }

                        Text("Tap the area above to open drawing canvas")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSubtle)
                    }
                }
            }

            // Recipient Email Field (shown if no sender email or on payment step)
            if showEmailField || currentStep == 2 || (card.sender?.email ?? "").isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                    Text("Recipient Email")
                        .font(.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)

                    Text("Enter the email address to send the signed document to:")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSubtle)

                    TextField("teacher@school.edu", text: $recipientEmail)
                        .padding()
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                        .cornerRadius(DesignTokens.Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                        )

                    if !recipientEmail.isEmpty && !isValidEmail(recipientEmail) {
                        Text("⚠️ Please enter a valid email address")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            // Preview PDF button (only show on final step)
            if !(totalSteps > 1 && currentStep == 1) {
                Button {
                    previewPDF()
                } label: {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Preview PDF Before Sending")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(DesignTokens.Opacity.overlayMedium))
                    .cornerRadius(DesignTokens.Radius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.orange.opacity(DesignTokens.Opacity.overlayStrong), lineWidth: 1)
                    )
                }
                .disabled(isSignatureIncomplete)
            }

            // Continue/Submit button
            Button {
                if totalSteps > 1 && currentStep == 1 {
                    // Check if we need to show email field
                    if (card.sender?.email ?? "").isEmpty && recipientEmail.isEmpty {
                        withAnimation {
                            showEmailField = true
                        }
                    }
                    // Go to payment step
                    withAnimation {
                        currentStep = 2
                    }
                } else {
                    // Final step - check email and send
                    if recipientEmail.isEmpty && (card.sender?.email ?? "").isEmpty {
                        withAnimation {
                            showEmailField = true
                            showError = true
                            errorMessage = "Please enter recipient email address"
                        }
                        return
                    }

                    if !recipientEmail.isEmpty && !isValidEmail(recipientEmail) {
                        withAnimation {
                            showError = true
                            errorMessage = "Please enter a valid email address"
                        }
                        return
                    }

                    // Generate PDF and send email
                    sendSignedDocument()
                }
            } label: {
                HStack {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: totalSteps > 1 && currentStep == 1 ? "arrow.right" : "checkmark")
                    }
                    Text(isSending ? "Sending..." : (totalSteps > 1 && currentStep == 1 ? "Continue to Payment" : "Complete & Send"))
                }
            }
            .buttonStyle(.gradientPrimary)
            .disabled(isSignatureIncomplete || isSending)
            .opacity((isSignatureIncomplete || isSending) ? 0.5 : 1.0)

            // Success message
            if showSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Email sent successfully!")
                        .foregroundColor(.green)
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(DesignTokens.Opacity.overlayLight))
                .cornerRadius(DesignTokens.Radius.button)
            }

            // Error message
            if showError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
                .cornerRadius(DesignTokens.Radius.button)
            }
        }
        .sheet(isPresented: $showPDFPreview) {
            if let pdfData = previewPDFData {
                DocumentPreviewModal(
                    documentTitle: card.title,
                    pdfData: pdfData,
                    pdfURL: nil,
                    isPresented: $showPDFPreview
                )
            }
        }
        .sheet(isPresented: $showSignatureCanvas) {
            SignatureCanvasView(signatureImage: $signatureImage)
                .onDisappear {
                    // Ensure we stay in drawn mode if signature was captured
                    if signatureImage != nil {
                        signatureMode = .drawn
                    }
                }
        }
        .onAppear {
            // Auto-populate recipient email if available from sender
            if let senderEmail = card.sender?.email, !senderEmail.isEmpty {
                recipientEmail = senderEmail
            } else {
                // For mock data, auto-populate with fake email to streamline testing
                let useMockData = UserDefaults.standard.bool(forKey: "useMockData")
                if useMockData {
                    // Generate appropriate fake email based on card context
                    if card.title.lowercased().contains("teacher") || card.title.lowercased().contains("school") {
                        recipientEmail = "teacher@school.edu"
                    } else if card.title.lowercased().contains("coach") || card.title.lowercased().contains("sports") {
                        recipientEmail = "coach@school.edu"
                    } else if let kid = card.kid {
                        recipientEmail = "teacher@\(kid.grade.lowercased().replacingOccurrences(of: " ", with: ""))school.edu"
                    } else {
                        recipientEmail = "recipient@example.com"
                    }
                    Logger.info("Mock data detected: auto-populated recipient email: \(recipientEmail)", category: .action)
                }
            }
        }
    }

    var paymentStep: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.card) {
            // Payment summary
            if let amount = card.paymentAmount, let description = card.paymentDescription {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                    Text("Payment Required")
                        .font(.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            if let kid = card.kid {
                                Text("For \(kid.name)")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textSubtle)
                            }
                        }
                        Spacer()
                        Text("$\(String(format: "%.2f", amount))")
                            .font(.title2.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    .padding()
                    .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                }
            }
            
            // Payment method selection
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.component) {
                Text("Payment Method")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                ForEach(["Apple Pay", "Credit Card on File"], id: \.self) { method in
                    Button {
                        paymentMethod = method
                    } label: {
                        HStack {
                            Image(systemName: method == "Apple Pay" ? "apple.logo" : "creditcard.fill")
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            Text(method)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            Spacer()
                            if paymentMethod == method {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(paymentMethod == method ? 0.2 : 0.1))
                        .cornerRadius(DesignTokens.Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(paymentMethod == method ? Color.green : Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                        )
                    }
                }
            }

            Divider()
                .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))

            // Recipient Email Field (always show on payment step)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
                Text("Recipient Email")
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text("Enter the email address to send the signed document to:")
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.textSubtle)

                TextField("teacher@school.edu", text: $recipientEmail)
                    .padding()
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(recipientEmail.isEmpty ? Color.orange : Color.white.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: recipientEmail.isEmpty ? 2 : 1)
                    )

                if !recipientEmail.isEmpty && !isValidEmail(recipientEmail) {
                    Text("⚠️ Please enter a valid email address")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if recipientEmail.isEmpty {
                    Text("⚠️ Email address required to send signed document")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // Pay button
            Button {
                // Validate email before sending
                if recipientEmail.isEmpty {
                    withAnimation {
                        showError = true
                        errorMessage = "Please enter recipient email address"
                    }
                    return
                }

                if !isValidEmail(recipientEmail) {
                    withAnimation {
                        showError = true
                        errorMessage = "Please enter a valid email address"
                    }
                    return
                }

                // Complete payment and send signed document
                sendSignedDocument()
            } label: {
                HStack {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Pay & Send")
                    }
                }
            }
            .buttonStyle(GradientButtonStyle(colors: [.vibrantGreen, .vibrantEmerald]))
            .disabled(recipientEmail.isEmpty || !isValidEmail(recipientEmail) || isSending)
            .opacity((recipientEmail.isEmpty || !isValidEmail(recipientEmail) || isSending) ? 0.5 : 1.0)
            
            // Back button
            Button {
                withAnimation {
                    currentStep = 1
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back to Signature")
                }
                .foregroundColor(DesignTokens.Colors.textSubtle)
                .frame(maxWidth: .infinity)
            }

            // Error message
            if showError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(DesignTokens.Opacity.overlayLight))
                .cornerRadius(DesignTokens.Radius.button)
            }
        }
    }

    // MARK: - Email Sending Logic

    func sendSignedDocument() {
        // Save signature for future use (based on mode)
        if signatureMode == .typed && !signature.isEmpty {
            SignatureManager.shared.saveSignature(name: signature)
        } else if signatureMode == .drawn, let image = signatureImage {
            SignatureManager.shared.saveSignatureImage(image)
        }

        isSending = true
        showError = false
        showSuccess = false

        Logger.info("Generating PDF for signed document (mode: \(signatureMode))", category: .action)

        // Determine which signature to use based on mode
        let typedSignature = signatureMode == .typed ? signature : nil
        let drawnSignature = signatureMode == .drawn ? signatureImage : nil

        // Generate PDF
        guard let pdfData = SignedDocumentGenerator.generatePermissionFormPDF(
            formTitle: card.title,
            formSummary: card.summary,
            kidName: card.kid?.name,
            kidGrade: card.kid?.grade,
            signature: typedSignature,
            signatureImage: drawnSignature,
            paymentAmount: card.paymentAmount,
            paymentDescription: card.paymentDescription
        ) else {
            isSending = false
            showError = true
            errorMessage = "Failed to generate PDF"
            Logger.error("PDF generation failed", category: .action)
            return
        }

        Logger.info("PDF generated successfully: \(pdfData.count) bytes", category: .action)

        // Generate filename
        let filename = SignedDocumentGenerator.generateFilename(
            kidName: card.kid?.name,
            formTitle: card.title
        )

        // Generate email body
        let emailBody = generateEmailBody()

        // Get recipient email - prioritize manually entered email, then sender email
        let recipient = !recipientEmail.isEmpty ? recipientEmail : (card.sender?.email ?? "")

        guard !recipient.isEmpty else {
            isSending = false
            showError = true
            showEmailField = true
            errorMessage = "Please enter recipient email address"
            Logger.error("No recipient email", category: .action)
            return
        }

        // Validate email format
        guard isValidEmail(recipient) else {
            isSending = false
            showError = true
            errorMessage = "Invalid email address format"
            Logger.error("Invalid recipient email format: \(recipient)", category: .action)
            return
        }

        Logger.info("Sending email to \(recipient)", category: .action)

        // Send email
        EmailSendingService.shared.sendEmailWithAttachment(
            to: recipient,
            subject: "Re: \(card.title)",
            body: emailBody,
            pdfData: pdfData,
            filename: filename,
            threadId: nil // EmailCard doesn't have threadId yet
        ) { result in
            DispatchQueue.main.async {
                isSending = false

                switch result {
                case .success(let messageId):
                    Logger.info("Email sent successfully! Message ID: \(messageId)", category: .action)
                    showSuccess = true

                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)

                    // Call completion callback
                    onSignComplete?(signature)

                    // Close modal after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        isPresented = false
                    }

                case .failure(let error):
                    Logger.error("Email sending failed: \(error.localizedDescription)", category: .action)
                    showError = true
                    errorMessage = error.localizedDescription

                    // Haptic feedback
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.error)
                }
            }
        }
    }

    func generateEmailBody() -> String {
        var body = "Hi,\n\n"

        let formType = card.title.lowercased().contains("permission") ? "permission form" : "form"

        if let kid = card.kid {
            body += "I've signed and attached the \(formType) for \(kid.name) (\(kid.grade)).\n\n"
        } else {
            body += "I've signed and attached the \(formType).\n\n"
        }

        if let amount = card.paymentAmount, let desc = card.paymentDescription {
            body += "Payment Details:\n"
            body += "• \(desc): $\(String(format: "%.2f", amount))\n"
            body += "• Payment will be processed via \(paymentMethod)\n\n"
        }

        body += "Please let me know if you need anything else.\n\nBest regards"

        return body
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func previewPDF() {
        Logger.info("Generating PDF preview (mode: \(signatureMode))", category: .action)

        // Determine which signature to use based on mode
        let typedSignature = signatureMode == .typed ? signature : nil
        let drawnSignature = signatureMode == .drawn ? signatureImage : nil

        // Generate PDF
        guard let pdfData = SignedDocumentGenerator.generatePermissionFormPDF(
            formTitle: card.title,
            formSummary: card.summary,
            kidName: card.kid?.name,
            kidGrade: card.kid?.grade,
            signature: typedSignature,
            signatureImage: drawnSignature,
            paymentAmount: card.paymentAmount,
            paymentDescription: card.paymentDescription
        ) else {
            showError = true
            errorMessage = "Failed to generate PDF preview"
            Logger.error("PDF preview generation failed", category: .action)
            return
        }

        Logger.info("PDF preview generated: \(pdfData.count) bytes", category: .action)

        // Store PDF data and show preview modal
        previewPDFData = pdfData
        showPDFPreview = true

        // Analytics
        AnalyticsService.shared.log("pdf_preview_opened", properties: [
            "document_type": "signed_form",
            "has_signature": !signature.isEmpty,
            "has_payment": card.paymentAmount != nil
        ])
    }
}

// MARK: - Signature Mode
enum SignatureMode {
    case typed
    case drawn
}

