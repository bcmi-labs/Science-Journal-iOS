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

extension UITextView {

  /// Commits any pending autocomplete suggestions to the view's text.
  func commitPendingAutocomplete() {
    if isFirstResponder {
      // This is a workaround that commits the autocomplete suggestion without firing keyboard
      // notifications the way `resignFirstResponder()` does.
      inputDelegate?.selectionWillChange(self)
      inputDelegate?.selectionDidChange(self)
    }
  }

  func set(htmlText: String?) {
    guard let htmlText = htmlText else {
      self.attributedText = nil
      return
    }
    
    guard let data = htmlText.data(using: String.Encoding.utf8) else { return }
    
    guard let text = try? NSAttributedString(data: data,
                                             options: [.documentType: NSAttributedString.DocumentType.html,
                                                       .characterEncoding: String.Encoding.utf8.rawValue],
                                             documentAttributes: nil) else {
      return
    }
    
    let attributedText = NSMutableAttributedString(attributedString: text)
    attributedText.addAttributes([.font: font!, .foregroundColor: textColor!],
                                 range: NSRange(location: 0, length: attributedText.length))
    self.attributedText = attributedText
  }
  
  func inject(urls: [URL]) {
    var values = urls.map { $0 }
    let injectedString = NSMutableAttributedString(attributedString: attributedText)
    attributedText.enumerateAttribute(.link,
                                      in: NSRange(location: 0, length: attributedText.length),
                                      options: [.reverse]) { value, range, stop in
      guard value != nil else { return }
      guard let url = values.popLast() else {
        stop.pointee = true
        return
      }
      injectedString.removeAttribute(.link, range: range)
      injectedString.addAttributes([.link: url, .font: self.font?.bold() as Any], range: range)
    }
    attributedText = injectedString
  }

  func makeBold(originalText: NSMutableAttributedString, boldText: String) {
    let matchRange = originalText.mutableString.range(of: boldText)

    originalText.addAttribute(NSAttributedString.Key.font,
                                        value: ArduinoTypography.boldFont(forSize: 16), range: matchRange)
  }

  // Adds `link` functionality to string in text - handled by the delegate in the controller
  func addLink(originalText: NSMutableAttributedString, value: String, selectedText: String) {
    let matchRange = originalText.mutableString.range(of: selectedText)
    originalText.addAttribute(NSAttributedString.Key.link, value: value, range: matchRange)
  }
}
