import SwiftUI

struct PlaceArtwork: View {
    let place: Place
    var height: CGFloat = 120

    private var palette: [Color] {
        switch place.visualSeed % 4 {
        case 0: [Color(red: 0.76, green: 0.70, blue: 0.62), TasteTheme.moss]
        case 1: [Color(red: 0.93, green: 0.88, blue: 0.79), TasteTheme.clay]
        case 2: [Color(red: 0.13, green: 0.13, blue: 0.12), Color(red: 0.55, green: 0.39, blue: 0.27)]
        default: [Color(red: 0.55, green: 0.68, blue: 0.68), Color(red: 0.67, green: 0.54, blue: 0.40)]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.white.opacity(0.25)).frame(width: 90).offset(x: 60, y: -35)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.white.opacity(0.83))
                .frame(width: 55, height: 42)
                .overlay(alignment: .top) {
                    Capsule().fill(TasteTheme.ink.opacity(0.68)).frame(width: 43, height: 9).offset(y: 5)
                }
                .overlay(alignment: .trailing) {
                    Circle().stroke(.white.opacity(0.85), lineWidth: 5).frame(width: 24).offset(x: 15)
                }
                .offset(x: 8, y: 25)
            Image(systemName: place.category.symbol)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
                .offset(x: -60, y: -35)
        }
        .frame(height: height)
        .clipped()
        .accessibilityHidden(true)
    }
}

struct ScoreBadge: View {
    let score: Double
    var body: some View {
        Text(score, format: .number.precision(.fractionLength(1)))
            .font(.system(.title3, design: .serif, weight: .bold))
            .foregroundStyle(TasteTheme.gold)
            .monospacedDigit()
    }
}
