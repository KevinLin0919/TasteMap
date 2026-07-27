# TasteMap

一款個人地點日誌。使用者在 Google Maps 上發現的店，在 TasteMap 留下自己的評論與評分 —— 為了日後回憶、決定要不要再去，以及推薦給別人。

## Language

**Place**：
一間真實存在的店。它的身分與描述資料由外部的 Place Provider 定義，TasteMap 只認得它、不擁有它。
_Avoid_: Location, Spot, Venue, 店家, POI

**Visit**：
一次造訪的完整記錄，包含當下的評分、印象與評論。這是使用者真正擁有的資產，與任何外部服務無關。
_Avoid_: Review, Entry, Log, Check-in, 打卡

**Place Provider**：
提供 Place 身分與描述資料的外部服務。TasteMap 向它租用地點資料，不擁有。
_Avoid_: Maps API, 地圖服務

**Place ID**：
Place Provider 給一間店的穩定識別碼。是 TasteMap 唯一可以長期保存的外部資料。
_Avoid_: External ID, Google ID

**Score（分數）**：
一次 Visit 當下給出的主觀評分，0.0 至 5.0。屬於那一次造訪，不是店家的總評 —— Place 的分數由其所有 Visit 推導而來。
_Avoid_: Rating, 評價, 星等

**Current Score（現況分數）**：
一間 Place 對外顯示的代表分數，由其所有 Visit 的 Score 依時間加權推導而來 —— 近期的造訪權重高。它回答的是「我現在該不該去」，不是「這家店歷史上有多好」。**不是平均值**。
_Avoid_: Average score, averageScore, 平均分, 總評

**Dish（餐點）**：
一次 Visit 中實際點的東西，例如「綠咖哩」。屬於 Visit 而非 Place —— 同一間店的咖哩可能很好、拉麵很普通。可複選、可自由新增。
_Avoid_: Category, Cuisine, Menu item, 品項

**Impression（印象）**：
一次 Visit 的情境感受，例如「適合工作」「安靜」。與 Dish 是兩個互不相干的維度，不可混為一談，各自擁有獨立的詞彙庫。可複選、可自由新增 —— 詞彙由使用者自己長出來，app 不預設一套。
_Avoid_: Tag, Label, 標籤

**Note（評論）**：
Visit 中寫給未來自己的話。100% 私密，永不隨分享外流。它的價值正來自於私密 —— 使用者只在確信沒人會看到時才寫得出真話。
_Avoid_: Review, Comment, 心得

**Pitch（推薦語）**：
記錄 Visit 時寫下的一句對外建議，例如「綠咖哩必點，烤雞可以跳過」。是**建議**而非事實 —— Dish 記錄「我點過什麼」，Pitch 表達「你該點什麼、為什麼值得去」。與 Note 也不同：Pitch 為了說服朋友，Note 為了提醒自己。
_Avoid_: Description, Blurb, 簡介

**Collection（清單）**：
依 Dish、Impression 或分數自動算出的一組 Place，例如「咖哩」。使用者不手動維護清單成員，記錄時選了 Dish，清單自己長出來。**需至少 2 家 Place 才成立** —— 只有一個選項時使用者需要的是答案，不是清單。
_Avoid_: List, Folder, 收藏夾
