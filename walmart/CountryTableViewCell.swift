//
//  CountryTableViewCell.swift
//  walmart
//
//  Created by Makambo Yemomo on 5/15/25.
//

import Foundation
import UIKit

class CountryCell: UITableViewCell {
    static let reuseID = "CountryCell"
    
    @IBOutlet weak var nameAndRegion: UILabel!
    @IBOutlet weak var capital: UILabel!
    @IBOutlet weak var code: UILabel!

    func configure(_ viewModel: CountryCellViewModel) {
        nameAndRegion.text = viewModel.titleText
        capital.text = viewModel.capitalText
        code.text = viewModel.codeText
    }
}
