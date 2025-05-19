//
//  CountryCellViewModel.swift
//  walmart
//
//  Created by Makambo Yemomo on 5/15/25.
//

import Foundation

struct CountryCellViewModel {
    let id: String
    let titleText: String
    let codeText: String
    let capitalText: String

    init(country: Country) {
        self.id = country.code
        self.titleText = "\(country.name), \(country.region)"
        self.codeText  = country.code
        self.capitalText = country.capital ?? "N/A"
    }
}
