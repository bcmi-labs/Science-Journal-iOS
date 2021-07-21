//  
//  OnboardingPageView.swift
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

class OnboardingPageView: UIView {

  let scrollView = UIScrollView()
  let stackView = UIStackView()

  let titleLabel = UILabel()

  let scrollIndicator = OnboardingScrollIndicator()

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
    configureConstraints()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
    configureConstraints()
  }
  
  private func configureView() {
    backgroundColor = ArduinoColorPalette.grayPalette.tint50

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(scrollView)
  
    stackView.axis = .vertical
    stackView.alignment = .fill
    stackView.distribution = .fill
    stackView.spacing = 0
    stackView.isLayoutMarginsRelativeArrangement = true
    stackView.addArrangedSubview(titleLabel)
    stackView.setCustomSpacing(20, after: titleLabel)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stackView)

    titleLabel.font = ArduinoTypography.boldFont(forSize: ArduinoTypography.FontSize.Medium.rawValue)
    titleLabel.textAlignment = .center
    titleLabel.textColor = ArduinoColorPalette.grayPalette.tint700
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    
    scrollIndicator.translatesAutoresizingMaskIntoConstraints = false
    addSubview(scrollIndicator)
    bringSubviewToFront(scrollIndicator)
  }
  
  private func configureConstraints() {
    scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    
    stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor).isActive = true
    stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor).isActive = true
    stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor).isActive = true
    stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor).isActive = true
    stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor).isActive = true
    stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()

    updateStackViewMargins()
    updateScrollViewIndicator(animated: false)
  }

  func updateScrollViewIndicator(animated: Bool = true) {
    if !animated {
      // if not animated we are setting the initial state
      // so let's make sure content size and frames are setup
      // correctly
      UIView.performWithoutAnimation {
        self.scrollView.layoutIfNeeded()
      }
    }

    let transform: CGAffineTransform

    if scrollView.isContentOutsideOfSafeArea {
      transform = .identity
    } else {
      transform = CGAffineTransform(translationX: 0, y: scrollIndicator.frame.height)
    }

    guard transform != scrollIndicator.transform else {
      return
    }

    if animated {
      UIView.animate(withDuration: 0.2) {
        self.scrollIndicator.transform = transform
      }
    } else {
      UIView.performWithoutAnimation {
        self.scrollIndicator.transform = transform
      }
    }
  }
}

extension OnboardingPageView: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    updateScrollViewIndicator()
  }
}

private extension OnboardingPageView {
  func updateStackViewMargins() {
    let leading = floor(bounds.width * 0.08)
    let trailing = leading
    stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16,
                                                                 leading: leading,
                                                                 bottom: 24,
                                                                 trailing: trailing)
  }
}

class OnboardingPageControl: UIStackView {

  var numberOfPages: Int = 0 {
    didSet {
      guard numberOfPages != oldValue else { return }
      updateNumberOfPages()
    }
  }

  var currentPage: Int = 0 {
    didSet {
      guard currentPage != oldValue else { return }
      updateCurrentPage()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    setupView()
  }

  required init(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    setupView()
  }

  override var intrinsicContentSize: CGSize {
    var size = super.intrinsicContentSize
    size.height = 2
    return size
  }

  private func setupView() {
    backgroundColor = .clear
    axis = .horizontal
    spacing = 3
    alignment = .fill
    distribution = .fillEqually
  }

  private func updateNumberOfPages() {
    removeAllArrangedViews()

    for _ in 0..<numberOfPages {
      let view = UIView()
      addArrangedSubview(view)
    }

    updateCurrentPage()
  }

  private func updateCurrentPage() {
    for i in 0..<numberOfPages {
      let segment = arrangedSubviews[i]
      if i <= currentPage {
        segment.backgroundColor = .white
      } else {
        segment.backgroundColor = UIColor(white: 1, alpha: 0.4)
      }
    }
  }
}

class OnboardingSpacer: UIView {
  convenience init(fixed: CGFloat? = nil) {
    self.init()
    if let fixed = fixed {
      setContentCompressionResistancePriority(.required, for: .horizontal)
      setContentHuggingPriority(.required, for: .horizontal)
      widthAnchor.constraint(equalToConstant: fixed).isActive = true
    }
  }
}

class OnboardingContainer: UIView {
  convenience init(content: UIView,
                   anchoredTo edges: [Edge] = [.top, .bottom],
                   width: CGFloat? = nil,
                   centered: Bool = true) {
    self.init()
    addSubview(content)
    content.translatesAutoresizingMaskIntoConstraints = false
    content.pinToEdgesOfView(self, andEdges: edges, withInsets: .zero)
    if let width = width {
      content.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    if centered {
      content.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
  }
}

class OnboardingConnector: UIView {

  var edges: [Edge] = []

  private lazy var shapeLayer: CAShapeLayer = {
    let shapeLayer = CAShapeLayer()
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = ArduinoColorPalette.grayPalette.tint300?.cgColor
    shapeLayer.lineWidth = 2
    shapeLayer.lineDashPattern = [4, 4]
    return shapeLayer
  }()

  private var path: CGPath {
    let path = CGMutablePath()

    let p1: CGPoint
    let p2: CGPoint
    let p3: CGPoint
    let p4: CGPoint
    if traitCollection.layoutDirection == .rightToLeft {
      p1 = CGPoint(x: bounds.width, y: 0)
      p2 = CGPoint(x: bounds.width, y: bounds.height)
      p3 = CGPoint(x: 0, y: bounds.height)
      p4 = CGPoint(x: 0, y: 0)
    } else {
      p1 = CGPoint(x: 0, y: 0)
      p2 = CGPoint(x: 0, y: bounds.height)
      p3 = CGPoint(x: bounds.width, y: bounds.height)
      p4 = CGPoint(x: bounds.width, y: 0)
    }

    path.move(to: p1)
    if edges.contains(.leading) {
      path.addLine(to: p2)
    } else {
      path.move(to: p2)
    }

    if edges.contains(.bottom) {
      path.addLine(to: p3)
    } else {
      path.move(to: p3)
    }

    if edges.contains(.trailing) {
      path.addLine(to: p4)
    } else {
      path.move(to: p4)
    }

    if edges.contains(.top) {
      path.addLine(to: p1)
    } else {
      path.move(to: p1)
    }

    return path
  }

  convenience init(edges: [Edge]) {
    self.init(frame: .zero)
    self.edges = edges
    layer.addSublayer(shapeLayer)
  }

  override func layoutSublayers(of layer: CALayer) {
    super.layoutSublayers(of: layer)
    shapeLayer.frame = self.layer.bounds
    shapeLayer.path = self.path
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    shapeLayer.path = self.path
  }
}

class OnboardingPolylineConnector: UIView {

  private lazy var shapeLayer: CAShapeLayer = {
    let shapeLayer = CAShapeLayer()
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = ArduinoColorPalette.grayPalette.tint300?.cgColor
    shapeLayer.lineWidth = 2
    shapeLayer.lineDashPattern = [4, 4]
    return shapeLayer
  }()

  private var path: CGPath {
    let path = CGMutablePath()

    let p1: CGPoint
    let p2: CGPoint
    let p3: CGPoint
    let p4: CGPoint
    if traitCollection.layoutDirection == .rightToLeft {
      p1 = CGPoint(x: bounds.width, y: 0)
      p2 = CGPoint(x: bounds.width, y: bounds.height / 2.0)
      p3 = CGPoint(x: 0, y: bounds.height / 2.0)
      p4 = CGPoint(x: 0, y: bounds.height)
    } else {
      p1 = CGPoint(x: 0, y: 0)
      p2 = CGPoint(x: 0, y: bounds.height / 2.0)
      p3 = CGPoint(x: bounds.width, y: bounds.height / 2.0)
      p4 = CGPoint(x: bounds.width, y: bounds.height)
    }

    path.move(to: p1)
    path.addLine(to: p2)
    path.addLine(to: p3)
    path.addLine(to: p4)

    return path
  }

  init() {
    super.init(frame: .zero)
    layer.addSublayer(shapeLayer)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func layoutSublayers(of layer: CALayer) {
    super.layoutSublayers(of: layer)
    shapeLayer.frame = self.layer.bounds
    shapeLayer.path = self.path
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    shapeLayer.path = self.path
  }
}

class OnboardingHTMLText: UILabel {
  convenience init(text: String, lineHeight: Float? = 24, font: UIFont? = nil) {
    self.init()

    numberOfLines = 0

    let textFont = font ?? ArduinoTypography.regularFont(forSize: ArduinoTypography.FontSize.XSmall.rawValue)
    let textColor = ArduinoColorPalette.grayPalette.tint700!

    attributedText = NSAttributedString(htmlBody: text,
                                        font: textFont,
                                        color: textColor,
                                        lineHeight: lineHeight,
                                        layoutDirection: traitCollection.layoutDirection)
  }
}

class OnboardingText: UILabel {
  convenience init(text: String) {
    self.init()

    numberOfLines = 0

    font = ArduinoTypography.boldFont(forSize: ArduinoTypography.FontSize.XSmall.rawValue)
    textColor = ArduinoColorPalette.grayPalette.tint700!
    self.text = text
  }
}

class OnboardingImage: UIImageView {
  convenience init(imageName: String) {
    self.init()

    contentMode = .scaleAspectFit
    image = UIImage(named: imageName)
  }
}

class OnboardingButton: UIButton {
  enum Style {
    case outline
    case filled
  }
  
  enum Size {
    case small
    case large
  }

  private var style = Style.outline
  private var size = Size.small

  convenience init(style: Style, size: Size = .small, title: String) {
    self.init(type: .system)

    self.size = size
    self.style = style

    let verticalSpacing:CGFloat = self.size == .small ? 4 : 8
    contentEdgeInsets = UIEdgeInsets(top: verticalSpacing,
                                     left: 28,
                                     bottom: verticalSpacing,
                                     right: 28)
    setTitle(title, for: .normal)

    let fontSize = self.size == .small ?
      ArduinoTypography.FontSize.XSmall :
      ArduinoTypography.FontSize.Small
    titleLabel?.font = ArduinoTypography.boldFont(forSize: fontSize.rawValue)

    updateStyle()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = frame.height / 2.0
  }

  private func updateStyle() {
    switch style {
    case .outline:
      setTitleColor(ArduinoColorPalette.grayPalette.tint700, for: .normal)
      backgroundColor = .clear
      layer.borderWidth = 1.5
      layer.borderColor = ArduinoColorPalette.grayPalette.tint700?.cgColor
    case .filled:
      setTitleColor(.white, for: .normal)
      backgroundColor = ArduinoColorPalette.tealPalette.tint800
      layer.borderWidth = 0
      layer.borderColor = nil
    }
  }
}

class OnboardingQuickTip: UIStackView {
  convenience init(text: String) {
    self.init()
    axis = .horizontal
    spacing = 16

    let segment = UIView()
    segment.translatesAutoresizingMaskIntoConstraints = false
    segment.widthAnchor.constraint(equalToConstant: 6).isActive = true
    segment.backgroundColor = ArduinoColorPalette.tealPalette.tint600

    addArrangedSubview(segment)

    let header = UILabel()
    header.numberOfLines = 1
    header.text = String.onboardingQuickTipHeader
    header.font = ArduinoTypography.monoBoldFont(forSize: ArduinoTypography.FontSize.XXSmall.rawValue)
    header.textColor = ArduinoColorPalette.grayPalette.tint700

    let tipFont = ArduinoTypography.monoRegularFont(forSize: ArduinoTypography.FontSize.XXSmall.rawValue)
    let tipColor = ArduinoColorPalette.grayPalette.tint700!

    let tip = UILabel()
    tip.numberOfLines = 0
    tip.attributedText = NSAttributedString(htmlBody: text,
                                            font: tipFont,
                                            color: tipColor,
                                            lineHeight: 22,
                                            layoutDirection: traitCollection.layoutDirection)

    let textContainer = UIStackView(arrangedSubviews: [header, tip])
    textContainer.axis = .vertical
    textContainer.spacing = 0

    addArrangedSubview(textContainer)
  }
}

class OnboardingScrollIndicator: UIView {
  let safeAreaBackgroundView = UIView()
  let backgroundImageView = UIImageView()
  let indicatorView = UIImageView()

  private var animator: UIViewPropertyAnimator?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    configureView()
    configureConstraints()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureView()
    configureConstraints()
  }
  
  func configureView() {
    safeAreaBackgroundView.translatesAutoresizingMaskIntoConstraints = false
    safeAreaBackgroundView.backgroundColor = ArduinoColorPalette.grayPalette.tint50
    addSubview(safeAreaBackgroundView)
    
    backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
    backgroundImageView.image = UIImage(named: "onboarding_scroll_indicator_bg")?.resizableImage(withCapInsets: .zero)
    addSubview(backgroundImageView)
    
    indicatorView.image = UIImage(named: "onboarding_scroll_indicator")
    indicatorView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(indicatorView)
  }
  
  func configureConstraints() {
    safeAreaBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    safeAreaBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    safeAreaBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    safeAreaBackgroundView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    
    backgroundImageView.heightAnchor.constraint(equalToConstant: 64).isActive = true
    backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    backgroundImageView.bottomAnchor.constraint(equalTo: safeAreaBackgroundView.topAnchor).isActive = true
    
    indicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    indicatorView.bottomAnchor.constraint(equalTo: safeAreaBackgroundView.topAnchor, constant: -12).isActive = true
  }
  
  func startAnimation(_ reversed: Bool = false) {
    if let animator = animator, animator.isRunning {
      return
    }

    let animator = UIViewPropertyAnimator(duration: 1.25,
                                          timingParameters: UICubicTimingParameters(animationCurve: .easeInOut))
    animator.addAnimations { [weak indicatorView] in
      indicatorView?.transform =  reversed ? .identity : CGAffineTransform(translationX: 0, y: -15)
    }
    animator.addCompletion { [weak self] _ in
      self?.animator = nil
      self?.startAnimation(!reversed)
    }
    animator.startAnimation()

    self.animator = animator
  }

  func stopAnimation() {
    animator?.stopAnimation(true)
  }
}
