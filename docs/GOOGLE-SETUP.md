# Google Maps Platform 設定

TasteMap 需要一把 Google API 金鑰才能使用地點搜尋與 Google 底圖。沒有金鑰時 app 仍可建置與執行 —— 記錄、清單、足跡都是本機資料 —— 只是 Places 相關功能停用。

供應商選型與底圖綁定的理由見 [ADR 0001](adr/0001-google-places-as-place-provider.md)。

## 一、建立專案並啟用 API

在 [Google Cloud Console](https://console.cloud.google.com) 建立專案，於 **API 和服務 → 程式庫** 啟用：

- **Maps SDK for iOS** —— 底圖
- **Places API (New)** —— 搜尋店家、GPS 撈附近

接著在 **帳單** 連結帳單帳戶。即使全程在免費額度內，Google 仍要求綁定信用卡。

## 二、建立並限制金鑰

**API 和服務 → 憑證 → 建立憑證 → API 金鑰**，建立後立即編輯：

| 限制 | 設定 |
|---|---|
| 應用程式限制 | iOS 應用程式，bundle ID `com.kevinlin.TasteMap` |
| API 限制 | 只允許 Maps SDK for iOS 與 Places API (New) |

**這是主要防線。** 金鑰打包在 app 內，任何人都能從 IPA 挖出來；讓它只能從這個 bundle ID 呼叫這兩個 API，才是它安全的原因。

> Sideloadly 以免費 Apple ID 簽名時可能改寫 bundle ID。若實際安裝的識別碼與上述不同，需一併加入限制清單，否則 Places 會回 403。

## 三、配額上限

**IAM 與管理 → 配額與系統限制**，篩選 Places API (New)。

免費額度為每月 10,000 次，除以三十天約為每日 333 次，因此把每日配額設在 300 左右等於「用滿也不超出免費額度」。實際用量約每日 10–30 次，餘裕充足。

| 配額 | 建議值/天 | 用途 |
|---|---|---|
| `SearchTextRequest` | 300 | 打店名搜尋 |
| `SearchNearbyRequest` | 300 | GPS 撈附近 |
| `GetPlaceRequest` | 300 | 取店名座標、快取到期後刷新 |
| `AutocompletePlacesRequest` | 500 | 逐字觸發，乘數較高 |
| `GetPhotoMediaRequest` | **0** | 不使用 |
| `SearchMediaRequest` | **0** | 不使用 |
| `SearchReviewPostsRequest` | **0** | 不使用 |

後三項設為 0，是把 [ADR 0007](adr/0007-photos-are-the-users-own.md)「不顯示也不儲存 Google 的店家照片」變成平台層級的硬限制 —— 即使程式出錯去呼叫，也會被擋下而不是產生帳單。前兩者預設為「無限制」，金鑰若外洩會是最好用的缺口，應優先設定。

`per minute` 一律設 30 即可，用來擋爆量。

預算警示（**帳單 → 預算與快訊**）只會寄信，**不會停止服務**，僅作為第二道防線。

## 四、本機設定

複製範本並填入金鑰：

```sh
cp Config.example.xcconfig Config.xcconfig
```

`Config.xcconfig` 已列入 `.gitignore`。金鑰經由 `Supporting/Info.plist` 打包，程式以 `AppSecrets.googleMapsAPIKey` 讀取。

## 五、CI 設定

CI 由 `secrets.GOOGLE_MAPS_API_KEY` 產生 `Config.xcconfig`。未設定該祕密時寫入空值，建置仍會成功，只是產出的 IPA 沒有金鑰。

```sh
gh secret set GOOGLE_MAPS_API_KEY
```
