# geolocator_ohos

[![pub package](https://img.shields.io/pub/v/geolocator.svg)](https://pub.dartlang.org/packages/geolocator) ![Build status](https://github.com/Baseflow/flutter-geolocator/workflows/geolocator/badge.svg?branch=master) [![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://github.com/tenhobi/effective_dart) [![codecov](https://codecov.io/gh/Baseflow/flutter-geolocator/branch/master/graph/badge.svg)](https://codecov.io/gh/Baseflow/flutter-geolocator)

A Flutter geolocation plugin which provides easy access to platform specific location services.

## Features

* Get the last known location;
* Get the current location of the device;
* Get continuous location updates;
* Check if location services are enabled on the device;
* Calculate the distance (in meters) between two geocoordinates;
* Calculate the bearing between two geocoordinates;

> **IMPORTANT:**
>
> Version 7.0.0 of the geolocator plugin contains several breaking changes, for a complete overview please have a look at the [Breaking changes in 7.0.0](https://github.com/Baseflow/flutter-geolocator/wiki/Breaking-changes-in-7.0.0) wiki page.
>
> Starting from version 6.0.0 the geocoding features (`placemarkFromAddress` and `placemarkFromCoordinates`) are no longer part of the geolocator plugin. We have moved these features to their own plugin: [geocoding](https://pub.dev/packages/geocoding). This new plugin is an improved version of the old methods.

## Usage

To add the geolocator to your Flutter application read the [install](https://pub.dev/packages/geolocator/install) instructions.

<details>
<summary>Ohos</summary>

**Permissions**

On Ohos you'll need to add either the `LOCATION_IN_BACKGROUND` or the `APPROXIMATELY_LOCATION` permission to your Ohos module.json5. To do so open the module.json5 file (located under ohos/entry/src/main) and add one of the following two lines as direct children of the `requestPermissions` tag (when you configure both permissions the `LOCATION_IN_BACKGROUND` will be used by the geolocator plugin):

``` json5
{"name" :  "ohos.permission.LOCATION_IN_BACKGROUND"},
{"name" :  "ohos.permission.APPROXIMATELY_LOCATION"},
```

</details>

<details>
<summary>Windows</summary>

To use the Geolocator plugin on Windows you need to be using Flutter 2.10 or higher. Flutter will automatically add the endorsed [geolocator_windows]() package to your application when you add the `flutter_geolocator_ohos: ^1.0.0` dependency to your `pubspec.yaml`.

</details>

### Example

The code below shows an example on how to acquire the current position of the device, including checking if the location services are enabled and checking / requesting permission to access the position of the device:

```dart
import 'package:flutter_geolocator_ohos/flutter_geolocator_ohos.dart';

/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await geolocatorOhos.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the 
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await geolocatorOhos.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Ohos's shouldShowRequestPermissionRationale 
      // returned true. According to Ohos guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately. 
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.');
  } 

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}
```

## API

### Geolocation

#### Current location

To query the current location of the device simply make a call to the `getCurrentPosition` method. You can finetune the results by specifying the following parameters:

- `desiredAccuracy`: the accuracy of the location data that your app wants to receive;
- `timeLimit`: the maximum amount of time allowed to acquire the current location. When the time limit is passed a `TimeOutException` will be thrown and the call will be cancelled. By default no limit is configured.

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

Position position = await geolocatorOhos.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
```

#### Last known location

To query the last known location retrieved stored on the device you can use the `getLastKnownPosition` method (note that this can result in a `null` value when no location details are available):

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

Position? position = await geolocatorOhos.getLastKnownPosition();
```

#### Listen to location updates

To listen for location changes you can call the `getPositionStream` to receive stream you can listen to and receive position updates. You can finetune the results by specifying the following parameters:

- `accuracy`: the accuracy of the location data that your app wants to receive;
- `distanceFilter`: the minimum distance (measured in meters) a device must move horizontally before an update event is generated;
- `timeLimit`: the maximum amount of time allowed between location updates. When the time limit is passed a `TimeOutException` will be thrown and the stream will be cancelled. By default no limit is configured.

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

final LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 100,
);
StreamSubscription<Position> positionStream = geolocatorOhos.getPositionStream(locationSettings: locationSettings).listen(
    (Position? position) {
        print(position == null ? 'Unknown' : '${position.latitude.toString()}, ${position.longitude.toString()}');
    });
```

In certain situation it is necessary to specify some platform specific settings. This can be accomplished using the platform specific `OhosSettings` or `AppleSettings` classes. When using a platform specific class, the platform specific package must be imported as well. For example:

```dart
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:flutter_geolocator_ohos/flutter_geolocator_ohos.dart';

late OhosSettings ohosSettings;

ohosSettings = OhosSettings(
accuracy: LocationAccuracy.high,
distanceFilter: 100,
forceLocationManager: true,
intervalDuration: const Duration(seconds: 10),
//(Optional) Set foreground notification config to keep the app alive 
//when going to the background
foregroundNotificationConfig: const ForegroundNotificationConfig(
notificationText:
"Example app will continue to receive your location even when you aren't using it",
notificationTitle: "Running in Background",
enableWakeLock: true,
)
);

StreamSubscription<Position> positionStream = geolocatorOhos.getPositionStream(locationSettings: locationSettings).listen(
    (Position? position) {
        print(position == null ? 'Unknown' : '${position.latitude.toString()}, ${position.longitude.toString()}');
    });
```

#### Location accuracy (Ohos)

To query if a user enabled Approximate location fetching or Precise location fetching, you can call the `Geolocator().getLocationAccuracy()` method.

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

var accuracy = await Geolocator.getLocationAccuracy();
```

#### Location service information

To check if location services are enabled you can call the `isLocationServiceEnabled` method:

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

bool isLocationServiceEnabled  = await geolocatorOhos.isLocationServiceEnabled();
```

To listen for service status changes you can call the `getServiceStatusStream`. This will return a `Stream<ServiceStatus>` which can be listened to, to receive location service status updates.

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

StreamSubscription<ServiceStatus> serviceStatusStream = geolocatorOhos.getServiceStatusStream().listen(
    (ServiceStatus status) {
        print(status);
    });
```

### Permissions

When using the web platform, the `checkPermission` method will return the `LocationPermission.denied` status, when the browser doesn't support the JavaScript Permissions API. Nevertheless, the `getCurrentPosition` and `getPositionStream` methods can still be used on the web platform.

If you want to check if the user already granted permissions to acquire the device's location you can make a call to the `checkPermission` method:

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

LocationPermission permission = await geolocatorOhos.checkPermission();
```

If you want to request permission to access the device's location you can call the `requestPermission` method:

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

LocationPermission permission = await geolocatorOhos.requestPermission();
```

Possible results from the `checkPermission` and `requestPermission` methods are:

Permission | Description
-----------|------------
denied | Permission to access the device's location is denied by the user. You are free to request permission again (this is also the initial permission state).
deniedForever | Permission to access the device's location is permanently denied. When requesting permissions the permission dialog will not be shown until the user updates the permission in the App settings.
whileInUse | Permission to access the device's location is allowed only while the App is in use.
always | Permission to access the device's location is allowed even when the App is running in the background.

> Note: Ohos can only return `whileInUse`, `always` or `denied` when checking permissions. Due to limitations on the Ohos OS it is not possible to determine if permissions are denied permanently when checking permissions. Using a workaround the geolocator is only able to do so as a result of the `requestPermission` method. More information can be found in our [wiki](https://github.com/Baseflow/flutter-geolocator/wiki/Breaking-changes-in-7.0.0#Ohos-permission-update).

### Settings

In some cases it is necessary to ask the user and update their device settings. For example when the user initially permanently denied permissions to access the device's location or if the location services are not enabled (and, on Ohos, automatic resolution didn't work). In these cases you can use the `openAppSettings` or `openLocationSettings` methods to immediately redirect the user to the device's settings page.

On Ohos the `openAppSettings` method will redirect the user to the App specific settings where the user can update necessary permissions. The `openLocationSettings` method will redirect the user to the location settings where the user can enable/ disable the location services.

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

await geolocatorOhos.openAppSettings();
await geolocatorOhos.openLocationSettings();
```

### Utility methods

To calculate the distance (in meters) between two geocoordinates you can use the `distanceBetween` method. The `distanceBetween` method takes four parameters:

Parameter | Type | Description
----------|------|------------
startLatitude | double | Latitude of the start position
startLongitude | double | Longitude of the start position
endLatitude | double | Latitude of the destination position
endLongitude | double | Longitude of the destination position

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

double distanceInMeters = geolocatorOhos.distanceBetween(52.2165157, 6.9437819, 52.3546274, 4.8285838);
```

If you want to calculate the bearing between two geocoordinates you can use the `bearingBetween` method. The `bearingBetween` method also takes four parameters:

Parameter | Type | Description
----------|------|------------
startLatitude | double | Latitude of the start position
startLongitude | double | Longitude of the start position
endLatitude | double | Latitude of the destination position
endLongitude | double | Longitude of the destination position

``` dart
import 'package:flutter_geolocator_ohos/geolocator_ohos.dart';

double bearing = geolocatorOhos.bearingBetween(52.2165157, 6.9437819, 52.3546274, 4.8285838);
```

## Issues

Please file any issues, bugs or feature requests as an issue on our [GitHub](https://github.com/Baseflow/flutter-geolocator/issues) page. Commercial support is available, you can contact us at <hello@baseflow.com>.

## Want to contribute

If you would like to contribute to the plugin (e.g. by improving the documentation, solving a bug or adding a cool new feature), please carefully review our [contribution guide](../CONTRIBUTING.md) and send us your [pull request](https://github.com/Baseflow/flutter-geolocator/pulls).

## Author

This Geolocator plugin for Flutter is developed by [Baseflow](https://baseflow.com).


