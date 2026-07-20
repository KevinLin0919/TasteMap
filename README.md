# TasteMap

TasteMap 是一款原生 iOS 個人地點日誌：保存每次造訪，而不是覆蓋店家總評；用自己的分數、情境與筆記，在需要時找回真正適合的地方。

## Milestone 1

- SwiftUI + SwiftData，iOS 17+
- 足跡、地圖、清單、搜尋四個頂層區域
- Tab Bar 中央「記錄」主要動作
- 多次 Visit、小數評分、再訪意願、標籤與私人筆記
- 本地搜尋與排名核心（獨立 Swift Package，含測試）
- 離線 seed data，尚未連接 Google Places 或 VPS

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

- [產品與技術路線](docs/ROADMAP.md)
- [架構決策](docs/ARCHITECTURE.md)
