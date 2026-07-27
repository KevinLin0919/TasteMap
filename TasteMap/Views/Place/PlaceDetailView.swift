import SwiftUI
import UIKit
import TasteMapCore

struct PlaceDetailView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss
    @State private var addingVisit = false
    @State private var editingVisit: Visit?

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
                    ShareLink(item: shareText)
                }
            }
            .sheet(isPresented: $addingVisit) { NewVisitSheet(initialPlace: place) }
            .sheet(item: $editingVisit) { NewVisitSheet(editing: $0) }
        }
    }

    /// 分享出去的內容：店名、Current Score、去過次數、Dish 與 Pitch。
    ///
    /// **Note 永遠不包含在內。** 那是寫給未來自己的話，它的價值正來自於私密 ——
    /// 只有確信沒人會看到時才寫得出真話。見 ADR 0003。
    /// （Google Maps 連結要等 place_id 存在才加得上，屬於 Places 整合那一輪。）
    private var shareText: String {
        var lines = [
            "\(place.name)  \(place.currentScore.formatted(.number.precision(.fractionLength(1)))) / 5 · 去過 \(place.visits.count) 次"
        ]
        if !place.topDishes.isEmpty {
            lines.append("我點過：\(place.topDishes.joined(separator: "、"))")
        }
        if let pitch = place.latestPitch {
            lines.append(pitch)
        }
        return lines.joined(separator: "\n")
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

            TagFlow(tags: place.topImpressions)

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

            HStack(alignment: .firstTextBaseline) {
                Text("造訪紀錄").font(.title3.weight(.bold)).foregroundStyle(TasteTheme.ink)
                Spacer()
                Text("點一下可以補內容").font(.caption2).foregroundStyle(TasteTheme.muted)
            }

            // 記錄分兩段，第二段可以完全跳過（ADR 0005），所以補欄位的入口必須存在。
            // 這裡是編輯而不是新增 —— 用「再記一次」補內容會多出一筆 Visit，
            // 而「去過 N 次」是取代 RevisitIntent 的核心指標，不能被污染。
            ForEach(place.sortedVisits) { visit in
                Button { editingVisit = visit } label: {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text(visit.visitedAt, format: .dateTime.year().month().day())
                                .font(.caption).foregroundStyle(TasteTheme.muted)
                            Spacer()
                            ScoreBadge(score: visit.score)
                        }

                        if let photo = visit.photo, let image = UIImage(data: photo) {
                            Image(uiImage: image)
                                .resizable().scaledToFill()
                                .frame(maxWidth: .infinity).frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        }

                        if !visit.dishes.isEmpty {
                            Text("點了 \(visit.dishes.joined(separator: "、"))")
                                .font(.caption.weight(.semibold)).foregroundStyle(TasteTheme.clay)
                        }

                        if !visit.note.isEmpty {
                            Text(visit.note).font(.subheadline).foregroundStyle(TasteTheme.ink)
                        }

                        if !visit.pitch.isEmpty {
                            Label(visit.pitch, systemImage: "quote.opening")
                                .font(.caption).foregroundStyle(TasteTheme.mossDark)
                        }

                        TagFlow(tags: visit.impressions)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
                    .tasteCard()
                }
                .buttonStyle(.plain)
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
