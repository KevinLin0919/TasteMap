import SwiftUI

enum TasteTheme {
    static let paper = Color(red: 0.957, green: 0.937, blue: 0.902)
    static let paperDeep = Color(red: 0.922, green: 0.886, blue: 0.835)
    static let ink = Color(red: 0.161, green: 0.137, blue: 0.118)
    static let muted = Color(red: 0.478, green: 0.439, blue: 0.404)
    static let moss = Color(red: 0.435, green: 0.502, blue: 0.408)
    static let mossDark = Color(red: 0.322, green: 0.380, blue: 0.302)
    static let clay = Color(red: 0.780, green: 0.427, blue: 0.310)
    static let gold = Color(red: 0.776, green: 0.576, blue: 0.208)

    static let cardShape = RoundedRectangle(cornerRadius: 22, style: .continuous)
    static let compactShape = RoundedRectangle(cornerRadius: 15, style: .continuous)
}

extension View {
    func tasteCard() -> some View {
        self
            .background(.white.opacity(0.62), in: TasteTheme.cardShape)
            .overlay(TasteTheme.cardShape.stroke(TasteTheme.ink.opacity(0.08)))
    }
}
