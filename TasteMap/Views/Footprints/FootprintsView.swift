import SwiftData
import SwiftUI
import UIKit

/// 足跡以 **Visit** 為單位，不是 Place。
///
/// 回憶是沿著時間展開的 —— 「上個月我去了哪些地方」「去年生日那餐吃了什麼」。
/// 原本這裡列的是 Place（依最後造訪排序），同一家店去五次只會出現一次，
/// 答不出這種問題。地圖負責空間、清單負責分類，這裡負責時間。
struct FootprintsView: View {
    @Query(sort: \Visit.visitedAt, order: .reverse) private var visits: [Visit]
    @Query private var places: [Place]
    @State private var selectedPlace: Place?

    private var averageScore: Double {
        guard !visits.isEmpty else { return 0 }
        return visits.map(\.score).reduce(0, +) / Double(visits.count)
    }

    /// 對齊 ScoreCalculator.label 的「很喜歡，會推薦」那一檔。
    private var recommendable: Int { places.filter { $0.currentScore >= 4.2 }.count }

    private var months: [(start: Date, visits: [Visit])] {
        let calendar = Calendar.current
        return Dictionary(grouping: visits) { visit in
            calendar.dateInterval(of: .month, for: visit.visitedAt)?.start ?? visit.visitedAt
        }
        .map { (start: $0.key, visits: $0.value.sorted { $0.visitedAt > $1.visitedAt }) }
        .sorted { $0.start > $1.start }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                    header
                    stats

                    if visits.isEmpty {
                        emptyState
                    } else {
                        ForEach(months, id: \.start) { month in
                            Section {
                                ForEach(month.visits) { visit in
                                    visitRow(visit)
                                    Divider().opacity(0.6)
                                }
                            } header: {
                                monthHeader(month.start, count: month.visits.count)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 18)
            }
            .background(TasteTheme.paper)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedPlace) { PlaceDetailView(place: $0) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(TasteTheme.mossDark)
                .textCase(.uppercase)
            Text("你的足跡")
                .font(.system(size: 36, weight: .semibold, design: .serif))
                .foregroundStyle(TasteTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stats: some View {
        HStack(spacing: 0) {
            stat("\(visits.count)", "累積造訪")
            Divider().frame(height: 34)
            stat(averageScore.formatted(.number.precision(.fractionLength(1))), "平均給分")
            Divider().frame(height: 34)
            stat("\(recommendable)", "值得推薦")
        }
        .padding(.vertical, 14)
        .tasteCard()
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(TasteTheme.ink)
            Text(label).font(.caption2).foregroundStyle(TasteTheme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("還沒有足跡").font(.headline).foregroundStyle(TasteTheme.ink)
            Text("按右下角的按鈕記下第一次造訪。只要地點、分數跟一張照片就能存，其他之後再補。")
                .font(.caption).foregroundStyle(TasteTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .tasteCard()
    }

    private func monthHeader(_ start: Date, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(start, format: .dateTime.year().month(.wide))
                .font(.subheadline.weight(.bold)).foregroundStyle(TasteTheme.ink)
            Spacer()
            Text("\(count) 次").font(.caption2).foregroundStyle(TasteTheme.muted)
        }
        .padding(.vertical, 8)
        .background(TasteTheme.paper)
    }

    private func visitRow(_ visit: Visit) -> some View {
        Button {
            selectedPlace = visit.place
        } label: {
            HStack(alignment: .top, spacing: 13) {
                thumbnail(for: visit)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(visit.place?.name ?? "未知地點")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(TasteTheme.ink)
                        Spacer()
                        ScoreBadge(score: visit.score)
                    }
                    Text(visit.visitedAt, format: .dateTime.month().day().weekday(.abbreviated))
                        .font(.caption).foregroundStyle(TasteTheme.muted)
                    if !visit.dishes.isEmpty {
                        Text(visit.dishes.joined(separator: "、"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TasteTheme.clay).lineLimit(1)
                    }
                    if !visit.note.isEmpty {
                        Text(visit.note)
                            .font(.caption)
                            .foregroundStyle(TasteTheme.ink.opacity(0.78))
                            .lineLimit(2)
                    }
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 這一次造訪自己的照片優先 —— 時間軸上的每一格都該是那天的樣子，
    /// 而不是這家店的代表照。
    @ViewBuilder
    private func thumbnail(for visit: Visit) -> some View {
        if let photo = visit.photo, let image = UIImage(data: photo) {
            Image(uiImage: image)
                .resizable().scaledToFill()
                .frame(width: 78, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else if let place = visit.place {
            PlaceArtwork(place: place, height: 72)
                .frame(width: 78)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TasteTheme.paperDeep)
                .frame(width: 78, height: 72)
        }
    }
}
