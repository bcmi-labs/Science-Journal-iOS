//  
//  SettingsItemCell.swift
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

class SettingsItemCell: UICollectionViewCell {

  static let margin: CGFloat = 28.0
  
  var accessoryView: UIView? {
    didSet {
      oldValue?.removeFromSuperview()
      if let view = accessoryView {
        view.setContentHuggingPriority(.required, for: .horizontal)
        horizontalStackView.addArrangedSubview(view)
      }
    }
  }
  
  let titleLabel = UILabel()
  let subtitleLabel = UILabel()
  let horizontalStackView = UIStackView()
  let verticalStackView = UIStackView()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    configureCell()
  }

  required init(coder: NSCoder) {
    super.init(coder: coder)!
    configureCell()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
    subtitleLabel.text = nil
    titleLabel.textColor = ArduinoColorPalette.grayPalette.tint400
    accessoryView = nil
  }

  private func configureCell() {
    titleLabel.font = ArduinoTypography.regularFont(forSize: ArduinoTypography.FontSize.Small.rawValue)
    titleLabel.textColor = ArduinoColorPalette.grayPalette.tint400
    
    subtitleLabel.font = ArduinoTypography.boldFont(forSize: ArduinoTypography.FontSize.XXSmall.rawValue)
    subtitleLabel.textColor = ArduinoColorPalette.grayPalette.tint500
    
    horizontalStackView.alignment = .center
    horizontalStackView.axis = .horizontal
    horizontalStackView.distribution = .fill
    horizontalStackView.spacing = 0
    horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(horizontalStackView)
    
    verticalStackView.alignment = .fill
    verticalStackView.axis = .vertical
    verticalStackView.distribution = .fill
    verticalStackView.spacing = 2
    horizontalStackView.addArrangedSubview(verticalStackView)
    
    verticalStackView.addArrangedSubview(titleLabel)
    verticalStackView.addArrangedSubview(subtitleLabel)
    
    configureConstraints()
  }
  
  private func configureConstraints() {
    horizontalStackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SettingsItemCell.margin).isActive = true
    horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: SettingsItemCell.margin * -1).isActive = true
  }
}
