import SwiftUI
import SwiftData

@main
struct HookApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Capo.self, Outfit.self])
    }
}
