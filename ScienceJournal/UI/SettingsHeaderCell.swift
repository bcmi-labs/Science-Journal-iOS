//  
//  SettingsHeaderCell.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 13/04/21.
//  Copyright © 2021 Arduino. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import UIKit

class SettingsHeaderCell: UICollectionViewCell {
  
  static let textLabelMargin: CGFloat = 28.0
  
  let textLabel = UILabel()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    configureCell()
  }

  required init(coder: NSCoder) {
    super.init(coder: coder)!
    configureCell()
  }
  
  // MARK: - View

  private func configureCell() {
    textLabel.font = ArduinoTypography.regularFont(forSize: ArduinoTypography.FontSize.Small.rawValue)
    textLabel.textColor = ArduinoColorPalette.tealPalette.tint800
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(textLabel)
    configureConstraints()
  }

  private func configureConstraints() {
    textLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor,
                                       constant: SettingsHeaderCell.textLabelMargin).isActive = true
    textLabel.trailingAnchor.constraint(greaterThanOrEqualTo: self.trailingAnchor,
                                        constant: SettingsHeaderCell.textLabelMargin * -1).isActive = true
    textLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
  }
}
