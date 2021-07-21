//  
//  DriveSyncStartViewController.swift
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

class DriveSyncStartViewController: WizardViewController {

  let user: GIDGoogleUser
  let folder: DriveFetcher.Folder
  let accountsManager: AccountsManager
  
  private(set) lazy var startView = DriveSyncStartView(folderName: folder.name)
  
  init(user: GIDGoogleUser, folder: DriveFetcher.Folder, accountsManager: AccountsManager) {
    self.user = user
    self.folder = folder
    self.accountsManager = accountsManager
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    title = String.driveSyncStartTitle
    
    wizardView.text = String.driveSyncStartText
    wizardView.contentView = startView
    
    startView.confirmButton.addTarget(self, action: #selector(start(_:)), for: .touchUpInside)

    startView.notice.text = String.driveSyncStartNotice
  }
  
  @objc private func start(_ sender: UIButton) {
    accountsManager.enableDriveSync(with: user, folderID: folder.id, folderName: folder.name)
    rootViewController?.close(isCancelled: false)
    NotificationCenter.default.post(name: .settingsShouldClose, object: self)
  }

}
