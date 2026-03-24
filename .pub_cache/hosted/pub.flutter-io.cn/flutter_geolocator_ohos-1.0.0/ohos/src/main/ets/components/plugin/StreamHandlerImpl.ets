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
import { EventChannel, FlutterPluginBinding } from "@ohos/flutter_ohos";
import { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import PermissionManager from "./permission/PermissionManager";
import { ErrorCodes, getErrorCodeString, locationToMap, LocationAccuracyStatus } from "./utils/Utils";
import { LocationOptions } from "./location/LocationOptions";
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import common from '@ohos.app.ability.common';

let eventSink: EventSink | null = null
const locationChangeListener = (location: geoLocationManager.Location): void => {
  console.debug(">>>>>>>StreamHandlerImpl===,location data: " + JSON.stringify(location));
  let position = locationToMap(location);
  if (eventSink != null) {
    eventSink.success(position);
  }
}

export default class StreamHandlerImpl implements StreamHandler {
  private channel: EventChannel | null = null;

  constructor() {
    console.debug(">>>>>>>>>>StreamHandlerImpl===")
  }

  startListening(binding: FlutterPluginBinding): void {
    console.debug(">>>>>>>>>>StreamHandlerImpl=======startListening")
    if (this.channel != null) {
      this.stopListening();
    }
    this.channel = new EventChannel(binding.getBinaryMessenger(), 'flutter.baseflow.com/geolocator_updates');
    this.channel.setStreamHandler(this);

  }

  stopListening(): void {
    if (this.channel == null) {
      return;
    }
    console.debug(">>>>>>>>>>StreamHandlerImpl=======stopListening")
    geoLocationManager.off('locationChange')
    this.channel.setStreamHandler(null);
    this.channel = null;
  }

  async onListen(args: object, events: EventSink): Promise<void> {
    console.debug(">>>>>>>>>>StreamHandlerImpl=======onListen")
    try {
      let permissionManager = new PermissionManager();
      let permissionStatus: boolean | undefined = await permissionManager.checkPermissions();
      if (!permissionStatus) {
        events.error(ErrorCodes.permissionDenied, getErrorCodeString(ErrorCodes.permissionDenied), null);
        return;
      }
    } catch (err) {
      events.error(ErrorCodes.permissionDefinitionsNotFound,
        getErrorCodeString(ErrorCodes.permissionDefinitionsNotFound), null);
      return;
    }
    this.getLocation(args, events);

  }

  // 获取定位
  async getLocation(args: Object, events: EventSink) {
    eventSink = events;
    try {
      //使用ContinuousLocationRequest\LocationRequest作为入参
      let timeInterval = 10000;
      let distanceInterval = 100;
      let maxAccuracy = 0;
      let map = args as Map<String, Object>;
      if (map != null) {
        if (map.get("timeInterval") != null) {
          timeInterval = map.get("timeInterval") as number / 1000;
        }
        if (map.get("accuracy") != null) {
          maxAccuracy = map.get("accuracy") as number;
        }
        if (map.get("distanceFilter") != null) {
          distanceInterval = map.get("distanceFilter") as number;
        }
      }
      let requestInfo: geoLocationManager.ContinuousLocationRequest = {
        'interval': timeInterval,
        'locationScenario': geoLocationManager.UserActivityScenario.NAVIGATION
      };
      try {
        console.debug(">>>>>>>>>>StreamHandlerImpl=======getLocation   requestInfo:" + JSON.stringify(requestInfo))
        geoLocationManager.on('locationChange', requestInfo, locationChangeListener);
      } catch (err) {
        console.error(">>>>>>>>StreamHandlerImpl=====errCode:" + JSON.stringify(err));
      }
    } catch (err) {
      console.error(">>>>>>>>>>>StreamHandlerImpl=====getCurrentPosition--------errCode:" + JSON.stringify(err));
    }
  }

  onCancel(args: object): void {
    console.debug(">>>>>>>>>>StreamHandlerImpl=======onCancel-------")
    geoLocationManager.off('locationChange')
  }
}