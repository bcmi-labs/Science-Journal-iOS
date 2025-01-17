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

import third_party_sciencejournal_ios_ScienceJournalProtos

extension SensorSpec {

  /// Convenience initializer that creates a sensor spec from a BLE sensor interface.
  ///
  /// - Parameter bleSensorInterface: A BLE sensor interface.
  convenience init(bleSensorInterface: BLESensorInterface) {
    let proto = GSJSensorSpec()
    proto.config = bleSensorInterface.config
    proto.info.address = bleSensorInterface.identifier
    proto.info.providerId = bleSensorInterface.providerId
    proto.rememberedAppearance.name = bleSensorInterface.name
    proto.rememberedAppearance.units = bleSensorInterface.unitDescription
    proto.rememberedAppearance.shortDescription = bleSensorInterface.textDescription

    let iconPath = IconPath(type: .proto, pathString: nil).proto
    proto.rememberedAppearance.iconPath = iconPath
    proto.rememberedAppearance.largeIconPath = iconPath

    self.init(proto: proto)
  }

}
