//  
//  DriveSyncLearnMoreView.swift
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

class DriveSyncLearnMoreView: UIStackView {

  let label = UILabel()
  let termsLink = UIButton()
  let privacyLink = UIButton()

  init() {
    super.init(frame: .zero)

    axis = .vertical
    alignment = .center
    isLayoutMarginsRelativeArrangement = true
    layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
    spacing = 40

    addArrangedSubview(label)
    addArrangedSubview(termsLink)
    addArrangedSubview(privacyLink)

    label.translatesAutoresizingMaskIntoConstraints = false
    label.topAnchor.constraint(equalTo: topAnchor).isActive = true
    label.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true

    label.numberOfLines = 0

    termsLink.translatesAutoresizingMaskIntoConstraints = false
    termsLink.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20).isActive = true
    termsLink.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true

    privacyLink.translatesAutoresizingMaskIntoConstraints = false
    privacyLink.topAnchor.constraint(equalTo: termsLink.bottomAnchor).isActive = true
    privacyLink.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
  }

  required init(coder: NSCoder) {
    super.init(coder: coder)
  }
}
