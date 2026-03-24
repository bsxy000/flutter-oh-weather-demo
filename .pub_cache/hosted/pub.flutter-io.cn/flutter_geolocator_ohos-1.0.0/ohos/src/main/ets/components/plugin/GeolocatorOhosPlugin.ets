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
import { FlutterPlugin, FlutterPluginBinding, } from '@ohos/flutter_ohos';

import common from '@ohos.app.ability.common';
import MethodCallHandlerImpl from './MethodCallHandlerImpl';
import StreamHandlerImpl from './StreamHandlerImpl';
import LocationServiceHandlerImpl from './LocationServiceHandlerImpl';


/** GeolocatorOhosPlugin **/
export default class GeolocatorOhosPlugin implements FlutterPlugin {
  private methodCallHandler: MethodCallHandlerImpl | null = null;
  private streamHandler: StreamHandlerImpl | null = null;
  private locationServiceHandler: LocationServiceHandlerImpl | null = null;
  private context: common.UIAbilityContext;

  constructor() {
    this.context = getContext(this) as common.UIAbilityContext;
  }

  getUniqueClassName(): string {
    return "GeolocatorOhosPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.methodCallHandler = new MethodCallHandlerImpl();
    this.methodCallHandler.startListening(binding);

    this.streamHandler = new StreamHandlerImpl();
    this.streamHandler.startListening(binding);

    this.locationServiceHandler = new LocationServiceHandlerImpl();
    this.locationServiceHandler.startListening(this.context, binding);

  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.methodCallHandler != null) {
      this.methodCallHandler.stopListening()
      this.methodCallHandler = null;
    }
    if (this.streamHandler != null) {
      this.streamHandler.stopListening();
      this.streamHandler = null;
    }
    if (this.locationServiceHandler != null) {
      this.locationServiceHandler.stopListening();
      this.locationServiceHandler = null;
    }
  }
}
