import Foundation
import Testing
@testable import walmart

struct CountryDecodingTests {
    @Test func decodesAFullRecord() throws {
        let json = """
        [{
          "capital": "Kabul", "code": "AF", "name": "Afghanistan", "region": "AS",
          "flag": "https://example.com/afg.svg",
          "currency": {"code": "AFN", "name": "Afghan afghani", "symbol": "؋"},
          "language": {"code": "ps", "name": "Pashto"}
        }]
        """
        let countries = try JSONDecoder().decode([Country].self, from: Data(json.utf8))

        let country = try #require(countries.first)
        #expect(country.name == "Afghanistan")
        #expect(country.region == "AS")
        #expect(country.id == "AF")
        #expect(country.capital == "Kabul")
        #expect(country.flag == URL(string: "https://example.com/afg.svg"))
        #expect(country.currency?.symbol == "؋")
        #expect(country.language?.name == "Pashto")
    }

    @Test func decodesRecordsWithOnlyTheRequiredFields() throws {
        let json = #"[{"code": "AQ", "name": "Antarctica", "region": "AN"}]"#
        let country = try #require(JSONDecoder().decode([Country].self, from: Data(json.utf8)).first)

        #expect(country.capital == nil)
        #expect(country.currency == nil)
        #expect(country.language == nil)
    }

    @Test func ignoresFieldsItDoesNotModel() throws {
        let json = #"[{"code": "JP", "name": "Japan", "region": "AS", "demonym": "Japanese"}]"#
        let countries = try JSONDecoder().decode([Country].self, from: Data(json.utf8))
        #expect(countries.count == 1)
    }

    @Test func rejectsARecordMissingARequiredField() {
        let json = #"[{"code": "JP", "region": "AS"}]"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([Country].self, from: Data(json.utf8))
        }
    }
}
