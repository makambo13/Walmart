import Foundation

/// Anything that can supply the list of countries. The app uses the network
/// implementation; tests and UI tests substitute their own.
protocol CountryServicing: Sendable {
    func fetchCountries() async throws -> [Country]
}

/// Failures the list screen knows how to explain to a person.
enum CountryServiceError: Error, Equatable, LocalizedError {
    case connectivity(String)
    case invalidResponse
    case httpStatus(Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .connectivity(let reason):
            "The network request failed: \(reason)"
        case .invalidResponse:
            "The server sent a response the app could not read."
        case .httpStatus(let code):
            "The server answered with HTTP status \(code)."
        case .decoding:
            "The country data was not in the expected format."
        }
    }
}

struct CountryService: CountryServicing {
    static let defaultURL = URL(string: "https://gist.githubusercontent.com/peymano-wmt/32dcb892b06648910ddd40406e37fdab/raw/db25946fd77c5873b0303b858e861ce724e0dcd0/")!

    private let session: URLSession
    private let url: URL

    init(session: URLSession = .shared, url: URL = CountryService.defaultURL) {
        self.session = session
        self.url = url
    }

    func fetchCountries() async throws -> [Country] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code != .cancelled {
            throw CountryServiceError.connectivity(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw CountryServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CountryServiceError.httpStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode([Country].self, from: data)
        } catch {
            throw CountryServiceError.decoding
        }
    }
}
