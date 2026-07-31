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
                name: "山嶼咖啡", address: "台北市中山區某某路 1 號", typeKey: "cafe", typeName: "咖啡廳",
                latitude: 25.0522, longitude: 121.5226, visualSeed: 0,
                visits: [
                    Visit(visitedAt: calendar.date(byAdding: .day, value: -12, to: .now)!, score: 4.3, impressions: ["適合工作", "有插座", "安靜"], dishes: ["拿鐵", "布丁"], note: "咖啡普通，但工作環境非常舒服。平日下午會想再來。", pitch: "拿鐵普通，來這裡是為了位子。"),
                    Visit(visitedAt: calendar.date(byAdding: .month, value: -2, to: .now)!, score: 4.4, impressions: ["適合工作", "安靜"], note: "靠窗第二桌採光很好。")
                ]
            ),
            makePlace(
                name: "森白甜點", address: "台北市大安區某某路 2 號", typeKey: "dessert_shop", typeName: "甜點店",
                latitude: 25.0336, longitude: 121.5434, visualSeed: 1,
                visits: [
                    Visit(visitedAt: calendar.date(byAdding: .month, value: -1, to: .now)!, score: 4.1, impressions: ["採光好", "適合聊天"], dishes: ["布丁", "手沖"], note: "布丁值得再點，週末客滿時不適合久坐。", pitch: "焦糖布丁必點，避開週末。")
                ]
            ),
            makePlace(
                name: "夜丘珈琲", address: "台北市信義區某某路 3 號", typeKey: "cafe", typeName: "咖啡廳",
                latitude: 25.0380, longitude: 121.5665, visualSeed: 2,
                visits: [
                    Visit(visitedAt: calendar.date(byAdding: .day, value: -5, to: .now)!, score: 4.6, impressions: ["營業到很晚", "氣氛", "安靜"], dishes: ["手沖"], note: "晚上十點後還能安靜坐著，音樂和燈光都很穩定。", pitch: "深夜想安靜坐著的話就是這裡。")
                ]
            ),
            makePlace(
                name: "河岸小室", address: "台北市松山區某某路 4 號", typeKey: "cafe", typeName: "咖啡廳",
                latitude: 25.0562, longitude: 121.5622, visualSeed: 3,
                visits: [
                    Visit(visitedAt: calendar.date(byAdding: .month, value: -2, to: .now)!, score: 3.8, impressions: ["河景", "戶外座位", "適合傍晚"], dishes: ["拿鐵"], note: "景色比咖啡更值得，天氣好的傍晚可以帶朋友來。")
                ]
            )
        ]

        places.forEach { context.insert($0) }
        try? context.save()
    }

    /// Seed 的地點刻意沒有 providerPlaceID —— 它們代表「手動建立」的地點，
    /// 不受 Provider 條款約束，也不會被當成過期快取而去刷新。
    private static func makePlace(
        name: String,
        address: String,
        typeKey: String,
        typeName: String,
        latitude: Double,
        longitude: Double,
        visualSeed: Int,
        visits: [Visit]
    ) -> Place {
        let place = Place(
            name: name,
            address: address,
            typeKey: typeKey,
            typeName: typeName,
            latitude: latitude,
            longitude: longitude,
            visualSeed: visualSeed
        )
        visits.forEach { $0.place = place }
        place.visits = visits
        return place
    }
}
