//  
//  DriveSyncIntroViewController.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 05/01/21.
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

class DriveSyncIntroViewController: WizardViewController {

  let accountsManager: AccountsManager
  let isSignup: Bool
  
  private(set) lazy var introView = DriveSyncIntroView()

  init(accountsManager: AccountsManager, isSignup: Bool? = nil) {
    
    self.accountsManager = accountsManager
    self.isSignup = isSignup ?? false
        
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = String.driveSyncIntroTitle
    
    wizardView.text = String.driveSyncIntroText
    wizardView.contentView = introView

    introView.learnMoreButton.addTarget(self, action: #selector(showMoreInfo(_:)), for: .touchUpInside)
    introView.googleDriveButton.addTarget(self, action: #selector(setupGoogleDrive(_:)), for: .touchUpInside)

    if isSignup {
      introView.skipButton.addTarget(self, action: #selector(close(_:)), for: .touchUpInside)
    } else {
      introView.skipButton.isHidden = true
    }
  }

  @objc private func showMoreInfo(_ sender: UIButton) {
    accountsManager.learnMoreDriveSync(fromViewController: self)
  }

  @objc private func setupGoogleDrive(_ sender: UIButton) {
    sender.isEnabled = false

    accountsManager.signInWithGoogle(fromViewController: self) { [weak self] in
      sender.isEnabled = true
      switch $0 {
      case .success(let user):
        self?.handleAuthenticatedUser(user)
      case .failure:
        // TODO: show error
        break
      }
    }
  }

  private func handleAuthenticatedUser(_ user: GIDGoogleUser) {
    guard user.authentication.fetcherAuthorizer() != nil else {
      // TODO: show error
      return
    }

    let folderPicker = DriveSyncFolderPickerViewController(user: user, accountsManager: accountsManager)
    show(folderPicker, sender: nil)
  }
}
