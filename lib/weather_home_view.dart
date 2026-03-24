import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'weather_service.dart';

typedef WeatherIconResolver = IconData Function(int code, bool isDay);
typedef WeatherDescriptionResolver = String Function(int code);
typedef WeatherActionLabelResolver = String Function(
  WeatherRecoveryAction action,
);
typedef ForecastDayLabelResolver = String Function(
  DailyForecast forecast,
  int index,
);
typedef ForecastTapHandler = void Function(
  DailyForecast forecast,
  String dayLabel,
  String description,
  IconData weatherIcon,
);

const Color _pageTopColor = Color(0xFF6B7788);
const Color _pageMiddleColor = Color(0xFF4B566A);
const Color _pageBottomColor = Color(0xFF28323F);
const Color _panelColor = Color(0xFF465164);
const Color _panelHighlightColor = Color(0xFF5B667A);
const Color _panelBorderColor = Color(0x26FFFFFF);
const Color _panelTextSecondary = Color(0xFFD5DFEA);
const Color _softWhite = Color(0xFFF7FBFF);

class WeatherHomeView extends StatelessWidget {
  const WeatherHomeView({
    super.key,
    required this.weatherData,
    required this.weatherError,
    required this.isWeatherLoading,
    required this.onRefresh,
    required this.onRecoveryAction,
    required this.weatherIconFor,
    required this.weatherDescriptionForCode,
    required this.weatherActionLabelFor,
    required this.forecastDayLabelFor,
    required this.onForecastTap,
  });

  final WeatherData? weatherData;
  final WeatherLoadException? weatherError;
  final bool isWeatherLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(WeatherRecoveryAction action) onRecoveryAction;
  final WeatherIconResolver weatherIconFor;
  final WeatherDescriptionResolver weatherDescriptionForCode;
  final WeatherActionLabelResolver weatherActionLabelFor;
  final ForecastDayLabelResolver forecastDayLabelFor;
  final ForecastTapHandler onForecastTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_pageTopColor, _pageMiddleColor, _pageBottomColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -80,
            right: -30,
            child: _BackgroundGlow(
              size: 220,
              color: Color(0x33FFFFFF),
            ),
          ),
          const Positioned(
            top: 260,
            left: -70,
            child: _BackgroundGlow(
              size: 180,
              color: Color(0x1F9FD2FF),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: const Color(0xFFD8F0FF),
              backgroundColor: const Color(0xFF334154),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                children: [
                  _buildWeatherHeroCard(),
                  if (weatherData != null) ...[
                    const SizedBox(height: 16),
                    _buildHourlyTrendSection(weatherData!),
                    const SizedBox(height: 16),
                    _buildWeeklyForecastSection(weatherData!),
                    const SizedBox(height: 16),
                    _buildAirQualitySection(weatherData!),
                    const SizedBox(height: 16),
                    _buildLifestyleSection(weatherData!),
                    const SizedBox(height: 16),
                    _buildSunMoonSection(weatherData!),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: _panelDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF606D80), Color(0xFF424E61)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weatherHeaderLocation(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _weatherHeaderCaption(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRefreshButton(),
            ],
          ),
          const SizedBox(height: 22),
          if (weatherData == null && weatherError == null)
            _buildLoadingState()
          else if (weatherData == null && weatherError != null)
            _buildErrorState(weatherError!)
          else if (weatherData != null)
            _buildSuccessState(weatherData!),
          if (weatherData != null && weatherError != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '天气更新失败，当前显示的是上次成功获取的数据。',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _weatherHeaderLocation() {
    if (weatherData != null) {
      return weatherData!.locationName;
    }

    if (weatherError != null) {
      return '当前位置天气';
    }

    return '正在定位...';
  }

  String _weatherHeaderCaption() {
    if (weatherData != null) {
      return '当前位置实时天气';
    }

    if (weatherError != null) {
      return '定位或天气获取失败';
    }

    return '正在获取当前位置天气';
  }

  Widget _buildRefreshButton() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: isWeatherLoading
          ? const Padding(
              padding: EdgeInsets.all(11),
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : IconButton(
              onPressed: onRefresh,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            '正在定位并获取当前所在地的实时天气信息...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(WeatherLoadException error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          error.message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.tonal(
          onPressed: () => onRecoveryAction(error.action),
          style: FilledButton.styleFrom(
            foregroundColor: const Color(0xFF203A5D),
            backgroundColor: Colors.white,
          ),
          child: Text(weatherActionLabelFor(error.action)),
        ),
      ],
    );
  }

  Widget _buildSuccessState(WeatherData weather) {
    final metrics = <_HeroMetricData>[
      _HeroMetricData(
        icon: Icons.thermostat_rounded,
        label: '体感温度',
        value: weather.apparentTemperatureLabel,
      ),
      _HeroMetricData(
        icon: Icons.water_drop_outlined,
        label: '相对湿度',
        value: weather.humidityLabel,
      ),
      _HeroMetricData(
        icon: Icons.air_rounded,
        label: '风速',
        value: weather.windSpeedLabel,
      ),
      _HeroMetricData(
        icon: Icons.speed_rounded,
        label: '气压',
        value: weather.surfacePressureLabel,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bigTemperatureSize = constraints.maxWidth < 360 ? 78.0 : 92.0;
        final metricWidth = (constraints.maxWidth - 10) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Icon(
                weatherIconFor(weather.weatherCode, weather.isDay),
                color: Colors.white,
                size: 46,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${weather.temperatureC.round()}°',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: bigTemperatureSize,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${weather.maxTemperatureLabel} / ${weather.minTemperatureLabel}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                weatherDescriptionForCode(weather.weatherCode),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: metrics
                  .map(
                    (metric) => SizedBox(
                      width: metricWidth,
                      child: _HeroMetricCard(data: metric),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            Text(
              '更新时间 ${weather.updatedTimeLabel}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHourlyTrendSection(WeatherData weather) {
    final forecasts = weather.hourlyForecasts.take(6).toList();
    final icons = forecasts
        .map((forecast) => weatherIconFor(forecast.weatherCode, forecast.isDay))
        .toList();

    return _WeatherPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.show_chart_rounded,
            title: '温度曲线',
            subtitle:
                '未来 6 小时温度变化趋势',
          ),
          const SizedBox(height: 18),
          _TemperatureLineChart(
            forecasts: forecasts,
            icons: icons,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyForecastSection(WeatherData weather) {
    return _WeatherPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.calendar_month_rounded,
            title: '未来 7 天天气',
            subtitle:
                '左右滑动查看未来几天的天气情况',
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: weather.dailyForecasts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final forecast = weather.dailyForecasts[index];
                final dayLabel = forecastDayLabelFor(forecast, index);
                final description =
                    weatherDescriptionForCode(forecast.weatherCode);
                final weatherIcon = weatherIconFor(forecast.weatherCode, true);

                return _ForecastTile(
                  forecast: forecast,
                  dayLabel: dayLabel,
                  description: description,
                  weatherIcon: weatherIcon,
                  onTap: () => onForecastTap(
                    forecast,
                    dayLabel,
                    description,
                    weatherIcon,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirQualitySection(WeatherData weather) {
    final airQuality = weather.airQuality;
    if (airQuality == null) {
      return const _WeatherPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.air_rounded,
              title: '空气质量',
              subtitle:
                  '暂时未获取到空气质量数据',
            ),
          ],
        ),
      );
    }

    final aqi = airQuality.europeanAqi;
    final aqiColor = _aqiColor(aqi);
    final aqiLevel = _aqiLevel(aqi);

    return _WeatherPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.air_rounded,
            title: '空气质量',
            subtitle:
                '当前位置实时空气质量与紫外线',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final metrics = _AirMetricsColumn(
                airQuality: airQuality,
                levelLabel: aqiLevel,
                levelColor: aqiColor,
                summary: _aqiSummary(aqi),
              );

              if (compact) {
                return Column(
                  children: [
                    _AqiGauge(
                      value: aqi,
                      levelLabel: aqiLevel,
                      color: aqiColor,
                    ),
                    const SizedBox(height: 16),
                    metrics,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AqiGauge(
                    value: aqi,
                    levelLabel: aqiLevel,
                    color: aqiColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: metrics),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleSection(WeatherData weather) {
    final uvIndex = _resolvedUvIndex(weather);
    final indices = <_LifeIndexData>[
      _LifeIndexData(
        title: '穿衣建议',
        value: _clothingLevel(weather.temperatureC),
        note: _clothingNote(weather.temperatureC),
        icon: Icons.checkroom_rounded,
      ),
      _LifeIndexData(
        title: '体感温度',
        value: weather.apparentTemperatureLabel,
        note: _comfortNote(weather.apparentTemperatureC),
        icon: Icons.thermostat_auto_rounded,
      ),
      _LifeIndexData(
        title: '紫外线',
        value: _uvLevel(uvIndex),
        note:
            '指数 ${uvIndex.toStringAsFixed(1)}，${_uvNote(uvIndex)}',
        icon: Icons.wb_sunny_outlined,
      ),
      _LifeIndexData(
        title: '能见度',
        value: _visibilityLevel(weather.visibilityKm),
        note: _visibilityNote(weather.visibilityKm),
        icon: Icons.visibility_rounded,
      ),
    ];

    return _WeatherPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.grid_view_rounded,
            title: '生活指数',
            subtitle:
                '根据当前天气整理的出行与体感建议',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final ratio = constraints.maxWidth < 360 ? 0.82 : 0.92;
              return GridView.builder(
                itemCount: indices.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: ratio,
                ),
                itemBuilder: (context, index) {
                  return _LifeIndexCard(data: indices[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSunMoonSection(WeatherData weather) {
    final today = weather.todayForecast;
    final moonPhase = _moonPhaseName(today.date);
    final illumination = _moonIllumination(today.date);

    return _WeatherPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.dark_mode_rounded,
            title: '日出月相',
            subtitle:
                '查看今日昼夜长度与当前月相',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final sunCard = _SunMoonCard(
                title: '日出日落',
                icon: Icons.wb_twilight_rounded,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailLine(
                      label: '日出',
                      value: today.sunriseLabel,
                    ),
                    const SizedBox(height: 8),
                    _DetailLine(
                      label: '日落',
                      value: today.sunsetLabel,
                    ),
                    const SizedBox(height: 8),
                    _DetailLine(
                      label: '白昼时长',
                      value: today.daylightDurationLabel,
                    ),
                  ],
                ),
              );
              final moonCard = _SunMoonCard(
                title: '月相',
                icon: Icons.brightness_2_rounded,
                content: Row(
                  children: [
                    _MoonBadge(illumination: illumination),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moonPhase,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '照明比例 ${(illumination * 100).round()}%',
                            style: const TextStyle(
                              color: _panelTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '月相按当前日期计算，用于展示当晚月面明暗变化。',
                            style: TextStyle(
                              color: _panelTextSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (compact) {
                return Column(
                  children: [
                    sunCard,
                    const SizedBox(height: 12),
                    moonCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: sunCard),
                  const SizedBox(width: 12),
                  Expanded(child: moonCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  double _resolvedUvIndex(WeatherData weather) {
    final airQuality = weather.airQuality;
    if (airQuality != null) {
      return airQuality.uvIndex;
    }

    return weather.todayForecast.uvIndexMax;
  }

  String _aqiLevel(double value) {
    if (value <= 20) {
      return '优';
    }
    if (value <= 40) {
      return '良';
    }
    if (value <= 60) {
      return '轻度污染';
    }
    if (value <= 80) {
      return '中度污染';
    }
    if (value <= 100) {
      return '重度污染';
    }
    return '严重污染';
  }

  Color _aqiColor(double value) {
    if (value <= 20) {
      return const Color(0xFF58D178);
    }
    if (value <= 40) {
      return const Color(0xFFE4C94B);
    }
    if (value <= 60) {
      return const Color(0xFFF79A3E);
    }
    if (value <= 80) {
      return const Color(0xFFE56B52);
    }
    if (value <= 100) {
      return const Color(0xFFC44863);
    }
    return const Color(0xFF8A54DE);
  }

  String _aqiSummary(double value) {
    if (value <= 20) {
      return '空气清新，适合外出活动。';
    }
    if (value <= 40) {
      return '空气质量尚可，敏感人群可留意变化。';
    }
    if (value <= 60) {
      return '建议减少长时间户外停留。';
    }
    if (value <= 80) {
      return '空气一般，外出时建议适度防护。';
    }
    if (value <= 100) {
      return '污染较重，尽量减少户外活动。';
    }
    return '空气污染明显，建议做好防护并减少外出。';
  }

  String _clothingLevel(double temperatureC) {
    if (temperatureC <= 5) {
      return '厚羽绒';
    }
    if (temperatureC <= 12) {
      return '大衣';
    }
    if (temperatureC <= 18) {
      return '外套';
    }
    if (temperatureC <= 25) {
      return '薄外套';
    }
    if (temperatureC <= 30) {
      return '短袖';
    }
    return '清凉短袖';
  }

  String _clothingNote(double temperatureC) {
    if (temperatureC <= 5) {
      return '气温偏低，注意防风保暖。';
    }
    if (temperatureC <= 12) {
      return '早晚偏凉，外出建议加一层外套。';
    }
    if (temperatureC <= 18) {
      return '温度舒适，常规外套即可。';
    }
    if (temperatureC <= 25) {
      return '白天舒适，出门可带薄外套。';
    }
    return '体感偏暖，注意补水和防晒。';
  }

  String _comfortNote(double apparentTemperatureC) {
    if (apparentTemperatureC <= 5) {
      return '体感明显偏冷，久坐时也容易发凉。';
    }
    if (apparentTemperatureC <= 14) {
      return '体感偏凉，晨晚外出注意保暖。';
    }
    if (apparentTemperatureC <= 24) {
      return '体感较舒适，适合日常出行。';
    }
    if (apparentTemperatureC <= 30) {
      return '体感稍热，避免长时间暴晒。';
    }
    return '体感闷热，尽量避开高温时段。';
  }

  String _uvLevel(double uvIndex) {
    if (uvIndex < 3) {
      return '较弱';
    }
    if (uvIndex < 5) {
      return '中等';
    }
    if (uvIndex < 7) {
      return '较强';
    }
    if (uvIndex < 10) {
      return '很强';
    }
    return '极强';
  }

  String _uvNote(double uvIndex) {
    if (uvIndex < 3) {
      return '日常防晒即可';
    }
    if (uvIndex < 5) {
      return '外出建议带遮阳用品';
    }
    if (uvIndex < 7) {
      return '建议涂抹防晒并减少暴晒';
    }
    if (uvIndex < 10) {
      return '中午前后尽量避免长时间户外活动';
    }
    return '紫外线很强，外出请做好全套防晒';
  }

  String _visibilityLevel(double? visibilityKm) {
    if (visibilityKm == null) {
      return '--';
    }
    if (visibilityKm >= 15) {
      return '清晰';
    }
    if (visibilityKm >= 8) {
      return '良好';
    }
    if (visibilityKm >= 3) {
      return '一般';
    }
    return '较差';
  }

  String _visibilityNote(double? visibilityKm) {
    if (visibilityKm == null) {
      return '暂时未获取到能见度数据。';
    }
    return '当前约 ${visibilityKm.toStringAsFixed(1)} 公里，出行请留意路况与视线变化。';
  }

  String _moonPhaseName(DateTime date) {
    final age = _moonAge(date);
    if (age < 1.84566) {
      return '新月';
    }
    if (age < 5.53699) {
      return '娥眉月';
    }
    if (age < 9.22831) {
      return '上弦月';
    }
    if (age < 12.91963) {
      return '盈凸月';
    }
    if (age < 16.61096) {
      return '满月';
    }
    if (age < 20.30228) {
      return '亏凸月';
    }
    if (age < 23.99361) {
      return '下弦月';
    }
    if (age < 27.68493) {
      return '残月';
    }
    return '新月';
  }

  double _moonIllumination(DateTime date) {
    final age = _moonAge(date);
    return (1 - math.cos((age / 29.53058867) * 2 * math.pi)) / 2;
  }

  double _moonAge(DateTime date) {
    const synodicMonth = 29.53058867;
    final baseNewMoon = DateTime.utc(2000, 1, 6, 18, 14);
    final daysSinceBase =
        date.toUtc().difference(baseNewMoon).inMinutes / (60 * 24);
    final remainder = daysSinceBase % synodicMonth;
    return remainder < 0 ? remainder + synodicMonth : remainder;
  }
}

BoxDecoration _panelDecoration({
  Gradient? gradient,
  Color color = _panelColor,
}) {
  return BoxDecoration(
    color: color,
    gradient: gradient,
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: _panelBorderColor),
    boxShadow: const [
      BoxShadow(
        color: Color(0x22000000),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  );
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.55,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

class _WeatherPanel extends StatelessWidget {
  const _WeatherPanel({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(
        gradient: const LinearGradient(
          colors: [_panelHighlightColor, _panelColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _softWhite,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _panelTextSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroMetricData {
  const _HeroMetricData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({
    required this.data,
  });

  final _HeroMetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              data.icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TemperatureLineChart extends StatelessWidget {
  const _TemperatureLineChart({
    required this.forecasts,
    required this.icons,
  });

  final List<HourlyForecast> forecasts;
  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 114,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final points = _chartPoints(
                forecasts: forecasts,
                size: constraints.biggest,
              );
              final maxLeft = math.max(0.0, constraints.maxWidth - 40);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TemperatureLinePainter(points: points),
                    ),
                  ),
                  for (var index = 0; index < forecasts.length; index++)
                    Positioned(
                      left: (points[index].dx - 20).clamp(0.0, maxLeft),
                      top: math.max(0.0, points[index].dy - 32),
                      child: Text(
                        forecasts[index].temperatureLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var index = 0; index < forecasts.length; index++)
              Expanded(
                child: _HourlyForecastItem(
                  forecast: forecasts[index],
                  icon: icons[index],
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Offset> _chartPoints({
    required List<HourlyForecast> forecasts,
    required Size size,
  }) {
    final temperatures = forecasts.map((forecast) => forecast.temperatureC);
    final minTemp = temperatures.reduce(math.min);
    final maxTemp = temperatures.reduce(math.max);
    final range = math.max(1.0, maxTemp - minTemp);

    const horizontalPadding = 12.0;
    const topPadding = 24.0;
    const bottomPadding = 18.0;
    final usableHeight =
        math.max(1.0, size.height - topPadding - bottomPadding);
    final step = forecasts.length == 1
        ? 0.0
        : (size.width - horizontalPadding * 2) / (forecasts.length - 1);

    return List<Offset>.generate(forecasts.length, (index) {
      final temperature = forecasts[index].temperatureC;
      final x = horizontalPadding + step * index;
      final y = topPadding + (maxTemp - temperature) / range * usableHeight;
      return Offset(x, y);
    });
  }
}

class _TemperatureLinePainter extends CustomPainter {
  const _TemperatureLinePainter({
    required this.points,
  });

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;

    for (var index = 1; index <= 3; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) {
      return;
    }

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()
      ..color = const Color(0xFFF6FDFF)
      ..style = PaintingStyle.fill;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final areaPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(areaPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 4.5, dotPaint);
      canvas.drawCircle(
        point,
        7.5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TemperatureLinePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _HourlyForecastItem extends StatelessWidget {
  const _HourlyForecastItem({
    required this.forecast,
    required this.icon,
  });

  final HourlyForecast forecast;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 6),
        Text(
          forecast.shortHourLabel,
          style: const TextStyle(
            color: _panelTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ForecastTile extends StatelessWidget {
  const _ForecastTile({
    required this.forecast,
    required this.dayLabel,
    required this.description,
    required this.weatherIcon,
    required this.onTap,
  });

  final DailyForecast forecast;
  final String dayLabel;
  final String description;
  final IconData weatherIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF617084), Color(0xFF4A576B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _panelBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    dayLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    forecast.shortDateLabel,
                    style: const TextStyle(
                      color: _panelTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      weatherIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _panelTextSecondary,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${forecast.maxTemperatureLabel} / ${forecast.minTemperatureLabel}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _InfoPill(
                    icon: Icons.grain_rounded,
                    text:
                        '降水 ${forecast.precipitationProbabilityLabel}',
                  ),
                  _InfoPill(
                    icon: Icons.air_rounded,
                    text: '风 ${forecast.windSpeedMaxKmh.round()} km/h',
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AqiGauge extends StatelessWidget {
  const _AqiGauge({
    required this.value,
    required this.levelLabel,
    required this.color,
  });

  final double value;
  final String levelLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(148),
            painter: _AqiGaugePainter(
              progress: (value / 120).clamp(0.0, 1.0),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                levelLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value.round().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'AQI',
                style: TextStyle(
                  color: _panelTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AqiGaugePainter extends CustomPainter {
  const _AqiGaugePainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final rect = Rect.fromLTWH(
      strokeWidth,
      strokeWidth,
      size.width - strokeWidth * 2,
      size.height - strokeWidth * 2,
    );
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          Color(0xFF5AD76F),
          Color(0xFFF5D353),
          Color(0xFFF69B42),
          Color(0xFFE65C5C),
          Color(0xFF8C5BE7),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AqiGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _AirMetricsColumn extends StatelessWidget {
  const _AirMetricsColumn({
    required this.airQuality,
    required this.levelLabel,
    required this.levelColor,
    required this.summary,
  });

  final AirQualityData airQuality;
  final String levelLabel;
  final Color levelColor;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '空气质量 $levelLabel',
          style: TextStyle(
            color: levelColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          summary,
          style: const TextStyle(
            color: _panelTextSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        _AirMetricRow(label: 'PM2.5', value: '${airQuality.pm25Label} ug/m3'),
        const SizedBox(height: 10),
        _AirMetricRow(label: 'PM10', value: '${airQuality.pm10Label} ug/m3'),
        const SizedBox(height: 10),
        _AirMetricRow(
            label: '臭氧 O3', value: '${airQuality.ozoneLabel} ug/m3'),
        const SizedBox(height: 10),
        _AirMetricRow(
          label: '二氧化氮 NO2',
          value: '${airQuality.nitrogenDioxideLabel} ug/m3',
        ),
        const SizedBox(height: 10),
        _AirMetricRow(
            label: '紫外线', value: airQuality.uvIndexLabel),
      ],
    );
  }
}

class _AirMetricRow extends StatelessWidget {
  const _AirMetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _panelTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeIndexData {
  const _LifeIndexData({
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
  });

  final String title;
  final String value;
  final String note;
  final IconData icon;
}

class _LifeIndexCard extends StatelessWidget {
  const _LifeIndexCard({
    required this.data,
  });

  final _LifeIndexData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              data.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            data.title,
            style: const TextStyle(
              color: _panelTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.note,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _panelTextSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SunMoonCard extends StatelessWidget {
  const _SunMoonCard({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _panelTextSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MoonBadge extends StatelessWidget {
  const _MoonBadge({
    required this.illumination,
  });

  final double illumination;

  @override
  Widget build(BuildContext context) {
    final innerGlow = Color.lerp(
      const Color(0xFF8590A5),
      const Color(0xFFF6F7FB),
      illumination,
    )!;

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            innerGlow,
            const Color(0xFF5E667A),
            const Color(0xFF2F3947),
          ],
          stops: const [0.2, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 30 + illumination * 18,
          height: 30 + illumination * 18,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
