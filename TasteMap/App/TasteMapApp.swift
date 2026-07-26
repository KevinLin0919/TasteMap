import SwiftData
import SwiftUI

@main
struct TasteMapApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Place.self, Visit.self)
        } catch {
            fatalError("Unable to create TasteMap database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                // TasteTheme 的顏色全是固定 RGB，paper 永遠是淺米色。若跟隨系統進入深色
                // 模式，未指定顏色的文字會套用系統的 .primary（白色）疊在淺底上而讀不清。
                // 真正的深色模式支援見 ROADMAP M3，在那之前先鎖定淺色以維持一致。
                .preferredColorScheme(.light)
                .task { SeedData.insertIfNeeded(into: container.mainContext) }
        }
    }
}
