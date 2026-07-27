import Foundation

/// 從 Place Provider 找到的一間店。
///
/// `providerPlaceID` 是唯一可以永久保存的外部資料；其餘欄位都是租來的快取，
/// 有保存期限。見 ADR 0002。
public struct DiscoveredPlace: Identifiable, Equatable, Sendable {
    public let providerPlaceID: String
    public let name: String
    public let address: String
    public let latitude: Double
    public let longitude: Double
    /// Provider 給的穩定類型鍵，例如 `"cafe"`。存這個而不是顯示字串 —— 顯示字串
    /// 會隨語言變，拿它當持久化的值等於埋雷。用來對應本地的圖示對照表。
    public let primaryType: String?
    /// Provider 已依請求語言在地化的類型名稱，例如「咖啡廳」。純顯示用。
    public let typeDisplayName: String?

    public var id: String { providerPlaceID }

    public init(
        providerPlaceID: String,
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        primaryType: String? = nil,
        typeDisplayName: String? = nil
    ) {
        self.providerPlaceID = providerPlaceID
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.primaryType = primaryType
        self.typeDisplayName = typeDisplayName
    }
}

/// 地點資料來源。TasteMap 向它租用地點資料，不擁有。
///
/// 抽象成 protocol 是為了讓更換供應商只是多寫一個實作 —— 但要注意
/// Places 資料與地圖顯示受同一份條款綁定（§5.3），兩者不能各自獨立更換。
public protocol PlacesProvider: Sendable {
    func search(_ query: String) async throws -> [DiscoveredPlace]
    func nearby(latitude: Double, longitude: Double, radiusMeters: Double) async throws -> [DiscoveredPlace]
}

/// Provider 回傳的錯誤。金鑰未設定、超出配額、bundle ID 不符都會走到這裡。
public struct PlacesError: Error, Equatable, Sendable {
    public let code: Int
    public let status: String
    public let message: String

    public init(code: Int, status: String, message: String) {
        self.code = code
        self.status = status
        self.message = message
    }

    /// 給使用者看的說明。原始訊息是英文且假設讀者是開發者。
    public var userMessage: String {
        switch code {
        case 403: "金鑰沒有權限。請確認 Google Cloud 上的 bundle ID 限制與 API 限制。"
        case 429: "今天的查詢次數已達上限，明天會重置。"
        default: "無法連上地點服務（\(code)）。"
        }
    }
}

public enum PlacesResponseParser {
    /// 只索取實際會用到的欄位。Places API (New) 依欄位計費，索取越多層級越貴，
    /// 而且沒有預設值 —— 省略 field mask 會直接回錯誤。
    public static let fieldMask = [
        "places.id",
        "places.displayName",
        "places.formattedAddress",
        "places.location",
        "places.primaryType",
        "places.primaryTypeDisplayName"
    ].joined(separator: ",")

    public static func places(from data: Data) throws -> [DiscoveredPlace] {
        let decoder = JSONDecoder()

        // 錯誤與成功共用 HTTP 200 以外的狀態碼，但兩種形狀都是 JSON，
        // 先試錯誤形狀才不會把錯誤訊息解成「零筆結果」。
        if let failure = try? decoder.decode(ErrorEnvelope.self, from: data), let error = failure.error {
            throw PlacesError(code: error.code, status: error.status, message: error.message)
        }

        let response = try decoder.decode(SearchResponse.self, from: data)

        // 沒有結果時 Google 直接省略 places 這個鍵，不是給空陣列。
        return (response.places ?? []).compactMap(Self.convert)
    }

    private static func convert(_ place: SearchResponse.Place) -> DiscoveredPlace? {
        // 沒有 id 或座標的結果無法使用 —— id 是唯一能永久保存的東西，
        // 座標則決定它能不能出現在地圖上。
        guard let location = place.location else { return nil }

        return DiscoveredPlace(
            providerPlaceID: place.id,
            name: place.displayName?.text ?? place.formattedAddress ?? "未命名地點",
            address: place.formattedAddress ?? "",
            latitude: location.latitude,
            longitude: location.longitude,
            primaryType: place.primaryType,
            typeDisplayName: place.primaryTypeDisplayName?.text
        )
    }
}

// MARK: - 傳輸格式

private struct SearchResponse: Decodable {
    struct Place: Decodable {
        struct LocalizedText: Decodable { let text: String }
        struct Location: Decodable {
            let latitude: Double
            let longitude: Double
        }

        let id: String
        let displayName: LocalizedText?
        let formattedAddress: String?
        let location: Location?
        let primaryType: String?
        let primaryTypeDisplayName: LocalizedText?
    }

    let places: [Place]?
}

private struct ErrorEnvelope: Decodable {
    struct Failure: Decodable {
        let code: Int
        let message: String
        let status: String
    }

    let error: Failure?
}
