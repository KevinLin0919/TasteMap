import Foundation
import SwiftData
import TasteMapCore

enum PlaceCategory: String, Codable, CaseIterable, Identifiable {
    case cafe = "咖啡廳"
    case restaurant = "餐廳"
    case dessert = "甜點"
    case bar = "酒吧"
    case other = "其他"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .cafe: "cup.and.saucer.fill"
        case .restaurant: "fork.knife"
        case .dessert: "birthday.cake.fill"
        case .bar: "wineglass.fill"
        case .other: "mappin.and.ellipse"
        }
    }
}

@Model
final class Place {
    @Attribute(.unique) var id: UUID
    var name: String
    var categoryRawValue: String
    var district: String
    var latitude: Double
    var longitude: Double
    var externalPlaceID: String?
    var visualSeed: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Visit.place) var visits: [Visit]

    init(
        id: UUID = UUID(),
        name: String,
        category: PlaceCategory,
        district: String,
        latitude: Double,
        longitude: Double,
        externalPlaceID: String? = nil,
        visualSeed: Int = 0,
        createdAt: Date = .now,
        visits: [Visit] = []
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = category.rawValue
        self.district = district
        self.latitude = latitude
        self.longitude = longitude
        self.externalPlaceID = externalPlaceID
        self.visualSeed = visualSeed
        self.createdAt = createdAt
        self.visits = visits
    }

    var category: PlaceCategory {
        get { PlaceCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

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
            category: category.rawValue,
            district: district,
            currentScore: currentScore,
            impressions: topImpressions,
            dishes: topDishes,
            visitCount: visits.count
        )
    }
}
