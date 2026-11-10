import Foundation

/// A country as published by the countries feed.
struct Country: Codable, Hashable, Sendable, Identifiable {
    let name: String
    let region: String
    let code: String
    let capital: String?
    let flag: URL?
    let currency: Currency?
    let language: Language?

    var id: String { code }

    struct Currency: Codable, Hashable, Sendable {
        let code: String?
        let name: String?
        let symbol: String?
    }

    struct Language: Codable, Hashable, Sendable {
        let code: String?
        let name: String?
    }
}
