import Foundation
import SwiftData

enum RevisitIntent: String, Codable, CaseIterable, Identifiable {
    case definitely = "一定會"
    case maybe = "看情況"
    case no = "不會"

    var id: String { rawValue }
}

@Model
final class Visit {
    @Attribute(.unique) var id: UUID
    var visitedAt: Date
    var score: Double
    var revisitIntentRawValue: String
    var tags: [String]
    var note: String
    var orderedItems: String
    var place: Place?

    init(
        id: UUID = UUID(),
        visitedAt: Date = .now,
        score: Double,
        revisitIntent: RevisitIntent,
        tags: [String] = [],
        note: String = "",
        orderedItems: String = "",
        place: Place? = nil
    ) {
        self.id = id
        self.visitedAt = visitedAt
        self.score = score
        self.revisitIntentRawValue = revisitIntent.rawValue
        self.tags = tags
        self.note = note
        self.orderedItems = orderedItems
        self.place = place
    }

    var revisitIntent: RevisitIntent {
        get { RevisitIntent(rawValue: revisitIntentRawValue) ?? .maybe }
        set { revisitIntentRawValue = newValue.rawValue }
    }
}
