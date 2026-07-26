import Foundation

/// 一間 Place 提供給 Collection 推導的素材。
///
/// 每個詞對應的是「這家店最近一次記下它」的時間 —— Collection 依此排序。
public struct CollectionSource: Equatable, Sendable {
    public let placeID: UUID
    public let currentScore: Double
    public let dishes: [String: Date]
    public let impressions: [String: Date]

    public init(
        placeID: UUID,
        currentScore: Double,
        dishes: [String: Date] = [:],
        impressions: [String: Date] = [:]
    ) {
        self.placeID = placeID
        self.currentScore = currentScore
        self.dishes = dishes
        self.impressions = impressions
    }
}

/// 依 Dish 或 Impression 自動算出的一組 Place，例如「咖哩」。
///
/// 使用者不手動維護成員 —— 記錄時選了 Dish，清單自己長出來。
public struct TasteCollection: Identifiable, Equatable, Sendable {
    public enum Kind: String, Equatable, Sendable {
        case dish, impression
    }

    public let name: String
    public let kind: Kind
    public let placeIDs: [UUID]
    /// 最近一次有新成員加入的時間。
    public let lastAddedAt: Date

    public var id: String { "\(kind.rawValue):\(name)" }
    public var count: Int { placeIDs.count }

    public init(name: String, kind: Kind, placeIDs: [UUID], lastAddedAt: Date) {
        self.name = name
        self.kind = kind
        self.placeIDs = placeIDs
        self.lastAddedAt = lastAddedAt
    }
}

public enum CollectionBuilder {
    /// Collection 至少要有這麼多家 Place 才成立。
    ///
    /// Dish 與 Impression 都是自由輸入，不設門檻的話清單頁會被幾十個「只有一家店」
    /// 的清單淹沒。而只有一個選項時，使用者需要的是答案不是清單 —— 那個情境由搜尋
    /// 承接（搜尋會比對 Dish 與 Impression，一家店也找得到）。
    public static let minimumPlaces = 2

    public static func collections(from sources: [CollectionSource]) -> [TasteCollection] {
        let dishes = group(sources, kind: .dish, terms: \.dishes)
        let impressions = group(sources, kind: .impression, terms: \.impressions)

        // 依「最近有新成員加入」排序，而不是依成員數量：三年前吃了八家拉麵，
        // 不代表今天想找拉麵。
        return (dishes + impressions).sorted { lhs, rhs in
            if lhs.lastAddedAt != rhs.lastAddedAt { return lhs.lastAddedAt > rhs.lastAddedAt }
            if lhs.count != rhs.count { return lhs.count > rhs.count }
            return lhs.name < rhs.name
        }
    }

    private static func group(
        _ sources: [CollectionSource],
        kind: TasteCollection.Kind,
        terms: KeyPath<CollectionSource, [String: Date]>
    ) -> [TasteCollection] {
        var members: [String: [(placeID: UUID, at: Date)]] = [:]

        for source in sources {
            for (term, at) in source[keyPath: terms] {
                members[term, default: []].append((source.placeID, at))
            }
        }

        return members.compactMap { term, entries in
            let placeIDs = Set(entries.map(\.placeID))
            guard placeIDs.count >= minimumPlaces else { return nil }
            guard let lastAddedAt = entries.map(\.at).max() else { return nil }

            // 依該店最近一次記下這個詞排序，最近的在前。
            let ordered = entries
                .sorted { $0.at > $1.at }
                .reduce(into: [UUID]()) { result, entry in
                    if !result.contains(entry.placeID) { result.append(entry.placeID) }
                }

            return TasteCollection(name: term, kind: kind, placeIDs: ordered, lastAddedAt: lastAddedAt)
        }
    }
}
