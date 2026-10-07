import BirthdayKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(BirthdayKit.appName)
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
    }
}

#Preview {
    ContentView()
}
