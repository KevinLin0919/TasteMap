# 照片只用使用者自己的

Visit 的照片一律來自使用者 —— 現拍或從相簿挑選既有的照片。不顯示、也不儲存 Google 的店家照片。沒有照片的 Place 沿用 `PlaceArtwork` 的程序生成漸層作為 fallback。

## Considered Options

**在缺照片時即時抓取 Google 店家照顯示（不儲存）** 被否決，儘管它能解決冷啟動時滿頁漸層的問題：

- Place Photos 是計費 SKU。一個清單 20 筆、一天開 10 次即約每月 6000 次呼叫，逼近免費額度
- 離線直接開天窗，違背本地優先的前提
- 照片是 Places 授權中最嚴格的一項

冷啟動問題改以「允許從相簿挑選既有照片」解決 —— 使用者補記憶中的愛店時，手機相簿裡通常本來就有那家店的照片。此法完全在政策內且離線可用。

## Consequences

照片屬於 Visit 而非 Place，符合 Visit is source of truth。Place 的代表照取自最近一則有照片的 Visit。

儲存壓縮版而非原圖（長邊 1600px、JPEG 0.8，約 300–500KB），透過 SwiftData `@Attribute(.externalStorage)`。原圖本就存在使用者相簿中，TasteMap 只需要顯示用的那張。

`PlaceArtwork` 與 `Place.visualSeed` 保留，降級為無照片時的 fallback。`visualSeed` 是使用者自己的資料，不受 Provider 條款約束。
