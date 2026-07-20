import SwiftData
import SwiftUI
import TasteMapCore

struct TasteSearchView: View {
    @Query private var places: [Place]
    @State private var query = ""
    @State private var selectedPlace: Place?

    private var results: [Place] {
        let ids = TasteSearchEngine.search(query, in: places.map(\.searchCandidate)).map(\.id)
        let lookup = Dictionary(uniqueKeysWithValues: places.map { ($0.id, $0) })
        return ids.compactMap { lookup[$0] }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TASTE FINDER").font(.caption2.weight(.bold)).tracking(1.2).foregroundStyle(TasteTheme.mossDark)
                        Text("你現在想找什麼？").font(.system(size: 33, weight: .semibold, design: .serif))
                    }

                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(TasteTheme.muted)
                        TextField("中山區適合工作的咖啡廳", text: $query)
                            .textInputAutocapitalization(.never).submitLabel(.search)
                        if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(TasteTheme.muted) } }
                    }.padding(14).tasteCard()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            suggestion("適合工作")
                            suggestion("8.5分以上")
                            suggestion("中山 咖啡")
                            suggestion("甜點")
                        }
                    }

                    HStack(spacing: 11) {
                        Image(systemName: "sparkles").foregroundStyle(.white).frame(width: 36, height: 36).background(TasteTheme.moss, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(query.isEmpty ? "根據你的全部造訪" : "「\(query)」").font(.caption).foregroundStyle(TasteTheme.muted).lineLimit(1)
                            Text(results.isEmpty ? "暫時找不到符合的地方" : "我會先推薦這 \(results.count) 間").font(.system(.headline, design: .serif))
                        }
                    }.padding(14).frame(maxWidth: .infinity, alignment: .leading).background(TasteTheme.moss.opacity(0.12), in: TasteTheme.cardShape)

                    ForEach(Array(results.enumerated()), id: \.element.id) { index, place in
                        Button { selectedPlace = place } label: {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack(alignment: .topLeading) {
                                    PlaceArtwork(place: place, height: 96).frame(width: 82).clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                                    Text("\(index + 1)").font(.caption2.bold()).foregroundStyle(.white).frame(width: 23, height: 23).background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 8)).padding(6)
                                }
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack { Text(place.name).font(.system(.headline, design: .serif)); Spacer(); ScoreBadge(score: place.averageScore) }
                                    Text("\(place.district) · 去過 \(place.visits.count) 次").font(.caption).foregroundStyle(TasteTheme.muted)
                                    Text(recommendationReason(for: place)).font(.caption).foregroundStyle(TasteTheme.ink.opacity(0.75)).lineLimit(2)
                                }
                            }.padding(.vertical, 5)
                        }.buttonStyle(.plain)
                        Divider().opacity(0.55)
                    }
                }.padding(20).padding(.bottom, 18)
            }
            .background(TasteTheme.paper)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedPlace) { PlaceDetailView(place: $0) }
        }
    }

    private func suggestion(_ text: String) -> some View {
        Button { query = text } label: { Text(text).font(.caption.weight(.semibold)).padding(.horizontal, 12).padding(.vertical, 8).background(TasteTheme.moss.opacity(0.1), in: Capsule()) }.buttonStyle(.plain)
    }

    private func recommendationReason(for place: Place) -> String {
        let tags = place.topTags.prefix(2).joined(separator: "、")
        return tags.isEmpty ? "依照你的個人分數排序。" : "因為你標記了「\(tags)」，而且願意再次造訪。"
    }
}
