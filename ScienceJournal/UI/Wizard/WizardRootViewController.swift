//  
//  WizardRootViewController.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 04/01/21.
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
import RxSwift
import SafariServices

class WizardRootViewController: UIViewController {
  
  var onDismiss: ((_ wizard: WizardRootViewController, _ isCancelled: Bool) -> Void)?
  
  var initialViewController: UIViewController? {
    didSet {
      guard isViewLoaded else { return }
      guard let viewController = initialViewController else { return }
      childNavigationController.setViewControllers([viewController], animated: true)
    }
  }
  
  let childNavigationController = WizardNavigationController()
  
  let footerView = WizardFooterView()
  let childContainer = UIView()
  
  private var disposeBag: DisposeBag?
  
  override func loadView() {
    view = UIView()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
    configureConstraints()
    addChildNavigation()
    if let viewController = initialViewController {
      childNavigationController.setViewControllers([viewController], animated: true)
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    footerView.layer.shadowPath = UIBezierPath(rect: footerView.bounds).cgPath
  }
  
  private func configureView() {
    childContainer.translatesAutoresizingMaskIntoConstraints = false
    childContainer.clipsToBounds = true
    view.addSubview(childContainer)
    
    footerView.clipsToBounds = false
    footerView.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
    footerView.layer.shadowOffset = CGSize(width: 0, height: -3)
    footerView.layer.shadowOpacity = 1
    footerView.layer.shadowRadius = 0
    footerView.translatesAutoresizingMaskIntoConstraints = false
    footerView.termsButton.addTarget(self, action: #selector(showTermsOfService), for: .touchUpInside)
    footerView.privacyButton.addTarget(self, action: #selector(showPrivacyPolicy), for: .touchUpInside)
    view.addSubview(footerView)
    
    childNavigationController.navigationBar.titleTextAttributes = [
      NSAttributedString.Key.font: ArduinoTypography.boldFont(forSize: 20),
      NSAttributedString.Key.foregroundColor: ArduinoColorPalette.tealPalette.tint800!
    ]
  }
  
  private func configureConstraints() {
    footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    footerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -42).isActive = true
    
    childContainer.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    childContainer.bottomAnchor.constraint(equalTo: footerView.topAnchor).isActive = true
    childContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    childContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
  }
  
  private func addChildNavigation() {
    childNavigationController.delegate = self
    addChild(childNavigationController)
    childNavigationController.view.frame = childContainer.frame
    childContainer.addSubview(childNavigationController.view)
    childNavigationController.didMove(toParent: self)
  }
  
  func close(isCancelled: Bool) {
    onDismiss?(self, isCancelled)
  }
  
  @objc
  private func close(_ sender: UIBarButtonItem) {
    close(isCancelled: true)
  }
  
  @objc
  func showTermsOfService() {
    let vc = SFSafariViewController(url: Constants.ArduinoScienceJournalURLs.sjTermsOfServiceUrl)
    present(vc, animated: true, completion: nil)
  }
  
  @objc
  func showPrivacyPolicy() {
    let vc = SFSafariViewController(url: Constants.ArduinoSignIn.privacyPolicyUrl)
    present(vc, animated: true, completion: nil)
  }
  
  private func createCloseButton() -> UIBarButtonItem {
    let button = UIBarButtonItem(image: UIImage(named: "navigation_close"),
                                 style: .plain,
                                 target: self,
                                 action: #selector(close(_:)))
    return button
  }
  
}

extension WizardRootViewController: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController,
                            willShow viewController: UIViewController,
                            animated: Bool) {
    viewController.navigationItem.rightBarButtonItem = createCloseButton()
    viewController.view.backgroundColor = navigationController.navigationBar.barTintColor
    
    if let wizard = viewController as? WizardViewController {
      wizard.rootViewController = self
      
      let disposeBag = DisposeBag()
      
      wizard.isLoading
        .distinctUntilChanged()
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: {
          viewController.navigationItem.titleView = $0 ? NavigationActivityIndicatorView() : nil
        })
        .disposed(by: disposeBag)
      
      self.disposeBag = disposeBag
    }
  }
}
