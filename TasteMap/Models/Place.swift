import Foundation
import SwiftData
import TasteMapCore

/// 一間真實存在的店。
///
/// **Place 是租來的，Visit 才是資產。** 只有 `providerPlaceID` 能永久保存；
/// 名稱、地址、座標、類型全部是向 Place Provider 租用的快取，有保存期限。
/// 更換供應商時損失的只是這層殼，使用者的評論一個字都不會遺失。見 ADR 0002。
@Model
final class Place {
    @Attribute(.unique) var id: UUID

    /// Provider 的識別碼，格式為 `provider:id`（例如 `google:ChIJ...`）。
    ///
    /// 帶上來源前綴，是為了日後若新增第二個 Provider 時還分辨得出這串是誰家的。
    /// 手動建立的地點沒有這個值。條款只允許無限期保存這一項。
    var providerPlaceID: String?

    // MARK: 以下皆為租來的快取

    var name: String
    var address: String

    /// Provider 的穩定類型鍵，例如 `"cafe"`。存這個而不是顯示字串 ——
    /// 顯示字串會隨語言變，存它等於把今天的語系烤進資料庫。
    var typeKey: String?
    /// Provider 已在地化的類型名稱，例如「咖啡廳」。純顯示用。
    var typeName: String?

    var latitude: Double
    var longitude: Double

    /// 上次向 Provider 取得快取資料的時間。手動建立的地點為 nil。
    ///
    /// 條款 §5.4 只允許座標快取 30 個連續日曆天。見 `needsRefresh`。
    var cachedAt: Date?

    var visualSeed: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Visit.place) var visits: [Visit]

    init(
        id: UUID = UUID(),
        providerPlaceID: String? = nil,
        name: String,
        address: String = "",
        typeKey: String? = nil,
        typeName: String? = nil,
        latitude: Double,
        longitude: Double,
        cachedAt: Date? = nil,
        visualSeed: Int = 0,
        createdAt: Date = .now,
        visits: [Visit] = []
    ) {
        self.id = id
        self.providerPlaceID = providerPlaceID
        self.name = name
        self.address = address
        self.typeKey = typeKey
        self.typeName = typeName
        self.latitude = latitude
        self.longitude = longitude
        self.cachedAt = cachedAt
        self.visualSeed = visualSeed
        self.createdAt = createdAt
        self.visits = visits
    }

    /// 快取是否已超過條款允許的保存期限。
    ///
    /// 手動建立的地點（沒有 provider）永遠不需要刷新 —— 那些資料是使用者自己輸入的，
    /// 不受 Provider 條款約束。
    var needsRefresh: Bool {
        // 手動建立的地點資料是使用者自己輸入的，不受 Provider 條款約束。
        guard providerPlaceID != nil else { return false }
        // 有 provider 卻從未取過快取 —— 需要補。
        guard let cachedAt else { return true }
        return PlaceCachePolicy.isStale(cachedAt: cachedAt)
    }

    /// 顯示用的一行摘要，例如「咖啡廳 · 中山區」。
    var summary: String {
        [typeName, PlaceCachePolicy.locality(from: address)]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    var symbolName: String { PlaceSymbol.name(forType: typeKey) }

    // MARK: 由 Visit 推導

    /// 見 ADR 0006 —— 時間加權的現況分數，**不是平均值**。近期造訪權重高，
    /// 因為它要回答的是「我現在該不該去」。
    var currentScore: Double {
        ScoreCalculator.currentScore(
            of: visits.map { ScoredVisit(score: $0.score, visitedAt: $0.visitedAt) }
        )
    }

    var sortedVisits: [Visit] { visits.sorted { $0.visitedAt > $1.visitedAt } }
    var lastVisitedAt: Date? { sortedVisits.first?.visitedAt }
    var latestNote: String? { sortedVisits.lazy.map(\.note).first { !$0.isEmpty } }

    /// 最近一次寫下的 Pitch —— 分享時用這句。與 Note 不同，Pitch 本來就是對外的。
    var latestPitch: String? { sortedVisits.lazy.map(\.pitch).first { !$0.isEmpty } }

    /// 這家店最常被記下的 Impression。
    var topImpressions: [String] { mostFrequent(visits.flatMap(\.impressions)) }

    /// 這家店最常被點的 Dish。與 Impression 是互不相干的兩個維度。
    var topDishes: [String] { mostFrequent(visits.flatMap(\.dishes)) }

    /// 最近一次留下照片的造訪 —— 用作這家店的代表照。見 ADR 0007。
    var coverPhoto: Data? { sortedVisits.lazy.compactMap(\.photo).first }

    private func mostFrequent(_ values: [String], limit: Int = 3) -> [String] {
        let counts = values.reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        return counts.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
        }.prefix(limit).map(\.key)
    }

    /// 提供給 Collection 推導的素材：每個詞對應這家店最近一次記下它的時間。
    var collectionSource: CollectionSource {
        var dishes: [String: Date] = [:]
        var impressions: [String: Date] = [:]

        for visit in visits {
            for dish in visit.dishes {
                dishes[dish] = max(dishes[dish] ?? .distantPast, visit.visitedAt)
            }
            for impression in visit.impressions {
                impressions[impression] = max(impressions[impression] ?? .distantPast, visit.visitedAt)
            }
        }

        return CollectionSource(
            placeID: id,
            currentScore: currentScore,
            dishes: dishes,
            impressions: impressions
        )
    }

    var searchCandidate: TasteCandidate {
        TasteCandidate(
            id: id,
            name: name,
            typeName: typeName ?? "",
            address: address,
            currentScore: currentScore,
            impressions: topImpressions,
            dishes: topDishes,
            visitCount: visits.count
        )
    }
}
