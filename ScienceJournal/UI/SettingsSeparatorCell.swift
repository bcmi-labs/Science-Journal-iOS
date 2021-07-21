//  
//  SettingsSeparatorCell.swift
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

class SettingsSeparatorCell: UICollectionViewCell {
  static let margin: CGFloat = 28.0
  
  private let separator = UIView()
  
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
    separator.backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 0.95, alpha: 1)
    separator.translatesAutoresizingMaskIntoConstraints = false
    addSubview(separator)
    configureConstraints()
  }
  
  private func configureConstraints() {
    separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
    separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SettingsSeparatorCell.margin).isActive = true
    separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: SettingsSeparatorCell.margin * -1).isActive = true
    separator.centerYAnchor.constraint(equalTo: centerYAnchor)
  }
}
