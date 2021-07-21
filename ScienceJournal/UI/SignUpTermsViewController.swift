//  
//  SignUpTermsViewController.swift
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

enum SignUpTermsItem: String, CaseIterable, Hashable {
  case termsAndPrivacy
  case newsletter
  case marketing
  case tracking
  
  var htmlText: String {
    switch self {
    case .termsAndPrivacy: return String.arduinoSignUpTermsAndPrivacy
    case .newsletter: return String.arduinoSignUpNewsletterApproval
    case .marketing: return String.arduinoSignUpMarketingApproval
    case .tracking: return String.arduinoSignUpTrackingApproval
    }
  }
  
  var isRequired: Bool {
    switch self {
    case .termsAndPrivacy: return true
    default: return false
    }
  }
  
  var urls: [URL] {
    switch self {
    case .termsAndPrivacy: return [
      Constants.ArduinoSignIn.privacyPolicyUrl,
      Constants.ArduinoScienceJournalURLs.sjTermsOfServiceUrl
    ]
    default: return []
    }
  }
}

class SignUpTermsViewController: WizardViewController {
  
  let accountsManager: ArduinoAccountsManager
  private(set) var viewModel: SignUpViewModel
  
  private(set) lazy var termsView = SignUpTermsView(terms: SignUpTermsItem.allCases) { [weak self] in
    self?.viewModel.acceptedTerms = $0
    self?.checkTerms()
  }
  
  init(accountsManager: ArduinoAccountsManager, viewModel: SignUpViewModel) {
    self.accountsManager = accountsManager
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    wizardView.contentView = termsView
    
    termsView.signUpButton.addTarget(self, action: #selector(signUp(_:)), for: .touchUpInside)
    
    checkTerms()
  }
  
  private func checkTerms() {
    termsView.signUpButton.isEnabled = viewModel.hasAcceptedRequiredTerms
  }
  
  @objc private func signUp(_ sender: UIButton) {
    guard let email = viewModel.email,
          let username = viewModel.username,
          let password = viewModel.password else {
      return
    }
    
    isLoading.onNext(true)
    
    accountsManager.signUp(email: email,
                           username: username,
                           password: password,
                           userMetadata: viewModel.userMetadata) { [weak self] in
      guard let self = self else { return }
      
      self.isLoading.onNext(false)
      
      switch $0 {
      case .failure(let error):
        switch error {
        case .notValid(let json):
          self.backToSignUp(error: json)
        default:
          break
        }
      case .success(let account):
        if account.emailVerified {
          self.rootViewController?.close(isCancelled: false)
        } else {
          let viewController = SignUpConfirmationViewController(account: account, accountsManager: self.accountsManager)
          self.show(viewController, sender: nil)
        }
      }
    }
  }
}
