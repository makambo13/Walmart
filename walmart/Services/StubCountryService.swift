#if DEBUG
import Foundation

/// Offline feed used by UI tests and scripted simulator runs. It reads the
/// bundled `StubCountries.json` so screens look the same on every run.
actor StubCountryService: CountryServicing {
    private let failFirstLoad: Bool
    private var hasFailed = false

    init(failFirstLoad: Bool = false) {
        self.failFirstLoad = failFirstLoad
    }

    func fetchCountries() async throws -> [Country] {
        try await Task.sleep(for: .milliseconds(400))

        if failFirstLoad, !hasFailed {
            hasFailed = true
            throw CountryServiceError.connectivity("The Internet connection appears to be offline.")
        }

        guard let url = Bundle.main.url(forResource: "StubCountries", withExtension: "json") else {
            throw CountryServiceError.invalidResponse
        }
        return try JSONDecoder().decode([Country].self, from: Data(contentsOf: url))
    }
}
#endif
