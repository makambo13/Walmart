import Foundation
import Testing
@testable import walmart

@MainActor
struct CountryListViewModelTests {
    private func makeViewModel(
        countries: [Country] = Country.samples(count: 50),
        pageSize: Int = 20
    ) -> (CountryListViewModel, MockCountryService) {
        let service = MockCountryService(results: [.success(countries)])
        return (CountryListViewModel(service: service, pageSize: pageSize), service)
    }

    // MARK: Loading

    @Test func startsIdleAndEmpty() {
        let (viewModel, _) = makeViewModel()

        #expect(viewModel.loadState == .idle)
        #expect(viewModel.rows.isEmpty)
    }

    @Test func loadShowsTheFirstPageOnly() async {
        let (viewModel, _) = makeViewModel()

        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.rows.count == 20)
        #expect(viewModel.rows.first?.title == "Country 00, EU")
        #expect(viewModel.hasMoreRows)
    }

    @Test func anEmptyFeedLoadsWithNoRows() async {
        let (viewModel, _) = makeViewModel(countries: [])

        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.rows.isEmpty)
        #expect(!viewModel.isSearching)
    }

    @Test func duplicateCodesAreShownOnce() async {
        let countries = [Country.sample("One", code: "AA"), .sample("One again", code: "AA"), .sample("Two", code: "BB")]
        let (viewModel, _) = makeViewModel(countries: countries)

        await viewModel.load()

        #expect(viewModel.rows.map(\.id) == ["AA", "BB"])
    }

    @Test func aSecondLoadWhileLoadingIsIgnored() async {
        let service = MockCountryService(results: [.success(Country.samples(count: 3))], delay: .milliseconds(150))
        let viewModel = CountryListViewModel(service: service)

        async let first: Void = viewModel.load()
        try? await Task.sleep(for: .milliseconds(30))
        #expect(viewModel.loadState == .loading)
        await viewModel.load()
        await first

        #expect(await service.callCount == 1)
        #expect(viewModel.rows.count == 3)
    }

    // MARK: Failure and retry

    @Test func aFailedFirstLoadReportsTheReason() async {
        let service = MockCountryService(results: [.failure(CountryServiceError.httpStatus(500))])
        let viewModel = CountryListViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.loadState == .failed(CountryServiceError.httpStatus(500).errorDescription!))
        #expect(viewModel.rows.isEmpty)
    }

    @Test func retryAfterAFailureLoadsTheList() async {
        let service = MockCountryService(results: [
            .failure(CountryServiceError.connectivity("offline")),
            .success(Country.samples(count: 5)),
        ])
        let viewModel = CountryListViewModel(service: service)

        await viewModel.load()
        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.rows.count == 5)
        #expect(await service.callCount == 2)
    }

    @Test func aFailedRefreshKeepsTheListThatIsAlreadyShown() async {
        let service = MockCountryService(results: [
            .success(Country.samples(count: 5)),
            .failure(CountryServiceError.connectivity("offline")),
        ])
        let viewModel = CountryListViewModel(service: service)

        await viewModel.load()
        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.rows.count == 5)
    }

    // MARK: Paging

    @Test func scrollingNearTheEndAddsTheNextPage() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.load()

        viewModel.loadMoreIfNeeded(displayedRow: 19)
        #expect(viewModel.rows.count == 40)

        viewModel.loadMoreIfNeeded(displayedRow: 39)
        #expect(viewModel.rows.count == 50)
        #expect(!viewModel.hasMoreRows)
    }

    @Test func scrollingAtTheTopDoesNotAddRows() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.load()

        viewModel.loadMoreIfNeeded(displayedRow: 3)

        #expect(viewModel.rows.count == 20)
    }

    @Test func pagingNeverRepeatsOrSkipsARow() async {
        let (viewModel, _) = makeViewModel(countries: Country.samples(count: 47), pageSize: 10)
        await viewModel.load()
        while viewModel.hasMoreRows {
            viewModel.loadMoreIfNeeded(displayedRow: viewModel.rows.count - 1)
        }

        #expect(viewModel.rows.map(\.id) == Country.samples(count: 47).map(\.id))
    }

    // MARK: Search

    private func searchableCountries() -> [Country] {
        [
            .sample("Japan", code: "JP", capital: "Tokyo"),
            .sample("Jordan", code: "JO", capital: "Amman"),
            .sample("Côte d'Ivoire", code: "CI", capital: "Yamoussoukro"),
            .sample("Brazil", code: "BR", capital: "Brasília"),
            .sample("Macao", code: "MO", capital: nil),
        ]
    }

    @Test func searchMatchesNamesIgnoringCaseAndPunctuation() async {
        let (viewModel, _) = makeViewModel(countries: searchableCountries())
        await viewModel.load()

        viewModel.searchText = "JAP"

        #expect(viewModel.rows.map(\.id) == ["JP"])
    }

    @Test func searchMatchesCapitals() async {
        let (viewModel, _) = makeViewModel(countries: searchableCountries())
        await viewModel.load()

        viewModel.searchText = "amman"

        #expect(viewModel.rows.map(\.id) == ["JO"])
    }

    @Test func searchIgnoresAccents() async {
        let (viewModel, _) = makeViewModel(countries: searchableCountries())
        await viewModel.load()

        viewModel.searchText = "cote"
        #expect(viewModel.rows.map(\.id) == ["CI"])

        viewModel.searchText = "brasilia"
        #expect(viewModel.rows.map(\.id) == ["BR"])
    }

    @Test func searchIgnoresSurroundingWhitespace() async {
        let (viewModel, _) = makeViewModel(countries: searchableCountries())
        await viewModel.load()

        viewModel.searchText = "  japan  "

        #expect(viewModel.rows.map(\.id) == ["JP"])
    }

    @Test func aSearchWithNoMatchGivesAnEmptyLoadedList() async {
        let (viewModel, _) = makeViewModel(countries: searchableCountries())
        await viewModel.load()

        viewModel.searchText = "zzz"

        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.isSearching)
        #expect(viewModel.loadState == .loaded)
    }

    @Test func clearingTheSearchRestoresTheFirstPage() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.load()

        viewModel.searchText = "Country 07"
        #expect(viewModel.rows.count == 1)

        viewModel.searchText = ""
        #expect(viewModel.rows.count == 20)
        #expect(!viewModel.isSearching)
    }

    @Test func searchResultsPageToo() async {
        let (viewModel, _) = makeViewModel(countries: Country.samples(count: 50), pageSize: 10)
        await viewModel.load()

        viewModel.searchText = "Country"
        #expect(viewModel.rows.count == 10)

        viewModel.loadMoreIfNeeded(displayedRow: 9)
        #expect(viewModel.rows.count == 20)
    }

    @Test func searchingBeforeTheFeedLoadsIsAppliedWhenItArrives() async {
        let (viewModel, _) = makeViewModel(countries: searchableCountries())
        viewModel.searchText = "japan"

        await viewModel.load()

        #expect(viewModel.rows.map(\.id) == ["JP"])
    }
}
