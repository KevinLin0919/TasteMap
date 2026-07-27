import Foundation
import TasteMapCore

/// Place Provider 的組裝點。
///
/// 沒有金鑰時回 nil，讓呼叫端把「還沒設定」跟「查無結果」分開處理 ——
/// 兩者對使用者的意義完全不同，混在一起會變成一片無從除錯的空白。
enum Places {
    static var provider: PlacesProvider? {
        guard let key = AppSecrets.googleMapsAPIKey else { return nil }
        return GooglePlacesProvider(apiKey: key)
    }

    /// 附近查詢的半徑。走路可及的範圍 —— 你按下記錄時通常人就在店裡或剛走出門口。
    static let nearbyRadiusMeters: Double = 300
}
