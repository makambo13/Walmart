//
//  Untitled.swift
//  walmart
//
//  Created by Makambo Yemomo on 5/15/25.
//

//
//  CountryListViewModel.swift
//  walmart
//
//  Created by Makambo Yemomo on 5/15/25.
//

import Foundation

final class CountryListViewModel {
    var onUpdate: (() -> Void)?
    var onError: ((String) -> Void)?
    
    // MARK: - Paging
    private let pageSize = 20
    var isLoading = false
    private var hasMoreData = true
    
    // MARK: - State
    private var originalCountries = [Country]()
    private var allCountries = [Country]()
    private(set) var cellViewModels = [CountryCellViewModel]()
    private var currentIndex = 0
    
    private let networkService = NetworkService()
    
    func loadCountries() {
        guard !isLoading else { return }
        resetState()
        fetchCountries()
    }
    
    // MARK: - Fetch Data
    private func fetchCountries() {
        guard !isLoading, hasMoreData else { return }
        isLoading = true

        networkService.request(with: .getCountryList) { [weak self] (result: Result<[Country], CustomError>) in
            guard let self = self else { return }

            self.isLoading = false

            switch result {
            case .success(let countries):
                guard !countries.isEmpty else {
                    self.hasMoreData = false
                    
                    DispatchQueue.main.async {
                        if self.cellViewModels.isEmpty {
                            self.onError?("No data available")
                        }
                    }
                    return
                }

                self.originalCountries = countries
                self.resetPaging()

            case .failure(let error):
                DispatchQueue.main.async {
                    self.onError?(error.message)
                }
            }
        }
    }

    private func resetState() {
        isLoading = false
        hasMoreData = true
        currentIndex = 0
        originalCountries.removeAll()
        allCountries.removeAll()
        cellViewModels.removeAll()
    }
    
    // MARK: - Reset Paging
    private func resetPaging() {
        allCountries = originalCountries
        cellViewModels = []
        currentIndex = 0
        loadNextPage()
    }

    // MARK: - Load Next Page
    func loadNextPage() {
        guard !isLoading, hasMoreData, currentIndex < allCountries.count else {
            isLoading = false
            return
        }
        
        isLoading = true

        let nextIndex = min(currentIndex + pageSize, allCountries.count)
        let slice = allCountries[currentIndex..<nextIndex]

        let newViewModels = slice.map { CountryCellViewModel(country: $0) }
        let existingIDs = cellViewModels.map { $0.id }
        
        let uniqueViewModels = newViewModels.filter { newVM in
            !existingIDs.contains(newVM.id)
        }

        cellViewModels += uniqueViewModels
        currentIndex = nextIndex

        hasMoreData = nextIndex < allCountries.count

        isLoading = false
        DispatchQueue.main.async {
            self.onUpdate?()
        }
    }
    
    // MARK: - Filtering Data
    func filter(query: String?) {
        guard let query = query, !query.isEmpty else {
            resetPaging()
            return
        }

        let lowercasedQuery = query.lowercased()
        let filtered = originalCountries.filter {
            $0.name.lowercased().contains(lowercasedQuery) ||
            ($0.capital?.lowercased().contains(lowercasedQuery) ?? false)
        }

        if filtered.isEmpty {
            DispatchQueue.main.async {
                self.onError?("No results found for \"\(query)\"")
            }
        }

        allCountries = filtered
        cellViewModels = filtered.map { CountryCellViewModel(country: $0) }
        currentIndex = allCountries.count
        
        DispatchQueue.main.async {
            self.onUpdate?()
        }
    }
}
