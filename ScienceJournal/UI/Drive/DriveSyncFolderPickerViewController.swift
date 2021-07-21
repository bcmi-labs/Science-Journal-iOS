//  
//  DriveSyncFolderPickerViewController.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 07/01/21.
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
import MaterialComponents
import RxSwift
import GoogleSignIn
import GoogleAPIClientForREST

class DriveSyncFolderPickerViewController: WizardViewController {

  let driveFetcher: DriveFetcher
  let user: GIDGoogleUser
  let accountsManager: AccountsManager
  
  let selectButton = WizardButton(title: String.driveSyncFolderPickerSelect, style: .solid)

  private(set) lazy var pathView = DriveSyncPathView(onBack: goBack, onCreate: createFolder)
  private(set) lazy var pickerView = DriveSyncFolderPickerView(pathView: pathView)

  private lazy var pageViewController = UIPageViewController(transitionStyle: .scroll,
                                                             navigationOrientation: .horizontal,
                                                             options: nil)
  
  private lazy var disposeBag = DisposeBag()
  
  init(user: GIDGoogleUser, accountsManager: AccountsManager) {
    guard let authorizer = user.authentication.fetcherAuthorizer() else {
      fatalError("Missing authentication in GIDGoogleUser")
    }

    let service = GTLRDriveService()
    service.authorizer = authorizer
    service.shouldFetchNextPages = true

    self.driveFetcher = DriveFetcher(service: service)
    self.user = user
    self.accountsManager = accountsManager
    
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    title = String.driveSyncFolderPickerTitle
    
    wizardView.text = String.driveSyncFolderPickerText

    addContentView()
    addPageViewController()
    addSelectButton()
  }

  override func show(_ vc: UIViewController, sender: Any?) {
    if let folderViewController = vc as? DriveSyncFolderListTableViewController {
      pathView.folder = folderViewController.folder
      pageViewController.setViewControllers([vc], direction: .forward, animated: true, completion: nil)
    } else {
      navigationController?.show(vc, sender: sender)
    }
  }
  
  private func addContentView() {
    wizardView.hasFixedHeight = true
    wizardView.contentView = pickerView
  }

  private func addSelectButton() {
    selectButton.addTarget(self, action: #selector(selectFolder(_:)), for: .touchUpInside)
    
    view.addSubview(selectButton)
    selectButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      selectButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
      selectButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25)
    ])
  }

  private func addPageViewController() {
    addChild(pageViewController)
    pickerView.pageView.addSubview(pageViewController.view)
    pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
    pageViewController.view.pinToEdgesOfView(pickerView.pageView)
    pageViewController.didMove(toParent: self)

    pageViewController.setViewControllers([
      DriveSyncFolderListTableViewController(driveFetcher: driveFetcher, folder: nil, selectButton: selectButton)
    ], direction: .forward, animated: false, completion: nil)
  }
  
  private func goBack() {
    guard let folderViewController = pageViewController.viewControllers?.first
            as? DriveSyncFolderListTableViewController else {
      return
    }
    
    guard let folder = folderViewController.folder else {
      return
    }
    
    pageViewController.setViewControllers([
      DriveSyncFolderListTableViewController(driveFetcher: driveFetcher,
                                             folder: folder.parent,
                                             selectButton: selectButton)
    ], direction: .reverse, animated: true, completion: nil)
  }
  
  private func createFolder() {
    let title = String.driveSyncCreateFolderTitle
    let alertController = MDCAlertController(title: title, message: "")
    alertController.backgroundColor = ArduinoColorPalette.grayPalette.tint50
    alertController.cornerRadius = 5
    alertController.titleFont = ArduinoTypography.boldFont(forSize: ArduinoTypography.FontSize.Small.rawValue)
    alertController.titleColor = ArduinoColorPalette.grayPalette.tint600
    alertController.accessoryView = DriveSyncFolderCreateView { [weak alertController, weak self] folderName in
      alertController?.dismiss(animated: true, completion: nil)
      self?.createFolder(named: folderName)
    }
    present(alertController, animated:true)
  }
  
  private func createFolder(named folderName: String) {
    guard let folderViewController = pageViewController.viewControllers?.first
            as? DriveSyncFolderListTableViewController else {
      return
    }
    
    let folder = folderViewController.folder
    
    folderViewController.startLoading()
    driveFetcher.createFolder(named: folderName, in: folder)
      .observe(on: MainScheduler.instance)
      .subscribe { folder in
        folderViewController.add(folder)
      } onError: { _ in
        // TODO: show error
      } onDisposed: {
        folderViewController.stopLoading()
      }
      .disposed(by: disposeBag)
  }
  
  @objc private func selectFolder(_ sender: UIButton) {
    guard let folderViewController = pageViewController.viewControllers?.first
            as? DriveSyncFolderListTableViewController else {
      return
    }
    
    guard let selectedFolder = folderViewController.folder else {
      return
    }
    
    let viewController = DriveSyncSummaryViewController(user: user, folder: selectedFolder, accountsManager: accountsManager)
    show(viewController, sender: nil)
  }
}
