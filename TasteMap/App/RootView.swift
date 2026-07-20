import SwiftData
import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case footprints, map, collections, search

    var title: String {
        switch self {
        case .footprints: "足跡"
        case .map: "地圖"
        case .collections: "清單"
        case .search: "搜尋"
        }
    }

    var symbol: String {
        switch self {
        case .footprints: "clock"
        case .map: "map"
        case .collections: "list.bullet"
        case .search: "magnifyingglass"
        }
    }
}

struct RootView: View {
    @State private var selectedTab: AppTab = .footprints
    @State private var showingNewVisit = false

    var body: some View {
        ZStack {
            TasteTheme.paper.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .footprints: FootprintsView()
                case .map: TasteMapScreen()
                case .collections: CollectionsView()
                case .search: TasteSearchView()
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TasteTabBar(selection: $selectedTab) { showingNewVisit = true }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
        }
        .sheet(isPresented: $showingNewVisit) {
            NewVisitSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .tint(TasteTheme.mossDark)
    }
}

private struct TasteTabBar: View {
    @Binding var selection: AppTab
    let addVisit: () -> Void

    var body: some View {
        HStack(spacing: 3) {
            tab(.footprints)
            tab(.map)
            addButton
            tab(.collections)
            tab(.search)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(.white.opacity(0.65)))
        .shadow(color: TasteTheme.ink.opacity(0.14), radius: 24, y: 12)
    }

    private func tab(_ tab: AppTab) -> some View {
        Button { selection = tab } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol).font(.system(size: 18, weight: selection == tab ? .semibold : .regular))
                Text(tab.title).font(.caption2.weight(.semibold))
            }
            .foregroundStyle(selection == tab ? TasteTheme.ink : TasteTheme.muted)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
    }

    private var addButton: some View {
        Button(action: addVisit) {
            VStack(spacing: 2) {
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 47, height: 47)
                    .background(TasteTheme.ink, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(.white.opacity(0.75), lineWidth: 2))
                    .shadow(color: TasteTheme.ink.opacity(0.24), radius: 10, y: 5)
                Text("記錄").font(.caption2.weight(.bold)).foregroundStyle(TasteTheme.ink)
            }
            .frame(maxWidth: .infinity)
            .offset(y: -9)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("記錄一次新造訪")
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Place.self, Visit.self], inMemory: true)
}
