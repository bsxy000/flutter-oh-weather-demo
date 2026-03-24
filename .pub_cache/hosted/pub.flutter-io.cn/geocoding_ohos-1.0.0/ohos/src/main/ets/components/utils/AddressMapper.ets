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

import { List } from '@kit.ArkTS';
import { geoLocationManager } from '@kit.LocationKit';

export class AddressMapper {
  static TAG: string = 'AddressMapper';

  static toLocationHashMapList(addresses: List<geoLocationManager.GeoAddress>): List<Map<string, Object>> {
    let locationList: List<Map<string, Object>> = new List<Map<string, Object>>();
    for (let address of addresses) {
      locationList.add(AddressMapper.toLocationHashmap(address));
    }
    return locationList;
  }

  private static toLocationHashmap(address: geoLocationManager.GeoAddress): Map<string, Object> {
    let location: Map<string, Object> = new Map<string, Object>();
    if (address.latitude != undefined) {
      location.set("latitude", address.latitude);
    } else {
      location.set("latitude", 0);
    }
    if (address.longitude != undefined) {
      location.set("longitude", address.longitude);
    } else {
      location.set("longitude", 0);
    }
    location.set("timestamp", Date.now());
    return location;
  }

  static toAddressHashMapList(addresses: List<geoLocationManager.GeoAddress>): List<Map<string, string>> {
    let addressList: List<Map<string, string>> = new List<Map<string, string>>();
    for (let address of addresses) {
      addressList.add(AddressMapper.toAddressHashMap(address));
    }
    return addressList;
  }

  private static toAddressHashMap(address: geoLocationManager.GeoAddress): Map<string, string> {
    let hashMap: Map<string, string> = new Map<string, string>();
    hashMap.set("name", '');
    if (address.placeName !== undefined && address.placeName !== null) {
      hashMap.set("name", address.placeName);
    }
    hashMap.set("street", '');
    if (address.roadName !== undefined && address.roadName !== null) {
      hashMap.set("street", address.roadName);
    }
    hashMap.set("isoCountryCode", '');
    if (address.countryCode !== undefined && address.countryCode !== null) {
      hashMap.set("isoCountryCode", address.countryCode);
    }
    hashMap.set("country", '');
    if (address.countryName !== undefined && address.countryName !== null) {
      hashMap.set("country", address.countryName);
    }
    hashMap.set("thoroughfare", '');
    if (address.roadName !== undefined && address.roadName !== null) {
      hashMap.set("thoroughfare", address.roadName);
    }
    hashMap.set("subThoroughfare", '');
    if (address.subRoadName !== undefined && address.subRoadName !== null) {
      hashMap.set("subThoroughfare", address.subRoadName);
    }
    hashMap.set("postalCode", '');
    if (address.postalCode !== undefined && address.postalCode !== null) {
      hashMap.set("postalCode", address.postalCode);
    }
    hashMap.set("administrativeArea", '');
    if (address.administrativeArea !== undefined && address.administrativeArea !== null) {
      hashMap.set("administrativeArea", address.administrativeArea);
    }
    hashMap.set("subAdministrativeArea", '');
    if (address.subAdministrativeArea !== undefined && address.subAdministrativeArea !== null) {
      hashMap.set("subAdministrativeArea", address.subAdministrativeArea);
    }
    hashMap.set("locality", '');
    if (address.locality !== undefined && address.locality !== null) {
      hashMap.set("locality", address.locality);
    }
    hashMap.set("subLocality", '');
    if (address.subLocality !== undefined && address.subLocality !== null) {
      hashMap.set("subLocality", address.subLocality);
    }
    return hashMap;
  }
}