//  
//  MDCAlertController+Styles.swift
//  ScienceJournal
//
//  Created by Mateusz Ramski on 05/05/2021.
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

import MaterialComponents.MaterialDialogs

extension MDCAlertController {
  func styleAlertOk(button: MDCButton) {
    let tealColor = ArduinoColorPalette.tealPalette.tint800!
    let buttonFont = ArduinoTypography.boldFont(forSize: ArduinoTypography.FontSize.Small.rawValue)
    
    button.layer.cornerRadius = 18
    button.setBackgroundColor(tealColor, for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.clipsToBounds = true
    button.setTitleFont(buttonFont, for: .normal)
  }
  
  func styleAlertCancel(button: MDCButton) {
    let tealColor = ArduinoColorPalette.tealPalette.tint800!
    let buttonFont = ArduinoTypography.boldFont(forSize: ArduinoTypography.FontSize.Small.rawValue)
    
    button.layer.cornerRadius = 18
    button.setTitleColor(tealColor, for: .normal)
    button.setTitleFont(buttonFont, for: .normal)
    button.clipsToBounds = true
    
    let border = UIView()
    border.isUserInteractionEnabled = false
    border.translatesAutoresizingMaskIntoConstraints = false
    border.backgroundColor = .clear
    border.layer.cornerRadius = 18
    border.layer.borderWidth = 1
    border.layer.borderColor = tealColor.cgColor
    button.addSubview(border)
    border.topAnchor.constraint(equalTo: button.topAnchor, constant: 5).isActive = true
    border.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -5).isActive = true
    border.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 0).isActive = true
    border.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 0).isActive = true
  }
}
