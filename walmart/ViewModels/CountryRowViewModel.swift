import Foundation

/// Display text for one row of the list.
struct CountryRowViewModel: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let code: String
    let capital: String

    init(country: Country) {
        id = country.code
        title = "\(country.name), \(country.region)"
        code = country.code

        let trimmedCapital = country.capital?.trimmingCharacters(in: .whitespaces) ?? ""
        capital = trimmedCapital.isEmpty ? "N/A" : trimmedCapital
    }
}
