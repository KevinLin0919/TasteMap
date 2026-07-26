import Foundation
import Testing
@testable import TasteMapCore

private let day: TimeInterval = 24 * 60 * 60
private let epoch = Date(timeIntervalSince1970: 1_800_000_000)

private func daysAgo(_ days: Double) -> Date { epoch.addingTimeInterval(-days * day) }

private func source(
    _ id: UUID = UUID(),
    score: Double = 4.0,
    dishes: [String: Date] = [:],
    impressions: [String: Date] = [:]
) -> CollectionSource {
    CollectionSource(placeID: id, currentScore: score, dishes: dishes, impressions: impressions)
}

@Test func aTermWithOnlyOnePlaceDoesNotBecomeACollection() {
    // 只有一家店的「清單」不是清單，是一筆記錄。這個情境由搜尋承接。
    let only = source(dishes: ["綠咖哩": daysAgo(1)])

    #expect(CollectionBuilder.collections(from: [only]).isEmpty)
}

@Test func aTermReachingTheMinimumBecomesACollection() {
    let a = source(dishes: ["綠咖哩": daysAgo(3)])
    let b = source(dishes: ["綠咖哩": daysAgo(1)])

    let collections = CollectionBuilder.collections(from: [a, b])

    #expect(collections.count == 1)
    #expect(collections.first?.name == "綠咖哩")
    #expect(collections.first?.kind == .dish)
    #expect(collections.first?.count == 2)
}

@Test func dishesAndImpressionsStayInSeparateNamespaces() {
    // 同名但不同維度不該被合併 —— 它們是互不相干的兩種東西。
    let a = source(dishes: ["手沖": daysAgo(2)], impressions: ["手沖": daysAgo(2)])
    let b = source(dishes: ["手沖": daysAgo(1)], impressions: ["手沖": daysAgo(1)])

    let collections = CollectionBuilder.collections(from: [a, b])

    #expect(collections.count == 2)
    #expect(Set(collections.map(\.kind)) == [.dish, .impression])
    #expect(Set(collections.map(\.id)).count == 2)
}

@Test func collectionsAreSortedByMostRecentlyGrownNotBySize() {
    // 三年前吃了八家拉麵，不代表今天想找拉麵。
    let ramen = (0..<4).map { _ in source(dishes: ["拉麵": daysAgo(400)]) }
    let curry = (0..<2).map { i in source(dishes: ["咖哩": daysAgo(Double(i))]) }

    let collections = CollectionBuilder.collections(from: ramen + curry)

    #expect(collections.map(\.name) == ["咖哩", "拉麵"])
    #expect(collections.first?.count == 2)
    #expect(collections.last?.count == 4)
}

@Test func lastAddedAtIsTheMostRecentTimeAnyPlaceRecordedTheTerm() {
    let a = source(dishes: ["咖哩": daysAgo(30)])
    let b = source(dishes: ["咖哩": daysAgo(2)])

    #expect(CollectionBuilder.collections(from: [a, b]).first?.lastAddedAt == daysAgo(2))
}

@Test func membersAreOrderedByHowRecentlyTheyEarnedTheTerm() {
    let old = UUID(), recent = UUID(), middle = UUID()
    let sources = [
        source(old, dishes: ["咖哩": daysAgo(90)]),
        source(recent, dishes: ["咖哩": daysAgo(1)]),
        source(middle, dishes: ["咖哩": daysAgo(20)])
    ]

    #expect(CollectionBuilder.collections(from: sources).first?.placeIDs == [recent, middle, old])
}

@Test func aPlaceCountsOnceEvenIfItRecordedTheTermRepeatedly() {
    // CollectionSource 每個詞只保留最近一次，但仍要確認去重後的家數才是門檻依據。
    let single = source(dishes: ["咖哩": daysAgo(1)])

    #expect(CollectionBuilder.collections(from: [single, single]).isEmpty)
}

@Test func noSourcesProducesNoCollections() {
    #expect(CollectionBuilder.collections(from: []).isEmpty)
}
