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

    var topTags: [String] {
        let counts = visits.flatMap(\.tags).reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        return counts.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
        }.prefix(3).map(\.key)
    }

    var searchCandidate: TasteCandidate {
        TasteCandidate(
            id: id,
            name: name,
            category: category.rawValue,
            district: district,
            currentScore: currentScore,
            tags: topTags,
            visitCount: visits.count
        )
    }
}
