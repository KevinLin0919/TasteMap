import SwiftData
import SwiftUI
import TasteMapCore

struct NewVisitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Place.name) private var places: [Place]

    private let initialPlace: Place?
    @State private var selectedPlace: Place?
    @State private var score = 8.5
    @State private var revisitIntent = RevisitIntent.definitely
    @State private var selectedTags: Set<String> = []
    @State private var note = ""
    @State private var orderedItems = ""

    private let tags = ["咖啡好喝", "適合工作", "安靜", "有插座", "座位舒服", "適合聊天", "甜點不錯", "價格偏高"]

    init(initialPlace: Place? = nil) {
        self.initialPlace = initialPlace
        _selectedPlace = State(initialValue: initialPlace)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 21) {
                    placePicker
                    scoreControl
                    revisitControl
                    tagControl
                    noteControl
                }
                .padding(20)
                .padding(.bottom, 86)
            }
            .background(TasteTheme.paper)
            .navigationTitle("記錄一次造訪")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Label("儲存這次造訪", systemImage: "checkmark")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(selectedPlace == nil ? TasteTheme.muted : TasteTheme.ink, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .disabled(selectedPlace == nil)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
        .onAppear { selectedPlace = selectedPlace ?? initialPlace ?? places.first }
    }

    private var placePicker: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("地點").font(.headline)
            Menu {
                ForEach(places) { place in
                    Button { selectedPlace = place } label: {
                        Label(place.name, systemImage: place.category.symbol)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedPlace?.category.symbol ?? "mappin")
                        .foregroundStyle(TasteTheme.clay)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedPlace?.name ?? "選擇地點").font(.headline)
                        if let selectedPlace { Text("\(selectedPlace.district) · \(selectedPlace.category.rawValue)").font(.caption).foregroundStyle(TasteTheme.muted) }
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(TasteTheme.muted)
                }
                .padding(15).tasteCard()
            }
            .buttonStyle(.plain)
        }
    }

    private var scoreControl: some View {
        VStack(spacing: 7) {
            Text("這次感覺如何？").font(.caption).foregroundStyle(TasteTheme.muted)
            Text(score, format: .number.precision(.fractionLength(1)))
                .font(.system(size: 58, weight: .semibold, design: .serif))
                .foregroundStyle(TasteTheme.gold).monospacedDigit()
            Text(ScoreCalculator.label(for: score)).font(.subheadline.weight(.semibold))
            Slider(value: $score, in: 5...10, step: 0.1)
                .tint(TasteTheme.moss)
                .accessibilityValue(score.formatted(.number.precision(.fractionLength(1))))
            HStack { Text("5.0"); Spacer(); Text("普通"); Spacer(); Text("10.0") }
                .font(.caption2).foregroundStyle(TasteTheme.muted)
        }
        .padding(17)
        .background(LinearGradient(colors: [TasteTheme.gold.opacity(0.12), .white.opacity(0.56)], startPoint: .topLeading, endPoint: .bottomTrailing), in: TasteTheme.cardShape)
    }

    private var revisitControl: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("你會再去嗎？").font(.headline)
            Picker("再訪意願", selection: $revisitIntent) {
                ForEach(RevisitIntent.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var tagControl: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack { Text("留下最多三個印象").font(.headline); Spacer(); Text("\(selectedTags.count) / 3").font(.caption).foregroundStyle(TasteTheme.muted) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        if selectedTags.contains(tag) { selectedTags.remove(tag) }
                        else if selectedTags.count < 3 { selectedTags.insert(tag) }
                    } label: {
                        Text(tag).font(.caption.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedTags.contains(tag) ? .white : TasteTheme.muted)
                    .background(selectedTags.contains(tag) ? TasteTheme.moss : .white.opacity(0.55), in: Capsule())
                }
            }
        }
    }

    private var noteControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                Text("點了什麼").font(.headline)
                TextField("例如：拿鐵、焦糖布丁", text: $orderedItems)
                    .padding(13).background(.white.opacity(0.55), in: TasteTheme.compactShape)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text("留給未來自己的一句話").font(.headline)
                TextField("例如：平日下午很安靜，靠窗第二桌有插座。", text: $note, axis: .vertical)
                    .lineLimit(3...6).padding(13).background(.white.opacity(0.55), in: TasteTheme.compactShape)
            }
        }
    }

    private func save() {
        guard let selectedPlace else { return }
        let visit = Visit(score: score, revisitIntent: revisitIntent, tags: selectedTags.sorted(), note: note.trimmingCharacters(in: .whitespacesAndNewlines), orderedItems: orderedItems.trimmingCharacters(in: .whitespacesAndNewlines), place: selectedPlace)
        selectedPlace.visits.append(visit)
        modelContext.insert(visit)
        try? modelContext.save()
        dismiss()
    }
}
