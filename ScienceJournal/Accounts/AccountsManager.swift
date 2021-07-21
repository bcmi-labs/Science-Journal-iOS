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

import googlemac_iPhone_Shared_SSOAuth_SSOAuth
import GTMSessionFetcher
import GoogleSignIn

public enum SignInType {
  /// A sign in is occuring.
  case newSignIn

  /// An account is already signed in, but is being restored on launch.
  case restoreCachedAccount
}

public enum SignInError: Error {
  /// Sign in did fail.
  case notAuthenticated
  
  /// Network error.
  case networkError(Error)
  
  /// Unable to parse the response JSON.
  case badResponse
  
  /// Unable to create the request.
  case badRequest
  
  /// Trying to authenticate while another authentication is in progress.
  case alreadyAuthenticating
  
  /// Sign in failed the backend validation.
  case notValid([String : Any])
}

public protocol AccountsManagerDelegate: class {
  /// Tells the delegate to delete all user data for the identity with the specified ID.
  func deleteAllUserDataForIdentity(withID identityID: String)

  func accountsManagerDidSignIn(signInType: SignInType)
  
  func accountsManagerDidSignOut()
  
  func accountsManagerDidSkipDriveSyncSetup()
  
  func accountsManagerDidCompleteDriveSyncSetup(with authorization: GTMFetcherAuthorizationProtocol)
  
  func accountsManagerDidFailDriveSyncSetup(with error: Error)
  
  func accountsManagerDidDisableDriveSync()
}

/// Protocol for managing Arduino user accounts.
public protocol AccountsManager: class {

  /// The delegate for an AccountsManager object.
  var delegate: AccountsManagerDelegate? { get set }

  /// If accounts are supported, Arduino Sign-in and Drive Sync will be available to the user. If
  /// not, these features are completely hidden from the UI and no data is synced.
  var supportsAccounts: Bool { get }

  /// The current account selected for use by the app.
  var currentAccount: AuthAccount? { get }

  /// This should check for a saved account and sign in as this account if the account is valid.
  /// Should call the delegate when complete.
  func signInAsCurrentAccount()

  /// Signs the current account out of Science Journal, but does not remove it from SSO. Needed
  /// when permission has been denied by the server for a specific account, which means the user
  /// will be required to switch accounts. But in this case, we don't want to delete the user's
  /// data.
  func signOutCurrentAccount()

  /// Presents a view controller that allows the user to select an existing account or sign into
  /// a new account. Should call the delegate when sign in is complete.
  ///
  /// - Parameter viewController: The view controller from which to present the sign in view
  ///                             controller.
  func presentSignIn(fromViewController viewController: UIViewController)
  
  /// Presents a view controller that allows the user to sign in with Google.
  ///
  /// - Parameter viewController: The view controller from which to present the sign in view
  ///                             controller.
  /// - Parameter completion: The completion handler that will be called when the authentication
  ///                         completes.
  func signInWithGoogle(fromViewController viewController: UIViewController,
                        completion: @escaping (Result<GIDGoogleUser, Error>) -> Void)

  /// Reauthenticates the current user account.
  ///
  /// - Returns: True if successful, false if not.
  @discardableResult func reauthenticateCurrentAccount() -> Bool

  /// Removes accounts no longer available in SSO, which might have been deleted while the app was
  /// not active.
  func removeLingeringAccounts()
  
  /// Handle a possible redirect URL coming from the web authentication flow (i.e. social sign in).
  ///
  /// - Parameter url: the URL coming from the app delegate.
  /// - Returns: `true` if `url` is a valid redirect one, `false` otherwise.
  func handle(redirectURL url: URL) -> Bool
  
  /// Presents the wizard to setup the Drive Sync. Should call the delegate when setup is complete.
  ///
  /// - Parameter viewController: The view controller from which to present the Drive Sync
  ///                             wizard.
  /// - Parameter isSignup: `true` if the controller is presented during the signup flow, `false` otherwise 
  func setupDriveSync(fromViewController viewController: UIViewController, isSignup: Bool)
  
  /// Enable Drive sync for the current account, using the provided Google account and folder ID.
  ///
  /// - Parameter user: The authenticated Google account.
  /// - Parameter folderID: The ID of the Drive folder where to sync experiments.
  /// - Parameter folderName: The name of the Drive folder where to sync experiments. 
  func enableDriveSync(with user: GIDGoogleUser, folderID: String, folderName: String)
  
  /// Disable Drive sync for the current account.
  ///
  func disableDriveSync()

  /// Display additional information about Drive Sync integration 
  /// - Parameter viewController: The view controller from which to present the Drive Sync
  ///                             Learn More wizard.
  func learnMoreDriveSync(fromViewController viewController: UIViewController)
}

public extension Notification.Name {
  /// The name of a notification posted when a user will be signed out immediately.
  static let userWillBeSignedOut = Notification.Name("GSJNotificationUserWillBeSignedOut")
  
  /// The name of a notification posted when Drive sync has been enabled.
  static let driveSyncDidEnable = Notification.Name("ASJNotificationDriveSyncDidEnable")
  
  /// The name of a notification posted when Drive sync has been disabled.
  static let driveSyncDidDisable = Notification.Name("ASJNotificationDriveSyncDidDisable")

  /// The name of a notification posted when Settings should be dismissed automatically.
  static let settingsShouldClose = Notification.Name("ASJNotificationSettingsShouldClose")

  /// The name of a notification posted when the user has accepted the T&C's
  static let userHasAcceptedTerms = Notification.Name("ASJUserHasAcceptedTerms")
}

/// A protocol representing an auth account.
public protocol AuthAccount {

  /// The account age classification.
  var type: AuthAccountType { get }
  
  /// The account ID.
  var ID: String { get }

  /// The account email.
  var email: String { get }

  /// The account display name.
  var displayName: String { get }

  /// The account profile image URL.
  var profileImage: URL? { get }

  /// Does this account type have sharing restrictions?
  var isShareRestricted: Bool { get set }

  /// The authorization for the account.
  var authorization: GTMFetcherAuthorizationProtocol? { get set }

}

public extension AuthAccount {
  /// Returns `true` if this account can enable the Drive Sync feature.
  var supportsDriveSync: Bool {
    switch type {
    case .adult: return true
    default: return false
    }
  }
}

public enum AuthAccountType: Int, Codable {
  /// Age 0-14
  case kid
  /// Age 14-16
  case young
  /// Age >16
  case adult
}
