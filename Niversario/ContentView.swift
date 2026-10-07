import BirthdayKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date.now
        let upcoming = DemoBirthdays.make(today: today, calendar: calendar)
            .upcoming(limit: 2, from: today, in: calendar)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Niversar.io")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.textPrimary)
                ForEach(upcoming) { upcomingBirthday in
                    UpcomingBirthdayCard(upcoming: upcomingBirthday)
                }
            }
            .padding()
        }
        .background(Color.appBackground)
    }
}

#Preview {
    ContentView()
}
