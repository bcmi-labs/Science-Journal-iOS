//  
//  DriveSyncSummaryView.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 12/01/21.
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

class DriveSyncSummaryView: UIStackView {

  lazy var folderView: UIView = {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.spacing = 8
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    
    stackView.layer.borderWidth = 1
    stackView.layer.borderColor = ArduinoColorPalette.grayPalette.tint500?.cgColor
    stackView.layer.cornerRadius = 5
    stackView.heightAnchor.constraint(equalToConstant: 42).isActive = true
    
    let folderImage = UIImageView(image: UIImage(named: "google_drive_folder"))
    folderImage.setContentCompressionResistancePriority(.required, for: .horizontal)
    folderImage.tintColor = ArduinoColorPalette.grayPalette.tint500
    
    stackView.addArrangedSubview(folderImage)
    stackView.addArrangedSubview(folderLabel)
    
    return stackView
  }()
  
  let confirmButton = WizardButton(title: String.driveSyncConfirmButton.uppercased(), style: .solid)

  private let folderLabel: UILabel = {
    let label = UILabel()
    label.textColor = ArduinoColorPalette.grayPalette.tint500
    label.font = ArduinoTypography.regularFont(forSize: ArduinoTypography.FontSize.Small.rawValue)
    return label
  }()
  
  init(folderName: String) {
    super.init(frame: .zero)

    axis = .vertical
    alignment = .center
    isLayoutMarginsRelativeArrangement = true
    layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    spacing = 48

    folderLabel.text = folderName
    
    addArrangedSubview(folderView)
    addArrangedSubview(confirmButton)
  }

  required init(coder: NSCoder) {
    super.init(coder: coder)
  }

}
