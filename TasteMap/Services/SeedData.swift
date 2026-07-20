import Foundation
import SwiftData

@MainActor
enum SeedData {
    static func insertIfNeeded(into context: ModelContext) {
        let descriptor = FetchDescriptor<Place>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        let calendar = Calendar.current
        let places = [
            makePlace(
                name: "山嶼咖啡", category: .cafe, district: "中山",
                latitude: 25.0522, longitude: 121.5226, visualSeed: 0,
                visits: [
                    Visit(visitedAt: calendar.date(byAdding: .day, value: -12, to: .now)!, score: 8.7, revisitIntent: .definitely, tags: ["適合工作", "有插座", "安靜"], note: "咖啡普通，但工作環境非常舒服。平日下午會想再來。", orderedItems: "拿鐵、布丁"),
                    Visit(visitedAt: calendar.date(byAdding: .month, value: -2, to: .now)!, score: 8.8, revisitIntent: .definitely, tags: ["適合工作", "安靜"], note: "靠窗第二桌採光很好。")
                ]
            ),
            makePlace(
                name: "森白甜點", category: .dessert, district: "大安",
                latitude: 25.0336, longitude: 121.5434, visualSeed: 1,
                visits: [
                    Visit(visitedAt: calendar.date(byAdding: .month, value: -1, to: .now)!, score: 8.2, revisitIntent: .definitely, tags: ["採光好", "布丁", "適合聊天"], note: "布丁值得再點，週末客滿時不適合久坐。", orderedItems: "焦糖布丁、手沖")
                ]
            ),
            makePlace(
                name: "夜丘珈琲", category: .cafe, district: "信義",
                latitude: 25.0380, longitude: 121.5665, visualSeed: 2,
                visits: [
                    Visit(visitedAt: calendar.date(byAdding: .day, value: -5, to: .now)!, score: 9.1, revisitIntent: .definitely, tags: ["營業到很晚", "氣氛", "手沖"], note: "晚上十點後還能安靜坐著，音樂和燈光都很穩定。", orderedItems: "衣索比亞手沖")
                ]
            ),
            makePlace(
                name: "河岸小室", category: .cafe, district: "松山",
                latitude: 25.0562, longitude: 121.5622, visualSeed: 3,
                visits: [
                    Visit(visitedAt: calendar.date(byAdding: .month, value: -2, to: .now)!, score: 7.9, revisitIntent: .maybe, tags: ["河景", "戶外座位", "適合傍晚"], note: "景色比咖啡更值得，天氣好的傍晚可以帶朋友來。")
                ]
            )
        ]

        places.forEach { context.insert($0) }
        try? context.save()
    }

    private static func makePlace(
        name: String,
        category: PlaceCategory,
        district: String,
        latitude: Double,
        longitude: Double,
        visualSeed: Int,
        visits: [Visit]
    ) -> Place {
        let place = Place(name: name, category: category, district: district, latitude: latitude, longitude: longitude, visualSeed: visualSeed)
        visits.forEach { $0.place = place }
        place.visits = visits
        return place
    }
}
