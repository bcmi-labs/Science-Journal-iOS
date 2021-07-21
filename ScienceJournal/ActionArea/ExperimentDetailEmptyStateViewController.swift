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

import MaterialComponents.MaterialTypography

// TODO: This VC still needs a final image.
final class ExperimentDetailEmptyStateViewController: UIViewController {

  private enum Metrics {
    static let labelTextColor: UIColor = .lightGray
    static let labelFont = MDCTypography.fontLoader().boldFont?(ofSize: 16)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = ArduinoColorPalette.containerBackgroundColor

    let backgroundImageView =
      UIImageView(image: UIImage(named: "action_area_add_note_placeholder"))
    view.addSubview(backgroundImageView)
    backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
    backgroundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    backgroundImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40).isActive = true

    let label = UILabel()
    label.font = ArduinoTypography.subtitleFont
    label.text = String.actionAreaAddMoreNotes
    label.textColor = Metrics.labelTextColor
    view.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    label.topAnchor.constraint(equalTo: backgroundImageView.bottomAnchor).isActive = true
  }

  override var description: String {
    return "\(type(of: self))"
  }

}
