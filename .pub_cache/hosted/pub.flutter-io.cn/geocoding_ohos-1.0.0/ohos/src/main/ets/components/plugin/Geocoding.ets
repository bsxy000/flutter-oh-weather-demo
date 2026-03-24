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

import { geoLocationManager } from '@kit.LocationKit';
import { GeocodeListenerAdapter } from './GeocodeMethodCallListener';
import { GeocodeCallResult } from './GeocodeMethodCallListener';
import { BusinessError } from '@kit.BasicServicesKit';
import { Locale } from './Locale';
import { StringTokenizer } from '../utils/StringTokenizer';
import { isEmpty } from '../utils/StringUtils';
import { DataConverter } from '../utils/DataConverter';

/**
 * the geocoding plugin implementation
 */
export class Geocoding {
  private readonly TAG: string = 'Geocoding';
  private locale?: Locale;
  private readonly MAX_RESULTS: number = 5;
  private readonly LOCALE_DELIMITER: string = '_';

  constructor() {

  }

  /**
   * OHOS geo request param, the same as java.util.Locale in android
   * geo search range param
   * @param localeStr
   */
  setLocaleIdentifier(localeStr: string): void {
    if (isEmpty(localeStr)) {
      return;
    }
    const stringTokenizer = new StringTokenizer(localeStr, this.LOCALE_DELIMITER);
    this.locale = new Locale(stringTokenizer);
  }

  /**
   * Returns a list of Address objects matching the supplied address string.
   *
   * @param address the address string for the search
   * @param callback the GeocodeListenerAdapter that listens for success or error
   * @return a list of Address objects. Returns null or empty list if no matches were found or there is no backend service available.
   * OHOS geoLocationManager.getAddressesFromLocationName
   * getAddressesFromLocationName(request: GeoCodeRequest): Promise<Array<GeoAddress>>
   * country 限制查询结果在指定的国家内，采用ISO 3166-1 alpha-2 。“CN”代表中国。默认值从设置中的“语言和地区”获取。
   */
  placemarkFromAddress(address: string, callback: GeocodeListenerAdapter): void {
    let geocodeRequest: geoLocationManager.GeoCodeRequest = { 'description': address, 'maxItems': this.MAX_RESULTS };
    if (this.locale !== undefined && this.locale !== null && this.locale instanceof Locale) {
      let localeTemp = this.locale.getLanguage();
      let countryTemp = this.locale.getCountry();
      if (!isEmpty(localeTemp) && !isEmpty(countryTemp)) {
        geocodeRequest = { 'description': address, 'locale': localeTemp, 'country': countryTemp };
      } else if (!isEmpty(localeTemp) && isEmpty(countryTemp)) {
        geocodeRequest = { 'description': address, 'locale': localeTemp };
      }
    }
    try {
      geoLocationManager.getAddressesFromLocationName(geocodeRequest).then((result) => {
        if (callback && typeof callback.onGeocode === 'function') {
          if (result) {
            let geoAddressList = DataConverter.arrayToList(result);
            callback.onGeocode(geoAddressList);
          }
        }
      })
        .catch((error: BusinessError) => {
          if (callback && typeof callback.onError === 'function') {
            callback.onError(JSON.stringify(error));
          }
        });
    } catch (err) {
      console.error(this.TAG + '  errCode:' + JSON.stringify(err));
    }
  }

  /**
   * Returns a list of Address objects matching the supplied coordinates.
   *
   * @param latitude  the latitude point for the search
   * @param longitude the longitude point for the search
   * @param callback the GeocodeListenerAdapter that listens for success or error
   * @return a list of Address objects. Returns null or empty list if no matches were found or there is no backend service available.
   */
  public placemarkFromCoordinates(latitude: number, longitude: number, callback: GeocodeListenerAdapter): void {
    let reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest =
      { 'latitude': latitude, 'longitude': longitude, 'maxItems': this.MAX_RESULTS };
    if (this.locale !== undefined && this.locale !== null && this.locale instanceof Locale) {
      let localeTemp = this.locale.getLanguage();
      let countryTemp = this.locale.getCountry();
      if (!isEmpty(localeTemp) && !isEmpty(countryTemp)) {
        reverseGeocodeRequest = {
          'locale': localeTemp,
          'country': countryTemp,
          'latitude': latitude,
          'longitude': longitude,
          'maxItems': this.MAX_RESULTS
        };
      } else if (!isEmpty(localeTemp) && isEmpty(countryTemp)) {
        reverseGeocodeRequest = {
          'locale': localeTemp,
          'latitude': latitude,
          'longitude': longitude,
          'maxItems': this.MAX_RESULTS
        };
      }
    }
    try {
      geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest, (err, data) => {
        if (data) {
          let geoAddressList = DataConverter.arrayToList(data);
          callback.onGeocode(geoAddressList);
        }
        if (err) {
          callback.onError(JSON.stringify(err));
        }
      });
    } catch (err) {
      console.error(this.TAG + '  errCode:  ' + JSON.stringify(err));
    }
  }

  /**
   * OHOS geoLocationManager.isGeocoderAvailable
   * 地理编码和逆编码服务是否可用
   * @param result
   */
  isPresent(result: GeocodeCallResult): void {
    let available: boolean = false;
    try {
      available = geoLocationManager.isGeocoderAvailable();
      result.onResult(available, '');
    } catch (err) {
      result.onResult(false, JSON.stringify(err));
    }
  }
}