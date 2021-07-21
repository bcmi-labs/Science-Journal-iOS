//  
//  ModalView.swift
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

class ModalView: UIView {

  var text: String? {
    get { textLabel.text }
    set {
      let attributedText = NSAttributedString(htmlBody: newValue,
                                              font: textLabel.font,
                                              color: textLabel.textColor,
                                              lineHeight: 28,
                                              alignment: textLabel.textAlignment,
                                              layoutDirection: traitCollection.layoutDirection)
      textLabel.attributedText = attributedText
    }
  }

  var contentView: UIView? {
    didSet {
      oldValue?.removeFromSuperview()
      if let contentView = contentView {
        stackView.insertArrangedSubview(contentView, at: 1)
      }
    }
  }

  var hasFixedHeight: Bool = false {
    didSet {
      heightConstraint.isActive = hasFixedHeight
    }
  }

  private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.delaysContentTouches = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.keyboardDismissMode = .interactive
    return scrollView
  }()

  private lazy var stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.translatesAutoresizingMaskIntoConstraints = false
    return stackView
  }()

  private lazy var textLabel: UILabel = {
    let label = UILabel()
    label.font = ArduinoTypography.regularFont(forSize: ArduinoTypography.FontSize.Small.rawValue)
    label.numberOfLines = 0
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var heightConstraint: NSLayoutConstraint = {
    let constraint = stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
    return constraint
  }()
  
  private var keyboardController: KeyboardController?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    refreshLayoutMargins()
  }

  private func setupView() {
    keyboardController = KeyboardController(scrollView: scrollView)
    
    addSubview(scrollView)
    scrollView.pinToEdgesOfView(self)

    scrollView.addSubview(stackView)
    let guide = scrollView.contentLayoutGuide
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
      stackView.topAnchor.constraint(equalTo: guide.topAnchor),
      stackView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
    ])

    stackView.addArrangedSubview(textLabel)

    refreshLayoutMargins()
  }

  private func refreshLayoutMargins() {
    if traitCollection.verticalSizeClass == .compact {
      stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
    } else {
      stackView.layoutMargins = UIEdgeInsets(top: 46, left: 20, bottom: 0, right: 20)
    }
  }

}
