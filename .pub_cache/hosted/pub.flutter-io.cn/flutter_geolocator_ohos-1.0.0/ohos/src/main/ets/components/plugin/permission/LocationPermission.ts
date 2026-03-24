/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// 定义LocationPermission枚举
export enum LocationPermission {
  denied = 0, // Permission to access the device's location is denied by the user.
  deniedForever = 1, // Permission to access the device's location is denied for ever. The permission dialog will not been shown again until the user updates the permission in the App settings.
  whileInUse = 2, // Permission to access the device's location is allowed only while the App is in use.
  always = 3 // Permission to access the device's location is allowed even when the App is running in the background.
}

// 由于ArkTS中枚举值可以直接映射到数字，因此无需额外的方法来转换枚举值为整数。
// 如果需要一个方法来从整数转换回枚举，可以定义一个辅助函数：
function fromInt(value: number): LocationPermission | undefined {
  switch (value) {
    case 0:
      return LocationPermission.denied;
    case 1:
      return LocationPermission.deniedForever;
    case 2:
      return LocationPermission.whileInUse;
    case 3:
      return LocationPermission.always;
    default:
      return undefined;
  }
}