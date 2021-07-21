//  
//  ArduinoAccountsManager.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 04/02/21.
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
import SafariServices
import AppAuth
import googlemac_iPhone_Shared_SSOAuth_SSOAuth
import GTMSessionFetcher
import GoogleSignIn

final class ArduinoAccountsManager: NSObject, AccountsManager {
  
  public enum Provider: String {
    case github
    case google = "google-oauth2"
    case apple
  }
  
  let devicePreferenceManager: DevicePreferenceManager
  let urlSession: URLSession
  
  weak var delegate: AccountsManagerDelegate?
  
  var supportsAccounts: Bool { true }
  
  private(set) var currentAccount: AuthAccount? {
    didSet {
      restoreDriveSyncIfNeeded()
    }
  }
  
  private var authHost: String { Constants.ArduinoSignIn.host }
  private var apiHost: String { Constants.ArduinoSignIn.apiHost }
  private var clientId: String { Constants.ArduinoSignIn.clientId }
  private var redirectUri: String { Constants.ArduinoSignIn.redirectUri }
  
  private var codeChallenge: String?
  private var state: String?
  private var authenticationHandler:((Result<ArduinoAccount, SignInError>) -> Void)?
  private var googleHandler:((Result<GIDGoogleUser, Error>) -> Void)?
  
  init(googleClientID: String = Bundle.googleClientID,
       googleScopes: [String] = Constants.GoogleSignInScopes.drive,
       devicePreferenceManager: DevicePreferenceManager = DevicePreferenceManager(),
       urlSession: URLSession = .shared) {
    self.devicePreferenceManager = devicePreferenceManager
    self.urlSession = urlSession
    super.init()
    GIDSignIn.sharedInstance()?.clientID = googleClientID
    GIDSignIn.sharedInstance()?.scopes = googleScopes
    GIDSignIn.sharedInstance()?.delegate = self
  }
}

// MARK:- AccountsManager
extension ArduinoAccountsManager {
  func presentSignIn(fromViewController viewController: UIViewController) {
    presentSignIn(from: viewController)
  }
  
  func signInAsCurrentAccount() {
    guard let account = devicePreferenceManager.savedAccount else {
      delegate?.accountsManagerDidSignOut()
      return
    }
    
    currentAccount = account
    delegate?.accountsManagerDidSignIn(signInType: .restoreCachedAccount)
  }
  
  func signOutCurrentAccount() {
    NotificationCenter.default.post(name: .userWillBeSignedOut, object: self)
    devicePreferenceManager.savedAccount = nil
    currentAccount = nil
    delegate?.accountsManagerDidSignOut()
  }
  
  func reauthenticateCurrentAccount() -> Bool {
    // as we don't call any API after authentication
    // there's no need to refresh a token eventually
    return currentAccount != nil
  }
  
  func removeLingeringAccounts() {
    
  }
  
  func handle(redirectURL url: URL) -> Bool {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return false
    }
    
    guard url.absoluteString.hasPrefix(redirectUri) else {
      return false
    }
    
    guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
      complete(with: .failure(.notAuthenticated))
      return true
    }
    
    guard let codeChallenge = codeChallenge else {
      complete(with: .failure(.notAuthenticated))
      return true
    }
    
    guard let state = components.queryItems?.first(where: { $0.name == "state" })?.value, state == self.state else {
      complete(with: .failure(.notAuthenticated))
      return true
    }
    
    exchange(code: code, codeChallenge: codeChallenge)
    return true
  }
  
  func setupDriveSync(fromViewController viewController: UIViewController, isSignup: Bool) {    
    setupDriveSync(from: viewController, isSignup: isSignup)
  }

  func learnMoreDriveSync(fromViewController viewController: UIViewController) {
    learnMoreDriveSync(from: viewController)
  }
  
  func signInWithGoogle(fromViewController viewController: UIViewController,
                        completion: @escaping (Result<GIDGoogleUser, Error>) -> Void) {
    guard googleHandler == nil else {
      completion(.failure(SignInError.alreadyAuthenticating))
      return
    }
    
    googleHandler = completion
    GIDSignIn.sharedInstance()?.presentingViewController = viewController
    GIDSignIn.sharedInstance()?.signIn()
  }
  
  func enableDriveSync(with user: GIDGoogleUser, folderID: String, folderName: String) {
    guard let account = currentAccount else { return }
    guard let authorization = user.authentication.fetcherAuthorizer() else { return }
    
    currentAccount?.authorization = authorization
    
    let preferenceManager = PreferenceManager(accountID: account.ID)
    preferenceManager.driveSyncUserID = user.userID
    preferenceManager.driveSyncFolderID = folderID
    preferenceManager.driveSyncFolderName = folderName
    preferenceManager.driveSyncUserEmail = user.profile.email
    
    delegate?.accountsManagerDidCompleteDriveSyncSetup(with: authorization)
    NotificationCenter.default.post(name: .driveSyncDidEnable, object: self)
  }
  
  func disableDriveSync() {
    guard let account = currentAccount else { return }
    
    currentAccount?.authorization = nil
    
    let preferenceManager = PreferenceManager(accountID: account.ID)
    preferenceManager.driveSyncUserID = nil
    preferenceManager.driveSyncFolderID = nil
    preferenceManager.driveSyncFolderName = nil
    preferenceManager.driveSyncUserEmail = nil
    
    delegate?.accountsManagerDidDisableDriveSync()
    NotificationCenter.default.post(name: .driveSyncDidDisable, object: self)
  }
}

// MARK:- SSO
extension ArduinoAccountsManager {
  func signIn(with provider: Provider,
              from presentingViewController: UIViewController,
              completion: @escaping (Result<ArduinoAccount, SignInError>) -> Void) {
    
    guard var url = URL(string: "https://\(authHost)") else {
      return
    }
    
    url.appendPathComponent("authorize")
    
    let codeChallenge = randomString(length: 64)
    let state = randomString(length: 32)
    let parameters: [String: String] = [
      "client_id": clientId,
      "audience": "https://api.arduino.cc",
      "scope": "openid profile email offline_access",
      "response_type": "code",
      "redirect_uri": redirectUri,
      "state": state,
      "code_challenge_method": "S256",
      "code_challenge": OIDTokenUtilities.encodeBase64urlNoPadding(OIDTokenUtilities.sha256(codeChallenge)),
      "connection": provider.rawValue
    ]
    
    var queryItems = [URLQueryItem]()
    for (key, value) in parameters {
      queryItems.append(URLQueryItem(name: key, value: value))
    }
    
    guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return
    }
    urlComponents.queryItems = queryItems
    
    guard let requestURL = urlComponents.url else {
      return
    }
    
    let safariViewController = SFSafariViewController(url: requestURL)
    presentingViewController.present(safariViewController, animated: true) { [weak self] in
      self?.codeChallenge = codeChallenge
      self?.state = state
    }
    
    let delegate = self.delegate
    authenticationHandler = { result in
      if safariViewController.presentationController != nil {
        safariViewController.dismiss(animated: true) {
          completion(result)
          
          switch result {
          case .success(let account):
            self.devicePreferenceManager.savedAccount = account
            self.currentAccount = account
            delegate?.accountsManagerDidSignIn(signInType: .newSignIn)
          case .failure: delegate?.accountsManagerDidSignOut()
          }
        }
      } else {
        completion(result)
      }
    }
  }
}

// MARK:- Arduino
extension ArduinoAccountsManager {
  func signUp(email: String,
              username: String,
              password: String,
              userMetadata: [String: String],
              completion: @escaping (Result<ArduinoAccount, SignInError>) -> Void) {
    
    var data: [String: String] = [
      "client_id": clientId,
      "connection": "arduino",
      "username": username,
      "email": email.lowercased(),
      "password": password
    ]
    
    userMetadata.forEach { key, value in
      data["user_metadata[\(key)]"] = value
    }
    
    guard let request = URLRequest.post(host: authHost, path: "/dbconnections/signup", data: data) else {
      completion(.failure(.notAuthenticated))
      return
    }
    
    urlSession.dataTask(with: request) { [weak self] data, response, error in
      guard let self = self else { return }
      
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(.networkError(error)))
          return
        }
        
        guard let response = response as? HTTPURLResponse else {
          completion(.failure(.badResponse))
          return
        }
        
        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          completion(.failure(.badResponse))
          return
        }
        
        guard response.statusCode == 200 else {
          completion(.failure(.notValid(json)))
          return
        }
        
        guard let ID = json["user_id"] as? String,
              let email = json["email"] as? String,
              let username = json["username"] as? String else {
          completion(.failure(.badResponse))
          return
        }
        
        let emailVerified = json["email_verified"] as? Bool
        
        let account = ArduinoAccount(type: .adult,
                                     ID: ID,
                                     email: email,
                                     displayName: username,
                                     profileImage: nil,
                                     isShareRestricted: false,
                                     emailVerified: emailVerified ?? false,
                                     authorization: nil)
        completion(.success(account))
        
        if account.emailVerified {
          self.devicePreferenceManager.savedAccount = account
          self.currentAccount = account
          self.delegate?.accountsManagerDidSignIn(signInType: .newSignIn)
        }
      }
    }.resume()
  }
  
  func signIn(username: String,
              password: String,
              accountType: AuthAccountType,
              completion: @escaping (Result<ArduinoAccount, SignInError>) -> Void) {
    
    var data: [String: String] = [
      "client_id": clientId,
      "audience": "https://api.arduino.cc",
      "scope": "openid profile email offline_access",
      "username": username,
      "password": password
    ]
    
    if accountType == .kid {
      data["grant_type"] = "http://auth0.com/oauth/grant-type/password-realm"
      data["realm"] = "coppa"
    } else {
      data["grant_type"] = "password"
    }
    
    guard let request = URLRequest.post(host: authHost, path: "/oauth/token", data: data) else {
      completion(.failure(.notAuthenticated))
      return
    }
    
    urlSession.dataTask(with: request) { [weak self] data, response, error in
      guard let self = self else { return }
      
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(.networkError(error)))
          return
        }
        
        guard let response = response as? HTTPURLResponse else {
          completion(.failure(.badResponse))
          return
        }
        
        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          completion(.failure(.badResponse))
          return
        }
        
        guard response.statusCode == 200 else {
          completion(.failure(.notValid(json)))
          return
        }
        
        guard let token = json["id_token"] as? String else {
          completion(.failure(.badResponse))
          return
        }
        
        guard let jwt = JWT(token: token), let account = ArduinoAccount(jwt: jwt, type: accountType) else {
          completion(.failure(.badResponse))
          return
        }
        
        completion(.success(account))
        
        self.devicePreferenceManager.savedAccount = account
        self.currentAccount = account
        self.delegate?.accountsManagerDidSignIn(signInType: .newSignIn)
      }
    }.resume()
  }
  
  func verify(code: String,
              token: String,
              completion: @escaping (Result<ArduinoAccount, SignInError>) -> Void) {
    
    let data: [String: String] = [
      "client_id": clientId,
      "scope": "openid profile email offline_access",
      "grant_type": "http://auth0.com/oauth/grant-type/mfa-otp",
      "mfa_token": token,
      "otp": code
    ]
    
    guard let request = URLRequest.post(host: authHost, path: "/oauth/token", data: data) else {
      completion(.failure(.notAuthenticated))
      return
    }
    
    urlSession.dataTask(with: request) { [weak self] data, response, error in
      guard let self = self else { return }
      
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(.networkError(error)))
          return
        }
        
        guard let response = response as? HTTPURLResponse else {
          completion(.failure(.badResponse))
          return
        }
        
        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          completion(.failure(.badResponse))
          return
        }
        
        guard response.statusCode == 200 else {
          completion(.failure(.notValid(json)))
          return
        }
        
        guard let token = json["id_token"] as? String else {
          completion(.failure(.badResponse))
          return
        }
        
        guard let jwt = JWT(token: token), let account = ArduinoAccount(jwt: jwt, type: .adult) else {
          completion(.failure(.badResponse))
          return
        }
        
        completion(.success(account))
        
        self.devicePreferenceManager.savedAccount = account
        self.currentAccount = account
        self.delegate?.accountsManagerDidSignIn(signInType: .newSignIn)
      }
    }.resume()
  }
  
  func recoverPassword(for email: String, completion: @escaping (Result<Void, SignInError>) -> Void) {
    let data: [String: String] = [
      "client_id": clientId,
      "connection": "arduino",
      "email": email.lowercased()
    ]
    
    guard let request = URLRequest.post(host: authHost, path: "/dbconnections/change_password", data: data) else {
      completion(.failure(.badRequest))
      return
    }
    
    urlSession.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(.networkError(error)))
          return
        }
        
        guard let response = response as? HTTPURLResponse else {
          completion(.failure(.badResponse))
          return
        }
        
        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          completion(.failure(.badResponse))
          return
        }
        
        guard response.statusCode == 200 else {
          completion(.failure(.notValid(json)))
          return
        }
        
        completion(.success(()))
      }
    }.resume()
  }
  
  func recoverPassword(for username: String, parentEmail: String, completion: @escaping (Result<Void, SignInError>) -> Void) {
    let data: [String: String] = [
      "username": username,
      "parent_email": parentEmail.lowercased()
    ]
    
    guard let request = URLRequest.post(host: apiHost, path: "/users/v1/children/help", data: data, contentType: .json) else {
      completion(.failure(.badRequest))
      return
    }
    
    urlSession.dataTask(with: request) { _, response, error in
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(.networkError(error)))
          return
        }
        
        guard let response = response as? HTTPURLResponse else {
          completion(.failure(.badResponse))
          return
        }
        
        guard response.statusCode == 200 else {
          completion(.failure(.badRequest))
          return
        }
        
        completion(.success(()))
      }
    }.resume()
  }
}

// MARK:- Junior
extension ArduinoAccountsManager {
  func getJuniorUsername(completion: @escaping (Result<String, SignInError>) -> Void) {
    guard let request = URLRequest.get(host: apiHost, path: "/users/v1/children/username") else {
      completion(.failure(.badRequest))
      return
    }
    
    urlSession.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(.networkError(error)))
          return
        }
        
        guard let response = response as? HTTPURLResponse else {
          completion(.failure(.badResponse))
          return
        }
        
        guard response.statusCode == 200 else {
          completion(.failure(.badRequest))
          return
        }
        
        guard let data = data, let username = String(data: data, encoding: .utf8) else {
          completion(.failure(.badResponse))
          return
        }
        
        let forbiddenCharacters = CharacterSet.alphanumerics.inverted
        completion(.success(username.trimmingCharacters(in: forbiddenCharacters)))
      }
    }.resume()
  }
  
  func getJuniorAvatars(completion: @escaping (Result<[[String: String]], SignInError>) -> Void) {
    guard let request = URLRequest.get(host: apiHost, path: "/users/v1/children/avatars") else {
      completion(.failure(.badRequest))
      return
    }
    
    urlSession.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(.networkError(error)))
          return
        }
        
        guard let response = response as? HTTPURLResponse else {
          completion(.failure(.badResponse))
          return
        }
        
        guard response.statusCode == 200 else {
          completion(.failure(.badRequest))
          return
        }
        
        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: String]] else {
          completion(.failure(.badResponse))
          return
        }
        
        completion(.success(json))
      }
    }.resume()
  }
  
  func signUpJunior(username: String,
                    password: String,
                    userMetadata: [String: String],
                    completion: @escaping (Result<Void, SignInError>) -> Void) {
    
    var data: [String: String] = [
      "username": username,
      "password": password
    ]
    
    userMetadata.forEach { key, value in
      data[key] = value
    }
    
    guard let request = URLRequest.post(host: apiHost, path: "/users/v1/children", data: data, contentType: .json) else {
      completion(.failure(.badRequest))
      return
    }
    
    urlSession.dataTask(with: request) { data, response, error in
      DispatchQueue.main.async {
        if let error = error {
          completion(.failure(.networkError(error)))
          return
        }
        
        guard let response = response as? HTTPURLResponse else {
          completion(.failure(.badResponse))
          return
        }
        
        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
          completion(.failure(.badResponse))
          return
        }
        
        guard response.statusCode == 201 else {
          completion(.failure(.notValid(json)))
          return
        }
        
        completion(.success(()))
      }
    }.resume()
  }
}

// MARK:- Helpers
private extension ArduinoAccountsManager {
  func restoreDriveSyncIfNeeded() {
    guard let account = currentAccount else { return }
    guard account.authorization == nil else { return }
    
    let preferenceManager = PreferenceManager(accountID: account.ID)
    
    guard preferenceManager.driveSyncUserID != nil else { return }
    
    restoreGooglePreviousSignIn()
  }
  
  func restoreGooglePreviousSignIn() {
    guard let googleSignIn = GIDSignIn.sharedInstance() else {
      return
    }
    guard googleSignIn.hasPreviousSignIn() else {
      delegate?.accountsManagerDidFailDriveSyncSetup(with: SignInError.notAuthenticated)
      NotificationCenter.default.post(name: .driveSyncDidDisable, object: self)
      return
    }
    googleSignIn.restorePreviousSignIn()
  }
}

// MARK:- GIDSignInDelegate
extension ArduinoAccountsManager: GIDSignInDelegate {  
  func sign(_ signIn: GIDSignIn!,
            didSignInFor user: GIDGoogleUser!,
            withError error: Error!) {
    if let handler = googleHandler {
      googleHandler = nil
      if let error = error {
        handler(.failure(error))
      } else if let user = user {
        handler(.success(user))
      } else {
        handler(.failure(SignInError.notAuthenticated))
      }
      return
    }
    
    guard let account = currentAccount else { return }
    
    let preferenceManager = PreferenceManager(accountID: account.ID)
    
    guard let userID = preferenceManager.driveSyncUserID else { return }
    
    if let authorization = user.authentication.fetcherAuthorizer(), userID == user.userID {
      delegate?.accountsManagerDidCompleteDriveSyncSetup(with: authorization)
      NotificationCenter.default.post(name: .driveSyncDidEnable, object: self)
    } else {
      delegate?.accountsManagerDidFailDriveSyncSetup(with: error ?? SignInError.notAuthenticated)
      NotificationCenter.default.post(name: .driveSyncDidDisable, object: self)
    }
  }
  
  func sign(_ signIn: GIDSignIn!,
            didDisconnectWith user: GIDGoogleUser!,
            withError error: Error!) {
    
  }
}

// MARK:- APIs
private extension ArduinoAccountsManager {
  func exchange(code: String, codeChallenge: String) {
    let data: [String: String] = [
      "client_id": clientId,
      "grant_type": "authorization_code",
      "code": code,
      "code_verifier": codeChallenge,
      "redirect_uri": redirectUri
    ]
    
    guard let request = URLRequest.post(host: authHost, path: "/oauth/token", data: data) else {
      complete(with: .failure(.notAuthenticated))
      return
    }
    
    urlSession.dataTask(with: request) { [weak self] data, _, error in
      guard let self = self else { return }
      
      DispatchQueue.main.async {
        if let error = error {
          self.complete(with: .failure(.networkError(error)))
          return
        }
        
        guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          self.complete(with: .failure(.badResponse))
          return
        }
        
        guard let token = json["id_token"] as? String else {
          self.complete(with: .failure(.badResponse))
          return
        }
        
        guard let jwt = JWT(token: token), let account = ArduinoAccount(jwt: jwt, type: .adult) else {
          self.complete(with: .failure(.badResponse))
          return
        }
        
        self.complete(with: .success(account))
      }
    }.resume()
  }
  
  func complete(with result: Result<ArduinoAccount, SignInError>) {
    codeChallenge = nil
    state = nil
    
    if let handler = authenticationHandler {
      handler(result)
      authenticationHandler = nil
    }
  }
  
  func randomString(length: Int) -> String {
    let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map { _ in chars.randomElement()! })
  }
}

// MARK:- UI
private extension ArduinoAccountsManager {
  func presentSignIn(from viewController: UIViewController, completion: (() -> Void)? = nil) {
    guard currentAccount == nil else { return }
    
    presentWizard(with: SignInIntroViewController(accountsManager: self),
                  from: viewController) { wizard, _ in
      wizard.dismiss(animated: true, completion: nil)
    }
  }
  
  func setupDriveSync(from viewController: UIViewController, isSignup: Bool? = nil, completion: (() -> Void)? = nil) {
    guard let account = currentAccount, account.supportsDriveSync else { return }
    let preferenceManager = PreferenceManager(accountID: account.ID)
    let googleUser = GIDSignIn.sharedInstance().currentUser

    if preferenceManager.driveSyncUserID != nil {
      presentWizard(with: DriveSyncFolderPickerViewController(user: googleUser!, accountsManager: self),
                    from: viewController) { [weak self] wizard, isCancelled in
        if isCancelled {
          self?.delegate?.accountsManagerDidSkipDriveSyncSetup()
          NotificationCenter.default.post(name: .driveSyncDidDisable, object: self)
        }
        
        wizard.dismiss(animated: true, completion: nil)
      }
    } else {
      presentWizard(with: DriveSyncIntroViewController(accountsManager: self, isSignup: isSignup),
                    from: viewController) { [weak self] wizard, isCancelled in
        if isCancelled {
          self?.delegate?.accountsManagerDidSkipDriveSyncSetup()
          NotificationCenter.default.post(name: .driveSyncDidDisable, object: self)
        }
        
        wizard.dismiss(animated: true, completion: nil)
      }
    }
  }

  func learnMoreDriveSync(from viewController: UIViewController, completion: (() -> Void)? = nil) {
    presentModal(with: DriveSyncLearnMoreViewController(), from: viewController) {modal, _ in 
    
    modal.dismiss(animated: true, completion: nil)
    }
  }
  
  func presentWizard(with initialViewController: UIViewController,
                     from presentingViewController: UIViewController,
                     onDismiss: @escaping (_ wizard: WizardRootViewController, _ isCancelled: Bool) -> Void) {
    
    let wizardViewController = WizardRootViewController()
    wizardViewController.initialViewController = initialViewController
    wizardViewController.onDismiss = onDismiss
    
    if presentingViewController.traitCollection.userInterfaceIdiom == .pad {
      wizardViewController.modalPresentationStyle = .formSheet
    } else {
      wizardViewController.modalPresentationStyle = .fullScreen
    }
    
    if let presentedViewController = presentingViewController.presentedViewController {
      presentedViewController.dismiss(animated: true) {
        presentingViewController.present(wizardViewController, animated: true, completion: nil)
      }
    } else {
      presentingViewController.present(wizardViewController, animated: true, completion: nil)
    }
  }

  func presentModal(with initialViewController: UIViewController,
                    from presentingViewController: UIViewController,
                    onDismiss: @escaping (_ modal: ModalRootViewController, _ isCancelled: Bool) -> Void) {
    
    guard let modalViewController = UIStoryboard(name: "Modal", bundle: nil).instantiateInitialViewController()
            as? ModalRootViewController else { return }
    
    modalViewController.initialViewController = initialViewController
    modalViewController.onDismiss = onDismiss
    
    if presentingViewController.traitCollection.userInterfaceIdiom == .pad {
      modalViewController.modalPresentationStyle = .formSheet
    } else {
      modalViewController.modalPresentationStyle = .fullScreen
    }
    
    if let presentedViewController = presentingViewController.presentedViewController {
      presentedViewController.dismiss(animated: true) {
        presentingViewController.present(modalViewController, animated: true, completion: nil)
      }
    } else {
      presentingViewController.present(modalViewController, animated: true, completion: nil)
    }
  }
}
