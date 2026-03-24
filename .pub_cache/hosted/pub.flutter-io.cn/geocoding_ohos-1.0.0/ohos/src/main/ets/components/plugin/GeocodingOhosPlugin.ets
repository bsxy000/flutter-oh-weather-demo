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

import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { Geocoding } from './Geocoding';
import { AddressMapper } from '../utils/AddressMapper';

/**
 * the Geocoding Plugin of OHOS
 */
export default class GeocodingOhosPlugin implements FlutterPlugin, MethodCallHandler {
  private readonly TAG: string = 'GeocodingOhosPlugin';
  private channel: MethodChannel | null = null;
  private geocoding: Geocoding | null = null;

  constructor() {

  }

  getUniqueClassName(): string {
    return "GeocodingOhosPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'flutter.baseflow.com/geocoding');
    this.channel.setMethodCallHandler(this)
    this.geocoding = new Geocoding();
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
      this.channel = null;
    }
  }

  /**
   *
   * @param call
   * @param result
   */
  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'setLocaleIdentifier':
        this.setLocaleIdentifier(call, result);
        break;
      case 'locationFromAddress':
        this.onLocationFromAddress(call, result);
        break;
      case 'placemarkFromAddress':
        this.onPlacemarkFromAddress(call, result);
        break;
      case 'placemarkFromCoordinates':
        this.onPlacemarkFromCoordinates(call, result);
        break;
      case 'isPresent':
        this.onIsPresent(call, result);
        break;
      default:
        break;
    }
  }

  /**
   *
   * @param call
   * @param result
   */
  private setLocaleIdentifier(call: MethodCall, result: MethodResult): void {
    const languageTag: string = call.argument('localeIdentifier');
    if(this.geocoding){
      this.geocoding.setLocaleIdentifier(languageTag);
      result.success(true);
    }else{
      result.success(false);
    }
  }

  /**
   *
   * @param call
   * @param result
   */
  private onLocationFromAddress(call: MethodCall, result: MethodResult): void {
    const address: string = call.argument('address');
    if (address === null || address.trim() === '') {
      result.error(
        'ARGUMENT_ERROR',
        'Supply a valid value for the \'address\' parameter.',
        null
      );
      return;
    }
    if (this.geocoding) {
      this.geocoding.placemarkFromAddress(address, {
        onGeocode: (addresses) => {
          result.success(AddressMapper.toLocationHashMapList(addresses));
        },
        onError: (error) => {
          result.error(null, null, {
            moreDetails: error
          });
        }
      }
      );
    }

  }

  /**
   *
   * @param call
   * @param result
   */
  private onPlacemarkFromAddress(call: MethodCall, result: MethodResult): void {
    const address: string = call.argument('address');
    if (address === null || address.trim() === "") {
      result.error(
        'ARGUMENT_ERROR',
        'Supply a valid value for the \'address\' parameter.',
        null
      );
      return;
    }
    if (this.geocoding) {
      this.geocoding.placemarkFromAddress(address, {
        onGeocode: (addresses) => {
          result.success(AddressMapper.toAddressHashMapList(addresses));
        },
        onError: (error) => {
          result.error(null, null, {
            moreDetails: error
          });
        }
      }
      );
    }
  }

  /**
   *
   * @param call
   * @param result
   */
  private onPlacemarkFromCoordinates(call: MethodCall, result: MethodResult): void {
    const latitude: number = call.argument('latitude');
    const longitude: number = call.argument('longitude');
    if (this.geocoding) {
      this.geocoding.placemarkFromCoordinates(latitude, longitude, {
        onGeocode: (addresses) => {
          result.success(AddressMapper.toAddressHashMapList(addresses));
        },
        onError: (error) => {
          result.error(null, null, {
            moreDetails: error
          });
        }
      }
      );
    }
  }

  /**
   *
   * @param call
   * @param result
   */
  private onIsPresent(call: MethodCall, result: MethodResult): void {
    if (this.geocoding) {
      this.geocoding.isPresent({
        onResult: (isSuccess, msg) => {
          result.success(isSuccess);
        }
      });
    }
  }
}