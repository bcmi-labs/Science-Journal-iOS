//  
//  SignUpJuniorViewController.swift
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

class SignUpJuniorViewController: WizardViewController {

  let accountsManager: ArduinoAccountsManager
  private(set) var viewModel: SignUpViewModel
  
  var error: [String: Any]? {
    didSet {
      parseError()
    }
  }
  
  private(set) lazy var signUpView = SignUpJuniorView()
  
  private lazy var username = BehaviorRelay<String?>(value: nil)
  private lazy var selectedAvatar = BehaviorRelay<[String: String]?>(value: nil)
  
  private lazy var avatars = BehaviorRelay<[[String: String]]>(value: [])
  
  private lazy var disposeBag = DisposeBag()
  
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
    
    navigationItem.hidesBackButton = true
    
    wizardView.contentView = signUpView
    
    signUpView.usernameView.reloadButton.addTarget(self, action: #selector(reloadUsername), for: .touchUpInside)
    signUpView.infoButton.addTarget(self, action: #selector(showInfo(_:)), for: .touchUpInside)
    signUpView.submitButton.addTarget(self, action: #selector(submit(_:)), for: .touchUpInside)
    
    addObservers()
    
    getAvatars()
    reloadUsername()
  }
  
  @objc private func showInfo(_ sender: UIButton) {
    let alertController = MDCAlertController(title: nil,
                                             message: String.arduinoSignUpJuniorUsernameHint)
    let okAction = MDCAlertAction(title: String.actionOk)
    alertController.addAction(okAction)
    alertController.accessibilityViewIsModal = true
    if let okButton = alertController.button(for: okAction) {
      alertController.styleAlertOk(button: okButton)
    }
    present(alertController, animated: true)
  }
  
  private func getAvatars() {
    accountsManager.getJuniorAvatars { [weak self] in
      switch $0 {
      case .success(let avatars):
        self?.avatars.accept(avatars)
        self?.selectedAvatar.accept(avatars.randomElement())
      case .failure: break
      }
    }
  }
  
  @objc private func reloadUsername() {
    accountsManager.getJuniorUsername { [weak self] in
      switch $0 {
      case .success(let username):
        self?.username.accept(username)
      case .failure: break
      }
    }
  }
  
  @objc private func submit(_ sender: UIButton) {
    guard let username = username.value else {
      return
    }
    
    guard let avatar = selectedAvatar.value?["id"] else {
      return
    }
    
    error = nil
    
    viewModel.username = username
    viewModel.avatar = avatar
    
    let viewController = SignUpParentViewController(accountsManager: accountsManager, viewModel: viewModel)
    show(viewController, sender: nil)
  }
  
  private func completeWithResult(_ result: Result<ArduinoAccount, SignInError>) {
    isLoading.onNext(false)
    switch result {
    case .success: rootViewController?.close(isCancelled: false)
    case .failure: break
    }
  }
  
  private func parseError() {
    
  }
  
  private func addObservers() {
    let isLoadingData = Observable.combineLatest(username, selectedAvatar)
      .map { $0.0 == nil || $0.1 == nil }
      
    isLoadingData
      .bind(to: signUpView.rx.isHidden)
      .disposed(by: disposeBag)
    
    isLoadingData
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] in
        self?.isLoading.onNext($0)
      })
      .disposed(by: disposeBag)
    
    selectedAvatar
      .compactMap { $0?["data"] }
      .map { Data(base64Encoded: $0) }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] in
        self?.signUpView.avatarView.image = $0
      })
      .disposed(by: disposeBag)
    
    username
      .bind(to: signUpView.usernameView.usernameLabel.rx.text)
      .disposed(by: disposeBag)
    
    signUpView.passwordTextField.rx.text.orEmpty
      .subscribe(onNext: { [weak self] in
        self?.viewModel.password = $0
      })
      .disposed(by: disposeBag)
    
    let hasUsername = username.map { $0 != nil }
    let hasPassword = signUpView.passwordTextField.rx.text.orEmpty
      .map { $0.isValidPassword }
    
    Observable.combineLatest(hasUsername, hasPassword, isLoading)
      .map { $0.0 && $0.1 && !$0.2 }
      .bind(to: signUpView.submitButton.rx.isEnabled)
      .disposed(by: disposeBag)
    
    [signUpView.usernameView.reloadButton,
     signUpView.passwordTextField].forEach { control in
      
      isLoading
        .map { !$0 }
        .observe(on: MainScheduler.instance)
        .bind(to: control.rx.isEnabled)
        .disposed(by: disposeBag)
     }
    
    isLoading
      .filter { $0 }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] _ in
        self?.view.endEditing(true)
      })
      .disposed(by: disposeBag)
  }
}
