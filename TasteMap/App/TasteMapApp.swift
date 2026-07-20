import SwiftData
import SwiftUI

@main
struct TasteMapApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Place.self, Visit.self)
        } catch {
            fatalError("Unable to create TasteMap database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .task { SeedData.insertIfNeeded(into: container.mainContext) }
        }
    }
}
