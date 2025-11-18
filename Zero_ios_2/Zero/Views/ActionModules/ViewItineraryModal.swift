import SwiftUI
import MapKit

/// View Itinerary Modal
/// Handles view_itinerary, manage_booking, get_directions actions
struct ViewItineraryModal: View {
    let card: EmailCard
    @Binding var isPresented: Bool
    let itineraryType: ItineraryType
    let bookingUrl: String?
    let context: [String: String]

    @State private var showDirections = false
    @State private var showSuccess = false
    @State private var copiedField: String?

    enum ItineraryType {
        case flight, hotel, rental, restaurant, general

        var title: String {
            switch self {
            case .flight: return "Flight Itinerary"
            case .hotel: return "Hotel Booking"
            case .rental: return "Car Rental"
            case .restaurant: return "Restaurant Reservation"
            case .general: return "Travel Itinerary"
            }
        }

        var icon: String {
            switch self {
            case .flight: return "airplane"
            case .hotel: return "bed.double.fill"
            case .rental: return "car.fill"
            case .restaurant: return "fork.knife"
            case .general: return "map.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (Week 6: Using shared ModalHeader component)
            ModalHeader(isPresented: $isPresented)

            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(DesignTokens.Opacity.overlayMedium), .cyan.opacity(DesignTokens.Opacity.overlayMedium)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 100, height: 100)

                        Image(systemName: itineraryType.icon)
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }

                    // Title
                    Text(itineraryType.title)
                        .font(.title.bold())
                        .foregroundColor(.white)

                    // Confirmation/Booking Number
                    if let confirmationNumber = context["confirmationNumber"] ?? context["bookingNumber"] ?? context["reservationNumber"] {
                        VStack(spacing: 12) {
                            Text("Confirmation Number")
                                .font(.caption)
                                .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))

                            HStack(spacing: 12) {
                                Text(confirmationNumber)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)

                                Button {
                                    ClipboardUtility.copy(confirmationNumber)
                                    copiedField = "confirmation"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        copiedField = nil
                                    }
                                } label: {
                                    Image(systemName: copiedField == "confirmation" ? "checkmark.circle.fill" : "doc.on.doc")
                                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textTertiary))
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(DesignTokens.Radius.button)
                        }
                    }

                    // Travel Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Dates
                        if let startDate = context["startDate"] ?? context["checkInDate"] ?? context["departureDate"],
                           !startDate.isEmpty {
                            ItineraryDetailRow(
                                icon: "calendar",
                                label: itineraryType == .flight ? "Departure" : "Check-in",
                                value: startDate
                            )
                        }

                        if let endDate = context["endDate"] ?? context["checkOutDate"] ?? context["returnDate"],
                           !endDate.isEmpty {
                            ItineraryDetailRow(
                                icon: "calendar",
                                label: itineraryType == .flight ? "Return" : "Check-out",
                                value: endDate
                            )
                        }

                        // Location/Destination
                        if let destination = context["destination"] ?? context["location"] ?? context["address"],
                           !destination.isEmpty {
                            ItineraryDetailRow(
                                icon: "mappin.circle.fill",
                                label: "Location",
                                value: destination,
                                copyable: true,
                                copiedField: $copiedField
                            )
                        }

                        // Flight-specific
                        if itineraryType == .flight {
                            if let flightNumber = context["flightNumber"], !flightNumber.isEmpty {
                                ItineraryDetailRow(icon: "airplane", label: "Flight", value: flightNumber)
                            }
                            if let airline = context["airline"], !airline.isEmpty {
                                ItineraryDetailRow(icon: "building.2", label: "Airline", value: airline)
                            }
                        }

                        // Hotel-specific
                        if itineraryType == .hotel {
                            if let hotelName = context["hotelName"] ?? context["propertyName"], !hotelName.isEmpty {
                                ItineraryDetailRow(icon: "building.2.fill", label: "Hotel", value: hotelName)
                            }
                            if let roomType = context["roomType"], !roomType.isEmpty {
                                ItineraryDetailRow(icon: "bed.double", label: "Room", value: roomType)
                            }
                        }

                        // Rental-specific
                        if itineraryType == .rental {
                            if let vehicleType = context["vehicleType"] ?? context["carType"], !vehicleType.isEmpty {
                                ItineraryDetailRow(icon: "car", label: "Vehicle", value: vehicleType)
                            }
                            if let pickupLocation = context["pickupLocation"], !pickupLocation.isEmpty {
                                ItineraryDetailRow(icon: "location", label: "Pickup", value: pickupLocation)
                            }
                        }

                        // Restaurant-specific
                        if itineraryType == .restaurant {
                            if let restaurantName = context["restaurantName"], !restaurantName.isEmpty {
                                ItineraryDetailRow(icon: "fork.knife.circle.fill", label: "Restaurant", value: restaurantName)
                            }
                            if let partySize = context["partySize"] ?? context["guests"], !partySize.isEmpty {
                                ItineraryDetailRow(icon: "person.2", label: "Party Size", value: partySize)
                            }
                            if let time = context["time"] ?? context["reservationTime"], !time.isEmpty {
                                ItineraryDetailRow(icon: "clock", label: "Time", value: time)
                            }
                        }

                        // Price
                        if let price = context["price"] ?? context["totalPrice"] ?? context["amount"], !price.isEmpty {
                            ItineraryDetailRow(icon: "dollarsign.circle", label: "Total", value: price)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(DesignTokens.Opacity.glassLight))
                    .cornerRadius(DesignTokens.Radius.button)

                    // Actions
                    VStack(spacing: 12) {
                        // Manage Booking Button
                        if let url = bookingUrl {
                            Button {
                                if let urlObj = URL(string: url) {
                                    UIApplication.shared.open(urlObj)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                    Text("Manage Booking")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }

                        // Get Directions Button
                        if let address = context["address"] ?? context["destination"] ?? context["location"],
                           !address.isEmpty {
                            Button {
                                openMapsWithDirections(to: address)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                    Text("Get Directions")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }

                        // Add to Calendar Button
                        if let startDate = context["startDate"] ?? context["checkInDate"] ?? context["departureDate"],
                           !startDate.isEmpty {
                            Button {
                                addToCalendar()
                            } label: {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Add to Calendar")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(DesignTokens.Opacity.overlayLight))
                                .cornerRadius(DesignTokens.Radius.button)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(DesignTokens.Opacity.overlayMedium), Color.cyan.opacity(DesignTokens.Opacity.overlayMedium)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    private func openMapsWithDirections(to address: String) {
        // Open Apple Maps with directions
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let placemark = placemarks?.first,
               let location = placemark.location {
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
                mapItem.name = context["hotelName"] ?? context["restaurantName"] ?? context["destination"]
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])

                HapticService.shared.success()
                Logger.info("Opened directions to: \(address)", category: .action)
            } else {
                // Fallback: try Apple Maps URL scheme
                if let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: "http://maps.apple.com/?daddr=\(encodedAddress)") {
                    UIApplication.shared.open(url)
                    HapticService.shared.success()
                }
            }
        }
    }

    private func addToCalendar() {
        // Open AddToCalendarModal or use system calendar
        HapticService.shared.mediumImpact()
        Logger.info("Add to calendar tapped for itinerary", category: .action)
        // TODO: Implement calendar integration
    }
}

// MARK: - ItineraryDetailRow Component

struct ItineraryDetailRow: View {
    let icon: String
    let label: String
    let value: String
    var copyable: Bool = false
    @Binding var copiedField: String?

    init(icon: String, label: String, value: String, copyable: Bool = false, copiedField: Binding<String?> = .constant(nil)) {
        self.icon = icon
        self.label = label
        self.value = value
        self.copyable = copyable
        self._copiedField = copiedField
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(DesignTokens.Opacity.textSubtle))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }

            Spacer()

            if copyable {
                Button {
                    ClipboardUtility.copy(value)
                    copiedField = label
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedField = nil
                    }
                } label: {
                    Image(systemName: copiedField == label ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundColor(.white.opacity(DesignTokens.Opacity.textDisabled))
                        .font(.caption)
                }
            }
        }
    }
}
