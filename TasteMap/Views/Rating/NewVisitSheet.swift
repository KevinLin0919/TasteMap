import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import TasteMapCore

/// 記錄一次造訪，分兩段。
///
/// 第一段只有 Place、Score 與照片，儲存鈕永遠在螢幕底部可按；第二段的 Dish、
/// Impression、Note、Pitch 全部可跳過，之後隨時回來補。整個產品建立在「記錄
/// 這件事真的會發生」之上 —— 吃完飯離開店家的當下沒有人會填完七個欄位，而只要
/// 不填，Collection、分享與回憶全部落空。**降級成功優於完全失敗。** 見 ADR 0005。
///
/// 任何人想把某個欄位改成必填，等同推翻該 ADR，請先取代它。
struct NewVisitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Place.name) private var places: [Place]
    @Query private var allVisits: [Visit]

    private let editing: Visit?
    private let initialPlace: Place?

    @State private var selectedPlace: Place?
    @State private var score = ScoreCalculator.defaultScore
    @State private var photo: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var dishes: [String] = []
    @State private var impressions: [String] = []
    @State private var note = ""
    @State private var pitch = ""
    @State private var hasLoaded = false

    init(initialPlace: Place? = nil) {
        self.initialPlace = initialPlace
        self.editing = nil
    }

    /// 編輯既有的 Visit。補欄位必須走這裡 —— 用「再記一次」新增另一筆會污染
    /// 「去過 N 次」，而那是取代 RevisitIntent 的核心指標。
    init(editing visit: Visit) {
        self.editing = visit
        self.initialPlace = visit.place
    }

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 21) {
                    placePicker
                    scoreControl
                    photoControl

                    optionalDivider

                    TokenField(
                        title: "點了什麼",
                        placeholder: "例如：綠咖哩",
                        vocabulary: vocabulary(\.dishes),
                        tokens: $dishes
                    )
                    TokenField(
                        title: "留下印象",
                        placeholder: "例如：適合工作",
                        vocabulary: vocabulary(\.impressions),
                        tokens: $impressions
                    )
                    noteControl
                    pitchControl
                }
                .padding(20)
                .padding(.bottom, 90)
            }
            .background(TasteTheme.paper)
            .navigationTitle(isEditing ? "編輯這次造訪" : "記錄一次造訪")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) { saveBar }
        }
        .task { loadOnce() }
    }

    // MARK: - 第一段

    private var placePicker: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("地點").font(.headline).foregroundStyle(TasteTheme.ink)
            Menu {
                ForEach(places) { place in
                    Button { selectedPlace = place } label: {
                        Label(place.name, systemImage: place.symbolName)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedPlace?.symbolName ?? "mappin")
                        .foregroundStyle(TasteTheme.clay)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedPlace?.name ?? "選擇地點")
                            .font(.headline).foregroundStyle(TasteTheme.ink)
                        if let selectedPlace {
                            Text(selectedPlace.summary)
                                .font(.caption).foregroundStyle(TasteTheme.muted)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption).foregroundStyle(TasteTheme.muted)
                }
                .padding(15).tasteCard()
            }
            .buttonStyle(.plain)
        }
    }

    private var scoreControl: some View {
        VStack(spacing: 7) {
            Text("這次感覺如何？").font(.caption).foregroundStyle(TasteTheme.muted)
            // 分母寫出來，「4.3」才不需要猜滿分是多少 —— 分享出去時同理。見 ADR 0004。
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(score, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 58, weight: .semibold, design: .serif))
                    .foregroundStyle(TasteTheme.gold).monospacedDigit()
                Text("/ 5")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(TasteTheme.gold.opacity(0.55))
            }
            Text(ScoreCalculator.label(for: score))
                .font(.subheadline.weight(.semibold)).foregroundStyle(TasteTheme.ink)
            Slider(value: $score, in: ScoreCalculator.range, step: 0.1)
                .tint(TasteTheme.moss)
                .accessibilityValue(score.formatted(.number.precision(.fractionLength(1))))
            HStack {
                Text(ScoreCalculator.range.lowerBound, format: .number.precision(.fractionLength(1)))
                Spacer()
                Text(ScoreCalculator.range.upperBound, format: .number.precision(.fractionLength(1)))
            }
            .font(.caption2).foregroundStyle(TasteTheme.muted)
        }
        .padding(17)
        .background(
            LinearGradient(
                colors: [TasteTheme.gold.opacity(0.12), .white.opacity(0.56)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: TasteTheme.cardShape
        )
    }

    /// 照片放在第一段，因為拍照是使用者在店裡本來就會做的事（不是額外負擔，是把
    /// 已經拍的挑一張），而且它是最強的回憶錨點。只用自己的照片，見 ADR 0007。
    private var photoControl: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("留一張照片").font(.headline).foregroundStyle(TasteTheme.ink)
                Spacer()
                if photo != nil {
                    Button("移除") { photo = nil; photoItem = nil }
                        .font(.caption.weight(.semibold)).foregroundStyle(TasteTheme.clay)
                }
            }
            PhotosPicker(selection: $photoItem, matching: .images) {
                Group {
                    if let photo, let image = UIImage(data: photo) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        VStack(spacing: 7) {
                            Image(systemName: "photo.badge.plus").font(.system(size: 27, weight: .light))
                            Text("拍新的，或從相簿挑一張").font(.caption)
                        }
                        .foregroundStyle(TasteTheme.muted)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 168)
                .background(.white.opacity(0.55))
                .clipShape(TasteTheme.cardShape)
            }
            .buttonStyle(.plain)
        }
        .onChange(of: photoItem) { _, item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self) else { return }
                photo = PhotoStore.compressed(data)
            }
        }
    }

    // MARK: - 第二段

    private var optionalDivider: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().padding(.bottom, 4)
            Text("以下都可以之後再補")
                .font(.caption.weight(.bold)).foregroundStyle(TasteTheme.mossDark)
            Text("現在按「\(saveTitle)」就能離開，之後點造訪紀錄隨時回來補齊。")
                .font(.caption2).foregroundStyle(TasteTheme.muted)
        }
        .padding(.top, 2)
    }

    private var noteControl: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("留給未來自己的一句話").font(.headline).foregroundStyle(TasteTheme.ink)
            Text("永遠不會出現在分享裡。")
                .font(.caption2).foregroundStyle(TasteTheme.muted)
            TextField("例如：平日下午很安靜，靠窗第二桌有插座。", text: $note, axis: .vertical)
                .lineLimit(3...6)
                .padding(13)
                .background(.white.opacity(0.55), in: TasteTheme.compactShape)
        }
    }

    private var pitchControl: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("推薦給朋友時會說什麼").font(.headline).foregroundStyle(TasteTheme.ink)
            Text("這句話會跟著分享出去。")
                .font(.caption2).foregroundStyle(TasteTheme.muted)
            TextField("例如：綠咖哩必點，烤雞可以跳過。", text: $pitch, axis: .vertical)
                .lineLimit(2...4)
                .padding(13)
                .background(.white.opacity(0.55), in: TasteTheme.compactShape)
        }
    }

    // MARK: - 儲存

    private var saveTitle: String { isEditing ? "儲存修改" : "儲存這次造訪" }

    private var saveBar: some View {
        Button(action: save) {
            Label(saveTitle, systemImage: "checkmark")
                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(
            selectedPlace == nil ? TasteTheme.muted : TasteTheme.ink,
            in: RoundedRectangle(cornerRadius: 17, style: .continuous)
        )
        .disabled(selectedPlace == nil)
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func save() {
        guard let selectedPlace else { return }
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPitch = pitch.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editing {
            editing.place = selectedPlace
            editing.score = score
            editing.photo = photo
            editing.dishes = dishes
            editing.impressions = impressions
            editing.note = cleanNote
            editing.pitch = cleanPitch
        } else {
            let visit = Visit(
                score: score,
                impressions: impressions,
                dishes: dishes,
                note: cleanNote,
                pitch: cleanPitch,
                photo: photo,
                place: selectedPlace
            )
            selectedPlace.visits.append(visit)
            modelContext.insert(visit)
        }

        try? modelContext.save()
        dismiss()
    }

    // MARK: - 輔助

    /// 建議詞按使用頻率排序 —— 你最常用的詞應該最先跳出來。
    private func vocabulary(_ key: KeyPath<Visit, [String]>) -> [String] {
        let counts = allVisits
            .flatMap { $0[keyPath: key] }
            .reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        return counts
            .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .map(\.key)
    }

    private func loadOnce() {
        guard !hasLoaded else { return }
        hasLoaded = true

        if let editing {
            selectedPlace = editing.place
            score = editing.score
            photo = editing.photo
            dishes = editing.dishes
            impressions = editing.impressions
            note = editing.note
            pitch = editing.pitch
        } else {
            selectedPlace = initialPlace ?? places.first
        }
    }
}
