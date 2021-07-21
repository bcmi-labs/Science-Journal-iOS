//  
//  JuniorRecoveryViewController.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 08/04/21.
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
import MaterialComponents.MaterialDialogs
import RxCocoa
import RxSwift

class JuniorRecoveryViewController: WizardViewController {
  
  let accountsManager: ArduinoAccountsManager
  let completion: () -> Void
  
  private(set) lazy var recoveryView = JuniorRecoveryView()
  
  private lazy var disposeBag = DisposeBag()
  
  init(accountsManager: ArduinoAccountsManager, completion: @escaping () -> Void) {
    self.accountsManager = accountsManager
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    wizardView.contentView = recoveryView
    
    recoveryView.infoButton.addTarget(self, action: #selector(showInfo(_:)), for: .touchUpInside)
    recoveryView.recoverButton.addTarget(self, action: #selector(recover(_:)), for: .touchUpInside)
    
    addObservers()
  }
  
  @objc private func showInfo(_ sender: UIButton) {
    let alertController = MDCAlertController(title: nil,
                                             message: String.arduinoPasswordJuniorRecoveryHint)
    let okAction = MDCAlertAction(title: String.actionOk)
    alertController.addAction(MDCAlertAction(title: String.actionOk))
    if let okButton = alertController.button(for: okAction) {
      alertController.styleAlertOk(button: okButton)
    }
    alertController.accessibilityViewIsModal = true
    present(alertController, animated: true)
  }
  
  @objc private func recover(_ sender: UIButton) {
    guard let email = recoveryView.emailTextField.text else {
      return
    }
    
    guard let username = recoveryView.usernameTextField.text else {
      return
    }

    let viewController =
      PasswordRecoveryConfirmationViewController(email: email,
                                                 username: username,
                                                 accountsManager: accountsManager,
                                                 completion: completion)
    show(viewController, sender: nil)
  }
  
  private func addObservers() {
    let hasEmail = recoveryView.emailTextField.rx.text.orEmpty
      .map { $0.isValidEmail }
    
    let hasUsername = recoveryView.usernameTextField.rx.text.orEmpty
      .map { $0.isValidUsername }
    
    Observable.combineLatest(hasEmail, hasUsername)
      .map { $0.0 && $0.1 }
      .bind(to: recoveryView.recoverButton.rx.isEnabled)
      .disposed(by: disposeBag)
  }
}
