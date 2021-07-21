//  
//  SignUpBirthdateViewController.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 24/03/21.
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
import MaterialComponents.MaterialSnackbar

class SignUpBirthdateViewController: WizardViewController {

  let accountsManager: ArduinoAccountsManager
  
  private(set) lazy var birthdateView = SignUpBirthdateView()

  init(accountsManager: ArduinoAccountsManager) {
    self.accountsManager = accountsManager
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    wizardView.contentView = birthdateView
    
    birthdateView.infoButton.addTarget(self, action: #selector(showInfo(_:)), for: .touchUpInside)
    birthdateView.submitButton.addTarget(self, action: #selector(signUp(_:)), for: .touchUpInside)
  }
  
  @objc private func showInfo(_ sender: UIButton) {
    let alertController = MDCAlertController(title: nil,
                                             message: String.arduinoSignUpBirthdateInfo)
    let okAction = MDCAlertAction(title: String.actionOk)
    alertController.addAction(okAction)
    alertController.accessibilityViewIsModal = true
    if let okButton = alertController.button(for: okAction) {
      alertController.styleAlertOk(button: okButton)
    }
    present(alertController, animated: true)
  }
  
  @objc private func signUp(_ sender: UIButton) {
    guard let birthdate = birthdateView.birthdate else { return }

    let viewModel = SignUpViewModel(birthdate: birthdate)
    if viewModel.age < 14 {
      let viewController = SignUpJuniorViewController(accountsManager: accountsManager,
                                                      viewModel: viewModel)
      show(viewController, sender: nil)
    } else {
      let viewController = SignUpViewController(accountsManager: accountsManager,
                                                viewModel: viewModel)
      show(viewController, sender: nil)
    }
  }
}
