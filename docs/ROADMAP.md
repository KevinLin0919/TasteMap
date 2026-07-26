# Product roadmap

## Product loop

```text
在 Google Maps 或街上發現一家店 → 去了 → 記錄一次 Visit
    → Collection 自動長出來 → 朋友問時分享純文字清單
```

職責分工：**Google Maps 管「我想去哪」，TasteMap 管「我去過哪、覺得如何」。**

## M1 — 可用的個人記錄

第一版就必須能記錄真實地點。原本把地點來源排在第二階段是錯的 —— 沒有它，app 只能操作 seed data。

- Google Places 作為 Place Provider；**GPS 定位撈附近店家**為主要入口，打字搜尋為備援
- Google Maps SDK for iOS 底圖，顯示 Google POI 供探索
- Places 查無結果時可手動建立地點
- 兩段式記錄：Place + Score + 照片即可存檔；Dish、Impression、Note、Pitch 全部可跳過
- Visit 可編輯，隨時回頭補欄位
- 照片只用使用者自己的，可現拍或從相簿挑選既有照片
- Score 0.0–5.0，0.1 為單位，預設起始 4.0
- Current Score 時間加權，半衰期 24 個月
- Collection 由 Dish、Impression 與分數自動推導；**需至少 2 家 Place 才成立**
- 足跡分頁以 **Visit** 為單位的時間軸，同一家店的多次造訪各自顯示
- 搜尋置於清單頁頂部，比對店名、Dish、Impression
- 分享：純文字清單（店名、Current Score、去過次數、Dish、Pitch、Google Maps 連結）
- Place 僅長期保存 place_id 與 provider 標記；座標依條款以 30 天為期快取
- 冷啟動引導：補記憶中最愛的 5–10 家，而非匯入清單

## M2 — Share Extension

- 從 Google Maps 分享地點進 TasteMap
- 解析 `maps.app.goo.gl` 短網址並與 Places 配對
- 貼上 Google Maps URL

## M3 — 產品硬化

- 快取過期後的刷新策略與離線 fallback（保留最後已知名稱）
- 無障礙、深色模式、本地化
- 觀測與當機回報
- App Store 素材、TestFlight

## M4 — 備份與跨裝置

分享已由純文字解決（見 [ADR 0003](adr/0003-sharing-is-plain-text-no-backend.md)），此階段只剩「換裝置不遺失資料」。

- Sign in with Apple
- Visit 層的備份與同步；Place 層可由 place_id 重建，不需同步
- 資料匯出與帳號刪除

## 明確不做

這些曾在路線圖上，經審視後放棄。列出來是為了避免日後有人再提。

| 項目 | 原因 |
|---|---|
| Google Takeout 清單匯入 | 匯入數百個無評論的空殼，比空地圖更打擊使用動力。冷啟動改用「回憶補記最愛的 10 家」 |
| 「想去」狀態 | Google Maps 已做得更好，且會讓地圖與清單長出兩種狀態 |
| 公開分享網頁 / VPS | 見 [ADR 0003](adr/0003-sharing-is-plain-text-no-backend.md) |
| LLM query parser、自然語言情境搜尋 | Collection 已涵蓋情境需求，搜尋只需找特定一間 |
| Pairwise 分數校準 | 在記錄當下增加決策，與「寫入必須輕」衝突。見 [ADR 0004](adr/0004-score-is-zero-to-five.md) |
| `RevisitIntent` | 收集後全 app 未使用，且與 Score 資訊重疊。改用「去過 N 次」這個更誠實的指標 |
| `Visit.orderedItems` | 已由 Dish 完全取代 |
