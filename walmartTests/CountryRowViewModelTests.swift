import Testing
@testable import walmart

struct CountryRowViewModelTests {
    @Test func combinesNameAndRegionIntoTheTitle() {
        let row = CountryRowViewModel(country: .sample("Japan", code: "JP", region: "AS", capital: "Tokyo"))

        #expect(row.title == "Japan, AS")
        #expect(row.code == "JP")
        #expect(row.capital == "Tokyo")
        #expect(row.id == "JP")
    }

    @Test(arguments: [nil, "", "   "] as [String?])
    func showsNotAvailableWhenThereIsNoCapital(capital: String?) {
        let row = CountryRowViewModel(country: .sample("Macao", code: "MO", capital: capital))
        #expect(row.capital == "N/A")
    }
}
