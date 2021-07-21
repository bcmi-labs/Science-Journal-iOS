//  
//  WizardFooterView.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 04/01/21.
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

class WizardFooterView: UIView {
  
  let stackView = UIStackView()
  let termsButton = UIButton(type: .system)
  let privacyButton = UIButton(type: .system)
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
    configureConstraints()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    configureView()
    configureConstraints()
  }
  
  private func configureView() {
    backgroundColor = .white
    
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .horizontal
    stackView.distribution = .fill
    stackView.alignment = .fill
    stackView.spacing = 36
    addSubview(stackView)
    
    [termsButton, privacyButton].forEach {
      $0.titleLabel?.font = ArduinoTypography.labelFont
      $0.tintColor = ArduinoColorPalette.tealPalette.tint800
    }
    termsButton.setTitle(String.settingsTermsTitle, for: .normal)
    termsButton.translatesAutoresizingMaskIntoConstraints = false
    privacyButton.setTitle(String.settingsPrivacyPolicyTitle, for: .normal)
    privacyButton.translatesAutoresizingMaskIntoConstraints = false
    stackView.addArrangedSubview(termsButton)
    stackView.addArrangedSubview(privacyButton)
  }
  
  private func configureConstraints() {
    stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
  }
}
