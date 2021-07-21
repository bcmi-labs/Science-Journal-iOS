//  
//  DriveSyncPathView.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 09/01/21.
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

class DriveSyncPathView: UIView {

  var folder: DriveFetcher.Folder? {
    didSet {
      refreshPath()
    }
  }
  
  var onBack: (() -> Void)?
  var onCreate: (() -> Void)?
  
  private let pathLabel: UILabel = {
    let label = UILabel()
    label.lineBreakMode = .byTruncatingHead
    label.textAlignment = .natural
    return label
  }()
  
  private let backButton: UIButton = {
    let button = UIButton(type: .system)
    button.tintColor = ArduinoColorPalette.grayPalette.tint700
    button.setImage(UIImage(named: "google_drive_back_folder"), for: .normal)
    button.widthAnchor.constraint(equalToConstant: 42).isActive = true
    button.addTarget(self, action: #selector(goBack(_:)), for: .touchUpInside)
    return button
  }()
  
  private let createButton: UIButton = {
    let button = UIButton(type: .system)
    button.backgroundColor = ArduinoColorPalette.grayPalette.tint300
    button.tintColor = UIColor.white
    button.clipsToBounds = true
    button.layer.cornerRadius = 5
    button.setImage(UIImage(named: "google_drive_create_folder"), for: .normal)
    button.widthAnchor.constraint(equalToConstant: 50).isActive = true
    button.addTarget(self, action: #selector(create(_:)), for: .touchUpInside)
    return button
  }()

  lazy private var stackView: UIStackView = {
    let view = UIStackView()
    view.axis = .horizontal
    view.spacing = 14
    
    view.backgroundColor = ArduinoColorPalette.grayPalette.tint200
    view.clipsToBounds = true
    view.layer.cornerRadius = 5
    
    view.addArrangedSubview(backButton)
    view.addArrangedSubview(pathLabel)
    view.addArrangedSubview(createButton)
    return view 
  }()
  
  init(onBack: @escaping () -> Void, onCreate: @escaping () -> Void) {
 
    super.init(frame: .zero)
    self.onBack = onBack
    self.onCreate = onCreate
    setupView()
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var intrinsicContentSize: CGSize {
    var size = super.intrinsicContentSize
    size.height = 44
    return size
  }
  
  private func setupView() {    
    backgroundColor = ArduinoColorPalette.grayPalette.tint200
    clipsToBounds = true
    layer.cornerRadius = 5

    addSubview(stackView)

    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    stackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    stackView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    stackView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    
    refreshPath()
  }
  
  private func refreshPath() {
    var folder = self.folder
    backButton.isEnabled = folder != nil
    
    let attributedText = NSMutableAttributedString()
    
    var path = [String]()
    while folder != nil {
      path.append(folder!.name)
      folder = folder?.parent
    }
    path.append(String.driveSyncRootFolderLabel)
    
    let font = ArduinoTypography.boldFont(forSize: ArduinoTypography.FontSize.XXSmall.rawValue)
    let normalColor = ArduinoColorPalette.grayPalette.tint700!
    let tintColor = ArduinoColorPalette.tealPalette.tint900!
    
    let separatorAttachment = NSTextAttachment()
    let separatorImage = UIImage(named: "google_drive_path_separator")
    separatorAttachment.image = separatorImage
    
    let separator = NSMutableAttributedString(attachment: separatorAttachment)
    
    var pathComponent = path.popLast()
    while pathComponent != nil {
      let isLast = path.isEmpty
      let color = isLast ? tintColor : normalColor
      let string = NSAttributedString(string: pathComponent!, attributes: [.font: font,
                                                                           .foregroundColor: color])
      attributedText.append(string)
      
      if !isLast {
        let spacing = NSAttributedString(string: "\u{200B}", attributes: [.kern: 8])
        attributedText.append(spacing)
        attributedText.append(separator)
        attributedText.append(spacing)
      }
      
      pathComponent = path.popLast()
    }
    
    pathLabel.attributedText = attributedText
  }
  
  @objc private func goBack(_ sender: UIButton) {
    folder = folder?.parent
    onBack?()
  }
  
  @objc private func create(_ sender: UIButton) {
    onCreate?()
  }
}
