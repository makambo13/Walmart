import Foundation
import Observation

/// State and behavior behind the country list: loading, searching and paging.
///
/// The feed arrives as one array, so paging is local: `rows` holds the first
/// `pageSize` matches and grows as the user scrolls.
@MainActor
@Observable
final class CountryListViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var rows: [CountryRowViewModel] = []

    /// Text typed into the search field. Setting it re-filters the list.
    var searchText = "" {
        didSet {
            if searchText != oldValue { applyFilter() }
        }
    }

    private let service: any CountryServicing
    private let pageSize: Int
    private var allCountries: [Country] = []
    private var matches: [Country] = []

    init(service: any CountryServicing, pageSize: Int = 20) {
        self.service = service
        self.pageSize = pageSize
    }

    var isSearching: Bool { !trimmedQuery.isEmpty }
    var hasMoreRows: Bool { rows.count < matches.count }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Fetches the feed. Safe to call again for Retry or pull to refresh; a
    /// call while a load is already running does nothing.
    func load() async {
        guard loadState != .loading else { return }
        let previousState = loadState
        loadState = .loading

        do {
            allCountries = Self.removingDuplicates(try await service.fetchCountries())
            loadState = .loaded
            applyFilter()
        } catch is CancellationError {
            loadState = previousState
        } catch {
            // Keep showing the old list if a refresh fails.
            loadState = allCountries.isEmpty ? .failed(Self.message(for: error)) : .loaded
        }
    }

    /// Call as rows appear. Adds the next page once the user nears the end.
    func loadMoreIfNeeded(displayedRow index: Int) {
        guard hasMoreRows, index >= rows.count - 5 else { return }
        let end = min(rows.count + pageSize, matches.count)
        rows += matches[rows.count..<end].map(CountryRowViewModel.init)
    }

    private func applyFilter() {
        let query = trimmedQuery
        if query.isEmpty {
            matches = allCountries
        } else {
            matches = allCountries.filter {
                $0.name.localizedStandardContains(query)
                    || ($0.capital?.localizedStandardContains(query) ?? false)
            }
        }
        rows = matches.prefix(pageSize).map(CountryRowViewModel.init)
    }

    private static func removingDuplicates(_ countries: [Country]) -> [Country] {
        var seen = Set<String>()
        return countries.filter { seen.insert($0.code).inserted }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
