import Foundation

/// 建置時代入的設定值。
///
/// 金鑰來自 `Config.xcconfig`（不進版控），經由 `Supporting/Info.plist` 打包進 app。
/// **打包進 app 的金鑰本質上是半公開的** —— 任何人都能從 IPA 裡挖出來。真正的防線
/// 是 Google Cloud 上的 bundle ID 限制、API 限制與每日配額，不是把字串藏起來。
enum AppSecrets {
    /// 未設定時回傳 nil，而不是空字串 —— 讓呼叫端能明確處理「沒有金鑰」的情況，
    /// 而不是把空字串送給 Google 再拿到一個難懂的錯誤。CI 產出的建置就是這種狀態。
    static var googleMapsAPIKey: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "GMSAPIKey") as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Places 相關功能是否可用。沒有金鑰時 app 其餘部分照常運作 ——
    /// 記錄、清單、足跡都是本機資料，不依賴 Google。
    static var isPlacesConfigured: Bool { googleMapsAPIKey != nil }
}
