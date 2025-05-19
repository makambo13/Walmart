//
//  ViewController.swift
//  walmart
//
//  Created by Makambo Yemomo on 5/15/25.
//

//
//  ViewController.swift
//  walmart
//
//  Created by Makambo Yemomo on 5/15/25.
//

import UIKit

class CountryListViewController: UITableViewController, UISearchBarDelegate {
    private let viewModel = CountryListViewModel()
    private var isInitialLoad = true
    
    private let searchController = UISearchController(searchResultsController: nil)
      private var isSearchBarEmpty: Bool {
          return searchController.searchBar.text?.isEmpty ?? true
      }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Countries"
        setupSearchController()
        setupTableView()
        setupBindings()
        viewModel.loadCountries()
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Countries"
        
        searchController.searchBar.searchTextField.backgroundColor = .systemGray6
        searchController.searchBar.searchTextField.textColor = .label
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 130
        tableView.backgroundView = createEmptyStateView(message: "Loading...")
    }

    private func setupBindings() {
        viewModel.onUpdate = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if self.viewModel.cellViewModels.isEmpty {
                    self.showEmptyState(message: "No data available")
                } else {
                    self.hideEmptyState()
                }

                self.isInitialLoad = false
                self.tableView.reloadData()
            }
        }

        viewModel.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                self?.showErrorAlert(message: errorMessage)
            }
        }
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func createEmptyStateView(message: String) -> UIView {
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }

    private func showEmptyState(message: String) {
        tableView.backgroundView = createEmptyStateView(message: message)
    }

    private func hideEmptyState() {
        tableView.backgroundView = nil
    }
}

extension CountryListViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.cellViewModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.cellViewModels.count else {
            return UITableViewCell()
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: CountryCell.reuseID, for: indexPath) as? CountryCell else {
            return UITableViewCell()
        }

        let cellViewModel = viewModel.cellViewModels[indexPath.row]
        cell.configure(cellViewModel)
        return cell
    }
}

extension CountryListViewController {

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !viewModel.isLoading else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        if offsetY > contentHeight - frameHeight - 100 {
            viewModel.loadNextPage()
        }
    }
}

extension CountryListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.filter(query: searchController.searchBar.text)
    }
}
