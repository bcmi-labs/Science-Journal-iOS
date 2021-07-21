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

import Foundation

/// String constants for common Drive file names.
public struct Constants {

  public struct ArduinoSignIn {
    public static let host = "login.arduino.cc"
    public static let apiHost = "api2.arduino.cc"
    public static let clientId = "yKi4AvWQnzyNTphKbHOXXlz53z8nSftN"
    public static let redirectUri = "arduino.sj://login.arduino.cc/ios/cc.arduino.sciencejournal/callback"
    
    public static let termsOfServiceUrl = URL(string: "https://www.arduino.cc/en/terms-conditions/?embed")!
    public static let privacyPolicyUrl = URL(string: "https://www.arduino.cc/en/privacy-policy/?embed")!
  }
  
  public struct ArduinoURLs {
    public static let activities = URL(string: String.navigationActivitiesLink)!
    public static let help = URL(string: String.navigationGetHelpLink)!
    public static let scienceKit = URL(string: String.navigationGetScienceKitLink)!
    public static let advancedSettings = "https://id.arduino.cc/"
  }

  public struct ArduinoScienceJournalURLs {
    public static let sjTermsOfServiceUrl = URL(string: "https://www.arduino.cc/en/sj-terms-conditions/?embed")!
  }
  
  public struct GoogleSignInScopes {
    public static let drive = [
      "https://www.googleapis.com/auth/drive.appdata",
      "https://www.googleapis.com/auth/drive"
    ]
  }
  
  public struct Drive {
    public static let experimentLibraryProtoFilename = "experiment_library.proto"
    public static let driveTermsOfServiceUrl = URL(string: "https://www.google.com/drive/terms-of-service/")!
    public static let drivePrivacyPolicyUrl = URL(string: "https://policies.google.com/privacy")!
  }

}
