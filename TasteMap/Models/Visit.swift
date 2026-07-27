import Foundation
import SwiftData

/// 一次造訪的完整記錄 —— 使用者真正擁有的資產，與任何外部服務無關。
///
/// `Place` 的描述資料是向 Place Provider 租來的、有保存期限；這一層不是。
/// 備份、匯出與跨裝置同步只需要涵蓋 Visit。見 ADR 0002。
@Model
final class Visit {
    @Attribute(.unique) var id: UUID
    var visitedAt: Date

    /// 0.0–5.0。屬於這一次造訪，存下來就不再變動；Place 的代表分數由所有 Visit
    /// 依時間加權推導。見 ADR 0004、ADR 0006。
    var score: Double

    /// Impression（印象）—— 情境感受，例如「適合工作」「安靜」。
    /// 與 Dish 是互不相干的兩個維度，各自擁有獨立的詞彙庫。
    @Attribute(originalName: "tags") var impressions: [String] = []

    /// Dish（餐點）—— 這次實際點的東西，例如「綠咖哩」。
    /// 屬於 Visit 而非 Place：同一間店的咖哩可能很好、拉麵很普通。
    var dishes: [String] = []

    /// Note（評論）—— 寫給未來自己的話。**100% 私密，永不隨分享外流。**
    /// 它的價值正來自於私密：只有確信沒人會看到時才寫得出真話。
    var note: String

    /// Pitch（推薦語）—— 一句對外建議，例如「綠咖哩必點，烤雞可以跳過」。
    /// 是建議而非事實：Dish 記錄「我點過什麼」，Pitch 表達「你該點什麼」。
    var pitch: String = ""

    /// 使用者自己拍的、或從相簿挑的照片，已壓縮。不儲存 Provider 的店家照片，
    /// 那是 Places 授權中最嚴格的一項。見 ADR 0007。
    @Attribute(.externalStorage) var photo: Data?

    var place: Place?

    init(
        id: UUID = UUID(),
        visitedAt: Date = .now,
        score: Double,
        impressions: [String] = [],
        dishes: [String] = [],
        note: String = "",
        pitch: String = "",
        photo: Data? = nil,
        place: Place? = nil
    ) {
        self.id = id
        self.visitedAt = visitedAt
        self.score = score
        self.impressions = impressions
        self.dishes = dishes
        self.note = note
        self.pitch = pitch
        self.photo = photo
        self.place = place
    }
}
