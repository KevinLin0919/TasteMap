import CoreLocation

/// 取得一次目前位置。
///
/// 用 `CLLocationUpdate.liveUpdates()` 而非 delegate —— 它本身就是 async 序列，
/// 授權提示也由系統處理，不必自己搬 delegate 回呼跨越 actor 邊界。
///
/// 拿不到位置一律回 nil 而不丟錯：附近查詢是**加速用的捷徑**，不是必要路徑。
/// 使用者拒絕定位時，打字搜尋照常運作。
enum CurrentLocation {
    static func fetch() async -> CLLocationCoordinate2D? {
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if update.authorizationDenied || update.authorizationDeniedGlobally {
                    return nil
                }
                if let location = update.location {
                    return location.coordinate
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}
