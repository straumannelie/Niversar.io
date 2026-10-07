import SwiftUI

@main
struct NiversarioApp: App {
    @State private var store = BirthdayStore.live()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .preferredColorScheme(.dark)
        }
    }
}
