import CoreLocation
import SwiftData
import SwiftUI
import TasteMapCore

/// 選一個地點。這是記錄流程的第一道關卡，也是整個 app 最高頻的互動。
///
/// 預設顯示 GPS 撈到的附近店家 —— 按下記錄時你通常人就在店裡或剛走出門口，
/// 第一個往往就是要找的，**零打字**。打字搜尋作為備援，兩種情況一定會發生：
/// 冷啟動補記憶中的愛店（人不在那裡），以及回家後才想起來要記。
struct PlacePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existingPlaces: [Place]

    let onSelect: (Place) -> Void

    @State private var query = ""
    @State private var results: [DiscoveredPlace] = []
    @State private var phase: Phase = .idle
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var searchTask: Task<Void, Never>?
    @State private var creatingManually = false

    private enum Phase: Equatable {
        case idle, loading, loaded, unconfigured
        case failed(String)
    }

    private var trimmed: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            List {
                if !recentlyUsed.isEmpty && trimmed.isEmpty {
                    Section("記過的地方") {
                        ForEach(recentlyUsed) { place in
                            Button { choose(place) } label: { existingRow(place) }
                        }
                    }
                }

                Section(trimmed.isEmpty ? "附近" : "搜尋結果") {
                    switch phase {
                    case .unconfigured: unconfiguredRow
                    case .loading: ProgressView().frame(maxWidth: .infinity)
                    case .failed(let message): messageRow(message, isError: true)
                    case .idle, .loaded:
                        if results.isEmpty {
                            messageRow(
                                trimmed.isEmpty
                                    ? "附近沒有找到店家。可以直接打店名搜尋。"
                                    : "找不到「\(trimmed)」。",
                                isError: false
                            )
                        } else {
                            ForEach(results) { discovered in
                                Button { choose(discovered) } label: { discoveredRow(discovered) }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        creatingManually = true
                    } label: {
                        Label("找不到？手動建立地點", systemImage: "plus.circle")
                    }
                    .disabled(coordinate == nil)
                    if coordinate == nil {
                        Text("手動建立需要目前位置，才知道要把它放在地圖的哪裡。")
                            .font(.caption2).foregroundStyle(TasteTheme.muted)
                    }
                }
            }
            .searchable(text: $query, prompt: "店名")
            .navigationTitle("選擇地點")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            }
            .sheet(isPresented: $creatingManually) {
                if let coordinate {
                    ManualPlaceSheet(coordinate: coordinate) { place in
                        modelContext.insert(place)
                        choose(place)
                    }
                }
            }
        }
        .task {
            coordinate = await CurrentLocation.fetch()
            await load()
        }
        .onChange(of: query) { _, _ in scheduleSearch() }
    }

    // MARK: 內容

    /// 已經記過的地方排在最前面。回訪同一家店是常態，而那條路徑完全不需要動用 API。
    private var recentlyUsed: [Place] {
        existingPlaces
            .sorted { ($0.lastVisitedAt ?? .distantPast) > ($1.lastVisitedAt ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    private func existingRow(_ place: Place) -> some View {
        HStack(spacing: 11) {
            Image(systemName: place.symbolName).foregroundStyle(TasteTheme.clay).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name).font(.headline).foregroundStyle(TasteTheme.ink)
                Text("去過 \(place.visits.count) 次 · \(place.summary)")
                    .font(.caption).foregroundStyle(TasteTheme.muted)
            }
        }
    }

    private func discoveredRow(_ discovered: DiscoveredPlace) -> some View {
        HStack(spacing: 11) {
            Image(systemName: PlaceSymbol.name(forType: discovered.primaryType))
                .foregroundStyle(TasteTheme.moss).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(discovered.name).font(.headline).foregroundStyle(TasteTheme.ink)
                Text([discovered.typeDisplayName, PlaceCachePolicy.locality(from: discovered.address)]
                    .compactMap { $0 }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(TasteTheme.muted)
            }
        }
    }

    private var unconfiguredRow: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("尚未設定地點服務").font(.subheadline.weight(.semibold)).foregroundStyle(TasteTheme.ink)
            Text("這個版本沒有 Google API 金鑰，只能從記過的地方選，或手動建立。")
                .font(.caption).foregroundStyle(TasteTheme.muted)
        }
        .padding(.vertical, 4)
    }

    private func messageRow(_ text: String, isError: Bool) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(isError ? TasteTheme.clay : TasteTheme.muted)
            .padding(.vertical, 4)
    }

    // MARK: 查詢

    /// 打字時延遲再送 —— 逐字觸發會讓一次搜尋變成好幾次計費呼叫。
    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await load()
        }
    }

    private func load() async {
        guard let provider = Places.provider else {
            phase = .unconfigured
            return
        }

        phase = .loading
        do {
            if trimmed.isEmpty {
                guard let coordinate else {
                    results = []
                    phase = .loaded
                    return
                }
                results = try await provider.nearby(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radiusMeters: Places.nearbyRadiusMeters
                )
            } else {
                results = try await provider.search(trimmed)
            }
            phase = .loaded
        } catch let error as PlacesError {
            results = []
            phase = .failed(error.userMessage)
        } catch {
            results = []
            phase = .failed("連線失敗，請稍後再試。")
        }
    }

    // MARK: 選取

    private func choose(_ place: Place) {
        onSelect(place)
        dismiss()
    }

    /// 以 providerPlaceID 找既有的 Place，找到就刷新快取而不是新增一筆。
    ///
    /// 這就是去重 —— `place_id` 是穩定的，同一家店不管從搜尋還是附近進來都是同一個值，
    /// 所以「去過 N 次」不會被拆散成兩間店。
    private func choose(_ discovered: DiscoveredPlace) {
        let providerID = "google:\(discovered.providerPlaceID)"

        if let existing = existingPlaces.first(where: { $0.providerPlaceID == providerID }) {
            apply(discovered, to: existing)
            choose(existing)
            return
        }

        let place = Place(
            providerPlaceID: providerID,
            name: discovered.name,
            address: discovered.address,
            typeKey: discovered.primaryType,
            typeName: discovered.typeDisplayName,
            latitude: discovered.latitude,
            longitude: discovered.longitude,
            cachedAt: .now,
            visualSeed: abs(discovered.providerPlaceID.hashValue)
        )
        modelContext.insert(place)
        choose(place)
    }

    private func apply(_ discovered: DiscoveredPlace, to place: Place) {
        place.name = discovered.name
        place.address = discovered.address
        place.typeKey = discovered.primaryType
        place.typeName = discovered.typeDisplayName
        place.latitude = discovered.latitude
        place.longitude = discovered.longitude
        place.cachedAt = .now
    }
}

/// Places 查無結果時的逃生口。台灣的小店、剛開的店查不到的機率不低，
/// 而「最想記的那家偏偏記不了」會直接殺掉使用習慣。見 ADR 0001。
private struct ManualPlaceSheet: View {
    let coordinate: CLLocationCoordinate2D
    let onCreate: (Place) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("店名", text: $name)
                } footer: {
                    Text("會使用你目前的位置。這個地點屬於你自己，不受 Google 條款約束。")
                }
            }
            .navigationTitle("手動建立")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("建立") {
                        onCreate(Place(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude,
                            visualSeed: abs(name.hashValue)
                        ))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
