import SwiftUI
import TasteMapCore

struct PlaceDetailView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss
    @State private var addingVisit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    content
                }
            }
            .background(TasteTheme.paper)
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("關閉", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    // 原本無論幾分都寫「我會推薦」。分數開放到 0 之後那句話會直接說謊，
                    // 所以改成陳述事實。完整的分享格式（Dish、Pitch、Google Maps 連結）
                    // 要等對應欄位存在才做，見 ADR 0003。
                    ShareLink(
                        item: """
                        \(place.name)
                        我的 TasteMap 評分 \(place.currentScore.formatted(.number.precision(.fractionLength(1)))) / 5 · 去過 \(place.visits.count) 次
                        \(ScoreCalculator.label(for: place.currentScore))
                        """
                    )
                }
            }
            .sheet(isPresented: $addingVisit) { NewVisitSheet(initialPlace: place) }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            PlaceArtwork(place: place, height: 285)
            Text(place.currentScore, format: .number.precision(.fractionLength(1)))
                .font(.system(size: 36, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .monospacedDigit()
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .padding(20)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(place.district) · \(place.category.rawValue)")
                    .font(.caption.weight(.bold)).foregroundStyle(TasteTheme.clay)
                Text(place.name).font(.system(size: 32, weight: .semibold, design: .serif))
                Text("去過 \(place.visits.count) 次")
                    .font(.caption).foregroundStyle(TasteTheme.muted)
            }

            TagFlow(tags: place.topTags)

            if let note = place.latestNote {
                Text("「\(note)」")
                    .font(.system(.body, design: .serif))
                    .lineSpacing(5)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(alignment: .leading) { Rectangle().fill(TasteTheme.clay).frame(width: 3) }
            }

            Button { addingVisit = true } label: {
                Text("再記一次").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(TasteTheme.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text("造訪紀錄").font(.title3.weight(.bold))
            ForEach(place.sortedVisits) { visit in
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(visit.visitedAt, format: .dateTime.year().month().day())
                            .font(.caption).foregroundStyle(TasteTheme.muted)
                        Spacer()
                        ScoreBadge(score: visit.score)
                    }
                    if !visit.note.isEmpty { Text(visit.note).font(.subheadline) }
                    TagFlow(tags: visit.tags)
                }
                .padding(15)
                .tasteCard()
            }
        }
        .padding(20)
    }
}

struct TagFlow: View {
    let tags: [String]
    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(TasteTheme.mossDark)
                    .padding(.horizontal, 9).padding(.vertical, 6)
                    .background(TasteTheme.moss.opacity(0.12), in: Capsule())
            }
        }
    }
}
