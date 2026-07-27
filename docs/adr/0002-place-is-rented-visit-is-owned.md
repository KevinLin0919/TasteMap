# Place 是租來的，Visit 才是資產

Google Maps Platform Service Specific Terms §5.4 只允許無限期保存 `place_id`；座標最多快取 30 個連續日曆天，其餘描述資料受 Places API Policies 規範。因此 Place 與 Visit 必須明確分層：Place 只永久保存 Place ID 與供應商標記，名稱、地址、座標一律視為可過期的快取；Visit 的評分、印象、評論、照片則完全屬於使用者，與任何外部服務無關。

## Consequences

現行 `Place` model 把 `latitude` / `longitude` 存成 SwiftData 永久欄位，直接違反 §5.4，需要改成帶有效期的快取。

`externalPlaceID: String?` 目前沒有記錄 ID 的來源，未來若新增第二個 Provider 將無法分辨，需要能表達 provider。

`PlaceCategory` enum 與 `Place.district` 同屬租來的一層，一併移除自行維護的版本。分類改存 Places 回傳的 `primaryType`（穩定英文鍵），顯示用 `primaryTypeDisplayName`（Google 已依請求語言在地化）。圖示改為 `primaryType → SF Symbol` 的本地對照表 —— 那是程式碼不是資料，無遷移風險。原 enum 的 rawValue 存中文（`"咖啡廳"`），改名或做多語系會導致既有資料靜默解析失敗，這是移除它的另一個理由。

分類不需要精確：Dish 與 Impression 是逃生口，Google 標錯時使用者自行補 tag 即可。因此不提供分類覆寫功能。

`ARCHITECTURE.md` 宣稱 "Local-first: recording a visit never requires network access"，但快取過期後離線將無法顯示店名。需要保留一份「最後已知名稱」作為離線 fallback，並接受它與政策之間的灰色地帶。

備份、匯出與跨裝置同步只需要涵蓋 Visit 這一層。更換 Place Provider 時，損失的僅是可重新取得的殼，使用者的評論一個字都不會遺失。
