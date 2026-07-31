import CoreLocation
import SwiftData
import SwiftUI
import TasteMapCore

struct TasteMapScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var places: [Place]

    @State private var selectedPlace: Place?
    @State private var recordingAt: Place?
    @State private var minimumScore = 0.0

    private var visiblePlaces: [Place] { places.filter { $0.currentScore >= minimumScore } }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                GoogleMapView(
                    places: visiblePlaces,
                    onSelectPlace: { selectedPlace = $0 },
                    onSelectPOI: recordAtPOI
                )
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
            .sheet(item: $recordingAt) { NewVisitSheet(initialPlace: $0) }
        }
    }

    /// 點底圖上還沒記過的 Google POI，直接開始記錄。
    ///
    /// POI 的點擊回傳 place_id、名稱與座標 —— 剛好就是建立一個 Place 需要的全部，
    /// 不必再打一次 Places API。這是「在地圖上探索、看到就記」的路徑。
    private func recordAtPOI(placeID: String, name: String, coordinate: CLLocationCoordinate2D) {
        let providerID = "google:\(placeID)"

        if let existing = places.first(where: { $0.providerPlaceID == providerID }) {
            recordingAt = existing
            return
        }

        let place = Place(
            providerPlaceID: providerID,
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            cachedAt: .now,
            visualSeed: abs(placeID.hashValue)
        )
        modelContext.insert(place)
        recordingAt = place
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
