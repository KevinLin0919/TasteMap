import SwiftUI

struct PlaceRow: View {
    let place: Place

    var body: some View {
        HStack(spacing: 13) {
            PlaceArtwork(place: place, height: 72)
                .frame(width: 78)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(place.name)
                        .font(.system(.headline, design: .serif, weight: .semibold))
                    Spacer()
                    ScoreBadge(score: place.averageScore)
                }
                Text("\(place.district) · \(place.category.rawValue)")
                    .font(.caption)
                    .foregroundStyle(TasteTheme.muted)
                HStack(spacing: 5) {
                    ForEach(place.topTags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .foregroundStyle(TasteTheme.mossDark)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(TasteTheme.moss.opacity(0.11), in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }
}
