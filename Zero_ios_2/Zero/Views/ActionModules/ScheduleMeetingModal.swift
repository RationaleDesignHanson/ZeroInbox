import SwiftUI

struct ScheduleMeetingModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    let onComplete: () -> Void
    
    @State private var selectedTimeSlot: String?
    @State private var selectedDuration: String = "1 hour"
    @State private var showSuccess = false
    
    let timeSlots = ["9:00 AM", "11:00 AM", "2:00 PM", "4:00 PM"]
    let durations = ["30 min", "1 hour", "2 hours"]
    
    func timeSlotButton(_ slot: String) -> some View {
        Button {
            selectedTimeSlot = slot
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            HStack {
                Text(slot)
                    .font(.subheadline.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                Spacer()
                if selectedTimeSlot == slot {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedTimeSlot == slot ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(selectedTimeSlot == slot ? Color.green : Color.white.opacity(0.2), lineWidth: selectedTimeSlot == slot ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    func durationButton(_ duration: String) -> some View {
        Button {
            selectedDuration = duration
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            Text(duration)
                .font(.subheadline.bold())
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedDuration == duration ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(selectedDuration == duration ? Color.green : Color.white.opacity(0.2), lineWidth: selectedDuration == duration ? 2 : 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Schedule Meeting")
                            .font(.title2.bold())
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Text(card.title)
                            .font(.subheadline)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(2)
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Meeting info
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Meeting with \(card.sender?.name ?? card.company?.name ?? "Guest")")
                                .font(.headline)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                        
                        // Time slot selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                Text("Select Time Slot")
                                    .font(.headline)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(timeSlots, id: \.self) { slot in
                                    timeSlotButton(slot)
                                }
                            }
                        }
                        
                        // Duration selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.purple)
                                Text("Meeting Duration")
                                    .font(.headline)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(durations, id: \.self) { duration in
                                    durationButton(duration)
                                }
                            }
                        }
                        
                        // Calendar integration hint
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.title2)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Calendar Integration")
                                    .font(.subheadline.bold())
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                Text("Meeting will be added to your calendar and an invite sent")
                                    .font(.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.blue.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                    .padding()
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding()
                
                // Schedule button
                Button {
                    scheduleMeeting()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Send Availability")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedTimeSlot != nil ? Color.blue : Color.gray)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .cornerRadius(16)
                }
                .disabled(selectedTimeSlot == nil)
                .padding()
                
                if showSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Meeting scheduled!")
                            .foregroundColor(.green)
                    }
                    .font(.subheadline.bold())
                    .padding(.bottom)
                }
        }
    }
    
    func scheduleMeeting() {
        showSuccess = true
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete()
            isPresented = false
        }
    }
}

