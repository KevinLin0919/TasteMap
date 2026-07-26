import SwiftData
import SwiftUI

@main
struct TasteMapApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Place.self, Visit.self)
        } catch {
            // 刻意不在失敗時重建空資料庫。Visit 是使用者唯一真正擁有的資產
            // （見 ADR 0002），靜默刪除它遠比當掉更糟 —— 當掉至少留得住檔案。
            //
            // 目前倚賴 SwiftData 的輕量遷移：新欄位都有預設值，`impressions`
            // 以 `@Attribute(originalName: "tags")` 對應舊名。累積真實資料前
            // 應改用 VersionedSchema 與明確的 SchemaMigrationPlan。
            fatalError(
                """
                無法開啟 TasteMap 資料庫，可能是 schema 遷移失敗。
                資料檔並未被刪除。錯誤：\(error)
                """
            )
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
