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
import { LocationAccuracy } from "../utils/Utils";
import { MethodCall, } from '@ohos/flutter_ohos';

export class LocationOptions {
  private accuracy: LocationAccuracy;
  private distanceFilter: number;
  private timeInterval: number;
  private useMSLAltitude: boolean;

  constructor(accuracy: LocationAccuracy, distanceFilter: number, timeInterval: number, useMSLAltitude: boolean) {
    this.accuracy = accuracy;
    this.distanceFilter = distanceFilter;
    this.timeInterval = timeInterval;
    this.useMSLAltitude = useMSLAltitude;
  }

  static parseArguments(argumentsMap: Map<String, Object>): LocationOptions {
    if (argumentsMap == null) {
      return new LocationOptions(LocationAccuracy.best, 0, 5000, false);
    }
    const accuracy = argumentsMap.get('accuracy') as number | undefined;
    const distanceFilter = argumentsMap.get('distanceFilter') as number | undefined;
    const timeInterval = argumentsMap.get('timeInterval') as number | undefined;
    const useMSLAltitude = argumentsMap.get('useMSLAltitude') as boolean | undefined;
    let locationAccuracy = LocationAccuracy.best;
    if (accuracy !== undefined) {
      switch (accuracy) {
        case 0:
          locationAccuracy = LocationAccuracy.lowest;
          break;
        case 1:
          locationAccuracy = LocationAccuracy.low;
          break;
        case 2:
          locationAccuracy = LocationAccuracy.medium;
          break;
        case 3:
          locationAccuracy = LocationAccuracy.high;
          break;
        case 5:
          locationAccuracy = LocationAccuracy.bestForNavigation;
          break;
        case 4:
        default:
          break;
      }
    }
    return new LocationOptions(
      locationAccuracy,
      distanceFilter !== undefined ? distanceFilter : 0,
      timeInterval !== undefined ? timeInterval : 5000,
      useMSLAltitude === true
    );
  }

  getAccuracy(): LocationAccuracy {
    return this.accuracy;
  }

  getDistanceFilter(): number {
    return this.distanceFilter;
  }

  getTimeInterval(): number {
    return this.timeInterval;
  }

  isUseMSLAltitude(): boolean {
    return this.useMSLAltitude;
  }
}