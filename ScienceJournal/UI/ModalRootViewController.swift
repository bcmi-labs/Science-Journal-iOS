//  
//  ModalRootViewController.swift
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
import RxSwift
import SafariServices

class ModalRootViewController: UIViewController {
  
  var onDismiss: ((_ modal: ModalRootViewController, _ isCancelled: Bool) -> Void)?
  
  var initialViewController: UIViewController? {
    didSet {
      guard isViewLoaded else { return }
      guard let viewController = initialViewController else { return }
      childNavigationController?.setViewControllers([viewController], animated: true)
    }
  }
  
  var childNavigationController: UINavigationController? {
    didSet {
      oldValue?.delegate = nil
      childNavigationController?.delegate = self
      childNavigationController?.navigationBar.titleTextAttributes = [
        NSAttributedString.Key.font: ArduinoTypography.boldFont(forSize: 20),
        NSAttributedString.Key.foregroundColor: ArduinoColorPalette.tealPalette.tint800!
      ]
    }
  }
  
  private var disposeBag: DisposeBag?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let viewController = initialViewController {
      childNavigationController?.setViewControllers([viewController], animated: true)
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "childNavigationController",
       let navigationController = segue.destination as? UINavigationController {
      childNavigationController = navigationController
    } else {
      super.prepare(for: segue, sender: sender)
    }
  }
  
  func close(isCancelled: Bool) {
    onDismiss?(self, isCancelled)
  }
  
  @objc
  private func close(_ sender: UIBarButtonItem) {
    close(isCancelled: true)
  }
  
  private func createCloseButton() -> UIBarButtonItem {
    let button = UIBarButtonItem(image: UIImage(named: "navigation_close"),
                                 style: .plain,
                                 target: self,
                                 action: #selector(close(_:)))
    return button
  }
  
}

extension ModalRootViewController: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController,
                            willShow viewController: UIViewController,
                            animated: Bool) {
    viewController.navigationItem.rightBarButtonItem = createCloseButton()
    
    if let modal = viewController as? ModalViewController {
      modal.rootViewController = self
      
      let disposeBag = DisposeBag()
      
      modal.isLoading
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
