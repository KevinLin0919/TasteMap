# Architecture

## Principles

- Visit is the source of truth: a Place score is derived from its Visits.
- Own the record, rent the place: Visit data is永久且完全屬於使用者；Place 的描述資料向 Place Provider 租用，受其保存期限規範。見 [ADR 0002](adr/0002-place-is-rented-visit-is-owned.md)。
- Offline for reading and writing an existing Place: 對已記錄過的地點寫 Visit 不需要網路。**新增**地點需要連線，因為地點身分來自 Place Provider。
- Provider boundaries: Place Provider、地圖顯示與同步都是可替換的服務，但 Places 資料與地圖顯示受同一份條款綁定，不可各自獨立更換。見 [ADR 0001](adr/0001-google-places-as-place-provider.md)。
- Private by default: Visit 的評論永不外流。分享是一個獨立產生的投影，不揭露原始 Visit 資料。

## Layers

```text
SwiftUI feature views
        ↓
SwiftData Place / Visit models
        ↓
TasteMapCore score and collection domain logic

Adapters:
PlacesProvider (Google Places) · MapRenderer (Google Maps SDK for iOS)
Future: SyncClient · ImageStore
```

## Data model

`Place` 只長期擁有 Place ID 與 provider 標記；名稱、地址、座標視為有期限的快取。`Visit` 擁有主觀資料：分數、Dish、Impression、Note、Pitch、照片與時間戳。

Note 與 Pitch 是兩個不同的欄位，不可合併：Note 私密、永不外流，Pitch 專為分享而寫。分享的投影只取 Place 名稱、Current Score、造訪次數、Dish 與 Pitch。

### Schema 遷移

目前倚賴 SwiftData 的輕量遷移 —— 新增欄位一律帶預設值，更名以 `@Attribute(originalName:)` 對應。**累積真實資料之前應改為 `VersionedSchema` 搭配明確的 `SchemaMigrationPlan`。**

`ModelContainer` 初始化失敗時刻意直接中止，而不是重建一個空資料庫：Visit 是使用者唯一真正擁有的資產，靜默刪除遠比當掉更糟。

Collection 一律由 Visit 記錄推導，不儲存明確的清單成員。使用者記錄時選了 Dish 或 Impression，對應的 Collection 自動成立。

Collection 需**至少 2 家 Place** 才成立，否則自由輸入的 Dish 與 Impression 會長出數十個只有一家店的清單，把清單頁淹沒。只有一個選項時使用者需要的是答案而不是清單 —— 那個情境由搜尋承接，搜尋會比對 Dish 與 Impression，一家店也找得到。Collection 依「最近有新成員加入」排序，而非依成員數量。

## 頂層結構

搜尋不佔獨立分頁，置於清單頁頂部。三個分頁各據一個維度，互不重疊：

| 分頁 | 維度 | 單位 |
|---|---|---|
| 足跡 | 時間 —— 我什麼時候去了哪、吃了什麼 | **Visit** |
| 地圖 | 空間 —— 我在哪留下過足跡，以及探索新店 | **Place** |
| 清單 | 分類 —— 咖哩、適合工作 | **Collection** |

足跡以 Visit 為單位是刻意的：回憶沿時間展開，同一家店的五次造訪必須各自顯示。現行實作列的是 Place（同店僅出現一次），名實不符。

## Map

底圖使用 Google Maps SDK for iOS，顯示 Google 的 POI，讓使用者能在圖上探索尚未記錄的店家。這是條款 §5.3 的必然結果，不是美術選擇 —— Places 資料不得與非 Google 地圖並用。

既有以 Apple MapKit 實作的 `TasteMapScreen`（含 `pointsOfInterest: .excludingAll`）需要重寫。
