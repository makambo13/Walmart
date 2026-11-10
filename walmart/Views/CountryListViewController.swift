import UIKit

final class CountryListViewController: UITableViewController {
    private let viewModel: CountryListViewModel
    private let searchController = UISearchController(searchResultsController: nil)

    /// What the table is showing. It changes only inside `render()`, together
    /// with `reloadData()`, so the table never sees a row count that does not
    /// match its rows while the view model is mid-update.
    private var displayedRows: [CountryRowViewModel] = []

    required init?(coder: NSCoder) {
        viewModel = CountryListViewModel(service: AppEnvironment.makeService())
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Countries"
        tableView.accessibilityIdentifier = "country-list"
        tableView.cellLayoutMarginsFollowReadableWidth = true

        configureSearch()
        configureRefresh()
        observeViewModel()
        reload()
    }

    // MARK: - Setup

    private func configureSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by name or capital"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func configureRefresh() {
        let control = UIRefreshControl()
        control.addAction(UIAction { [weak self, weak control] _ in
            Task { @MainActor in
                await self?.viewModel.load()
                control?.endRefreshing()
            }
        }, for: .valueChanged)
        refreshControl = control
    }

    // MARK: - Rendering

    /// Re-renders whenever something the view model exposes changes.
    private func observeViewModel() {
        withObservationTracking {
            render()
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeViewModel() }
        }
    }

    private func render() {
        displayedRows = viewModel.rows
        tableView.reloadData()
        if let configuration = contentConfiguration() {
            tableView.backgroundView = UIContentUnavailableView(configuration: configuration)
        } else {
            tableView.backgroundView = nil
        }
    }

    private func contentConfiguration() -> UIContentUnavailableConfiguration? {
        guard displayedRows.isEmpty else { return nil }

        switch viewModel.loadState {
        case .idle, .loading:
            return .loading()
        case .failed(let message):
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.image = UIImage(systemName: "wifi.exclamationmark")
            configuration.text = "Couldn't Load Countries"
            configuration.secondaryText = message
            configuration.button = .borderedProminent()
            configuration.button.title = "Retry"
            configuration.buttonProperties.primaryAction = UIAction { [weak self] _ in
                self?.reload()
            }
            return configuration
        case .loaded:
            var configuration = UIContentUnavailableConfiguration.empty()
            if viewModel.isSearching {
                configuration.image = UIImage(systemName: "magnifyingglass")
                configuration.text = "No Results"
                configuration.secondaryText = "No country or capital matches \u{201C}\(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}."
            } else {
                configuration.image = UIImage(systemName: "globe")
                configuration.text = "No Countries"
            }
            return configuration
        }
    }

    private func reload() {
        Task { await viewModel.load() }
    }

    // MARK: - Table view

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedRows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CountryCell.reuseID, for: indexPath)
        (cell as? CountryCell)?.configure(with: displayedRows[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.loadMoreIfNeeded(displayedRow: indexPath.row)
    }
}

extension CountryListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchText = searchController.searchBar.text ?? ""
    }
}
