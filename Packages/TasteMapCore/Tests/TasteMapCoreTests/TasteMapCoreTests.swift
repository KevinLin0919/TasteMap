import Foundation
import Testing
@testable import TasteMapCore

// 與 ScoreCalculator 內部使用同一個平均月長。在測試裡明寫出來，
// 是為了讓權重的期望值能手算驗證，而不是相信實作。
private let secondsPerMonth: Double = 30.436875 * 24 * 60 * 60

private let referenceNow = Date(timeIntervalSince1970: 1_800_000_000)

private func visit(_ score: Double, monthsAgo months: Double) -> ScoredVisit {
    ScoredVisit(score: score, visitedAt: referenceNow.addingTimeInterval(-months * secondsPerMonth))
}

// MARK: - Current Score

@Test func currentScoreOfNoVisitsIsZero() {
    #expect(ScoreCalculator.currentScore(of: [], now: referenceNow) == 0)
}

@Test func singleVisitScoresExactlyWhatWasGiven() {
    #expect(ScoreCalculator.currentScore(of: [visit(4.3, monthsAgo: 0)], now: referenceNow) == 4.3)
    // 年代久遠也一樣 —— 只有一筆時沒有東西可以被稀釋。
    #expect(ScoreCalculator.currentScore(of: [visit(4.3, monthsAgo: 60)], now: referenceNow) == 4.3)
}

@Test func aVisitOneHalfLifeOldCarriesHalfTheWeight() {
    // 現在給 5.0、24 個月前給 0.0。權重 1.0 與 0.5 → 5.0 / 1.5 = 3.33…
    let visits = [visit(5.0, monthsAgo: 0), visit(0.0, monthsAgo: ScoreCalculator.halfLifeInMonths)]
    #expect(ScoreCalculator.currentScore(of: visits, now: referenceNow) == 3.3)
}

@Test func recentVisitsOutweighOlderOnes() {
    // ADR 0006 的例子：一家變差的店。算術平均是 4.2，時間加權應更低。
    let visits = [
        visit(4.4, monthsAgo: 24),
        visit(4.5, monthsAgo: 18),
        visit(3.6, monthsAgo: 0)
    ]
    let arithmeticMean = (4.4 + 4.5 + 3.6) / 3

    let result = ScoreCalculator.currentScore(of: visits, now: referenceNow)

    #expect(result == 4.0)
    #expect(result < arithmeticMean)
}

@Test func improvingPlaceScoresHigherThanItsMean() {
    // 對稱檢查：變好的店應被往上拉，證明加權沒有單向偏誤。
    let visits = [visit(3.0, monthsAgo: 24), visit(4.8, monthsAgo: 0)]
    let arithmeticMean = (3.0 + 4.8) / 2

    #expect(ScoreCalculator.currentScore(of: visits, now: referenceNow) > arithmeticMean)
}

@Test func visitOrderDoesNotAffectResult() {
    let visits = [visit(4.4, monthsAgo: 24), visit(4.5, monthsAgo: 18), visit(3.6, monthsAgo: 0)]

    #expect(
        ScoreCalculator.currentScore(of: visits, now: referenceNow)
            == ScoreCalculator.currentScore(of: visits.reversed(), now: referenceNow)
    )
}

@Test func futureDatedVisitIsNotWeightedAboveThePresent() {
    // 時區或裝置時鐘偏移可能讓 visitedAt 落在未來，權重不應因此超過 1。
    let future = ScoredVisit(score: 5.0, visitedAt: referenceNow.addingTimeInterval(60 * 60 * 24))
    let present = ScoredVisit(score: 0.0, visitedAt: referenceNow)

    #expect(ScoreCalculator.currentScore(of: [future, present], now: referenceNow) == 2.5)
}

@Test func currentScoreStaysWithinTheAllowedRange() {
    let visits = [visit(0, monthsAgo: 30), visit(5, monthsAgo: 0), visit(2.5, monthsAgo: 12)]

    #expect(ScoreCalculator.range.contains(ScoreCalculator.currentScore(of: visits, now: referenceNow)))
}

// MARK: - Labels

@Test func labelsCoverEveryBandOfTheZeroToFiveScale() {
    #expect(ScoreCalculator.label(for: 5.0) == "會想專程再去")
    #expect(ScoreCalculator.label(for: 4.7) == "會想專程再去")
    #expect(ScoreCalculator.label(for: 4.6) == "很喜歡，會推薦")
    #expect(ScoreCalculator.label(for: 4.2) == "很喜歡，會推薦")
    #expect(ScoreCalculator.label(for: 4.1) == "不錯，願意再訪")
    #expect(ScoreCalculator.label(for: 3.5) == "不錯，願意再訪")
    #expect(ScoreCalculator.label(for: 3.4) == "有優點，但不一定再去")
    #expect(ScoreCalculator.label(for: 2.8) == "有優點，但不一定再去")
    #expect(ScoreCalculator.label(for: 2.7) == "不太符合我的期待")
    #expect(ScoreCalculator.label(for: 1.5) == "不太符合我的期待")
    // 舊的 5–10 尺度給不了負評，這一檔是新開放的。
    #expect(ScoreCalculator.label(for: 1.4) == "不會再來")
    #expect(ScoreCalculator.label(for: 0.0) == "不會再來")
}

@Test func defaultScoreIsAPositiveStartingPoint() {
    #expect(ScoreCalculator.range.contains(ScoreCalculator.defaultScore))
    #expect(ScoreCalculator.label(for: ScoreCalculator.defaultScore) == "不錯，願意再訪")
}

// MARK: - Search

private let yama = TasteCandidate(
    name: "山嶼咖啡", typeName: "咖啡廳", address: "台北市中山區某某路 1 號",
    currentScore: 4.4, impressions: ["適合工作", "有插座"], dishes: ["手沖", "布丁"], visitCount: 3
)
private let dessert = TasteCandidate(
    name: "森白甜點", typeName: "甜點店", address: "台北市大安區某某路 2 號",
    currentScore: 4.1, impressions: ["採光好"], dishes: ["焦糖布丁"], visitCount: 2
)

@Test func searchMatchesAcrossNameCategoryDistrictAndImpressions() {
    #expect(TasteSearchEngine.search("中山 工作", in: [dessert, yama]).map(\.name) == ["山嶼咖啡"])
    #expect(TasteSearchEngine.search("甜點", in: [dessert, yama]).map(\.name) == ["森白甜點"])
}

@Test func searchMatchesDishes() {
    // 「我記得那家有賣焦糖布丁…」—— Collection 幫不上忙，這是搜尋的職責。
    #expect(TasteSearchEngine.search("焦糖布丁", in: [dessert, yama]).map(\.name) == ["森白甜點"])
    #expect(TasteSearchEngine.search("手沖", in: [dessert, yama]).map(\.name) == ["山嶼咖啡"])
}

@Test func searchHonoursAMinimumScoreOnTheZeroToFiveScale() {
    #expect(TasteSearchEngine.search("4.2分以上", in: [dessert, yama]).map(\.name) == ["山嶼咖啡"])
    #expect(TasteSearchEngine.search("4分以上", in: [dessert, yama]).count == 2)
}

@Test func emptyQueryReturnsEverythingRankedByScore() {
    #expect(TasteSearchEngine.search("   ", in: [dessert, yama]).map(\.name) == ["山嶼咖啡", "森白甜點"])
}

@Test func visitCountBreaksTiesWithoutInflatingTheScore() {
    let often = TasteCandidate(name: "常去", typeName: "餐廳", address: "台北市中山區某某路 3 號", currentScore: 4.2, impressions: [], visitCount: 9)
    let once = TasteCandidate(name: "去過一次", typeName: "餐廳", address: "台北市中山區某某路 3 號", currentScore: 4.2, impressions: [], visitCount: 1)
    let better = TasteCandidate(name: "更高分", typeName: "餐廳", address: "台北市中山區某某路 3 號", currentScore: 4.3, impressions: [], visitCount: 1)

    // 同分時次數多的在前，但次數永遠贏不過更高的分數。
    #expect(TasteSearchEngine.search("", in: [once, often, better]).map(\.name) == ["更高分", "常去", "去過一次"])
}
