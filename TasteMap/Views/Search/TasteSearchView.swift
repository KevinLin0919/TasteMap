import SwiftData
import SwiftUI
import TasteMapCore

/// 搜尋結果列表。
///
/// 搜尋的職責是「找特定那一間」—— 比對店名、Dish 與 Impression，一家店也找得到。
/// 「找某一類」是 Collection 的職責，兩者分工不重疊。所以這裡不再是獨立分頁，
/// 而是清單頁頂部搜尋框的結果區。
struct TasteSearchView: View {
    let query: String

    @Query private var places: [Place]
    @State private var selectedPlace: Place?

    private var results: [Place] {
        let ids = TasteSearchEngine.search(query, in: places.map(\.searchCandidate)).map(\.id)
        let lookup = Dictionary(uniqueKeysWithValues: places.map { ($0.id, $0) })
        return ids.compactMap { lookup[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if results.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("找不到「\(query)」")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(TasteTheme.ink)
                    Text("可以試試店名、你點過的餐點，或是留下的印象。")
                        .font(.caption).foregroundStyle(TasteTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .tasteCard()
            } else {
                Text("\(results.count) 個結果")
                    .font(.caption).foregroundStyle(TasteTheme.muted)

                ForEach(results) { place in
                    Button { selectedPlace = place } label: { PlaceRow(place: place) }
                        .buttonStyle(.plain)
                    Divider().opacity(0.55)
                }
            }
        }
        .sheet(item: $selectedPlace) { PlaceDetailView(place: $0) }
    }
}
