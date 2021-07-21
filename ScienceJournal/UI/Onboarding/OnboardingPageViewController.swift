//  
//  OnboardingPageViewController.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 11/11/2020.
//  Copyright © 2020 Arduino. All rights reserved.
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

class OnboardingPageViewController: UIViewController {

  var onPrimaryAction: (() -> Void)?

  var scrollView: UIScrollView { pageView.scrollView }
  var stackView: UIStackView { pageView.stackView }
  var scrollIndicator: OnboardingScrollIndicator { pageView.scrollIndicator }
  
  private lazy var pageView: OnboardingPageView = OnboardingPageView()

  convenience init(primaryAction: (() -> Void)?) {
    self.init()
    onPrimaryAction = primaryAction
  }

  override func loadView() {
    view = pageView
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    pageView.titleLabel.text = self.title
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // let's wait a little bit before starting the animation
    // otherwise it won't run properly
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      self.scrollIndicator.startAnimation()
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    scrollIndicator.stopAnimation()
  }
}
