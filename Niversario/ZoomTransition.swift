import BirthdayKit
import SwiftUI

enum ZoomSource: Hashable {
    case card(UUID)
    case day(CalendarMonth, Int)
    case row(UUID)
}

extension View {
    func zoomTransition(from source: ZoomSource, in namespace: Namespace.ID) -> some View {
        modifier(ZoomTransition(source: source, namespace: namespace))
    }
}

private struct ZoomTransition: ViewModifier {
    let source: ZoomSource
    let namespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.navigationTransition(.zoom(sourceID: source, in: namespace))
        }
    }
}
