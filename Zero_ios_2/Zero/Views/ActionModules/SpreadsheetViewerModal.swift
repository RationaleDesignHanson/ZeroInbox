import SwiftUI
import Charts

struct SpreadsheetViewerModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    
    let cookieData = [
        ("Thin Mints", 45000, "+127%", Color.green),
        ("Samoas", 38000, "+95%", Color.brown),
        ("Tagalongs", 31000, "+112%", Color.orange),
        ("Do-si-dos", 28000, "+88%", Color.red),
        ("Trefoils", 22000, "+156%", Color.yellow)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spreadsheet Review")
                            .font(.title3.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Text(card.title)
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .font(.title2)
                    }
                }
                .padding()
                
                // Spreadsheet content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🍪 Q4 Cookie Sales Report")
                                .font(.title2.bold())
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Text("Girl Scout Cookie Division • Fiscal Year 2024")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.green)
                                Text("YoY Growth: +108%")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.bottom, 8)
                        
                        Divider()
                            .background(Color.white.opacity(DesignTokens.Opacity.overlayMedium))
                        
                        // Summary metrics
                        HStack(spacing: 16) {
                            MetricCard(title: "Total Sales", value: "$16.4M", icon: "dollarsign.circle.fill", color: .green)
                            MetricCard(title: "Units Sold", value: "164K", icon: "cart.fill", color: .blue)
                        }
                        
                        // Data table
                        VStack(spacing: 0) {
                            // Header row
                            HStack {
                                Text("Cookie Type")
                                    .font(.caption.bold())
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Units")
                                    .font(.caption.bold())
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .frame(width: 70, alignment: .trailing)
                                
                                Text("Growth")
                                    .font(.caption.bold())
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .frame(width: 70, alignment: .trailing)
                            }
                            .padding()
                            .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                            
                            // Data rows
                            ForEach(Array(cookieData.enumerated()), id: \.offset) { index, data in
                                HStack {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(data.3)
                                            .frame(width: 12, height: 12)
                                        Text(data.0)
                                            .font(.subheadline)
                                            .foregroundColor(DesignTokens.Colors.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("\(data.1.formatted())")
                                        .font(.subheadline.bold())
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                        .frame(width: 70, alignment: .trailing)
                                    
                                    Text(data.2)
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                        .frame(width: 70, alignment: .trailing)
                                }
                                .padding()
                                .background(index % 2 == 0 ? Color.white.opacity(DesignTokens.Opacity.glassUltraLight) : Color.clear)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 1)
                                )
                        )
                        
                        // Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sales Trend")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            HStack(alignment: .bottom, spacing: 12) {
                                ForEach(cookieData, id: \.0) { cookie in
                                    VStack(spacing: 4) {
                                        // Bar
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                LinearGradient(
                                                    colors: [cookie.3.opacity(DesignTokens.Opacity.textTertiary), cookie.3],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(width: 40, height: CGFloat(cookie.1) / 300)
                                        
                                        // Label
                                        Text(String(cookie.0.prefix(4)))
                                            .font(.system(size: 9))
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                    }
                                }
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.white.opacity(DesignTokens.Opacity.overlayLight), lineWidth: 1)
                                )
                        )
                        
                        // Footer note
                        Text("Note: Thin Mints continue to dominate market share. Consider increasing production capacity for Q1 2025.")
                            .font(.caption.italic())
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                            .padding()
                            .background(Color.yellow.opacity(DesignTokens.Opacity.overlayLight))
                            .cornerRadius(DesignTokens.Radius.chip)
                    }
                    .padding()
                }
                
                // Action button
                Button {
                    isPresented = false
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Reviewed")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .cornerRadius(DesignTokens.Radius.card)
                }
                .padding()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(color.opacity(DesignTokens.Opacity.overlayMedium), lineWidth: 1)
                )
        )
    }
}

