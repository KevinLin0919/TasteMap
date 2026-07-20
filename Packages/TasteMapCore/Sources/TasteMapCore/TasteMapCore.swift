import Foundation

public struct TasteCandidate: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let category: String
    public let district: String
    public let averageScore: Double
    public let tags: [String]
    public let visitCount: Int

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        district: String,
        averageScore: Double,
        tags: [String],
        visitCount: Int
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.district = district
        self.averageScore = averageScore
        self.tags = tags
        self.visitCount = visitCount
    }
}

public enum ScoreCalculator {
    public static func average(_ scores: [Double]) -> Double {
        guard !scores.isEmpty else { return 0 }
        let value = scores.reduce(0, +) / Double(scores.count)
        return (value * 10).rounded() / 10
    }

    public static func label(for score: Double) -> String {
        switch score {
        case 9.2...: "會想專程再去"
        case 8.5...: "很喜歡，會推薦"
        case 7.5...: "不錯，願意再訪"
        case 6.5...: "有優點，但不一定再去"
        default: "不太符合我的期待"
        }
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
                if let minimumScore, candidate.averageScore < minimumScore { return false }
                if tokens.isEmpty { return true }
                let haystack = ([candidate.name, candidate.category, candidate.district] + candidate.tags)
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

    private static func ranking(_ lhs: TasteCandidate, _ rhs: TasteCandidate) -> Bool {
        if lhs.averageScore != rhs.averageScore { return lhs.averageScore > rhs.averageScore }
        return lhs.visitCount > rhs.visitCount
    }
}
