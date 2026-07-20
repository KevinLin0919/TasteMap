import MapKit
import SwiftData
import SwiftUI

struct TasteMapScreen: View {
    @Query private var places: [Place]
    @State private var selectedPlace: Place?
    @State private var minimumScore = 0.0
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.044, longitude: 121.545), span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07))
    )

    private var visiblePlaces: [Place] { places.filter { $0.averageScore >= minimumScore } }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $camera) {
                    ForEach(visiblePlaces) { place in
                        Annotation(place.name, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), anchor: .bottom) {
                            Button { selectedPlace = place } label: {
                                Text(place.averageScore, format: .number.precision(.fractionLength(1)))
                                    .font(.system(.subheadline, design: .serif, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 11).padding(.vertical, 8)
                                    .background(place.averageScore >= 9 ? TasteTheme.gold : TasteTheme.moss, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(.white, lineWidth: 2))
                                    .shadow(radius: 6, y: 3)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
                .ignoresSafeArea(edges: .top)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterButton("全部", value: 0)
                        filterButton("8 分以上", value: 8)
                        filterButton("8.5 分以上", value: 8.5)
                    }.padding(.horizontal, 16)
                }
                .padding(.top, 10)
            }
            .navigationTitle("品味地圖")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedPlace) { PlaceDetailView(place: $0) }
        }
    }

    private func filterButton(_ title: String, value: Double) -> some View {
        Button { minimumScore = value } label: {
            Text(title).font(.caption.weight(.semibold)).padding(.horizontal, 12).padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .foregroundStyle(minimumScore == value ? .white : TasteTheme.ink)
        .background(minimumScore == value ? TasteTheme.ink : .white.opacity(0.85), in: Capsule())
    }
}
