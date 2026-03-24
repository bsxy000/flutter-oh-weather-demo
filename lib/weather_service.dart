import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_geolocator_ohos/flutter_geolocator_ohos.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geocoding_ohos/geocoding_ohos.dart';

enum WeatherRecoveryAction {
  retry,
  openLocationSettings,
  openAppSettings,
}

class WeatherLoadException implements Exception {
  const WeatherLoadException(
    this.message, {
    this.action = WeatherRecoveryAction.retry,
  });

  final String message;
  final WeatherRecoveryAction action;

  @override
  String toString() => message;
}

class DailyForecast {
  const DailyForecast({
    required this.dateIsoString,
    required this.weatherCode,
    required this.maxTemperatureC,
    required this.minTemperatureC,
    required this.precipitationMm,
    required this.precipitationProbabilityPercent,
    required this.windSpeedMaxKmh,
    required this.uvIndexMax,
    required this.sunriseIsoString,
    required this.sunsetIsoString,
  });

  final String dateIsoString;
  final int weatherCode;
  final double maxTemperatureC;
  final double minTemperatureC;
  final double precipitationMm;
  final double precipitationProbabilityPercent;
  final double windSpeedMaxKmh;
  final double uvIndexMax;
  final String sunriseIsoString;
  final String sunsetIsoString;

  DateTime get date => DateTime.tryParse(dateIsoString) ?? DateTime.now();

  DateTime? get sunriseTime => DateTime.tryParse(sunriseIsoString);

  DateTime? get sunsetTime => DateTime.tryParse(sunsetIsoString);

  String get shortDateLabel => '${date.month}/${date.day}';

  String get maxTemperatureLabel => '${maxTemperatureC.round()}°';

  String get minTemperatureLabel => '${minTemperatureC.round()}°';

  String get temperatureRangeLabel =>
      '$maxTemperatureLabel / $minTemperatureLabel';

  String get precipitationLabel =>
      '${precipitationMm.toStringAsFixed(1)} 毫米';

  String get precipitationProbabilityLabel =>
      '${precipitationProbabilityPercent.round()}%';

  String get windSpeedMaxLabel =>
      '${windSpeedMaxKmh.toStringAsFixed(1)} 公里/小时';

  String get uvIndexLabel => uvIndexMax.toStringAsFixed(1);

  String get sunriseLabel => _timeLabelFromIso(sunriseIsoString);

  String get sunsetLabel => _timeLabelFromIso(sunsetIsoString);

  String get daylightDurationLabel {
    if (sunriseTime == null || sunsetTime == null) {
      return '--';
    }

    final duration = sunsetTime!.difference(sunriseTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hours小时$minutes分';
  }

  static String _timeLabelFromIso(String isoString) {
    final sections = isoString.split('T');
    if (sections.length < 2) {
      return isoString;
    }

    final time = sections[1];
    return time.length >= 5 ? time.substring(0, 5) : time;
  }
}

class HourlyForecast {
  const HourlyForecast({
    required this.timeIsoString,
    required this.temperatureC,
    required this.weatherCode,
    required this.isDay,
  });

  final String timeIsoString;
  final double temperatureC;
  final int weatherCode;
  final bool isDay;

  DateTime get time => DateTime.tryParse(timeIsoString) ?? DateTime.now();

  String get hourLabel {
    final hour = time.hour.toString().padLeft(2, '0');
    return '$hour:00';
  }

  String get shortHourLabel => '${time.hour}时';

  String get temperatureLabel => '${temperatureC.round()}°';
}

class AirQualityData {
  const AirQualityData({
    required this.europeanAqi,
    required this.pm25,
    required this.pm10,
    required this.ozone,
    required this.nitrogenDioxide,
    required this.sulphurDioxide,
    required this.uvIndex,
  });

  factory AirQualityData.fromApiResponse(Map<String, dynamic> payload) {
    final current = payload['current'];
    if (current is! Map<String, dynamic>) {
      throw const WeatherLoadException(
        '空气质量服务返回的数据结构不正确。',
      );
    }

    return AirQualityData(
      europeanAqi: _readDouble(current, 'european_aqi'),
      pm25: _readDouble(current, 'pm2_5'),
      pm10: _readDouble(current, 'pm10'),
      ozone: _readDouble(current, 'ozone'),
      nitrogenDioxide: _readDouble(current, 'nitrogen_dioxide'),
      sulphurDioxide: _readDouble(current, 'sulphur_dioxide'),
      uvIndex: _readDouble(current, 'uv_index'),
    );
  }

  final double europeanAqi;
  final double pm25;
  final double pm10;
  final double ozone;
  final double nitrogenDioxide;
  final double sulphurDioxide;
  final double uvIndex;

  String get europeanAqiLabel => europeanAqi.round().toString();

  String get pm25Label => pm25.toStringAsFixed(1);

  String get pm10Label => pm10.toStringAsFixed(1);

  String get ozoneLabel => ozone.toStringAsFixed(0);

  String get nitrogenDioxideLabel => nitrogenDioxide.toStringAsFixed(0);

  String get sulphurDioxideLabel => sulphurDioxide.toStringAsFixed(0);

  String get uvIndexLabel => uvIndex.toStringAsFixed(1);

  static double _readDouble(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is num) {
      return value.toDouble();
    }

    throw WeatherLoadException(
      '空气质量字段 "$key" 缺失或类型不正确。',
    );
  }
}

class WeatherData {
  const WeatherData({
    required this.locationName,
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.humidityPercent,
    required this.windSpeedKmh,
    required this.precipitationMm,
    required this.maxTemperatureC,
    required this.minTemperatureC,
    required this.weatherCode,
    required this.isDay,
    required this.updatedAtIsoString,
    required this.dailyForecasts,
    required this.hourlyForecasts,
    this.airQuality,
    this.surfacePressureHpa,
    this.visibilityKm,
    this.cloudCoverPercent,
  });

  factory WeatherData.fromApiResponse(
    Map<String, dynamic> payload, {
    required String locationName,
    AirQualityData? airQuality,
  }) {
    final current = payload['current'];
    final daily = payload['daily'];
    final hourly = payload['hourly'];

    if (current is! Map<String, dynamic> ||
        daily is! Map<String, dynamic> ||
        hourly is! Map<String, dynamic>) {
      throw const WeatherLoadException(
        '天气服务返回的数据结构不正确。',
      );
    }

    final dates = _readStringList(daily, 'time');
    final weatherCodes = _readIntList(daily, 'weather_code');
    final maxTemperatures = _readDoubleList(daily, 'temperature_2m_max');
    final minTemperatures = _readDoubleList(daily, 'temperature_2m_min');
    final precipitationSums = _readDoubleList(daily, 'precipitation_sum');
    final precipitationProbabilityList =
        _readDoubleList(daily, 'precipitation_probability_max');
    final windSpeedMaxList = _readDoubleList(daily, 'wind_speed_10m_max');
    final uvIndexMaxList = _readDoubleList(daily, 'uv_index_max');
    final sunriseList = _readStringList(daily, 'sunrise');
    final sunsetList = _readStringList(daily, 'sunset');

    final hourlyTimes = _readStringList(hourly, 'time');
    final hourlyTemperatures = _readDoubleList(hourly, 'temperature_2m');
    final hourlyWeatherCodes = _readIntList(hourly, 'weather_code');
    final hourlyDayFlags = _readIntList(hourly, 'is_day');

    final dailyCount = [
      dates.length,
      weatherCodes.length,
      maxTemperatures.length,
      minTemperatures.length,
      precipitationSums.length,
      precipitationProbabilityList.length,
      windSpeedMaxList.length,
      uvIndexMaxList.length,
      sunriseList.length,
      sunsetList.length,
    ].reduce((value, element) => value < element ? value : element);

    if (dailyCount == 0) {
      throw const WeatherLoadException(
        '未获取到未来天气预报数据。',
      );
    }

    final hourlyCount = [
      hourlyTimes.length,
      hourlyTemperatures.length,
      hourlyWeatherCodes.length,
      hourlyDayFlags.length,
    ].reduce((value, element) => value < element ? value : element);

    if (hourlyCount == 0) {
      throw const WeatherLoadException(
        '未获取到逐小时天气数据。',
      );
    }

    final forecasts = List<DailyForecast>.generate(
      dailyCount,
      (index) => DailyForecast(
        dateIsoString: dates[index],
        weatherCode: weatherCodes[index],
        maxTemperatureC: maxTemperatures[index],
        minTemperatureC: minTemperatures[index],
        precipitationMm: precipitationSums[index],
        precipitationProbabilityPercent: precipitationProbabilityList[index],
        windSpeedMaxKmh: windSpeedMaxList[index],
        uvIndexMax: uvIndexMaxList[index],
        sunriseIsoString: sunriseList[index],
        sunsetIsoString: sunsetList[index],
      ),
    );

    final hourlyForecasts = List<HourlyForecast>.generate(
      hourlyCount,
      (index) => HourlyForecast(
        timeIsoString: hourlyTimes[index],
        temperatureC: hourlyTemperatures[index],
        weatherCode: hourlyWeatherCodes[index],
        isDay: hourlyDayFlags[index] == 1,
      ),
    );

    return WeatherData(
      locationName: locationName,
      temperatureC: _readDouble(current, 'temperature_2m'),
      apparentTemperatureC: _readDouble(current, 'apparent_temperature'),
      humidityPercent: _readDouble(current, 'relative_humidity_2m'),
      windSpeedKmh: _readDouble(current, 'wind_speed_10m'),
      precipitationMm: _readDouble(current, 'precipitation'),
      maxTemperatureC: maxTemperatures.first,
      minTemperatureC: minTemperatures.first,
      weatherCode: _readInt(current, 'weather_code'),
      isDay: _readInt(current, 'is_day') == 1,
      updatedAtIsoString: _readString(current, 'time'),
      dailyForecasts: forecasts,
      hourlyForecasts: hourlyForecasts,
      airQuality: airQuality,
      surfacePressureHpa: _readNullableDouble(current, 'surface_pressure'),
      visibilityKm: _readNullableDouble(current, 'visibility') != null
          ? _readNullableDouble(current, 'visibility')! / 1000
          : null,
      cloudCoverPercent: _readNullableDouble(current, 'cloud_cover'),
    );
  }

  final String locationName;
  final double temperatureC;
  final double apparentTemperatureC;
  final double humidityPercent;
  final double windSpeedKmh;
  final double precipitationMm;
  final double maxTemperatureC;
  final double minTemperatureC;
  final int weatherCode;
  final bool isDay;
  final String updatedAtIsoString;
  final List<DailyForecast> dailyForecasts;
  final List<HourlyForecast> hourlyForecasts;
  final AirQualityData? airQuality;
  final double? surfacePressureHpa;
  final double? visibilityKm;
  final double? cloudCoverPercent;

  DailyForecast get todayForecast => dailyForecasts.first;

  String get temperatureLabel => '${temperatureC.round()}°C';

  String get apparentTemperatureLabel =>
      '${apparentTemperatureC.round()}°C';

  String get maxTemperatureLabel => '${maxTemperatureC.round()}°';

  String get minTemperatureLabel => '${minTemperatureC.round()}°';

  String get humidityLabel => '${humidityPercent.round()}%';

  String get windSpeedLabel =>
      '${windSpeedKmh.toStringAsFixed(1)} 公里/小时';

  String get precipitationLabel =>
      '${precipitationMm.toStringAsFixed(1)} 毫米';

  String get surfacePressureLabel =>
      surfacePressureHpa == null ? '--' : '${surfacePressureHpa!.round()} hPa';

  String get visibilityLabel => visibilityKm == null
      ? '--'
      : '${visibilityKm!.toStringAsFixed(1)} 公里';

  String get cloudCoverLabel =>
      cloudCoverPercent == null ? '--' : '${cloudCoverPercent!.round()}%';

  String get updatedTimeLabel {
    final sections = updatedAtIsoString.split('T');
    if (sections.length < 2) {
      return updatedAtIsoString;
    }

    final time = sections[1];
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  static double _readDouble(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is num) {
      return value.toDouble();
    }

    throw WeatherLoadException(
      '天气字段 "$key" 缺失或类型不正确。',
    );
  }

  static double? _readNullableDouble(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is num) {
      return value.toDouble();
    }

    return null;
  }

  static List<double> _readDoubleList(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is List) {
      return value.whereType<num>().map((item) => item.toDouble()).toList();
    }

    throw WeatherLoadException(
      '天气列表 "$key" 缺失或类型不正确。',
    );
  }

  static int _readInt(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is num) {
      return value.toInt();
    }

    throw WeatherLoadException(
      '天气字段 "$key" 缺失或类型不正确。',
    );
  }

  static List<int> _readIntList(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is List) {
      return value.whereType<num>().map((item) => item.toInt()).toList();
    }

    throw WeatherLoadException(
      '天气列表 "$key" 缺失或类型不正确。',
    );
  }

  static String _readString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }

    throw WeatherLoadException(
      '天气字段 "$key" 缺失或为空。',
    );
  }

  static List<String> _readStringList(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is List) {
      return value.whereType<String>().toList();
    }

    throw WeatherLoadException(
      '天气列表 "$key" 缺失或类型不正确。',
    );
  }
}

class WeatherService {
  const WeatherService();

  static const Duration _requestTimeout = Duration(seconds: 12);
  static const String _defaultLocationName = '当前位置';
  static bool _isGeocodingRegistered = false;

  GeolocatorOhos get _geolocator => GeolocatorOhos();

  Future<WeatherData> loadCurrentLocationWeather() async {
    final position = await _getCurrentPosition();
    final weatherPayloadFuture = _fetchWeatherPayload(position);
    final airQualityPayloadFuture = _fetchAirQualityPayload(position);
    final locationNameFuture = _fetchLocationName(position);

    final weatherPayload = await weatherPayloadFuture;

    AirQualityData? airQuality;
    try {
      airQuality = AirQualityData.fromApiResponse(
        await airQualityPayloadFuture,
      );
    } catch (_) {
      airQuality = null;
    }

    String locationName = _defaultLocationName;
    try {
      locationName = await locationNameFuture;
    } catch (_) {
      locationName = _defaultLocationName;
    }

    return WeatherData.fromApiResponse(
      weatherPayload,
      locationName: locationName,
      airQuality: airQuality,
    );
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const WeatherLoadException(
        '定位服务未开启，请先在系统设置中打开定位服务。',
        action: WeatherRecoveryAction.openLocationSettings,
      );
    }

    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const WeatherLoadException(
        '定位权限被拒绝，无法获取当前所在地的天气。',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const WeatherLoadException(
        '定位权限被永久拒绝，请先在应用设置中打开定位权限。',
        action: WeatherRecoveryAction.openAppSettings,
      );
    }

    try {
      return await _geolocator
          .getCurrentPosition(
            locationSettings: OhosSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: _requestTimeout,
            ),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const WeatherLoadException(
        '定位超时，请确认已开启定位功能后重试。',
      );
    }
  }

  Future<Map<String, dynamic>> _fetchWeatherPayload(Position position) {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'current':
            'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,wind_speed_10m,is_day,surface_pressure,visibility,cloud_cover',
        'hourly': 'temperature_2m,weather_code,is_day',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max,uv_index_max,sunrise,sunset',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
        'precipitation_unit': 'mm',
        'timezone': 'auto',
        'forecast_days': '7',
        'forecast_hours': '12',
      },
    );

    return _fetchJson(
      uri,
      serviceLabel: '天气服务',
      headers: const {
        HttpHeaders.acceptHeader: 'application/json',
      },
    );
  }

  Future<Map<String, dynamic>> _fetchAirQualityPayload(Position position) {
    final uri = Uri.https(
      'air-quality-api.open-meteo.com',
      '/v1/air-quality',
      {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'current':
            'european_aqi,pm2_5,pm10,ozone,nitrogen_dioxide,sulphur_dioxide,uv_index',
        'timezone': 'auto',
        'forecast_hours': '1',
      },
    );

    return _fetchJson(
      uri,
      serviceLabel: '空气质量服务',
      headers: const {
        HttpHeaders.acceptHeader: 'application/json',
      },
    );
  }

  Future<String> _fetchLocationName(Position position) async {
    String geocoderName = _defaultLocationName;
    try {
      geocoderName = await _fetchLocationNameFromGeocoder(position);
    } catch (_) {
      geocoderName = _defaultLocationName;
    }

    if (_looksLikeDistrictLevel(geocoderName)) {
      return geocoderName;
    }

    String networkName = _defaultLocationName;
    try {
      networkName = await _fetchLocationNameFromNetwork(position);
    } catch (_) {
      networkName = _defaultLocationName;
    }

    if (_looksLikeDistrictLevel(networkName)) {
      return networkName;
    }

    if (geocoderName != _defaultLocationName) {
      return geocoderName;
    }

    if (networkName != _defaultLocationName) {
      return networkName;
    }

    return _defaultLocationName;
  }

  Future<String> _fetchLocationNameFromGeocoder(Position position) async {
    _ensureGeocodingRegistered();

    try {
      await geocoding.setLocaleIdentifier('zh_CN');
    } catch (_) {
      // Keep the default locale when the platform does not support overrides.
    }

    try {
      final isGeocoderAvailable = await geocoding.isPresent();
      if (!isGeocoderAvailable) {
        return _defaultLocationName;
      }
    } catch (_) {
      // Some platforms do not implement this probe.
    }

    final placemarks = await geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    for (final placemark in placemarks) {
      final locationName = _composeLocationNameFromPlacemark(placemark);
      if (locationName != _defaultLocationName) {
        return locationName;
      }
    }

    return _defaultLocationName;
  }

  void _ensureGeocodingRegistered() {
    if (_isGeocodingRegistered || Platform.operatingSystem != 'ohos') {
      return;
    }

    GeocodingOhos.registerWith();
    _isGeocodingRegistered = true;
  }

  Future<String> _fetchLocationNameFromNetwork(Position position) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '14',
        'accept-language': 'zh-CN,zh',
      },
    );

    final payload = await _fetchJson(
      uri,
      serviceLabel: '位置服务',
      headers: const {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.userAgentHeader: 'flutter-tabs-weather-demo/1.0',
      },
    );

    final address = payload['address'];
    if (address is Map<String, dynamic>) {
      final nameFromAddress = _composeLocationName(address);
      if (nameFromAddress != _defaultLocationName) {
        return nameFromAddress;
      }
    }

    final displayName = payload['display_name'];
    if (displayName is String && displayName.trim().isNotEmpty) {
      final nameFromDisplayName = _composeLocationNameFromDisplayName(
        displayName,
      );
      if (nameFromDisplayName != null) {
        return nameFromDisplayName;
      }
    }

    return _defaultLocationName;
  }

  String _composeLocationNameFromPlacemark(geocoding.Placemark placemark) {
    final district = _firstNonEmpty([
      _extractDistrictLikeSegment(placemark.subLocality),
      _extractDistrictLikeSegment(placemark.subAdministrativeArea),
      _extractDistrictLikeSegment(placemark.locality),
      _extractDistrictLikeSegment(placemark.name),
      _extractDistrictLikeSegment(placemark.thoroughfare),
      placemark.subLocality,
      placemark.subAdministrativeArea,
    ]);

    if (district != null && _looksLikeDistrictLevel(district)) {
      return district;
    }

    final city = _firstNonEmpty([
      _extractCityLikeSegment(placemark.locality),
      _extractCityLikeSegment(placemark.subAdministrativeArea),
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ]);

    if (city != null) {
      return city;
    }

    return _defaultLocationName;
  }

  Future<Map<String, dynamic>> _fetchJson(
    Uri uri, {
    required String serviceLabel,
    Map<String, String> headers = const {},
  }) async {
    final client = HttpClient()..connectionTimeout = _requestTimeout;

    try {
      final request = await client.getUrl(uri).timeout(_requestTimeout);
      headers.forEach(request.headers.set);

      final response = await request.close().timeout(_requestTimeout);
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw WeatherLoadException(
          '$serviceLabel暂时不可用（${response.statusCode}）。',
        );
      }

      final payload = jsonDecode(body);
      if (payload is! Map<String, dynamic>) {
        throw WeatherLoadException(
          '$serviceLabel返回的数据无法解析。',
        );
      }

      return payload;
    } on SocketException {
      throw const WeatherLoadException(
        '网络不可用，请检查当前连接后重试。',
      );
    } on TimeoutException {
      throw WeatherLoadException(
        '$serviceLabel请求超时，请稍后重试。',
      );
    } on FormatException {
      throw WeatherLoadException(
        '$serviceLabel返回的数据无法解析。',
      );
    } finally {
      client.close(force: true);
    }
  }

  String _composeLocationName(Map<String, dynamic> address) {
    final district = _firstNonEmpty([
      address['city_district'],
      address['district'],
      address['county'],
      address['state_district'],
    ]);

    final city = _firstNonEmpty([
      address['city'],
      address['municipality'],
      address['town'],
      address['state'],
    ]);

    final localArea = _firstNonEmpty([
      address['suburb'],
      address['borough'],
      address['village'],
    ]);

    if (district != null) {
      final exactDistrict = _extractDistrictLikeSegment(district);
      if (exactDistrict != null) {
        return exactDistrict;
      }

      return district;
    }

    if (localArea != null) {
      final exactDistrict = _extractDistrictLikeSegment(localArea);
      if (exactDistrict != null) {
        return exactDistrict;
      }
    }

    if (city != null) {
      return city;
    }

    if (localArea != null) {
      return localArea;
    }

    return _defaultLocationName;
  }

  String? _composeLocationNameFromDisplayName(String displayName) {
    final segments = displayName
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return null;
    }

    for (final segment in segments) {
      final district = _extractDistrictLikeSegment(segment);
      if (district != null) {
        return district;
      }
    }

    for (final segment in segments) {
      final city = _extractCityLikeSegment(segment);
      if (city != null) {
        return city;
      }
    }

    return segments.first;
  }

  String? _firstNonEmpty(List<dynamic> candidates) {
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return null;
  }

  String? _extractDistrictLikeSegment(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final matches = RegExp(
      '[一-龥A-Za-z0-9]+?(?:自治县|'
      '特别行政区|'
      '特区|'
      '新区|'
      '矿区|'
      '林区|'
      '县|'
      '区|'
      '旗)',
    ).allMatches(normalized).toList();

    if (matches.isNotEmpty) {
      return matches.last.group(0);
    }

    if (_looksLikeDistrictLevel(normalized)) {
      return normalized;
    }

    return null;
  }

  String? _extractCityLikeSegment(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final matches = RegExp(
      '[一-龥A-Za-z0-9]+?(?:自治州|'
      '地区|'
      '盟|'
      '州|'
      '市)',
    ).allMatches(normalized).toList();

    if (matches.isNotEmpty) {
      return matches.last.group(0);
    }

    if (_looksLikeCityLevel(normalized)) {
      return normalized;
    }

    return null;
  }

  bool _looksLikeDistrictLevel(String value) {
    return value != _defaultLocationName &&
        (value.contains('区') ||
            value.contains('县') ||
            value.contains('旗'));
  }

  bool _looksLikeCityLevel(String value) {
    return value != _defaultLocationName &&
        (value.contains('市') ||
            value.contains('州') ||
            value.contains('地区'));
  }
}
