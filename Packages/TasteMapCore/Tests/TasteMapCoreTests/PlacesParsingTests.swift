import Foundation
import Testing
@testable import TasteMapCore

private func json(_ string: String) -> Data { Data(string.utf8) }

@Test func parsesASearchResponse() throws {
    let places = try PlacesResponseParser.places(from: json("""
    {
      "places": [
        {
          "id": "ChIJifIePKtZwokRVZ-UdRGkZzs",
          "displayName": { "text": "山嶼咖啡", "languageCode": "zh-TW" },
          "formattedAddress": "台北市中山區某某路 1 號",
          "location": { "latitude": 25.0522, "longitude": 121.5226 },
          "primaryType": "cafe",
          "primaryTypeDisplayName": { "text": "咖啡廳", "languageCode": "zh-TW" }
        }
      ]
    }
    """))

    #expect(places.count == 1)
    let place = try #require(places.first)
    #expect(place.providerPlaceID == "ChIJifIePKtZwokRVZ-UdRGkZzs")
    #expect(place.name == "山嶼咖啡")
    #expect(place.address == "台北市中山區某某路 1 號")
    #expect(place.latitude == 25.0522)
    #expect(place.longitude == 121.5226)
    #expect(place.primaryType == "cafe")
    #expect(place.typeDisplayName == "咖啡廳")
}

@Test func noResultsOmitsThePlacesKeyEntirely() throws {
    // Google 在零筆結果時不給空陣列，而是完全省略 places —— 直接解 [Place] 會爆。
    #expect(try PlacesResponseParser.places(from: json("{}")).isEmpty)
}

@Test func aPlaceWithoutCoordinatesIsDropped() throws {
    // 沒有座標就無法放上地圖，留著只會變成看不見的幽靈。
    let places = try PlacesResponseParser.places(from: json("""
    {
      "places": [
        { "id": "no-location", "displayName": { "text": "缺座標" } },
        {
          "id": "ok",
          "displayName": { "text": "有座標" },
          "location": { "latitude": 25.0, "longitude": 121.0 }
        }
      ]
    }
    """))

    #expect(places.map(\.providerPlaceID) == ["ok"])
}

@Test func missingOptionalFieldsFallBackWithoutFailing() throws {
    // field mask 索取的欄位不保證每筆都有；缺類型或地址不該讓整批解析失敗。
    let places = try PlacesResponseParser.places(from: json("""
    {
      "places": [
        { "id": "bare", "location": { "latitude": 25.0, "longitude": 121.0 } }
      ]
    }
    """))

    let place = try #require(places.first)
    #expect(place.name == "未命名地點")
    #expect(place.address.isEmpty)
    #expect(place.primaryType == nil)
    #expect(place.typeDisplayName == nil)
}

@Test func aNameFallsBackToTheAddressBeforeThePlaceholder() throws {
    let places = try PlacesResponseParser.places(from: json("""
    {
      "places": [
        {
          "id": "addressed",
          "formattedAddress": "台北市大安區某某路 2 號",
          "location": { "latitude": 25.0, "longitude": 121.0 }
        }
      ]
    }
    """))

    #expect(places.first?.name == "台北市大安區某某路 2 號")
}

@Test func anErrorResponseThrowsRatherThanLookingLikeZeroResults() throws {
    // 這是最重要的一條：把 403 解成「找不到店家」會讓金鑰設定錯誤變成靜默的
    // 空白畫面，使用者完全無從得知哪裡壞了。
    let data = json("""
    {
      "error": {
        "code": 403,
        "message": "Requests from this ios client application are blocked.",
        "status": "PERMISSION_DENIED"
      }
    }
    """)

    #expect(throws: PlacesError.self) {
        try PlacesResponseParser.places(from: data)
    }

    do {
        _ = try PlacesResponseParser.places(from: data)
    } catch let error as PlacesError {
        #expect(error.code == 403)
        #expect(error.status == "PERMISSION_DENIED")
        #expect(error.userMessage.contains("bundle ID"))
    }
}

@Test func quotaExhaustionExplainsItselfInUserTerms() {
    let error = PlacesError(code: 429, status: "RESOURCE_EXHAUSTED", message: "Quota exceeded")
    #expect(error.userMessage.contains("上限"))
}

@Test func theFieldMaskAsksOnlyForWhatIsUsed() {
    // Places API (New) 依欄位計費，索取越多層級越貴。這條測試是在守住成本 ——
    // 有人日後加欄位時會先看到它。
    let requested = Set(PlacesResponseParser.fieldMask.split(separator: ",").map(String.init))

    #expect(requested == [
        "places.id",
        "places.displayName",
        "places.formattedAddress",
        "places.location",
        "places.primaryType",
        "places.primaryTypeDisplayName"
    ])
    // 照片與評論是最貴也最受授權限制的欄位，永遠不該出現在這裡。見 ADR 0007。
    #expect(!PlacesResponseParser.fieldMask.contains("photos"))
    #expect(!PlacesResponseParser.fieldMask.contains("reviews"))
}

// MARK: - 快取政策

@Test func coordinatesGoStaleAtThirtyDays() {
    // §5.4 明文規定的 30 個連續日曆天。這不是效能參數，是合約義務。
    let day: TimeInterval = 24 * 60 * 60
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    #expect(!PlaceCachePolicy.isStale(cachedAt: now.addingTimeInterval(-29 * day), now: now))
    #expect(PlaceCachePolicy.isStale(cachedAt: now.addingTimeInterval(-31 * day), now: now))
    #expect(PlaceCachePolicy.maximumAge == 30 * day)
}

@Test func localityIsExtractedFromATaiwaneseAddress() {
    #expect(PlaceCachePolicy.locality(from: "台北市中山區某某路 1 號") == "中山區")
    #expect(PlaceCachePolicy.locality(from: "新北市板橋區文化路一段 100 號") == "板橋區")
    #expect(PlaceCachePolicy.locality(from: "宜蘭縣礁溪鄉溫泉路 5 號") == "礁溪鄉")
}

@Test func localityFallsBackToCityWhenThereIsNoDistrict() {
    #expect(PlaceCachePolicy.locality(from: "嘉義市西區某某街") == "西區")
    #expect(PlaceCachePolicy.locality(from: "基隆市信義街 3 號") == "基隆市")
}

@Test func localityReturnsNilRatherThanGuessingOnForeignAddresses() {
    // 地址格式不符時回 nil，讓呼叫端顯示別的東西，而不是硬切出一段亂碼。
    #expect(PlaceCachePolicy.locality(from: "367 Pitt St, Sydney NSW 2000") == nil)
    #expect(PlaceCachePolicy.locality(from: "") == nil)
}
