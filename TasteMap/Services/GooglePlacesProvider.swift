import Foundation
import TasteMapCore

/// Places API (New) 的實作。
///
/// 用 REST 而非 Places SDK for iOS：搜尋與附近查詢只需要兩個端點，為此多背一個
/// 二進位相依不划算，而且 REST 的回應解析可以在 `TasteMapCore` 裡被單元測試。
/// 地圖顯示則沒有選擇，必須用 Maps SDK —— 條款 §5.3 不允許 Places 資料配非 Google 地圖。
struct GooglePlacesProvider: PlacesProvider {
    let apiKey: String
    var session: URLSession = .shared

    /// 要求 Google 以正體中文、台灣地區回傳 —— 影響 `primaryTypeDisplayName`
    /// 與地址格式，也影響搜尋結果的排序偏好。
    private let languageCode = "zh-TW"
    private let regionCode = "TW"

    func search(_ query: String) async throws -> [DiscoveredPlace] {
        try await post(endpoint: "places:searchText", body: TextSearchRequest(
            textQuery: query,
            languageCode: languageCode,
            regionCode: regionCode
        ))
    }

    func nearby(latitude: Double, longitude: Double, radiusMeters: Double) async throws -> [DiscoveredPlace] {
        try await post(endpoint: "places:searchNearby", body: NearbyRequest(
            languageCode: languageCode,
            regionCode: regionCode,
            maxResultCount: 15,
            rankPreference: "DISTANCE",
            includedTypes: ["restaurant", "cafe", "bar", "bakery"],
            locationRestriction: .init(circle: .init(
                center: .init(latitude: latitude, longitude: longitude),
                radius: radiusMeters
            ))
        ))
    }

    private func post(endpoint: String, body: some Encodable) async throws -> [DiscoveredPlace] {
        var request = URLRequest(url: URL(string: "https://places.googleapis.com/v1/\(endpoint)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(PlacesResponseParser.fieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: request)

        // 解析器自己會辨認錯誤形狀並丟出 PlacesError，所以這裡不看 HTTP 狀態碼 ——
        // Google 的錯誤內容比狀態碼本身有用得多。
        return try PlacesResponseParser.places(from: data)
    }
}

// MARK: - 請求格式

private struct TextSearchRequest: Encodable {
    let textQuery: String
    let languageCode: String
    let regionCode: String
}

private struct NearbyRequest: Encodable {
    struct LocationRestriction: Encodable {
        struct Circle: Encodable {
            struct Center: Encodable {
                let latitude: Double
                let longitude: Double
            }

            let center: Center
            let radius: Double
        }

        let circle: Circle
    }

    let languageCode: String
    let regionCode: String
    let maxResultCount: Int
    let rankPreference: String
    /// 限制在餐飲類型，否則附近查詢會回一堆公車站與提款機。
    /// 查不到的店由文字搜尋補上。
    let includedTypes: [String]
    let locationRestriction: LocationRestriction
}
