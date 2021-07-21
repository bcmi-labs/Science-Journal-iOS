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

import SafariServices

protocol SidebarDelegate: class {
  func sidebarShouldShow(_ item: SidebarRow)
  func sidebarShouldShowSignIn()
  func sidebarDidClose()
  func sidebarDidOpen()
}

/// Represents rows in the sidebar that provides titles and icons for each item.
enum SidebarRow {
  case settings
  case feedback
  case onboarding
  case activities
  case help
  case scienceKit
  case privacy
  case terms

  var title: String {

    switch self {
    case .settings: return String.actionAccountSettings
    case .feedback: return String.actionFeedback
    case .onboarding: return String.navigationGettingStarted
    case .activities: return String.navigationActivities
    case .help: return String.navigationGetHelp
    case .scienceKit: return String.navigationGetScienceKit
    case .privacy: return String.settingsPrivacyPolicyTitle
    case .terms: return String.driveSyncTermsOfService
    }
  }

  var icon: String {
    switch self {
    case .settings: return "ic_settings_36pt"
    case .feedback: return "ic_feedback_36pt"
    case .onboarding: return "ic_onboarding_36pt"
    case .activities: return "ic_activities_36pt"
    case .help: return "ic_help_36pt"
    case .scienceKit: return "ic_science_kit_36pt"
    case .privacy: return "ic_privacy_36pt"
    case .terms: return "ic_info_36pt"
    }
  }

  var accessoryIcon: UIImage? {
    switch self {
    case .activities, .help, .scienceKit:
      return UIImage(named: "ic_open_in_36pt")
    default: return nil
    }
  }
}

/// Controls the contents of the sidebar menu and manages its appearance and disappearance.
class SidebarViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, SidebarAccountViewDelegate {

  // MARK: - Nested types

  /// Enum for changing the visual state of the Sidebar, used in animations.
  enum SidebarState {
    case visible
    case hidden

    var dimmingAlpha: CGFloat {
      switch self {
      case .visible: return 1.0
      case .hidden: return 0
      }
    }

    var elevation: CGFloat {
      switch self {
      case .visible: return 16.0
      case .hidden: return 0
      }
    }

    var isSidebarVisible: Bool {
      switch self {
      case .visible: return true
      case .hidden: return false
      }
    }
  }

  // MARK: - DataSource

  var menuFirstSection: [SidebarRow] {
    let account = accountsManager.currentAccount
    if account?.type == .adult {
      return [
        .activities,
        .scienceKit,
        .help,
      ]
    } else if account?.type == .kid {
      return [
        .onboarding,
        .settings,
        .privacy,
        .terms,
      ]
    } else {
      // not logged in
      return [
        .activities,
        .scienceKit,
        .help,
      ]
    }
  }

  var menuSecondSection: [SidebarRow] {
    let account = accountsManager.currentAccount
    if account?.type == .adult {
      return [
        .onboarding,
        .settings,
        .privacy,
        .terms,
      ]
    } else if account?.type == .kid {
      return []
    } else {
      // not logged in
      return [
        .onboarding,
        .privacy,
        .terms,
      ]
    }
  }

  // MARK: - Constants

  let animationDuration: TimeInterval = 0.26
  let cellHeight: CGFloat = 48.0
  let cellIdentifier = "SidebarCell"
  let dragWidthThresholdClose: CGFloat = -125.0
  let headerCellIdentifier = "SidebarHeaderCell"
  let headerHeight: CGFloat = 150  // image plus a 10.0 inner vertical gap.
  let separatorCellIdentifier = "SidebarSeparatorCell"
  let separatorHeight: CGFloat = 40
  let sidebarMaxWidth: CGFloat = 290.0
  let velocityCap: CGFloat = 600.0
  var wrapperViewTopConstraint: NSLayoutConstraint?

  var statusBarHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.size.height
  }

  // MARK: - Properties

  /// The sidebar delegate, which listens for events upon opening/closing of the sidebar and when
  /// a sidebar item is tapped.
  weak var delegate: SidebarDelegate?

  private let accountsManager: AccountsManager
  private let analyticsReporter: AnalyticsReporter
  private var collectionView = UICollectionView(frame: .zero,
                                                collectionViewLayout: UICollectionViewFlowLayout())
  private var sidebarVisibilityConstraint = NSLayoutConstraint()
  private let dimmingView = UIView()
  private let wrapperView = ShadowedView()
  private let accountView = SidebarAccountView()
  
  private var collectionEdgeInsets: UIEdgeInsets {
    // In RTL, this will add right side inset to the items.
    return UIEdgeInsets(top: 0, left: view.safeAreaInsetsOrZero.left, bottom: 0, right: 0)
  }

  // MARK: - Public

  init(accountsManager: AccountsManager, analyticsReporter: AnalyticsReporter) {
    self.accountsManager = accountsManager
    self.analyticsReporter = analyticsReporter
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
    modalPresentationCapturesStatusBarAppearance = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView.register(SidebarCell.self, forCellWithReuseIdentifier: cellIdentifier)
    collectionView.register(SidebarHeaderCell.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: headerCellIdentifier)
    collectionView.register(SidebarSeparatorCell.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: separatorCellIdentifier)

    view.backgroundColor = .clear
    accessibilityViewIsModal = true

    // Dimming background view.
    view.addSubview(dimmingView)
    dimmingView.backgroundColor = UIColor(white: 0, alpha: 0.6)
    dimmingView.alpha = 0
    dimmingView.translatesAutoresizingMaskIntoConstraints = false
    dimmingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    dimmingView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    dimmingView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true

    // Shadowed wrapper view.
    view.addSubview(wrapperView)
    // Standard Material nav drawer elevation.
    // https://material.io/guidelines/patterns/navigation-drawer.html
    wrapperView.setElevation(points: SidebarState.hidden.elevation)
    wrapperView.translatesAutoresizingMaskIntoConstraints = false

    sidebarVisibilityConstraint = wrapperView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                                       constant: -sidebarMaxWidth)
    sidebarVisibilityConstraint.isActive = true
    wrapperViewTopConstraint = wrapperView.topAnchor.constraint(equalTo: view.topAnchor,
                                                                constant: -statusBarHeight)
    wrapperViewTopConstraint?.isActive = true
    wrapperView.widthAnchor.constraint(equalToConstant: sidebarMaxWidth).isActive = true
    wrapperView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    // CollectionView.
    wrapperView.addSubview(collectionView)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.backgroundColor = .white
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.topAnchor.constraint(equalTo: wrapperView.topAnchor).isActive = true
    collectionView.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor).isActive = true
    collectionView.widthAnchor.constraint(equalTo: wrapperView.widthAnchor).isActive = true

    let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
    gestureRecognizer.delegate = self
    wrapperView.addGestureRecognizer(gestureRecognizer)

    // Account footer view.
    if accountsManager.supportsAccounts {
      accountView.delegate = self
      accountView.translatesAutoresizingMaskIntoConstraints = false
      wrapperView.addSubview(accountView)
      accountView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor).isActive = true
      accountView.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor).isActive = true
      accountView.trailingAnchor.constraint(equalTo: wrapperView.trailingAnchor).isActive = true
      collectionView.bottomAnchor.constraint(equalTo: accountView.topAnchor).isActive = true
      if let currentAccount = accountsManager.currentAccount {
        accountView.showAccount(withName: currentAccount.displayName,
                                email: currentAccount.email,
                                profileImage: currentAccount.profileImage)
      } else {
        accountView.showNoAccount()
      }
      
    } else {
      // Without an account footer, the collectionView is pinned to the bottom of the wrapper.
      collectionView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor).isActive = true
    }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  /// When the view rotates, update layout to properly resize the sidebar and enable scrolling
  /// when necessary.
  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: nil) { _ in
      self.wrapperViewTopConstraint?.constant = -self.statusBarHeight
      self.wrapperView.layoutIfNeeded()
    }
  }

  /// Show the sidebar.
  ///
  /// - Parameters:
  ///   - animated: Animate the reveal of the sidebar?
  ///   - duration: The duration of the animated reveal.
  func show(animated: Bool = true, duration: TimeInterval? = nil) {
    updateVisibilityConstraint(show: true)
    animate(state: .visible, duration: duration)
  }

  /// Hide the sidebar.
  ///
  /// - Parameters:
  ///   - animated: Animate the dismissal of the sidebar?
  ///   - duration: The duration of the animated dismissal.
  ///   - completion: An optional block to fire once the sidebar has hidden.
  func hide(animated: Bool = true, duration: TimeInterval? = nil, completion: (() -> Void)? = nil) {
    updateVisibilityConstraint(show: false)
    animate(state: .hidden, duration: duration) {
      self.dismiss(animated: false, completion: completion)
    }
  }

  override func accessibilityPerformEscape() -> Bool {
    hide()
    return true
  }
  
  // MARK: - Private

  private func updateVisibilityConstraint(show: Bool) {
    sidebarVisibilityConstraint.constant = show ? 0 : -sidebarMaxWidth
  }

  // Animates the state of the sidebar and fires an optional completion block when done.
  private func animate(state: SidebarState,
                       duration: TimeInterval?,
                       completion: (() -> Void)? = nil) {
    wrapperView.layer.shouldRasterize = false

    UIView.animate(withDuration: duration ?? animationDuration,
                   delay: 0,
                   options: .beginFromCurrentState,
                   animations: {
      self.dimmingView.alpha = state.dimmingAlpha
      self.wrapperView.setElevation(points: state.elevation)
      self.view.setNeedsUpdateConstraints()
      self.view.layoutIfNeeded()
    }) { (_) in
      if state == SidebarState.visible {
        self.delegate?.sidebarDidOpen()
      } else {
        self.delegate?.sidebarDidClose()
      }

      self.wrapperView.layer.shouldRasterize = true
      if let completion = completion {
        completion()
      }
    }
  }

  // MARK: - SidebarAccountViewDelegate

  func sidebarAccountViewTapped() {
    // Hide the sidebar and when that's done, tell the delegate to show the account selector.
    hide {
      self.delegate?.sidebarShouldShowSignIn()
    }
    analyticsReporter.track(.signInFromSidebar)
  }

  // MARK: - UIGestureRecognizerDelegate, panning and background touch

  // Only recognize a pan gesture if it is horizontal, otherwise fall back to scroll support in
  // the collectionView.
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
      return true
    }
    let velocity = pan.velocity(in: wrapperView)
    return abs(velocity.y) < abs(velocity.x)
  }

  @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
    let translation = gestureRecognizer.translation(in: wrapperView)

    if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
      if translation.x < 0 {
        sidebarVisibilityConstraint.constant = translation.x
      }
    } else if gestureRecognizer.state == .ended {
      // The velocity of the pan gesture in `wrapperView`. Panning left gives a negative velocity,
      // panning right gives a positive velocity. For the purposes of hiding the view, we only
      // care about the negative velocity...
      var velocity: CGFloat = gestureRecognizer.velocity(in: wrapperView).x
      // So we track the direction to see if we need to close the sidebar at all.
      let velocityDirectionClose = velocity < 0

      if sidebarVisibilityConstraint.constant <= dragWidthThresholdClose || velocityDirectionClose {
        // Turn velocity into a positive number so we can use it to determine duration, and cap it
        // at a maximum value for visual reasons.
        velocity = max(abs(velocity), velocityCap)
        // Determine the distance remaining for the sidebar to close.
        let distance: CGFloat = (sidebarMaxWidth + translation.x)
        // Duration is distance remaing over velocity, capped at a maximum.
        let duration: TimeInterval = max(TimeInterval(distance / velocity), animationDuration)

        hide(animated: true, duration: duration)
      } else {
        show()
      }
    }
  }

  // Dismiss the sidebar if the user touches the non-sidebar background area.
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    hide()
  }

  // MARK: - CollectionView Delegate and DataSource

  @objc func collectionView(_ collectionView: UICollectionView,
                            layout collectionViewLayout: UICollectionViewLayout,
                            insetForSectionAt section: Int) -> UIEdgeInsets {
    return collectionEdgeInsets
  }

  @objc func collectionView(_ collectionView: UICollectionView,
                            layout: UICollectionViewLayout,
                            referenceSizeForHeaderInSection section: Int) -> CGSize {
    if section == 0 {
      return CGSize(width: view.bounds.size.width, height: headerHeight)
    } else {
      return CGSize(width: view.bounds.size.width, height: separatorHeight)
    }
  }

  @objc func collectionView(_ collectionView: UICollectionView,
                            layout collectionViewLayout: UICollectionViewLayout,
                            sizeForItemAt indexPath: IndexPath) -> CGSize {
    let itemWidth = collectionView.bounds.size.width - collectionEdgeInsets.left
    return CGSize(width: itemWidth, height: cellHeight)
  }

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {

    if section == 0 {
      return menuFirstSection.count
    } else {
      return menuSecondSection.count
    }
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int { 
    return 2
  }

  func collectionView(_ collectionView: UICollectionView,
                      viewForSupplementaryElementOfKind kind: String,
                      at indexPath: IndexPath) -> UICollectionReusableView {
    
    if indexPath.section == 0 {
      return collectionView.dequeueReusableSupplementaryView(
          ofKind: UICollectionView.elementKindSectionHeader,
          withReuseIdentifier: headerCellIdentifier,
          for: indexPath)
    } else {
      return collectionView.dequeueReusableSupplementaryView(
          ofKind: UICollectionView.elementKindSectionHeader,
          withReuseIdentifier: separatorCellIdentifier,
          for: indexPath)
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier,
                                                  for: indexPath)
    if let cell = cell as? SidebarCell {
      let cellData = indexPath.section == 0 ? menuFirstSection[indexPath.item] : menuSecondSection[indexPath.item]
      cell.titleLabel.text = cellData.title
      cell.accessibilityLabel = cell.titleLabel.text
      cell.iconView.image = UIImage(named: cellData.icon)
      cell.accessoryIconView.image = cellData.accessoryIcon
    }
    return cell
  }

  func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath) {
    hide {
      if indexPath.section == 0 {
        self.delegate?.sidebarShouldShow(self.menuFirstSection[indexPath.item])
      } else {
        self.delegate?.sidebarShouldShow(self.menuSecondSection[indexPath.item])
      }
    }
  }

}
