//  
//  SignUpTermsView.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 29/03/21.
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

class SignUpTermsView: UIStackView {

  var acceptedTerms: [SignUpTermsItem] {
    termsItemViews.filter { $0.isChecked }.map { $0.item }
  }
  
  let onAction: ([SignUpTermsItem]) -> Void
  
  let signUpButton = WizardButton(title: String.arduinoSignUpTermsSubmitButton, style: .solid)
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = String.arduinoSignUpTitle
    label.textAlignment = .center
    label.textColor = .black
    label.font = ArduinoTypography.regularFont(forSize: ArduinoTypography.FontSize.Large.rawValue)
    label.numberOfLines = 0
    return label
  }()
  
  private var termsItemViews = [SignUpTermsItemView]()

  private let termsNotice: UILabel = {
    let label = UILabel()
    label.text = String.arduinoSignUpTermsAndPrivacyNotice 
    label.textAlignment = .center
    label.textColor = ArduinoColorPalette.grayPalette.tint500
    label.font = ArduinoTypography.regularFont(forSize: ArduinoTypography.FontSize.XSmall.rawValue)
    label.numberOfLines = 0
    return label
  }()
  
  init(terms: [SignUpTermsItem], onAction: @escaping ([SignUpTermsItem]) -> Void) {
    self.onAction = onAction
    
    super.init(frame: .zero)

    axis = .vertical
    alignment = .center
    isLayoutMarginsRelativeArrangement = true
    layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    spacing = 32
    
    addArrangedSubview(titleLabel)
    
    let termsStackView = UIStackView()
    termsStackView.axis = .vertical
    termsStackView.spacing = 12
    addArrangedSubview(termsStackView)
    
    for term in terms {
      let itemView = SignUpTermsItemView(item: term) { [weak self] in
        self?.onAction(self?.acceptedTerms ?? [])
      }
      termsItemViews.append(itemView)
      termsStackView.addArrangedSubview(itemView)
    }

    addArrangedSubview(termsNotice)
    
    let signUpButtonStackView = UIStackView()
    signUpButtonStackView.axis = .horizontal
    signUpButtonStackView.addArrangedSubview(UIView())
    signUpButtonStackView.addArrangedSubview(signUpButton)
    addArrangedSubview(signUpButtonStackView)
    
    let leadingConstraint = termsStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 28)
    leadingConstraint.priority = .required-1
    NSLayoutConstraint.activate([
      leadingConstraint,
      termsStackView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
      termsStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
      signUpButtonStackView.trailingAnchor.constraint(equalTo: termsStackView.trailingAnchor)
    ])
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class SignUpTermsItemView: UIStackView {

  let item: SignUpTermsItem
  let onAction: () -> Void
  
  var isChecked: Bool = false {
    didSet {
      refreshCheckBox()
    }
  }
  
  private let checkBoxImageView = UIImageView(image: UIImage(named: "sign_in_checkbox"))
  private let textView: UITextView = {
    let textView = UITextView()
    textView.textContainer.lineFragmentPadding = 0
    textView.textContainerInset = .zero
    textView.isScrollEnabled = false
    textView.scrollsToTop = false
    textView.isSelectable = true
    textView.isEditable = false
    textView.delaysContentTouches = false
    textView.dataDetectorTypes = [.link]
    textView.font = ArduinoTypography.labelFont
    textView.textColor = .black
    textView.backgroundColor = .clear
    return textView
  }()
  
  private let uncheckedImage = UIImage(named: "sign_in_checkbox")
  private let checkedImage = UIImage(named: "sign_in_checkbox_selected")
  
  private var requiredColor: UIColor? {
    UIColor(red: 218/255.0, green: 91/255.0, blue: 74/255.0, alpha: 1)
  }
  
  init(item: SignUpTermsItem, onAction: @escaping (() -> Void)) {
    self.item = item
    self.onAction = onAction
    
    super.init(frame: .zero)
    
    axis = .horizontal
    spacing = 8
    alignment = .top
    
    textView.set(htmlText: item.htmlText)
    textView.inject(urls: item.urls)
    
    if item.isRequired {
      let attributes: [NSAttributedString.Key : Any] = [
        NSAttributedString.Key.foregroundColor: requiredColor as Any
      ]
      let attributedString = NSMutableAttributedString(attributedString: textView.attributedText)
      attributedString.append(NSAttributedString(string: " *", attributes: attributes))
      textView.attributedText = attributedString
    }
    
    checkBoxImageView.isUserInteractionEnabled = true
    checkBoxImageView.setContentHuggingPriority(.required, for: .horizontal)
    
    addArrangedSubview(checkBoxImageView)
    addArrangedSubview(textView)
    
    let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
    checkBoxImageView.addGestureRecognizer(tap)
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc private func didTap(_ sender: UITapGestureRecognizer) {
    if sender.state == .ended {
      isChecked.toggle()
      onAction()
    }
  }
  
  private func refreshCheckBox() {
    checkBoxImageView.image = isChecked ? checkedImage : uncheckedImage
  }
}
