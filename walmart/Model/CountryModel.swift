//
//  CountryModel.swift
//  walmart
//
//  Created by Makambo Yemomo on 5/15/25.
//

import Foundation

import Foundation

final class Country: Codable {
    let name: String
    let region: String
    let code: String
    let capital: String?
    let flag: URL?
    let currency: Currency?
    let language: Language?
}

final class Currency: Codable {
    let code: String?
    let name: String?
    let symbol: String?
}

final class Language: Codable {
    let code: String?
    let name: String?
}
