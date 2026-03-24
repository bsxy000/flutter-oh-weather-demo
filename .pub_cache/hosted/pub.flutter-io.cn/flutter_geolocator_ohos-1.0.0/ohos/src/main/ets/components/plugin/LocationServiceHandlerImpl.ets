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
import common from '@ohos.app.ability.common';

export default class LocationServiceHandlerImpl implements StreamHandler {
  private channel: EventChannel | null = null;
  private context: common.UIAbilityContext | null = null;

  constructor() {

  }

  startListening(context: common.UIAbilityContext, binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.stopListening();
    }
    this.channel = new EventChannel(binding.getBinaryMessenger(), 'flutter.baseflow.com/geolocator_service_updates');
    this.channel.setStreamHandler(this);
    this.context = context;

  }

  stopListening(): void {
    if (this.channel == null) {
      return;
    }
    console.debug(">>>>>>>>>>LocationServiceHandlerImpl=======stopListening")
    this.channel.setStreamHandler(null);
    this.channel = null;
  }

  async onListen(args: object, events: EventSink): Promise<void> {
    if (this.context == null) {
      return;
    }

  }

  onCancel(args: object): void {
    this.stopListening();
  }
}