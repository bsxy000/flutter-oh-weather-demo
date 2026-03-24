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
import { MethodChannel, MethodCall, MethodCallHandler, MethodResult, FlutterPluginBinding } from "@ohos/flutter_ohos";
import common from '@ohos.app.ability.common';
import PermissionManager from "./permission/PermissionManager";
import { LocationPermission } from "./permission/LocationPermission";
import { ErrorCodes, getErrorCodeString, locationToMap, LocationAccuracyStatus } from "./utils/Utils";
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Want from '@ohos.app.ability.Want';

export default class MethodCallHandlerImpl implements MethodCallHandler {
  private channel: MethodChannel | null = null;

  constructor() {
  }

  startListening(binding: FlutterPluginBinding): void {
    console.debug(">>>>>>>>>>MethodCallHandlerImpl=======startListening")
    if (this.channel != null) {
      this.stopListening();
    }
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'flutter.baseflow.com/geolocator');
    this.channel.setMethodCallHandler(this)

  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "checkPermission") {
      this.onCheckPermission(result);
    } else if (call.method == "isLocationServiceEnabled") {
      this.onIsLocationServiceEnabled(result)
    } else if (call.method == "requestPermission") {
      this.onRequestPermission(result);
    } else if (call.method == "getLastKnownPosition") {
      this.getLastKnownPosition(result)
    } else if (call.method == "getLocationAccuracy") {
      this.getLocationAccuracy(result)
    } else if (call.method == "getCurrentPosition") {
      this.getCurrentPosition(call, result);
    } else if (call.method == "cancelGetCurrentPosition") {
      this.cancelGetCurrentPosition(call, result);
    } else if (call.method == "openAppSettings") {
      this.openAppSettings(result);
    } else if (call.method == "openLocationSettings") {
      this.openLocationSettings(result)
    } else {
      result.notImplemented()
    }
  }

  //检查权限
  async onCheckPermission(result: MethodResult): Promise<void> {
    console.debug(">>>>>>>>>>MethodCallHandlerImpl======onCheckPermission")
    try {
      let permissionManager = new PermissionManager();
      let permissionStatus: boolean | undefined = await permissionManager.checkPermissions();
      if (permissionStatus) {
        result.success(LocationPermission.always);
      } else {
        result.success(LocationPermission.denied);
      }

    } catch (err) {
      let error: BusinessError = err as BusinessError;
      result.error(error.code + '', error.message, null);
    }
  }

  //定位服务开关
  onIsLocationServiceEnabled(result: MethodResult): void {
    console.debug(">>>>>>>>>>onIsLocationServiceEnabled")
    try {
      let isLocationEnable: boolean = geoLocationManager.isLocationEnabled();
      result.success(isLocationEnable);
    } catch (err) {
      console.error("errCode:" + JSON.stringify(err));
      let error: BusinessError = err as BusinessError;
      result.error(error.code + '', error.message, null);
    }
  }

  //请求权限
  onRequestPermission(result: MethodResult): void {
    console.debug(">>>>>>>>>>onRequestPermission")
    try {
      let permissionManager = new PermissionManager();
      let context = getContext(this) as common.UIAbilityContext;
      permissionManager.requestPermission(context, (permission: LocationPermission) => {
        result.success(permission);
      }, (err: BusinessError) => {
        let error: BusinessError = err as BusinessError;
        result.error(error.code + '', error.message, null);
      });
    } catch (err) {
      let error: BusinessError = err as BusinessError;
      result.error(error.code + '', error.message, null);
    }
  }

  //获取上一次最新缓存位置
  async getLastKnownPosition(result: MethodResult): Promise<void> {
    console.debug(">>>>>>>>>>getLastKnownPosition")
    try {
      let permissionManager = new PermissionManager();
      let permissionStatus: boolean | undefined = await permissionManager.checkPermissions();
      if (!permissionStatus) {
        result.error(ErrorCodes.permissionDenied, getErrorCodeString(ErrorCodes.permissionDenied), null);
        return;
      }
      try {
        let location = geoLocationManager.getLastLocation();
        if (location == null) {
          result.success(null);
          return;
        }
        let position = locationToMap(location);
        result.success(position);

      } catch (err) {
        console.error("errCode:" + JSON.stringify(err));
        let error: BusinessError = err as BusinessError;
        result.error(error.code + '', error.message, null);
      }

    } catch (err) {
      result.error(ErrorCodes.permissionDefinitionsNotFound,
        getErrorCodeString(ErrorCodes.permissionDefinitionsNotFound), null);
    }
  }

  //获取精准定位
  async getLocationAccuracy(result: MethodResult): Promise<void> {
    console.debug(">>>>>>>>>>getLocationAccuracy")
    let permissionManager = new PermissionManager();
    let permissionStatus: boolean = await permissionManager.checkPermissions();
    if (!permissionStatus) {
      result.error(ErrorCodes.permissionDenied, getErrorCodeString(ErrorCodes.permissionDenied), null);
      return;
    }
    let status: LocationAccuracyStatus = LocationAccuracyStatus.precise;
    if (status != null) {
      result.success(status);
    }
  }

  //获取当前位置
  async getCurrentPosition(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      let permissionManager = new PermissionManager();
      let permissionStatus: boolean | undefined = await permissionManager.checkPermissions();
      if (!permissionStatus) {
        result.error(ErrorCodes.permissionDenied, getErrorCodeString(ErrorCodes.permissionDenied), null);
        return;
      }
      try {
        let maxAccuracy: number = 0;
        let timeoutMs: number = 10000;
        if (call != null) {
          if (call.argument("accuracy") != null) {
            maxAccuracy = call.argument("accuracy");
          }
          if (call.argument("timeoutMs") != null) {
            timeoutMs = call.argument("timeoutMs");
          }
        }
        // 方式一：使用CurrentLocationRequest作为入参
        let requestInfo: geoLocationManager.CurrentLocationRequest = {
          'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
          'scenario': geoLocationManager.LocationRequestScenario.UNSET,
          'maxAccuracy': maxAccuracy,
          'timeoutMs': timeoutMs
        };
        try {
          let locationChange = (err: BusinessError, location: geoLocationManager.Location): void => {
            if (err) {
              console.debug(">>>>>>>getCurrentLocationData,locationChanger: err=" + JSON.stringify(err));
              result.error(err.code + '', err.message, null)
              return;
            }
            if (location) {
              console.debug(">>>>>>>getCurrentLocationData,location data: " + JSON.stringify(location));
              let position = locationToMap(location);
              result.success(position);
            }
          };
          geoLocationManager.getCurrentLocation(requestInfo, locationChange)
        } catch (err) {
          let error: BusinessError = err as BusinessError;
          console.debug(">>>>>>>getCurrentLocationData,locationChanger: err=" + JSON.stringify(error));
        }
      } catch (err) {
        let error: BusinessError = err as BusinessError;
        console.debug(">>>>>>>getCurrentLocationData,locationChanger: err=" + JSON.stringify(error));
      }

    } catch (err) {
      let error: BusinessError = err as BusinessError;
      result.error(error.code + '', error.message, null);
    }

  }

  //取消获取当前位置
  cancelGetCurrentPosition(call: MethodCall, result: MethodResult): void {
    console.debug(">>>>>>>>>>cancelGetCurrentPosition")
    geoLocationManager.off('locationChange')
    result.success(null);

  }

  //打开app详情系统设置
  openAppSettings(result: MethodResult): void {
    console.debug(">>>>>>>>>>openAppSettings")
    try {
      let context = getContext(this) as common.UIAbilityContext;
      let want: Want = {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'application_info_entry',
        parameters: {
          pushParams: context.applicationInfo.name
        }
      }
      context.startAbility(want).then(() => {
        result.success(true);
      }).catch((err: BusinessError) => {
        result.success(false);
      });
    } catch (err) {
      result.success(false);
    }
  }

  //打开app位置系统设置
  openLocationSettings(result: MethodResult): void {
    console.debug(">>>>>>>>>>openLocationSettings")
    try {
      let want: Want = {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'location_manager_settings',
      }
      let context = getContext(this) as common.UIAbilityContext;
      context.startAbility(want).then(() => {
        result.success(true);
      }).catch((err: BusinessError) => {
        result.success(false);
      });
    } catch (err) {
      result.success(false);
    }
  }

  stopListening(): void {
    if (this.channel == null) {
      console.debug(">>>>>Tried to stop listening when no MethodChannel had been initialized.")
      return;
    }
    this.channel.setMethodCallHandler(null);
    this.channel = null;
  }
}