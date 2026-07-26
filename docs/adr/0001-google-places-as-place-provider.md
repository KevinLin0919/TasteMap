# Google Places 作為 Place Provider

TasteMap 記錄的對象以台灣的獨立小店為主，這類店家在 Apple Maps 的 POI 覆蓋率明顯不如 Google Maps，因此選用 Google Places API 作為地點資料來源。Apple MapKit 雖然完全免費、不需 API key 也不需綁定信用卡，但覆蓋率的差距直接影響「想記的那家店查不到」這個致命體驗，而綁卡只是一次性設定。

## Consequences

Google Maps Platform Service Specific Terms §5.3 規定 Places 資料不得與非 Google 地圖並用。因此底圖也必須改用 Google Maps SDK for iOS，現有以 Apple MapKit 實作的 `TasteMapScreen` 需要重寫。原生 iOS 的地圖顯示不另計費（"All mobile usage of the Maps SDK for iOS is unlimited"），但仍需開通 Google Cloud 帳單與 API key。

同條款 §5.1 允許在完全不顯示地圖的情況下使用 Places 資料（需附 Google 標誌歸屬）。若日後決定拿掉地圖分頁，Apple MapKit 這條路才會重新打開。

Places 搜尋查無結果時的手動建立地點流程仍需保留，作為覆蓋率不足時的逃生口。
