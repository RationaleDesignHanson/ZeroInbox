import Foundation
import PDFKit
import UIKit

/// Service for generating professional signed PDF documents
class SignedDocumentGenerator {

    /// Generate a signed permission form PDF
    static func generatePermissionFormPDF(
        formTitle: String,
        formSummary: String,
        kidName: String?,
        kidGrade: String?,
        signature: String?,
        signatureImage: UIImage?,
        paymentAmount: Double?,
        paymentDescription: String?
    ) -> Data? {

        let pdfMetaData = [
            kCGPDFContextCreator: "Zero Email App",
            kCGPDFContextAuthor: signature ?? "Parent",
            kCGPDFContextTitle: formTitle
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        // Letter size: 612x792 points
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 50

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            formTitle.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40

            // Horizontal line
            let line = UIBezierPath()
            line.move(to: CGPoint(x: 50, y: yPosition))
            line.addLine(to: CGPoint(x: 562, y: yPosition))
            UIColor.gray.setStroke()
            line.lineWidth = 1
            line.stroke()
            yPosition += 20

            // Student Info
            if let kid = kidName, let grade = kidGrade {
                let studentInfo = "Student: \(kid) (\(grade))"
                let infoAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.darkGray
                ]
                studentInfo.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: infoAttributes)
                yPosition += 30
            }

            // Form Content
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4

            let formText = NSAttributedString(
                string: formSummary,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraphStyle
                ]
            )

            let textRect = CGRect(x: 50, y: yPosition, width: 512, height: 400)
            formText.draw(in: textRect)
            yPosition = textRect.maxY + 30

            // Payment Information (if applicable)
            if let amount = paymentAmount, let desc = paymentDescription {
                yPosition += 20
                let paymentText = "Payment: \(desc) - $\(String(format: "%.2f", amount))"
                let paymentAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 12),
                    .foregroundColor: UIColor.blue
                ]
                paymentText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: paymentAttributes)
                yPosition += 30
            }

            // Signature Section
            yPosition = max(yPosition, 600) // Ensure signature is near bottom

            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            let sigLabel = "Parent/Guardian Signature:"
            sigLabel.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 25

            // Draw signature line
            let signatureLine = UIBezierPath()
            signatureLine.move(to: CGPoint(x: 50, y: yPosition + 30))
            signatureLine.addLine(to: CGPoint(x: 350, y: yPosition + 30))
            UIColor.black.setStroke()
            signatureLine.lineWidth = 1
            signatureLine.stroke()

            // Draw signature image or typed signature
            if let sigImage = signatureImage {
                // Draw signature image above the line
                let signatureRect = CGRect(x: 50, y: yPosition - 10, width: 200, height: 40)
                sigImage.draw(in: signatureRect)
            } else if let sigText = signature {
                // Draw typed signature in cursive-like style
                let signatureAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "Apple Chancery", size: 18) ?? UIFont.italicSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.black
                ]
                sigText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: signatureAttributes)
            }

            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = "Date: \(dateFormatter.string(from: Date()))"
            dateString.draw(at: CGPoint(x: 370, y: yPosition + 15), withAttributes: bodyAttributes)

            // Footer
            let footer = "This document was digitally signed via Zero Email App"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.lightGray
            ]
            footer.draw(at: CGPoint(x: 50, y: 760), withAttributes: footerAttributes)
        }

        return data
    }

    /// Get a filename for the signed document
    static func generateFilename(kidName: String?, formTitle: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        // Clean up title for filename
        let cleanTitle = formTitle
            .replacingOccurrences(of: "[^a-zA-Z0-9]+", with: "_", options: .regularExpression)
            .prefix(30)

        if let kid = kidName {
            let cleanKid = kid
                .replacingOccurrences(of: "[^a-zA-Z0-9]+", with: "_", options: .regularExpression)
                .prefix(20)
            return "Signed_\(cleanKid)_\(cleanTitle)_\(dateString).pdf"
        } else {
            return "Signed_\(cleanTitle)_\(dateString).pdf"
        }
    }
}
