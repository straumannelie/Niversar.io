import BirthdayKit
import SwiftUI
import UIKit

struct BirthDateWheels: UIViewRepresentable {
    @Binding var day: Int
    @Binding var month: Int
    @Binding var year: Int?
    let years: [Int]

    private static let monthNames: [String] = {
        let locale = Locale(identifier: "fr_FR")
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar.standaloneMonthSymbols.map { $0.capitalized(with: locale) }
    }()

    func makeCoordinator() -> Coordinator {
        Coordinator(wheels: self)
    }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = ResizingPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return picker
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        context.coordinator.wheels = self
        picker.reloadComponent(Column.day.rawValue)
        select(row: min(day, BirthDate.maximumDay(inMonth: month)) - 1, in: .day, of: picker)
        select(row: month - 1, in: .month, of: picker)
        select(row: yearRow, in: .year, of: picker)
    }

    private var yearRow: Int {
        guard let year, let index = years.firstIndex(of: year) else { return 0 }
        return index + 1
    }

    private func select(row: Int, in column: Column, of picker: UIPickerView) {
        guard picker.selectedRow(inComponent: column.rawValue) != row else { return }
        picker.selectRow(row, inComponent: column.rawValue, animated: false)
    }

    enum Column: Int, CaseIterable {
        case day
        case month
        case year

        var widthFraction: CGFloat {
            switch self {
            case .day: 0.2
            case .month: 0.42
            case .year: 0.33
            }
        }
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var wheels: BirthDateWheels

        init(wheels: BirthDateWheels) {
            self.wheels = wheels
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            Column.allCases.count
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch Column(rawValue: component) {
            case .day: BirthDate.maximumDay(inMonth: wheels.month)
            case .month: BirthDateWheels.monthNames.count
            case .year: wheels.years.count + 1
            case nil: 0
            }
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            pickerView.bounds.width * (Column(rawValue: component)?.widthFraction ?? 0)
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            UIFont.preferredFont(forTextStyle: .title3).lineHeight + 12
        }

        func pickerView(
            _ pickerView: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let label = (view as? UILabel) ?? Self.makeRowLabel()
            label.text = title(forRow: row, in: Column(rawValue: component))
            return label
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch Column(rawValue: component) {
            case .day:
                wheels.day = row + 1
            case .month:
                let month = row + 1
                wheels.month = month
                wheels.day = min(wheels.day, BirthDate.maximumDay(inMonth: month))
            case .year:
                let index = row - 1
                wheels.year = wheels.years.indices.contains(index) ? wheels.years[index] : nil
            case nil:
                break
            }
        }

        private func title(forRow row: Int, in column: Column?) -> String {
            switch column {
            case .day:
                return String(row + 1)
            case .month:
                return BirthDateWheels.monthNames.indices.contains(row) ? BirthDateWheels.monthNames[row] : ""
            case .year:
                let index = row - 1
                return wheels.years.indices.contains(index) ? String(wheels.years[index]) : "Sans année"
            case nil:
                return ""
            }
        }

        private static func makeRowLabel() -> UILabel {
            let label = UILabel()
            label.font = .preferredFont(forTextStyle: .title3)
            label.adjustsFontForContentSizeCategory = true
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.6
            label.textAlignment = .center
            label.textColor = UIColor(resource: .textPrimary)
            return label
        }
    }
}

private final class ResizingPickerView: UIPickerView {
    private var lastLaidOutWidth: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width != lastLaidOutWidth else { return }
        lastLaidOutWidth = bounds.width
        reloadAllComponents()
    }
}
