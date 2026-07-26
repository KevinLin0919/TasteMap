import Foundation
import UIKit

/// 照片一律存壓縮版，不存原圖 —— 原圖本來就在使用者的相簿裡，
/// TasteMap 只需要顯示用的那張。見 ADR 0007。
enum PhotoStore {
    /// 長邊上限。一百筆記錄約 50MB，對本機資料庫是合理的量級。
    static let maxDimension: CGFloat = 1600
    static let compressionQuality: CGFloat = 0.8

    static func compressed(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxDimension else {
            return image.jpegData(compressionQuality: compressionQuality)
        }

        let ratio = maxDimension / longestSide
        let target = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)

        // scale 必須明確設為 1，否則 renderer 會套用裝置的 @3x，
        // 產出的點陣尺寸是我們要求的三倍。
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: compressionQuality)
    }
}
