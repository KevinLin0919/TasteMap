import Foundation
import SwiftData
import SwiftUI

struct CollectionsView: View {
    @Query private var places: [Place]
    @State private var selectedPlace: Place?

    private var ranking: [Place] { places.sorted { $0.currentScore > $1.currentScore } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("TASTE COLLECTIONS").font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(TasteTheme.mossDark)
                        Text("我的清單").font(.system(size: 36, weight: .semibold, design: .serif))
                    }

                    featured

                    VStack(alignment: .leading, spacing: 5) {
                        Text("你的排行榜").font(.title3.weight(.bold))
                        ForEach(Array(ranking.enumerated()), id: \.element.id) { index, place in
                            Button { selectedPlace = place } label: {
                                HStack(spacing: 11) {
                                    Text(String(format: "%02d", index + 1)).font(.system(.caption, design: .serif, weight: .bold)).foregroundStyle(TasteTheme.clay).frame(width: 24)
                                    PlaceArtwork(place: place, height: 56).frame(width: 60).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    VStack(alignment: .leading, spacing: 3) { Text(place.name).font(.system(.headline, design: .serif)); Text("\(place.district) · \(place.topTags.first ?? place.category.rawValue)").font(.caption).foregroundStyle(TasteTheme.muted) }
                                    Spacer(); ScoreBadge(score: place.currentScore)
                                }.padding(.vertical, 6)
                            }.buttonStyle(.plain)
                            Divider().opacity(0.55)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("依情境收藏").font(.title3.weight(.bold))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            smartCollection("帶電腦工作", "laptopcomputer", "\(places.filter { $0.topTags.contains("適合工作") }.count) 個地方", TasteTheme.moss)
                            smartCollection("兩個人聊天", "bubble.left.and.bubble.right", "\(places.filter { $0.topTags.contains("適合聊天") }.count) 個地方", TasteTheme.clay)
                            smartCollection("深夜還開", "moon.stars", "1 個地方", TasteTheme.gold)
                            smartCollection("值得專程去", "arrow.up.right", "\(places.filter { $0.currentScore >= 4.5 }.count) 個地方", TasteTheme.ink)
                        }
                    }
                }
                .padding(20).padding(.bottom, 18)
            }
            .background(TasteTheme.paper)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedPlace) { PlaceDetailView(place: $0) }
        }
    }

    private var featured: some View {
        ZStack(alignment: .bottomLeading) {
            if let place = ranking.first { PlaceArtwork(place: place, height: 225) }
            LinearGradient(colors: [.black.opacity(0.72), .clear], startPoint: .bottomLeading, endPoint: .topTrailing)
            VStack(alignment: .leading, spacing: 7) {
                Text("本月精選 · 深夜咖啡").font(.caption2.weight(.bold)).tracking(1).opacity(0.8)
                Text("晚上十點後，\n還想坐一下。").font(.system(size: 28, weight: .semibold, design: .serif))
            }.foregroundStyle(.white).padding(22)
        }
        .frame(height: 225).clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func smartCollection(_ title: String, _ symbol: String, _ count: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: symbol).foregroundStyle(.white).frame(width: 34, height: 34).background(color, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(title).font(.subheadline.weight(.bold)); Text(count).font(.caption2).foregroundStyle(TasteTheme.muted)
        }.frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading).padding(14).tasteCard()
    }
}
