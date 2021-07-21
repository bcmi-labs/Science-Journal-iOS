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

protocol ClaimExperimentsViewControllerDelegate: class {

  /// Informs the delegate the experiment with the given ID should be shown.
  ///
  /// - Parameter experimentID: An experiment ID.
  func claimExperimentsShowExperiment(withID experimentID: String)

  /// Informs the delegate the user has added the experiment to Drive.
  ///
  /// - Parameter experimentID: An experiment ID.
  func claimExperimentsAddExperimentToDrive(withID experimentID: String)

  /// Informs the delegate the user wants to save the experiment to files.
  ///
  /// - Parameter experimentID: An experiment ID.
  func claimExperimentsSaveExperimentToFiles(withID experimentID: String)

  /// Informs the delegate the user has deleted the experiment.
  ///
  /// - Parameter experimentID: An experiment ID.
  func claimExperimentsDeleteExperiment(withID experimentID: String)

  /// Informs the delegate the user has claimed all experiments.
  func claimExperimentsClaimAllExperiments()

  /// Informs the delegate the user has deleted all experiments.
  func claimExperimentsDeleteAllExperiments()

}

/// A list of experiments the user can claim, share or delete.
class ClaimExperimentsViewController: MaterialHeaderViewController, ClaimExperimentListCellDelegate,
    ExperimentsListItemsDelegate {

  private let experimentsListItemsViewController: ExperimentsListItemsViewController

  override var trackedScrollView: UIScrollView? {
    return experimentsListItemsViewController.collectionView
  }

  /// The claim experiments view controller delegate.
  weak var delegate: ClaimExperimentsViewControllerDelegate?

  private let menuBarButton = MaterialMenuBarButtonItem()
  private let collectAllButton = WizardButton(title: String.claimAllExperimentsButton,
                                              style: .outlined,
                                              size: .regular)
  private var shouldShowArchivedExperiments = true
  private let authAccount: AuthAccount

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - authAccount: The auth account.
  ///   - analyticsReporter: The analytics reporter.
  ///   - metadataManager: The metadata manager.
  ///   - preferenceManager: The preference manager.
  init(authAccount: AuthAccount,
       analyticsReporter: AnalyticsReporter,
       metadataManager: MetadataManager,
       preferenceManager: PreferenceManager) {
    self.authAccount = authAccount
    experimentsListItemsViewController =
        ExperimentsListItemsViewController(cellClass: ClaimExperimentListCell.self,
                                           metadataManager: metadataManager,
                                           preferenceManager: preferenceManager)

    super.init(analyticsReporter: analyticsReporter)

    // Cell configuration.
    experimentsListItemsViewController.cellConfigurationBlock = {
        [weak self] (cell, overview, image) in
      if let strongSelf = self,
          let cell = cell as? ClaimExperimentListCell, let overview = overview {
        cell.configureForExperimentOverview(overview,
                                            delegate: strongSelf,
                                            image: image)
      }
    }
    experimentsListItemsViewController.cellSizeBlock = { (width) in
      return ClaimExperimentListCell.itemSize(inWidth: width)
    }

    experimentsListItemsViewController.delegate = self
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = String.claimExperimentsViewTitle
    appBar.headerViewController.headerView.backgroundColor = ArduinoColorPalette.orangePalette.tint700
    
    // Experiments list items view controller.
    experimentsListItemsViewController.shouldIncludeArchivedExperiments =
        shouldShowArchivedExperiments
    experimentsListItemsViewController.scrollDelegate = self
    experimentsListItemsViewController.view.translatesAutoresizingMaskIntoConstraints = false
    addChild(experimentsListItemsViewController)
    view.addSubview(experimentsListItemsViewController.view)
    experimentsListItemsViewController.view.pinToEdgesOfView(view)

    // Close button
    navigationItem.leftBarButtonItem =
        MaterialCloseBarButtonItem(target: self, action: #selector(closeButtonPressed))

    // Menu button
    menuBarButton.button.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
    menuBarButton.button.setImage(UIImage(named: "ic_more_horiz"), for: .normal)
    navigationItem.rightBarButtonItem = menuBarButton
    
    // Collect all button
    collectAllButton.backgroundColor = experimentsListItemsViewController.collectionView.backgroundColor
    collectAllButton.layer.cornerRadius = 19
    collectAllButton.clipsToBounds = true
    collectAllButton.addTarget(self, action: #selector(collectAll(_:)), for: .touchUpInside)
    
    view.addSubview(collectAllButton)
    collectAllButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      collectAllButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      collectAllButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
    ])
    
    experimentsListItemsViewController.collectionView.contentInset.bottom = 78
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    refreshExperiments()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    showOnboarding()
  }

  /// Handles the event that an experiment fails to load.
  func handleExperimentLoadingFailure() {
    experimentsListItemsViewController.handleExperimentLoadingFailure()
  }

  /// Should be called when an experiment is removed.
  ///
  /// Parameter experimentID: The ID of the experiment that was removed.
  func experimentRemoved(withID experimentID: String) {
    experimentsListItemsViewController.experimentWasRemoved(withID: experimentID,
                                                            updateCollectionView: isViewVisible)
  }

  /// Refreshes the experiments.
  func refreshExperiments() {
    experimentsListItemsViewController.updateExperiments()
  }
  
  /// Show the onboarding.
  private var didShowOnboarding = false
  
  func showOnboarding() {
    guard !didShowOnboarding else { return }
    
    let viewController = ClaimOnboardingViewController(displayName: authAccount.displayName)
    viewController.modalPresentationStyle = .custom
    viewController.transitioningDelegate = self
    viewController.modalPresentationCapturesStatusBarAppearance = true
    present(viewController, animated: true) { [weak self] in
      self?.didShowOnboarding = true
    }
  }

  // MARK: - User actions

  @objc func closeButtonPressed() {
    dismiss(animated: true)
  }

  @objc func menuButtonPressed() {
    let popUpMenu = PopUpMenuViewController()

    // Show archived experiments?
    let iconName =
        self.shouldShowArchivedExperiments ? "ic_check_box" : "ic_check_box_outline_blank"
    let icon = UIImage(named: iconName)
    popUpMenu.addAction(PopUpMenuAction(title: String.actionIncludeArchivedExperiments,
                                        icon: icon) { _ -> Void in
      self.shouldShowArchivedExperiments.toggle()
      self.experimentsListItemsViewController.shouldIncludeArchivedExperiments =
          self.shouldShowArchivedExperiments
    })

    // Delete all
    let deleteA11yTitle = String.claimExperimentsDeleteAllContentDescription
    popUpMenu.addAction(PopUpMenuAction(title: String.claimExperimentsDeleteAll,
                                        accessibilityLabel: deleteA11yTitle) { _ -> Void in
      // Prompt the user to confirm deleting all.
      let message = String.claimExperimentsDeleteAllConfirmationMessage(withItemCount:
          self.experimentsListItemsViewController.itemCount)
      let alertController = MDCAlertController(title: nil, message: message)
      let deleteAction =
          MDCAlertAction(title: String.claimExperimentsDeleteAllConfirmationAction) { _ in
        self.delegate?.claimExperimentsDeleteAllExperiments()
      }
      let cancelAction = MDCAlertAction(title: String.actionCancel)
      alertController.addAction(deleteAction)
      alertController.addAction(cancelAction)
      alertController.accessibilityViewIsModal = true
      if let cancelButton = alertController.button(for: cancelAction),
         let okButton = alertController.button(for: deleteAction) {
        alertController.styleAlertCancel(button: cancelButton)
        alertController.styleAlertOk(button: okButton)
      }
      self.present(alertController, animated: true)
    })

    popUpMenu.present(from: self, position: .sourceView(menuBarButton.button))
  }
  
  @objc func collectAll(_ sender: UIButton) {
    // Prompt the user to confirm claiming all.
    let message = String.claimExperimentsClaimAllConfirmationMessage(withItemCount:
        self.experimentsListItemsViewController.itemCount, email: self.authAccount.displayName)
    let alertController = MDCAlertController(title: String.claimAllExperimentsConfirmationTitle, message: message)
    let claimAction =
        MDCAlertAction(title: String.claimAllExperimentsConfirmationActionConfirm) { _ in
      self.delegate?.claimExperimentsClaimAllExperiments()
    }
    let cancelAction = MDCAlertAction(title: String.actionCancel)
    alertController.addAction(claimAction)
    alertController.addAction(cancelAction)
    alertController.accessibilityViewIsModal = true
    if let cancelButton = alertController.button(for: cancelAction),
       let okButton = alertController.button(for: claimAction) {
      alertController.styleAlertCancel(button: cancelButton)
      alertController.styleAlertOk(button: okButton)
    }
    self.present(alertController, animated: true)
  }

  // MARK: - ExperimentsListItemsDelegate

  func experimentsListItemsViewControllerDidSelectExperiment(withID experimentID: String) {
    delegate?.claimExperimentsShowExperiment(withID: experimentID)
  }

  // MARK: - ClaimExperimentListCellDelegate

  func claimExperimentListCellPresssedAddToDriveButton(_ cell: ClaimExperimentListCell) {
    guard let overview = experimentsListItemsViewController.overview(forCell: cell) else { return }

    // Prompt the user to confirm adding to Drive.
    let message = String.claimExperimentConfirmationMessage(withEmail: self.authAccount.displayName)
    let alertController = MDCAlertController(title: String.claimExperimentConfirmationTitle,
                                             message: message)
    let cancelAction = MDCAlertAction(title: String.actionCancel)
    let claimAction =
        MDCAlertAction(title: String.claimExperimentConfirmationActionTitle) { _ in
      self.delegate?.claimExperimentsAddExperimentToDrive(withID: overview.experimentID)
    }
    alertController.addAction(claimAction)
    alertController.addAction(cancelAction)
    alertController.accessibilityViewIsModal = true
    if let cancelButton = alertController.button(for: cancelAction),
       let okAction = alertController.button(for: claimAction) {
      alertController.styleAlertCancel(button: cancelButton)
      alertController.styleAlertOk(button: okAction)
    }
    present(alertController, animated: true)
  }

  func claimExperimentListCellPressedSaveToFilesButton(_ cell: ClaimExperimentListCell) {
    guard let overview = experimentsListItemsViewController.overview(forCell: cell) else { return }
    delegate?.claimExperimentsSaveExperimentToFiles(withID: overview.experimentID)
  }

  func claimExperimentListCellPresssedDeleteButton(_ cell: ClaimExperimentListCell) {
    guard let overview = experimentsListItemsViewController.overview(forCell: cell) else { return }

    // Prompt the user to confirm deletion.
    let alertController = MDCAlertController(title: String.deleteExperimentDialogTitle,
                                             message: String.deleteExperimentDialogMessage)
    let cancelAction = MDCAlertAction(title: String.btnDeleteObjectCancel)
    let deleteAction = MDCAlertAction(title: String.btnDeleteObjectConfirm) { _ in
      self.delegate?.claimExperimentsDeleteExperiment(withID: overview.experimentID)
    }
    alertController.addAction(cancelAction)
    alertController.addAction(deleteAction)
    alertController.accessibilityViewIsModal = true
    if let cancelButton = alertController.button(for: cancelAction),
       let okButton = alertController.button(for: deleteAction) {
      alertController.styleAlertCancel(button: cancelButton)
      alertController.styleAlertOk(button: okButton)
    }
    present(alertController, animated: true)
  }
  
}

// MARK:- UIViewControllerTransitioningDelegate
extension ClaimExperimentsViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let controller = PopupPresentationController(presentedViewController: presented, presenting: presenting)
        return controller
    }
}
