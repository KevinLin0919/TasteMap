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
        TabView(selection: $selectedTab) {
            Tab(AppTab.footprints.title, systemImage: AppTab.footprints.symbol, value: AppTab.footprints) {
                FootprintsView().recordAction { showingNewVisit = true }
            }

            Tab(AppTab.map.title, systemImage: AppTab.map.symbol, value: AppTab.map) {
                TasteMapScreen().recordAction { showingNewVisit = true }
            }

            Tab(AppTab.collections.title, systemImage: AppTab.collections.symbol, value: AppTab.collections) {
                CollectionsView().recordAction { showingNewVisit = true }
            }

            Tab(AppTab.search.title, systemImage: AppTab.search.symbol, value: AppTab.search) {
                TasteSearchView().recordAction { showingNewVisit = true }
            }
        }
        .tint(TasteTheme.mossDark)
        .sheet(isPresented: $showingNewVisit) {
            NewVisitSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

/// 浮動的「記錄」按鈕。分頁列交給系統的 `TabView` 負責，所以主要動作改用 FAB，
/// 落在右下角 —— 單手握持時拇指的自然位置。
private struct RecordActionButton: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottomTrailing) {
            Button(action: action) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.tint(TasteTheme.ink).interactive(), in: Circle())
            .shadow(color: TasteTheme.ink.opacity(0.26), radius: 14, y: 7)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .accessibilityLabel("記錄一次新造訪")
        }
    }
}

private extension View {
    func recordAction(_ action: @escaping () -> Void) -> some View {
        modifier(RecordActionButton(action: action))
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Place.self, Visit.self], inMemory: true)
}
