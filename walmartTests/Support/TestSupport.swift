import Foundation
@testable import walmart

extension Country {
    static func sample(
        _ name: String,
        code: String? = nil,
        region: String = "EU",
        capital: String? = "Capital"
    ) -> Country {
        Country(
            name: name,
            region: region,
            code: code ?? String(name.prefix(2)).uppercased(),
            capital: capital,
            flag: nil,
            currency: nil,
            language: nil
        )
    }

    /// `count` countries named "Country 00", "Country 01", ... with unique codes.
    static func samples(count: Int) -> [Country] {
        (0..<count).map { index in
            let label = String(format: "%02d", index)
            return .sample("Country \(label)", code: "C\(label)", capital: "City \(label)")
        }
    }
}

/// Service double: returns queued results one per call and counts calls.
actor MockCountryService: CountryServicing {
    private var results: [Result<[Country], Error>]
    private(set) var callCount = 0
    private let delay: Duration?

    init(results: [Result<[Country], Error>], delay: Duration? = nil) {
        self.results = results
        self.delay = delay
    }

    func fetchCountries() async throws -> [Country] {
        callCount += 1
        if let delay { try await Task.sleep(for: delay) }
        guard !results.isEmpty else { return [] }
        let next = results.count > 1 ? results.removeFirst() : results[0]
        return try next.get()
    }
}

/// Intercepts a URLSession so service tests never touch the network.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    nonisolated(unsafe) static var handler: Handler?
    nonisolated(unsafe) static var lastRequest: URLRequest?

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
