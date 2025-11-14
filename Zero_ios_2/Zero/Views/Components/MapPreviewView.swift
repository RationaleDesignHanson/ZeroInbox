import SwiftUI
import MapKit

/// Reusable embedded map preview component
/// Shows a location on a small map that can be tapped to open full Apple Maps
struct MapPreviewView: View {
    let locationName: String
    let address: String
    let coordinate: CLLocationCoordinate2D?
    let height: CGFloat

    @State private var region: MKCoordinateRegion
    @State private var isGeocoding = false
    @State private var geoError: String?

    init(
        locationName: String,
        address: String,
        coordinate: CLLocationCoordinate2D? = nil,
        height: CGFloat = 220
    ) {
        self.locationName = locationName
        self.address = address
        self.coordinate = coordinate
        self.height = height

        // Initialize region with coordinate if provided, otherwise default to SF
        let initialCoordinate = coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        _region = State(initialValue: MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inline) {
            // Map view
            ZStack(alignment: .bottomTrailing) {
                if #available(iOS 17.0, *) {
                    Map {
                        Marker(locationName, coordinate: region.center)
                            .tint(.red)
                    }
                    .frame(height: height)
                    .cornerRadius(DesignTokens.Radius.button)
                    .disabled(true)  // Disable interaction, tap will open Maps
                } else {
                    Map(
                        coordinateRegion: $region,
                        annotationItems: [MapLocation(coordinate: region.center, name: locationName)]
                    ) { location in
                        MapMarker(coordinate: location.coordinate, tint: .red)
                    }
                    .frame(height: height)
                    .cornerRadius(DesignTokens.Radius.button)
                    .disabled(true)  // Disable interaction, tap will open Maps
                }

                // "Open in Maps" overlay button
                Button {
                    openInMaps()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.caption)
                        Text("Open in Maps")
                            .font(.caption.bold())
                    }
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, DesignTokens.Spacing.component)
                    .padding(.vertical, DesignTokens.Spacing.inline)
                    .background(Color.blue)
                    .cornerRadius(DesignTokens.Spacing.inline)
                    .shadow(color: .black.opacity(DesignTokens.Opacity.overlayMedium), radius: 4)
                }
                .padding(DesignTokens.Spacing.component)
            }

            // Location info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)

                    Text(locationName)
                        .font(.subheadline.bold())
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }

                Text(address)
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.textSubtle)
                    .lineLimit(2)
            }

            if isGeocoding {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Finding location...")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSubtle)
                }
            }

            if let error = geoError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .onAppear {
            // Geocode address if coordinate wasn't provided
            if coordinate == nil {
                geocodeAddress()
            }
        }
    }

    /// Geocode address to get coordinates
    private func geocodeAddress() {
        isGeocoding = true
        geoError = nil

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            isGeocoding = false

            if let error = error {
                Logger.warning("Geocoding failed for \(address): \(error.localizedDescription)", category: .action)
                geoError = "Could not find location"
                return
            }

            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                geoError = "Location not found"
                return
            }

            // Update region with geocoded coordinate
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )

            Logger.info("Geocoded \(locationName): \(location.coordinate.latitude), \(location.coordinate.longitude)", category: .action)
        }
    }

    /// Open location in Apple Maps app
    private func openInMaps() {
        let query = "\(locationName) \(address)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let mapsURL = URL(string: "maps://?q=\(query)") {
            if UIApplication.shared.canOpenURL(mapsURL) {
                UIApplication.shared.open(mapsURL)
                Logger.info("Opening Maps for \(locationName)", category: .action)

                // Analytics
                AnalyticsService.shared.log("map_opened", properties: [
                    "location_name": locationName,
                    "address": address
                ])
            } else {
                // Fallback to Google Maps web if Apple Maps isn't available
                if let googleMapsURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)") {
                    UIApplication.shared.open(googleMapsURL)
                }
            }
        }
    }
}

/// Helper struct for map annotations
struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
}

struct MapPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MapPreviewView(
                locationName: "CVS Pharmacy",
                address: "123 Main Street, San Francisco, CA 94102",
                height: 220
            )
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
