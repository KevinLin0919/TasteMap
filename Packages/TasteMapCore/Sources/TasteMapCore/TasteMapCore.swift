import Foundation

/// 一次造訪的分數與時間，供 Current Score 計算使用。
/// 刻意不依賴 SwiftData，讓計分邏輯能獨立測試。
public struct ScoredVisit: Equatable, Sendable {
    public let score: Double
    public let visitedAt: Date

    public init(score: Double, visitedAt: Date) {
        self.score = score
        self.visitedAt = visitedAt
    }
}

public struct TasteCandidate: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    /// Provider 已在地化的類型名稱，例如「咖啡廳」。
    public let typeName: String
    /// 完整地址。比對它而不是自行切出的行政區 —— 打「中山」也應該找得到
    /// 「台北市中山區…」，子字串比對天然就做到了。
    public let address: String
    public let currentScore: Double
    public let impressions: [String]
    public let dishes: [String]
    public let visitCount: Int

    public init(
        id: UUID = UUID(),
        name: String,
        typeName: String,
        address: String,
        currentScore: Double,
        impressions: [String] = [],
        dishes: [String] = [],
        visitCount: Int
    ) {
        self.id = id
        self.name = name
        self.typeName = typeName
        self.address = address
        self.currentScore = currentScore
        self.impressions = impressions
        self.dishes = dishes
        self.visitCount = visitCount
    }
}

public enum ScoreCalculator {
    /// Visit 分數的合法範圍。見 ADR 0004。
    public static let range: ClosedRange<Double> = 0...5

    /// 拉桿的預設起始值。記錄的多半是還不錯的店，從中間值起跳等於每次都要往上拉。
    public static let defaultScore: Double = 4.0

    /// 時間權重的半衰期（月）。見 ADR 0006 —— 使用者傾向探索新店而非頻繁回訪，
    /// 造訪間隔長，較短的半衰期會讓上一次評價幾乎失效。
    public static let halfLifeInMonths: Double = 24

    private static let secondsPerMonth: Double = 30.436875 * 24 * 60 * 60

    /// 一間 Place 對外顯示的代表分數：以時間加權推導，近期造訪權重高。
    ///
    /// **這不是平均值。** 店家會換廚師、漲價、變吵，使用者的口味也會變；
    /// 這個數字回答的是「我現在該不該去」，不是「這家店歷史上有多好」。
    /// 未來的維護者請勿「修正」成算術平均 —— 見 ADR 0006。
    public static func currentScore(of visits: [ScoredVisit], now: Date = .now) -> Double {
        guard !visits.isEmpty else { return 0 }

        var weightedSum = 0.0
        var totalWeight = 0.0

        for visit in visits {
            let elapsedMonths = max(0, now.timeIntervalSince(visit.visitedAt) / secondsPerMonth)
            let weight = pow(0.5, elapsedMonths / halfLifeInMonths)
            weightedSum += visit.score * weight
            totalWeight += weight
        }

        // 造訪久遠到權重下溢為零時，退回未加權平均，避免除以零。
        guard totalWeight > 0 else {
            return round(visits.map(\.score).reduce(0, +) / Double(visits.count), toPlaces: 1)
        }

        return round(weightedSum / totalWeight, toPlaces: 1)
    }

    public static func label(for score: Double) -> String {
        switch score {
        case 4.7...: "會想專程再去"
        case 4.2...: "很喜歡，會推薦"
        case 3.5...: "不錯，願意再訪"
        case 2.8...: "有優點，但不一定再去"
        case 1.5...: "不太符合我的期待"
        default: "不會再來"
        }
    }

    private static func round(_ value: Double, toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (value * factor).rounded() / factor
    }
}

public enum TasteSearchEngine {
    public static func search(_ query: String, in candidates: [TasteCandidate]) -> [TasteCandidate] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return candidates.sorted(by: ranking)
        }

        let minimumScore = minimumScore(in: normalized)
        let tokens = normalized
            .split(whereSeparator: { $0.isWhitespace || $0 == "，" || $0 == "," })
            .map(String.init)
            .filter { !$0.isEmpty && Double($0) == nil && !$0.contains("分以上") }

        return candidates
            .filter { candidate in
                if let minimumScore, candidate.currentScore < minimumScore { return false }
                if tokens.isEmpty { return true }
                // 搜尋負責「找特定那一間」，所以比對店名、Dish 與 Impression。
                // 「找某一類」由 Collection 承接。見 ROADMAP 的 M1。
                let haystack = ([candidate.name, candidate.typeName, candidate.address]
                    + candidate.impressions
                    + candidate.dishes)
                    .joined(separator: " ")
                    .lowercased()
                return tokens.allSatisfy { token in
                    let softened = token
                        .replacingOccurrences(of: "適合", with: "")
                        .replacingOccurrences(of: "的", with: "")
                        .replacingOccurrences(of: "咖啡廳", with: "咖啡")
                    return haystack.contains(token) || (!softened.isEmpty && haystack.contains(softened))
                }
            }
            .sorted(by: ranking)
    }

    private static func minimumScore(in query: String) -> Double? {
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*分?以上"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: query, range: NSRange(query.startIndex..., in: query)),
              let range = Range(match.range(at: 1), in: query)
        else { return nil }
        return Double(query[range])
    }

    /// 分數相同時以造訪次數決勝。次數刻意不併入分數本身 —— 混在一起會讓
    /// 4.5 分不知道代表「很好吃」還是「去很多次」。見 ADR 0006。
    private static func ranking(_ lhs: TasteCandidate, _ rhs: TasteCandidate) -> Bool {
        if lhs.currentScore != rhs.currentScore { return lhs.currentScore > rhs.currentScore }
        return lhs.visitCount > rhs.visitCount
    }
}
