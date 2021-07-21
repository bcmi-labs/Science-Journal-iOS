//  
//  SettingsAccountCell.swift
//  ScienceJournal
//
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

class SettingsButtonCell: UICollectionViewCell {

  @IBOutlet weak var button: UIButton!
  
  override func awakeFromNib() {
    super.awakeFromNib()

    button.setTitleColor(ArduinoColorPalette.tealPalette.tint800, for: .normal)
    button.titleLabel?.font = ArduinoTypography.boldFont(forSize: ArduinoTypography.FontSize.XXSmall.rawValue)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
  }

}
