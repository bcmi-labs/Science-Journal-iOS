//  
//  WizardRootViewController.swift
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

extension WizardRootViewController {
  override func backToSignIn() {
    guard let vc = childNavigationController.viewControllers.first(where: { $0 is SignInIntroViewController }) else {
      return
    }
    childNavigationController.popToViewController(vc, animated: true)
  }
  
  override func backToSignUp(error: [String: Any]?) {
    guard let vc = childNavigationController
            .viewControllers
            .first(where: { $0 is SignUpViewController }) as? SignUpViewController else {
      return
    }
    vc.error = error
    childNavigationController.popToViewController(vc, animated: true)
  }
}
