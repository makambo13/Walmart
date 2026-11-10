import Foundation
import Testing
@testable import walmart

/// Serialized because every test shares `MockURLProtocol`'s static handler.
@Suite(.serialized)
struct CountryServiceTests {
    private let url = URL(string: "https://example.com/countries.json")!

    private func makeService() -> CountryService {
        CountryService(session: MockURLProtocol.makeSession(), url: url)
    }

    private func respond(status: Int = 200, body: String) {
        let url = url
        MockURLProtocol.handler = { _ in
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }
    }

    @Test func returnsDecodedCountries() async throws {
        respond(body: #"[{"code": "JP", "name": "Japan", "region": "AS", "capital": "Tokyo"}]"#)

        let countries = try await makeService().fetchCountries()

        #expect(countries.map(\.name) == ["Japan"])
    }

    @Test func sendsAJSONGetRequestToTheConfiguredURL() async throws {
        respond(body: "[]")

        _ = try await makeService().fetchCountries()

        let request = try #require(MockURLProtocol.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.url == url)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test(arguments: [404, 500, 503])
    func reportsHTTPErrors(status: Int) async {
        respond(status: status, body: "")

        await #expect(throws: CountryServiceError.httpStatus(status)) {
            try await makeService().fetchCountries()
        }
    }

    @Test func reportsMalformedJSONAsADecodingError() async {
        respond(body: "{ not json")

        await #expect(throws: CountryServiceError.decoding) {
            try await makeService().fetchCountries()
        }
    }

    @Test func reportsAJSONShapeMismatchAsADecodingError() async {
        respond(body: #"{"countries": []}"#)

        await #expect(throws: CountryServiceError.decoding) {
            try await makeService().fetchCountries()
        }
    }

    @Test func mapsTransportFailuresToConnectivityErrors() async {
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

        await #expect {
            try await makeService().fetchCountries()
        } throws: { error in
            guard case CountryServiceError.connectivity = error else { return false }
            return true
        }
    }

    @Test func errorsHaveReadableDescriptions() {
        #expect(CountryServiceError.httpStatus(404).errorDescription?.contains("404") == true)
        #expect(CountryServiceError.decoding.errorDescription?.isEmpty == false)
    }
}
