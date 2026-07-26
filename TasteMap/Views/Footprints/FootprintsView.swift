import SwiftData
import SwiftUI

struct FootprintsView: View {
    @Query private var places: [Place]
    @State private var selectedPlace: Place?

    private var recentPlaces: [Place] {
        places.sorted { ($0.lastVisitedAt ?? .distantPast) > ($1.lastVisitedAt ?? .distantPast) }
    }

    private var allVisits: [Visit] { places.flatMap(\.visits) }
    private var average: Double {
        guard !allVisits.isEmpty else { return 0 }
        return allVisits.map(\.score).reduce(0, +) / Double(allVisits.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    header
                    tasteFinder
                    stats
                    recentSection
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

    private var tasteFinder: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(TasteTheme.moss, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("今天想找什麼？").font(.caption).foregroundStyle(TasteTheme.muted)
                Text("從你的品味裡找答案").font(.system(.headline, design: .serif))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(TasteTheme.muted)
        }
        .padding(15)
        .background(
            LinearGradient(colors: [TasteTheme.moss.opacity(0.19), .white.opacity(0.55)], startPoint: .leading, endPoint: .trailing),
            in: TasteTheme.cardShape
        )
        .overlay(TasteTheme.cardShape.stroke(TasteTheme.moss.opacity(0.12)))
    }

    private var stats: some View {
        HStack(spacing: 0) {
            stat("\(allVisits.count)", "累積造訪")
            Divider().frame(height: 34)
            stat(average.formatted(.number.precision(.fractionLength(1))), "平均分數")
            Divider().frame(height: 34)
            stat("\(places.filter { $0.currentScore >= 4.2 }.count)", "值得推薦")
        }
        .padding(.vertical, 14)
        .tasteCard()
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(.title3, design: .serif, weight: .semibold))
            Text(label).font(.caption2).foregroundStyle(TasteTheme.muted)
        }
        .frame(maxWidth: .infinity)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("最近足跡").font(.title3.weight(.bold))
            ForEach(recentPlaces) { place in
                Button { selectedPlace = place } label: { PlaceRow(place: place) }
                    .buttonStyle(.plain)
                Divider().opacity(0.6)
            }
        }
    }
}
