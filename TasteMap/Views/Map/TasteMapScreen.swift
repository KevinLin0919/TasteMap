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

    private var visiblePlaces: [Place] { places.filter { $0.currentScore >= minimumScore } }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $camera) {
                    ForEach(visiblePlaces) { place in
                        Annotation(place.name, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), anchor: .bottom) {
                            Button { selectedPlace = place } label: {
                                Text(place.currentScore, format: .number.precision(.fractionLength(1)))
                                    .font(.system(.subheadline, design: .serif, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 11).padding(.vertical, 8)
                                    .background(place.currentScore >= 4.5 ? TasteTheme.gold : TasteTheme.moss, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(.white, lineWidth: 2))
                                    .shadow(radius: 6, y: 3)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
                .ignoresSafeArea()

                // 篩選列浮在地圖上，而不是壓在一條不透明的導覽列下面 —— 地圖類畫面
                // 的慣例是滿版出血，控制項以玻璃浮層疊上去。
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterButton("全部", value: 0)
                        filterButton("4 分以上", value: 4)
                        filterButton("4.5 分以上", value: 4.5)
                    }.padding(.horizontal, 16)
                }
                .padding(.top, 6)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedPlace) { PlaceDetailView(place: $0) }
        }
    }

    private func filterButton(_ title: String, value: Double) -> some View {
        Button { minimumScore = value } label: {
            Text(title).font(.caption.weight(.semibold)).padding(.horizontal, 12).padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .foregroundStyle(minimumScore == value ? .white : TasteTheme.ink)
        .glassEffect(.regular.tint(minimumScore == value ? TasteTheme.ink : nil).interactive(), in: Capsule())
    }
}
