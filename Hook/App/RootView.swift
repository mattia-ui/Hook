import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            OggiView()
                .tabItem { Label("Oggi", systemImage: "sun.max") }
            ArmadioView()
                .tabItem { Label("Armadio", systemImage: "hanger") }
            OutfitListView()
                .tabItem { Label("Outfit", systemImage: "rectangle.stack") }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
