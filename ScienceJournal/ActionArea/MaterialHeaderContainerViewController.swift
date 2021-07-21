/*
 *  Copyright 2019 Google LLC. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

import UIKit

import MaterialComponents.MaterialAppBar

// TODO: Ensure this handles existing issues or use one of the other superclasses.
// TODO: Consider making this private and wrapping content VCs that are not subclasses
//       of the other material header types.
final class MaterialHeaderContainerViewController: ContentContainerViewController {

  private let appBar = MDCAppBar()

  override func viewDidLoad() {
    super.viewDidLoad()

    if let collectionViewController = content as? UICollectionViewController {
      appBar.configure(attachTo: self, scrollView: collectionViewController.collectionView)
    } else {
      appBar.configure(attachTo: self)
    }

    content.view.translatesAutoresizingMaskIntoConstraints = false
    content.view.topAnchor.constraint(equalTo: appBar.navigationBar.bottomAnchor).isActive = true
    content.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    content.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    content.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }

  override var description: String {
    return "\(type(of: self))(content: \(String(describing: content)))"
  }

}

extension MaterialHeaderContainerViewController {
  override func setCustomTint(_ customTint: CustomTint) {
    appBar.headerViewController.headerView.backgroundColor = customTint.primary
    super.setCustomTint(customTint)
  }
}
