import Testing
@testable import TasteMapCore

@Test func averageRoundsToOneDecimal() {
    #expect(ScoreCalculator.average([8.7, 8.2, 9.1]) == 8.7)
    #expect(ScoreCalculator.average([]) == 0)
}

@Test func scoreLabelsExpressIntent() {
    #expect(ScoreCalculator.label(for: 9.4) == "會想專程再去")
    #expect(ScoreCalculator.label(for: 8.7) == "很喜歡，會推薦")
}

@Test func searchMatchesContextAndMinimumScore() {
    let yama = TasteCandidate(name: "山嶼咖啡", category: "咖啡廳", district: "中山", averageScore: 8.7, tags: ["適合工作", "有插座"], visitCount: 3)
    let dessert = TasteCandidate(name: "森白甜點", category: "甜點", district: "大安", averageScore: 8.2, tags: ["採光好"], visitCount: 2)

    #expect(TasteSearchEngine.search("中山 工作", in: [dessert, yama]).map(\.name) == ["山嶼咖啡"])
    #expect(TasteSearchEngine.search("8.5分以上", in: [dessert, yama]).map(\.name) == ["山嶼咖啡"])
}
