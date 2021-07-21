//  
//  TermsAgreementViewController.swift
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
import GoogleSignIn
import GoogleAPIClientForREST
import MaterialComponents.MaterialDialogs
import SafariServices

class TermsAgreementViewController: UIViewController, UITextViewDelegate {
  
  private(set) lazy var termsAgreementView = TermsAgreementView()

  init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    termsAgreementView.textView.delegate = self

    self.view.addSubview(termsAgreementView)

    termsAgreementView.translatesAutoresizingMaskIntoConstraints = false
    termsAgreementView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    termsAgreementView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true

    // Title formatting

    let titleText = String.arduinoTermsAgreementTitle

    let titleAttributedString = NSMutableAttributedString(string: titleText)
    titleAttributedString.addAttribute(NSAttributedString.Key.font,
    value: ArduinoTypography.boldFont(forSize: 20), range: NSRange(location: 0, length: titleAttributedString.length))
    titleAttributedString.addAttribute(NSAttributedString.Key.foregroundColor,
    value: ArduinoColorPalette.tealPalette.tint800, range: NSRange(location: 0, length: titleAttributedString.length))

    termsAgreementView.title.attributedText = titleAttributedString

    // Textview formatting

    termsAgreementView.textView.text = String.arduinoTermsAgreement

    let textViewAttributedString = NSMutableAttributedString(attributedString: termsAgreementView.textView.attributedText!)

    termsAgreementView.textView.makeBold(originalText: textViewAttributedString, boldText: String.arduinoTermsAgreementLinkLabel)
    termsAgreementView.textView.addLink(originalText: textViewAttributedString, 
                                        value: "openTerms", selectedText: String.arduinoTermsAgreementLinkLabel)

    // apply a paragraph attribute to set alignment and lineSpacing
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 8
    paragraphStyle.alignment = .center
    textViewAttributedString.addAttribute(NSAttributedString.Key.paragraphStyle,
    value: paragraphStyle, range: NSRange(location: 0, length: textViewAttributedString.length))
    
    termsAgreementView.textView.attributedText = textViewAttributedString

    // Button style

    termsAgreementView.acceptButton.setTitle(String.arduinoTermsAgreementCta, for: .normal)
    termsAgreementView.acceptButton.setTitleColor(UIColor.white, for: .normal)
    termsAgreementView.acceptButton.contentHorizontalAlignment = .center

    termsAgreementView.acceptButton.addTarget(self,
                 action: #selector(acceptTerms),
                 for: .touchUpInside)

  }

  // Handle click on link inside textView
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange,
                interaction: UITextItemInteraction) -> Bool {
    openTerms()
    return false
  }

  @objc private func acceptTerms() {
    UserDefaults.standard.set(true, forKey: "termsAccepted")
    self.dismiss(animated: true)
    NotificationCenter.default.post(name: .userHasAcceptedTerms, object: self)
  }

  @objc private func openTerms() {
    let privacyVC = SFSafariViewController(url: Constants.ArduinoScienceJournalURLs.sjTermsOfServiceUrl)
    present(privacyVC, animated: true, completion: nil)
  }
}
