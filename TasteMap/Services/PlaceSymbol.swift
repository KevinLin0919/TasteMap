import Foundation

/// Provider 類型鍵 → SF Symbol 的對照。
///
/// 這是**程式碼而非資料** —— 隨時可以增修，沒有遷移風險。這正是不再自行維護
/// `PlaceCategory` enum 的理由之一：那個 enum 只有五種、把中文存進資料庫，
/// 而 Google 的類型清單有數百種且持續增加。對不到的一律回預設圖釘。
enum PlaceSymbol {
    static func name(forType type: String?) -> String {
        guard let type else { return fallback }
        if let exact = map[type] { return exact }

        // Google 的類型很細（`vegetarian_restaurant`、`ramen_restaurant`…），
        // 逐一列舉列不完，用字尾歸類涵蓋整個家族。
        for (suffix, symbol) in familySuffixes where type.hasSuffix(suffix) {
            return symbol
        }
        return fallback
    }

    private static let fallback = "mappin.and.ellipse"

    private static let map: [String: String] = [
        "cafe": "cup.and.saucer.fill",
        "coffee_shop": "cup.and.saucer.fill",
        "bakery": "birthday.cake.fill",
        "dessert_shop": "birthday.cake.fill",
        "ice_cream_shop": "birthday.cake.fill",
        "bar": "wineglass.fill",
        "wine_bar": "wineglass.fill",
        "pub": "wineglass.fill",
        "restaurant": "fork.knife",
        "food_court": "fork.knife",
        "meal_takeaway": "takeoutbag.and.cup.and.straw.fill",
        "meal_delivery": "takeoutbag.and.cup.and.straw.fill"
    ]

    private static let familySuffixes: [(String, String)] = [
        ("_restaurant", "fork.knife"),
        ("_shop", "birthday.cake.fill"),
        ("_bar", "wineglass.fill")
    ]
}
