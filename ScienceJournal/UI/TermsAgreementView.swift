//  
//  TermsAgreementView.swift
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

class TermsAgreementView: UIView {

let title: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.textAlignment = .center
    return label
}()

let textView: UITextView = {
    let textView = UITextView()
    textView.textContainer.lineFragmentPadding = 0
    textView.textContainerInset = .zero
    textView.textAlignment = .center
    textView.isScrollEnabled = false
    textView.scrollsToTop = false
    textView.isSelectable = true
    textView.isEditable = false
    textView.delaysContentTouches = false
    textView.dataDetectorTypes = [.link]
    textView.font = ArduinoTypography.paragraphFont
    textView.textColor = .black
    textView.backgroundColor = .clear
    textView.textAlignment = .center
    textView.linkTextAttributes = [
      .foregroundColor: ArduinoColorPalette.tealPalette.tint800!,
      .font: ArduinoTypography.boldFont(forSize: 16)
    ]
    return textView
}()

  let acceptButton = WizardButton(title: "Accept", style: .solid)

  init() {
    super.init(frame: .zero)

    backgroundColor = ArduinoColorPalette.grayPalette.tint100

    addSubview(title)
    addSubview(textView)
    addSubview(acceptButton)

    title.translatesAutoresizingMaskIntoConstraints = false
    title.topAnchor.constraint(equalTo: topAnchor, constant: 50).isActive = true
    title.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.topAnchor.constraint(equalTo: title.topAnchor, constant: 68).isActive = true
    textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
    textView.widthAnchor.constraint(equalTo: widthAnchor, constant: -40).isActive = true

    acceptButton.translatesAutoresizingMaskIntoConstraints = false
    acceptButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -80).isActive = true
    acceptButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    acceptButton.widthAnchor.constraint(equalToConstant: 136).isActive = true
  }

    required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
