import SwiftUI
import UIKit

struct NotificationsDisabledBanner: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)
            Text("Notifications désactivées : aucun rappel ne sera envoyé.")
                .font(.footnote)
                .foregroundStyle(Color.textSecondary)
            Spacer(minLength: 0)
            Button("Réglages", action: openNotificationSettings)
                .font(.footnote.bold())
                .buttonStyle(.borderless)
        }
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        openURL(url)
    }
}
