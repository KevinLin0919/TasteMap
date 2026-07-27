# 記錄分兩段，存檔鈕擋在第三個欄位之前

記錄一次 Visit 分成兩段：第一段只有 Place、Score 與照片，存檔鈕就在這裡；第二段的 Dish、Impression、Note、Pitch 全部可跳過，且可在任何時候回頭補。

## Context

TasteMap 的定位是寫入優先（見 [ADR 0003](0003-sharing-is-plain-text-no-backend.md) 的前提），整個產品建立在「記錄這件事真的會發生」之上。設計過程中欄位從 5 個增加到 7 個，若全部並列於單一表單，吃完飯離開店家的當下不會有人填完，而只要不填，Collection、分享與回憶全部落空。

原則是**降級成功優於完全失敗**：只留下「去過、幾分、一張照片」，Collection 仍排得出來、分享文字仍生得出來、照片仍能喚回記憶。這遠優於因為要填七樣而整筆未記錄。

## Consequences

任何人日後想把某個欄位改成必填，等同推翻此決定，需先取代這份 ADR。

Visit 必須可編輯。現行 `NewVisitSheet` 只能新建，`PlaceDetailView` 的「再記一次」是新增另一筆 Visit 而非修改 —— 若拿它當補欄位的途徑，會污染「去過 N 次」這個指標。

照片提前至第一版，`ROADMAP.md` 將 ImageStore 排在 M4 是錯的。拍照是使用者在店裡本來就會做的事，且是最強的回憶錨點。

`Visit.orderedItems` 自由文字欄由 Dish 完全取代，應移除。
