import Foundation
import SwiftData
import SwiftUI
import TasteMapCore

struct CollectionsView: View {
    @Query private var places: [Place]
    @State private var selectedPlace: Place?
    @State private var selectedCollection: TasteCollection?
    @State private var query = ""

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// 「值得專程去」的門檻，對齊 ScoreCalculator.label 的最高兩檔。
    private static let worthATripScore = 4.5

    private var ranking: [Place] { places.sorted { $0.currentScore > $1.currentScore } }
    private var worthATrip: [Place] { ranking.filter { $0.currentScore >= Self.worthATripScore } }

    /// 清單一律推導，不儲存成員 —— 記錄時選了 Dish，清單自己長出來。
    private var collections: [TasteCollection] {
        CollectionBuilder.collections(from: places.map(\.collectionSource))
    }

    private var placesByID: [UUID: Place] {
        Dictionary(uniqueKeysWithValues: places.map { ($0.id, $0) })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    header
                    searchField

                    // 搜尋一有內容就整片換成結果 —— 那是「找特定那一間」的模式，
                    // 跟底下瀏覽用的清單是兩件事，同時顯示只會互相干擾。
                    if trimmedQuery.isEmpty {
                        if let top = ranking.first { featured(top) }
                        if !worthATrip.isEmpty { worthATripShelf }
                        rankingSection
                        collectionsSection
                    } else {
                        TasteSearchView(query: trimmedQuery)
                    }
                }
                .padding(20).padding(.bottom, 18)
            }
            .background(TasteTheme.paper)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedPlace) { PlaceDetailView(place: $0) }
            .sheet(item: $selectedCollection) { collection in
                CollectionDetailView(
                    collection: collection,
                    places: collection.placeIDs.compactMap { placesByID[$0] }
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("TASTE COLLECTIONS")
                .font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(TasteTheme.mossDark)
            Text("我的清單")
                .font(.system(size: 36, weight: .semibold, design: .serif))
                .foregroundStyle(TasteTheme.ink)
        }
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass").foregroundStyle(TasteTheme.muted)
            TextField("找店名、餐點或印象", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(TasteTheme.ink)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(TasteTheme.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除搜尋")
            }
        }
        .padding(14)
        .tasteCard()
    }

    /// 標題取自真實資料。原本這裡寫死「本月精選 · 深夜咖啡」，與畫面上是哪家店無關。
    private func featured(_ place: Place) -> some View {
        Button { selectedPlace = place } label: {
            ZStack(alignment: .bottomLeading) {
                PlaceArtwork(place: place, height: 225)
                LinearGradient(
                    colors: [.black.opacity(0.72), .clear],
                    startPoint: .bottomLeading, endPoint: .topTrailing
                )
                VStack(alignment: .leading, spacing: 7) {
                    Text("你目前的第一名")
                        .font(.caption2.weight(.bold)).tracking(1).opacity(0.85)
                    Text(place.name)
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                    if let pitch = place.latestPitch {
                        Text(pitch).font(.caption).opacity(0.9).lineLimit(2)
                    }
                }
                .foregroundStyle(.white).padding(22)
            }
            .frame(height: 225)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var worthATripShelf: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("值得專程去").font(.title3.weight(.bold)).foregroundStyle(TasteTheme.ink)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(worthATrip) { place in
                        Button { selectedPlace = place } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                PlaceArtwork(place: place, height: 108)
                                    .frame(width: 148)
                                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                                Text(place.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(TasteTheme.ink).lineLimit(1)
                                Text(place.currentScore, format: .number.precision(.fractionLength(1)))
                                    .font(.caption.weight(.bold)).foregroundStyle(TasteTheme.gold)
                            }
                            .frame(width: 148, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var rankingSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("你的排行榜").font(.title3.weight(.bold)).foregroundStyle(TasteTheme.ink)
            ForEach(Array(ranking.enumerated()), id: \.element.id) { index, place in
                Button { selectedPlace = place } label: {
                    HStack(spacing: 11) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(.caption, design: .serif, weight: .bold))
                            .foregroundStyle(TasteTheme.clay).frame(width: 24)
                        PlaceArtwork(place: place, height: 56)
                            .frame(width: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(place.name)
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(TasteTheme.ink)
                            Text(subtitle(for: place))
                                .font(.caption).foregroundStyle(TasteTheme.muted)
                        }
                        Spacer()
                        ScoreBadge(score: place.currentScore)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                Divider().opacity(0.55)
            }
        }
    }

    private func subtitle(for place: Place) -> String {
        // 你自己記下的東西比 Google 給的類型更有意義 —— 有 Dish 或 Impression 就先用它們。
        guard let facet = place.topDishes.first ?? place.topImpressions.first else {
            return place.summary
        }
        return [PlaceCachePolicy.locality(from: place.address), facet]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("自動長出來的清單").font(.title3.weight(.bold)).foregroundStyle(TasteTheme.ink)
                Spacer()
                if !collections.isEmpty {
                    Text("\(collections.count) 個").font(.caption2).foregroundStyle(TasteTheme.muted)
                }
            }

            if collections.isEmpty {
                // 空狀態要說明「為什麼還沒有」，否則看起來像壞掉。
                VStack(alignment: .leading, spacing: 6) {
                    Text("還沒有清單")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(TasteTheme.ink)
                    Text("記錄時填「點了什麼」或「印象」，同一個詞出現在 \(CollectionBuilder.minimumPlaces) 家以上，清單就會自己出現。")
                        .font(.caption).foregroundStyle(TasteTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .tasteCard()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(collections) { collection in
                        Button { selectedCollection = collection } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                Image(systemName: collection.kind == .dish ? "fork.knife" : "sparkles")
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(
                                        collection.kind == .dish ? TasteTheme.clay : TasteTheme.moss,
                                        in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    )
                                Text(collection.name)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(TasteTheme.ink).lineLimit(1)
                                Text("\(collection.count) 個地方")
                                    .font(.caption2).foregroundStyle(TasteTheme.muted)
                            }
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                            .padding(14)
                            .tasteCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct CollectionDetailView: View {
    let collection: TasteCollection
    let places: [Place]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlace: Place?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text(collection.kind == .dish ? "你在這些地方點過" : "你給過這個印象的地方")
                        .font(.caption).foregroundStyle(TasteTheme.muted)
                        .padding(.bottom, 8)

                    ForEach(places) { place in
                        Button { selectedPlace = place } label: { PlaceRow(place: place) }
                            .buttonStyle(.plain)
                        Divider().opacity(0.6)
                    }
                }
                .padding(20)
            }
            .background(TasteTheme.paper)
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } }
            }
            .sheet(item: $selectedPlace) { PlaceDetailView(place: $0) }
        }
    }
}
