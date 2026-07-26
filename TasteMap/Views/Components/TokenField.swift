import SwiftUI

/// Dish 與 Impression 的輸入元件：自由輸入，但優先建議**使用者自己用過的詞**。
///
/// app 刻意不預設一套詞彙 —— 這是自用工具，使用者的語彙就是唯一正確的語彙。
/// 一致性靠這裡的自動補完保證，而不是靠限制資料型別：第一次要打字，之後都是點一下。
/// Dish 與 Impression 各自傳入獨立的 `vocabulary`，不共用。見 CONTEXT.md。
struct TokenField: View {
    let title: String
    let placeholder: String
    let vocabulary: [String]
    @Binding var tokens: [String]

    @State private var draft = ""

    private var suggestions: [String] {
        let query = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let unused = vocabulary.filter { !tokens.contains($0) }
        guard !query.isEmpty else { return Array(unused.prefix(6)) }
        return Array(unused.filter { $0.localizedCaseInsensitiveContains(query) }.prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.headline).foregroundStyle(TasteTheme.ink)

            if !tokens.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(tokens, id: \.self) { token in
                        Button { tokens.removeAll { $0 == token } } label: {
                            HStack(spacing: 5) {
                                Text(token).font(.caption.weight(.semibold))
                                Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, 11).padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(TasteTheme.moss, in: Capsule())
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("移除 \(token)")
                    }
                }
            }

            HStack(spacing: 8) {
                TextField(placeholder, text: $draft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit { commit(draft) }
                if !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button { commit(draft) } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(TasteTheme.moss)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("加入 \(draft)")
                }
            }
            .padding(13)
            .background(.white.opacity(0.55), in: TasteTheme.compactShape)

            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button { commit(suggestion) } label: {
                                Text(suggestion)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 11).padding(.vertical, 7)
                                    .background(TasteTheme.moss.opacity(0.11), in: Capsule())
                                    .foregroundStyle(TasteTheme.mossDark)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }

    private func commit(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        defer { draft = "" }
        guard !trimmed.isEmpty, !tokens.contains(trimmed) else { return }
        tokens.append(trimmed)
    }
}
