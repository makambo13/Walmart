import UIKit

/// Prototype cell from `Main.storyboard`.
@MainActor
final class CountryCell: UITableViewCell {
    static let reuseID = "CountryCell"

    @IBOutlet private weak var nameAndRegion: UILabel!
    @IBOutlet private weak var capital: UILabel!
    @IBOutlet private weak var code: UILabel!

    func configure(with row: CountryRowViewModel) {
        capital.textColor = .secondaryLabel
        code.textColor = .secondaryLabel
        nameAndRegion.text = row.title
        capital.text = row.capital
        code.text = row.code

        // One VoiceOver element per row, and a stable id for UI tests.
        isAccessibilityElement = true
        accessibilityIdentifier = "country-\(row.id)"
        accessibilityLabel = "\(row.title), code \(row.code), capital \(row.capital)"
    }
}
