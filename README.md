# TasteMap

TasteMap 是一款原生 iOS 個人地點日誌。你在 Google Maps 或街上發現的店，去過之後在這裡留下自己的分數與評論 —— 為了日後回憶、決定要不要再去，以及朋友問起時推薦得出來。

寫入優先：整個產品建立在「記錄這件事真的會發生」之上，所以記錄流程被刻意壓到極輕。分享出去的永遠不包含你的私人評論。

職責分工：**Google Maps 管「我想去哪」，TasteMap 管「我去過哪、覺得如何」。**

## 現況

專案目前是一份**設計已重新定案、程式碼尚未跟上**的狀態。`main` 上的實作是初期版本，與現行設計有多處衝突（地點無法新增、Score 尺度、清單寫死、`RevisitIntent` 待移除等）。動工前請先讀 [CONTEXT.md](CONTEXT.md) 與 [ADR](docs/adr/)。

## 開發

專案使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 描述 Xcode project，repository 也會提交生成後的 `TasteMap.xcodeproj`，一般開發者不必先安裝 XcodeGen。

```sh
open TasteMap.xcodeproj
```

核心邏輯可獨立測試：

```sh
cd Packages/TasteMapCore
swift test
```

完整 iOS build 需要 Xcode；Command Line Tools 本身無法提供 iPhone Simulator SDK。

## 下載 CI 產生的 IPA

每次 pull request、`main` push 或手動執行 workflow 時，GitHub Actions 會建立 `TasteMap-unsigned-ipa` artifact，內容包含：

- `TasteMap.ipa`
- `TasteMap.ipa.sha256`

這是未簽章的 device build，用來驗證封裝或交給 AltStore、Sideloadly、Xcode 等工具重新簽名；無法直接安裝到未越獄的 iPhone。正式 TestFlight／App Store IPA 需要 Apple Developer certificate、provisioning profile 與 GitHub secrets。

## 文件

- [詞彙表](CONTEXT.md) —— 領域用語的唯一定義，動工前先讀
- [產品與技術路線](docs/ROADMAP.md) —— 含「明確不做」清單
- [架構原則](docs/ARCHITECTURE.md)
- [架構決策紀錄 (ADR)](docs/adr/) —— 每一個難以反轉的決定與其理由
