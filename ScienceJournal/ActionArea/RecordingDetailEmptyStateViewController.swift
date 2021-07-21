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
// This VC represents the empty state detail view controller when the user is viewing the trial
// detail view controller in landscape orientation.
final class RecordingDetailEmptyStateViewController: UIViewController {

  private enum Metrics {
    static let stackSpacing: CGFloat = 10
    static let labelTextColor: UIColor = .trialHeaderDefaultBackgroundColor
    static let labelFont = MDCTypography.fontLoader().boldFont?(ofSize: 16)
  }

  let label: UILabel = {
    let label = UILabel()
    label.font = ArduinoTypography.subtitleFont
    label.textColor = Metrics.labelTextColor
    return label
  }()

  var timestampString: String? {
    didSet {
      updateLabel()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    let backgroundImageView =
      UIImageView(image: UIImage(named: "action_area_add_note_placeholder"))
    view.addSubview(backgroundImageView)
    backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
    backgroundImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    backgroundImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant:  -40).isActive = true

    let imageView = UIImageView(image: UIImage(named: "ic_access_time"))
    imageView.tintColor = Metrics.labelTextColor
    updateLabel()
    let stackView = UIStackView(arrangedSubviews: [imageView, label])
    stackView.spacing = Metrics.stackSpacing
    view.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    stackView.topAnchor.constraint(equalTo: backgroundImageView.bottomAnchor).isActive = true
  }

  override var description: String {
    return "\(type(of: self))"
  }

  private func updateLabel() {
    label.text = String.localizedAddNoteTo(with: timestampString ?? "0:00")
  }

}
