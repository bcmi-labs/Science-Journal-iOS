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
import MaterialComponents.MaterialPalettes

/// The timer view is a capsule containing the current recording timer.
/// It is meant to be used in a bar button item.
final class TimerView: UIView {

  enum Metrics {
    static let padding: CGFloat = 5
    static let spacing: CGFloat = 8
    static let backgroundCornerRadius: CGFloat = 14
    static let overallLayoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
    static let contentEdgeInsets = UIEdgeInsets(top: padding,
                                                left: padding,
                                                bottom: padding,
                                                right: backgroundCornerRadius)
    static let contentBackgroundColor: UIColor = .white
    static let dotDimension: CGFloat = 14
    static let dotCornerRadius: CGFloat = dotDimension / 2
    static let dotColor: UIColor = .trialHeaderRecordingBackgroundColor
    static let labelFont: UIFont = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
    static let labelTextColor: UIColor = MDCPalette.grey.tint900
  }

  /// The timer label.
  private let timerLabel: UILabel = {
    let timerLabel = UILabel()
    timerLabel.font = Metrics.labelFont
    timerLabel.textColor = Metrics.labelTextColor
    timerLabel.isAccessibilityElement = true
    timerLabel.accessibilityTraits = .updatesFrequently
    return timerLabel
  }()

  /// The elapsed time formatter.
  private let timeFormatter : ElapsedTimeFormatter = {
    let timeFormatter = ElapsedTimeFormatter()
    timeFormatter.alwaysDisplayHours = true
    timeFormatter.shouldDisplayTenths = false
    return timeFormatter
  }()

  // MARK: - Public

  override init(frame: CGRect) {
    super.init(frame: .zero)
    configureView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    return systemLayoutSizeFitting(size)
  }

  /// Updates `timerLabel.text` with a formatted version of `duration`.
  ///
  /// - Parameter duration: The duration to format and display.
  func updateTimerLabel(with duration: Int64) {
    timerLabel.text = timeFormatter.string(fromTimestamp: duration)
  }

  // MARK: - Private

  private func configureView() {
    layoutMargins = Metrics.overallLayoutMargins

    let contentView : UIView = {
      let contentView = UIView()
      contentView.layer.cornerRadius = Metrics.backgroundCornerRadius
      contentView.backgroundColor = Metrics.contentBackgroundColor
      contentView.layoutMargins = Metrics.contentEdgeInsets
      return contentView
    }()

    let dotView : UIView = {
      let dotView = UIView()
      dotView.backgroundColor = Metrics.dotColor
      dotView.layer.cornerRadius = Metrics.dotCornerRadius
      return dotView
    }()

    addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    contentView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

    contentView.addSubview(dotView)
    dotView.translatesAutoresizingMaskIntoConstraints = false
    dotView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
    dotView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    dotView.heightAnchor.constraint(equalToConstant: Metrics.dotDimension).isActive = true
    dotView.widthAnchor.constraint(equalToConstant: Metrics.dotDimension).isActive = true

    contentView.addSubview(timerLabel)
    timerLabel.translatesAutoresizingMaskIntoConstraints = false
    timerLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
    timerLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    timerLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
    timerLabel.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: Metrics.spacing).isActive = true
    
    timerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    timerLabel.setContentHuggingPriority(.required, for: .horizontal)
    timerLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    timerLabel.setContentHuggingPriority(.required, for: .vertical)

    updateTimerLabel(with: 0)
  }

}
