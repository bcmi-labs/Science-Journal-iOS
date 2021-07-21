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

import MaterialComponents.MaterialDialogs

import googlemac_iPhone_Shared_SSOAuth_SSOAuth
import GTMSessionFetcher

/// The primary view controller for Science Journal which owns the navigation controller and manages
/// all other flows and view controllers.
class AppFlowViewController: UIViewController {

  /// The account user manager for the current account. Exposed for testing. If the current
  /// account's ID matches the existing accountUserManager account ID, this returns the existing
  /// manager. If not, a new manager is created for the current account and returned.
  var currentAccountUserManager: AccountUserManager? {
    guard let account = accountsManager.currentAccount else { return nil }

    if _currentAccountUserManager == nil || _currentAccountUserManager!.account.ID != account.ID {
      _currentAccountUserManager = AccountUserManager(fileSystemLayout: fileSystemLayout,
                                                      account: account,
                                                      driveConstructor: driveConstructor,
                                                      networkAvailability: networkAvailability,
                                                      sensorController: sensorController,
                                                      analyticsReporter: analyticsReporter)
    }
    return _currentAccountUserManager
  }

  private var _currentAccountUserManager: AccountUserManager?

  /// The device preference manager. Exposed for testing.
  let devicePreferenceManager = DevicePreferenceManager()

  /// The root user manager. Exposed for testing.
  let rootUserManager: RootUserManager

  /// The accounts manager. Exposed so the AppDelegate can ask for reauthentication and related
  /// tasks, as well as testing.
  let accountsManager: AccountsManager

  private let analyticsReporter: AnalyticsReporter
  private let commonUIComponents: CommonUIComponents
  private let drawerConfig: DrawerConfig
  private let driveConstructor: DriveConstructor
  private var existingDataMigrationManager: ExistingDataMigrationManager?
  private var existingDataOptionsVC: ExistingDataOptionsViewController?
  private let feedbackReporter: FeedbackReporter
  private let fileSystemLayout: FileSystemLayout
  private let networkAvailability: NetworkAvailability
  private let queue = GSJOperationQueue()
  private let sensorController: SensorController
  private var shouldShowPreferenceMigrationMessage = false

  /// The current user flow view controller, if it exists.
  private weak var userFlowViewController: UserFlowViewController?

  #if FEATURE_FIREBASE_RC
  private var remoteConfigManager: RemoteConfigManager?

  /// Convenience initializer.
  ///
  /// - Parameters:
  ///   - fileSystemLayout: The file system layout.
  ///   - accountsManager: The accounts manager.
  ///   - analyticsReporter: The analytics reporter.
  ///   - commonUIComponents: Common UI components.
  ///   - drawerConfig: The drawer config.
  ///   - driveConstructor: The drive constructor.
  ///   - feedbackReporter: The feedback reporter.
  ///   - networkAvailability: Network availability.
  ///   - remoteConfigManager: The remote config manager.
  ///   - sensorController: The sensor controller.
  convenience init(fileSystemLayout: FileSystemLayout,
                   accountsManager: AccountsManager,
                   analyticsReporter: AnalyticsReporter,
                   commonUIComponents: CommonUIComponents,
                   drawerConfig: DrawerConfig,
                   driveConstructor: DriveConstructor,
                   feedbackReporter: FeedbackReporter,
                   networkAvailability: NetworkAvailability,
                   remoteConfigManager: RemoteConfigManager,
                   sensorController: SensorController) {
    self.init(fileSystemLayout: fileSystemLayout,
              accountsManager: accountsManager,
              analyticsReporter: analyticsReporter,
              commonUIComponents: commonUIComponents,
              drawerConfig: drawerConfig,
              driveConstructor: driveConstructor,
              feedbackReporter: feedbackReporter,
              networkAvailability: networkAvailability,
              sensorController: sensorController)
    self.remoteConfigManager = remoteConfigManager
  }
  #endif

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - fileSystemLayout: The file system layout.
  ///   - accountsManager: The accounts manager.
  ///   - analyticsReporter: The analytics reporter.
  ///   - commonUIComponents: Common UI components.
  ///   - drawerConfig: The drawer config.
  ///   - driveConstructor: The drive constructor.
  ///   - feedbackReporter: The feedback reporter.
  ///   - networkAvailability: Network availability.
  ///   - sensorController: The sensor controller.
  init(fileSystemLayout: FileSystemLayout,
       accountsManager: AccountsManager,
       analyticsReporter: AnalyticsReporter,
       commonUIComponents: CommonUIComponents,
       drawerConfig: DrawerConfig,
       driveConstructor: DriveConstructor,
       feedbackReporter: FeedbackReporter,
       networkAvailability: NetworkAvailability,
       sensorController: SensorController) {
    self.fileSystemLayout = fileSystemLayout
    self.accountsManager = accountsManager
    self.analyticsReporter = analyticsReporter
    self.commonUIComponents = commonUIComponents
    self.drawerConfig = drawerConfig
    self.driveConstructor = driveConstructor
    self.feedbackReporter = feedbackReporter
    self.networkAvailability = networkAvailability
    self.sensorController = sensorController
    rootUserManager = RootUserManager(
      fileSystemLayout: fileSystemLayout,
      sensorController: sensorController
    )
    super.init(nibName: nil, bundle: nil)

    // Register as the delegate for AccountsManager.
    self.accountsManager.delegate = self

    #if SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
    // If we should create root user data to test the claim flow, this notification will be fired.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(debug_createRootUserData),
                                           name: .DEBUG_createRootUserData,
                                           object: nil)
    // If we should create root user data and force auth to test the migration flow, this
    // notification will be fired.
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(debug_forceAuth),
                                           name: .DEBUG_forceAuth,
                                           object: nil)

    #endif  // SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if accountsManager.supportsAccounts {
      accountsManager.signInAsCurrentAccount()
    } else {
      reloadUserFlowViewController()
    }
  } 

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return children.last?.preferredStatusBarStyle ?? .lightContent
  }

  private func reloadUserFlowViewController() {
    guard let accountUserManager = currentAccountUserManager else {
      print("[AppFlowViewController] No current account user manager, must sign in.")
      showNonAccountUser(animated: false)
      return
    }

    let existingDataMigrationManager =
        ExistingDataMigrationManager(accountUserManager: accountUserManager,
                                     rootUserManager: rootUserManager)
    let accountUserFlow = UserFlowViewController(
        accountsManager: accountsManager,
        analyticsReporter: analyticsReporter,
        commonUIComponents: commonUIComponents,
        devicePreferenceManager: devicePreferenceManager,
        drawerConfig: drawerConfig,
        existingDataMigrationManager: existingDataMigrationManager,
        feedbackReporter: feedbackReporter,
        networkAvailability: networkAvailability,
        sensorController: sensorController,
        shouldShowPreferenceMigrationMessage: shouldShowPreferenceMigrationMessage,
        userManager: accountUserManager)
    accountUserFlow.delegate = self
    userFlowViewController = accountUserFlow
    transitionToViewControllerModally(accountUserFlow) { [weak self] in
      self?.setupDriveSyncIfNeeded()
    }

    // Set to false now so we don't accidently cache true and show it again when we don't want to.
    shouldShowPreferenceMigrationMessage = false
  }

  private func showNonAccountUser(animated: Bool) {
    let userFlow = UserFlowViewController(accountsManager: accountsManager,
                                          analyticsReporter: analyticsReporter,
                                          commonUIComponents: commonUIComponents,
                                          devicePreferenceManager: devicePreferenceManager,
                                          drawerConfig: drawerConfig,
                                          existingDataMigrationManager: nil,
                                          feedbackReporter: feedbackReporter,
                                          networkAvailability: networkAvailability,
                                          sensorController: sensorController,
                                          shouldShowPreferenceMigrationMessage: false,
                                          userManager: rootUserManager)
    userFlow.delegate = self
    userFlowViewController = userFlow
    transitionToViewControllerModally(userFlow, animated: animated)
  }

  /// Handles a file import URL if possible.
  ///
  /// - Parameter url: A file URL.
  /// - Returns: True if the URL can be handled, otherwise false.
  func handleImportURL(_ url: URL) -> Bool {
    if accountsManager.handle(redirectURL: url) {
      return true
    }
    
    guard let userFlowViewController = userFlowViewController else {
      showSnackbar(withMessage: String.importSignInError)
      return false
    }
    
    return userFlowViewController.handleImportURL(url)
  }

  // MARK: - Private
  
  private func setupDriveSyncIfNeeded() {
    guard let userManager = currentAccountUserManager else {
      return
    }
    
    guard userManager.account.supportsDriveSync else {
      return
    }
    
    guard userManager.preferenceManager.driveSyncUserID == nil ||
            userManager.preferenceManager.driveSyncFolderID == nil else {
      return
    }
    
    guard !userManager.preferenceManager.driveSyncSetupSkipped else {
      return
    }
    
    accountsManager.setupDriveSync(fromViewController: self, isSignup: true)
  }

  private func handlePermissionDenial() {
    // Remove the current account and force the user to sign in.
    accountsManager.signOutCurrentAccount()
    analyticsReporter.track(.signInPermissionDenied)
  }

  /// Migrates preferences and removes bluetooth devices if this account is signing in for the first
  /// time.
  ///
  /// - Parameter accountID: The account ID.
  /// - Returns: Whether the user should be messaged saying that preferences were migrated.
  private func migratePreferencesAndRemoveBluetoothDevicesIfNeeded(forAccountID accountID: String)
      -> Bool {
    // If an account does not yet have a directory, this is its first time signing in. Each new
    // account should have preferences migrated from the root user.
    let shouldMigratePrefs = !fileSystemLayout.hasAccountDirectory(for: accountID)
    if shouldMigratePrefs, let accountUserManager = currentAccountUserManager {
      let existingDataMigrationManager =
          ExistingDataMigrationManager(accountUserManager: accountUserManager,
                                       rootUserManager: rootUserManager)
      existingDataMigrationManager.migratePreferences()
      existingDataMigrationManager.removeAllBluetoothDevices()
    }

    let wasAppUsedByRootUser = rootUserManager.hasExperimentsDirectory
    return wasAppUsedByRootUser && shouldMigratePrefs
  }

  private func performMigrationIfNeededAndContinueSignIn() {
    guard let accountID = accountsManager.currentAccount?.ID else {
      sjlog_error("Accounts manager does not have a current account after sign in flow completion.",
                  category: .general)
      return
    }

    // Unwrapping `currentAccountUserManager` would initialize a new instance of the account manager
    // if a current account exists. This creates the account's directory. However, the migration
    // method checks to see if this directory exists or not, so we must not call it until after
    // migration.
    shouldShowPreferenceMigrationMessage =
        migratePreferencesAndRemoveBluetoothDevicesIfNeeded(forAccountID: accountID)

    // Show the migration options if a choice has never been selected.
    guard !devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption else {
      reloadUserFlowViewController()
      return
    }

    guard let accountUserManager = currentAccountUserManager else {
      return
    }

    let existingDataMigrationManager =
        ExistingDataMigrationManager(accountUserManager: accountUserManager,
                                     rootUserManager: rootUserManager)
    if existingDataMigrationManager.hasExistingExperiments {
      self.existingDataMigrationManager = existingDataMigrationManager
      let existingDataOptionsVC = ExistingDataOptionsViewController(
          analyticsReporter: analyticsReporter,
          numberOfExistingExperiments: existingDataMigrationManager.numberOfExistingExperiments)
      self.existingDataOptionsVC = existingDataOptionsVC
      existingDataOptionsVC.delegate = self
      transitionToViewControllerModally(existingDataOptionsVC)
    } else {
      reloadUserFlowViewController()
    }
  }

  /// Prepares an existing user to be removed from memory. This is non-descrtuctive in terms of
  /// the user's local data. It should be called when a user is logging out, being removed, or
  /// changing to a new user.
  private func tearDownCurrentUser() {
    _currentAccountUserManager?.tearDown()
    _currentAccountUserManager = nil
    userFlowViewController = nil
  }

  // swiftlint:disable vertical_parameter_alignment
  /// Uses a modal UI operation to transition to a view controller.
  ///
  /// - Parameters:
  ///   - viewController: The view controller.
  ///   - animated: Whether to animate.
  ///   - minimumDisplaySeconds: The minimum number of seconds to display the view controller for.
  ///   - completion: Called when finished transitioning to the view controller.
  private func transitionToViewControllerModally(_
      viewController: UIViewController,
      animated: Bool = true,
      withMinimumDisplaySeconds minimumDisplaySeconds: Double? = nil,
      completion: (() -> Void)? = nil) {
    let showViewControllerOp = GSJBlockOperation(mainQueueBlock: { [unowned self] finish in
      self.transitionToViewController(viewController, animated: animated) {
        completion?()
        if let minimumDisplaySeconds = minimumDisplaySeconds {
          DispatchQueue.main.asyncAfter(deadline: .now() + minimumDisplaySeconds) { finish() }
        } else {
          finish()
        }
      }
    })
//    showViewControllerOp.addCondition(MutuallyExclusive.modalUI)
    queue.addOperation(showViewControllerOp)
  }
  // swiftlint:enable vertical_parameter_alignment

}

// MARK: - AccountsManagerDelegate

extension AppFlowViewController: AccountsManagerDelegate {

  func deleteAllUserDataForIdentity(withID identityID: String) {
    // Remove the persistent store before deleting the DB files to avoid a log error. Use
    // `_currentAccountUserManager`, because `currentAccountUserManager` will return nil because
    // `accountsManager.currentAccount` is now nil. Also, remove the current account user manager so
    // the sensor data manager is recreated if this same user logs back in immediately.
    _currentAccountUserManager?.sensorDataManager.removeStore()
    tearDownCurrentUser()
    do {
      try AccountDeleter(fileSystemLayout: fileSystemLayout, accountID: identityID).deleteData()
    } catch {
      print("Failed to delete user data: \(error.localizedDescription)")
    }
  }

  func accountsManagerDidSignIn(signInType: SignInType) {
    switch signInType {
    case .newSignIn:
      tearDownCurrentUser()
      reloadUserFlowViewController()
    case .restoreCachedAccount:
      reloadUserFlowViewController()
    }
  }
  
  func accountsManagerDidSignOut() {
    tearDownCurrentUser()
    reloadUserFlowViewController()
  }
  
  func accountsManagerDidSkipDriveSyncSetup() {
    currentAccountUserManager?.preferenceManager.driveSyncSetupSkipped = true
  }
  
  func accountsManagerDidCompleteDriveSyncSetup(with authorization: GTMFetcherAuthorizationProtocol) {
    currentAccountUserManager?.driveSyncAuthorization = authorization
    userFlowViewController?.driveSyncManager = currentAccountUserManager?.driveSyncManager
  }
  
  func accountsManagerDidFailDriveSyncSetup(with error: Error) {
    currentAccountUserManager?.driveSyncAuthorization = nil
    userFlowViewController?.driveSyncManager = nil
    accountsManager.setupDriveSync(fromViewController: self, isSignup: false)
  }
  
  func accountsManagerDidDisableDriveSync() {
    currentAccountUserManager?.driveSyncAuthorization = nil
    userFlowViewController?.driveSyncManager = nil
  }
}

// MARK: - ExistingDataOptionsDelegate

extension AppFlowViewController: ExistingDataOptionsDelegate {

  func existingDataOptionsViewControllerDidSelectSaveAllExperiments() {
    guard let existingDataOptionsVC = existingDataOptionsVC else { return }
    devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption = true
    let spinnerViewController = SpinnerViewController()
    spinnerViewController.present(fromViewController: existingDataOptionsVC) {
      self.existingDataMigrationManager?.migrateAllExperiments(completion: { (errors) in
        spinnerViewController.dismissSpinner {
          self.reloadUserFlowViewController()
          if errors.containsDiskSpaceError {
            showSnackbar(withMessage: String.claimExperimentsDiskSpaceErrorMessage)
          } else if !errors.isEmpty {
            showSnackbar(withMessage: String.claimExperimentsErrorMessage)
          }
        }
      })
    }
  }

  func existingDataOptionsViewControllerDidSelectDeleteAllExperiments() {
    devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption = true
    existingDataMigrationManager?.removeAllExperimentsFromRootUser()
    reloadUserFlowViewController()
  }

  func existingDataOptionsViewControllerDidSelectSelectExperimentsToSave() {
    devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption = true
    // If the user wants to manually select experiments to claim, nothing needs to be done now. They
    // will see the option to claim experiments in the experiments list.
    reloadUserFlowViewController()
  }

}

// MARK: - UserFlowViewControllerDelegate

extension AppFlowViewController: UserFlowViewControllerDelegate {

  func presentAccountSelector() {
    if accountsManager.currentAccount == nil {
      accountsManager.presentSignIn(fromViewController: self)
    }
  }

}

#if SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
// MARK: - Debug additions for creating data and testing claim and migration flows in-app.

extension AppFlowViewController {

  @objc private func debug_createRootUserData() {
    guard let settingsVC = userFlowViewController?.settingsVC else { return }
    let spinnerVC = SpinnerViewController()
    spinnerVC.present(fromViewController: settingsVC) {
      self.rootUserManager.documentManager.debug_createRootUserData {
        DispatchQueue.main.async {
          self.userFlowViewController?.experimentsListVC?.refreshUnclaimedExperiments()
          spinnerVC.dismissSpinner()
        }
      }
    }
  }

  @objc private func debug_forceAuth() {
    devicePreferenceManager.hasAUserChosenAnExistingDataMigrationOption = false
    devicePreferenceManager.hasAUserCompletedPermissionsGuide = false
    NotificationCenter.default.post(name: .DEBUG_destroyCurrentUser, object: nil, userInfo: nil)
  }
}
#endif  // SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
