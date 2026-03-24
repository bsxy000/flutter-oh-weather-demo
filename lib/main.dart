import 'package:flutter/material.dart';
import 'package:flutter_geolocator_ohos/flutter_geolocator_ohos.dart';

import 'weather_home_view.dart';
import 'weather_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 天气示例',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1677FF)),
        useMaterial3: true,
      ),
      home: const TabsPage(),
    );
  }
}

class TabsPage extends StatefulWidget {
  const TabsPage({super.key});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  static const Duration _weatherRefreshInterval = Duration(minutes: 10);

  final WeatherService _weatherService = const WeatherService();
  final List<String> _tabTitles = const [
    '天气',
    '搜索',
    '收藏',
    '我的',
  ];

  int _currentIndex = 0;
  WeatherData? _weatherData;
  WeatherLoadException? _weatherError;
  DateTime? _weatherFetchedAt;
  bool _isWeatherLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshWeather();
  }

  List<Widget> get _pages => [
        _buildHomeTab(),
        _buildTabContent(
          icon: Icons.search,
          title: '搜索',
          description: '在这里搜索内容',
          color: Colors.green,
        ),
        _buildTabContent(
          icon: Icons.favorite,
          title: '收藏',
          description: '查看您的收藏内容',
          color: Colors.red,
        ),
        _buildTabContent(
          icon: Icons.person,
          title: '我的',
          description: '个人中心',
          color: Colors.orange,
        ),
      ];

  Future<void> _refreshWeather() async {
    if (_isWeatherLoading) {
      return;
    }

    setState(() {
      _isWeatherLoading = true;
      if (_weatherData == null) {
        _weatherError = null;
      }
    });

    try {
      final weather = await _weatherService.loadCurrentLocationWeather();
      if (!mounted) {
        return;
      }

      setState(() {
        _weatherData = weather;
        _weatherError = null;
        _weatherFetchedAt = DateTime.now();
      });
    } on WeatherLoadException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _weatherError = error;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _weatherError = const WeatherLoadException(
          '暂时无法获取实时天气，请稍后重试。',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isWeatherLoading = false;
        });
      }
    }
  }

  bool _shouldAutoRefreshWeather() {
    if (_weatherFetchedAt == null) {
      return true;
    }

    return DateTime.now().difference(_weatherFetchedAt!) >=
        _weatherRefreshInterval;
  }

  Future<void> _handleWeatherRecoveryAction(
    WeatherRecoveryAction action,
  ) async {
    final geolocator = GeolocatorOhos();

    switch (action) {
      case WeatherRecoveryAction.openLocationSettings:
        await geolocator.openLocationSettings();
        break;
      case WeatherRecoveryAction.openAppSettings:
        await geolocator.openAppSettings();
        break;
      case WeatherRecoveryAction.retry:
        break;
    }

    await _refreshWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: Text(_tabTitles[_currentIndex]),
            ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0 && _shouldAutoRefreshWeather()) {
            _refreshWeather();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_rounded),
            label: '天气',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜索',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '收藏',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return WeatherHomeView(
      weatherData: _weatherData,
      weatherError: _weatherError,
      isWeatherLoading: _isWeatherLoading,
      onRefresh: _refreshWeather,
      onRecoveryAction: _handleWeatherRecoveryAction,
      weatherIconFor: _weatherIconFor,
      weatherDescriptionForCode: _weatherDescriptionForCode,
      weatherActionLabelFor: _weatherActionLabel,
      forecastDayLabelFor: _forecastDayLabel,
      onForecastTap: (forecast, dayLabel, description, weatherIcon) {
        final weather = _weatherData;
        if (weather == null) {
          return;
        }

        _openForecastDetail(
          context,
          weather,
          forecast,
          dayLabel,
          description,
          weatherIcon,
        );
      },
    );
  }

  void _openForecastDetail(
    BuildContext context,
    WeatherData weather,
    DailyForecast forecast,
    String dayLabel,
    String description,
    IconData weatherIcon,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WeatherForecastDetailPage(
          locationName: weather.locationName,
          dayLabel: dayLabel,
          forecast: forecast,
          weatherDescription: description,
          weatherIcon: weatherIcon,
        ),
      ),
    );
  }

  String _forecastDayLabel(DailyForecast forecast, int index) {
    if (index == 0) {
      return '今天';
    }

    if (index == 1) {
      return '明天';
    }

    switch (forecast.date.weekday) {
      case DateTime.monday:
        return '周一';
      case DateTime.tuesday:
        return '周二';
      case DateTime.wednesday:
        return '周三';
      case DateTime.thursday:
        return '周四';
      case DateTime.friday:
        return '周五';
      case DateTime.saturday:
        return '周六';
      case DateTime.sunday:
        return '周日';
      default:
        return '未来';
    }
  }

  IconData _weatherIconFor(int code, bool isDay) {
    if (code == 0) {
      return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    }

    if (code == 1 || code == 2) {
      return isDay ? Icons.cloud_queue_rounded : Icons.cloud;
    }

    if (code == 3) {
      return Icons.cloud_rounded;
    }

    if (code == 45 || code == 48) {
      return Icons.blur_on_rounded;
    }

    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return Icons.grain_rounded;
    }

    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return Icons.ac_unit_rounded;
    }

    if (code >= 95) {
      return Icons.thunderstorm_rounded;
    }

    return Icons.cloud_rounded;
  }

  String _weatherDescriptionForCode(int code) {
    switch (code) {
      case 0:
        return '晴';
      case 1:
        return '大部晴朗';
      case 2:
        return '局部多云';
      case 3:
        return '阴天';
      case 45:
      case 48:
        return '有雾';
      case 51:
      case 53:
      case 55:
        return '毛毛雨';
      case 56:
      case 57:
        return '冻雨';
      case 61:
      case 63:
      case 65:
        return '降雨';
      case 66:
      case 67:
        return '冻雨';
      case 71:
      case 73:
      case 75:
      case 77:
        return '降雪';
      case 80:
      case 81:
      case 82:
        return '阵雨';
      case 85:
      case 86:
        return '阵雪';
      case 95:
        return '雷暴';
      case 96:
      case 99:
        return '雷暴伴冰雹';
      default:
        return '天气更新中';
    }
  }

  String _weatherActionLabel(WeatherRecoveryAction action) {
    switch (action) {
      case WeatherRecoveryAction.openLocationSettings:
        return '去打开定位';
      case WeatherRecoveryAction.openAppSettings:
        return '去授权';
      case WeatherRecoveryAction.retry:
        return '重新获取';
    }
  }

  Widget _buildTabContent({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: color,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherForecastDetailPage extends StatelessWidget {
  const WeatherForecastDetailPage({
    super.key,
    required this.locationName,
    required this.dayLabel,
    required this.forecast,
    required this.weatherDescription,
    required this.weatherIcon,
  });

  final String locationName;
  final String dayLabel;
  final DailyForecast forecast;
  final String weatherDescription;
  final IconData weatherIcon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$dayLabel天气详情'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3FAFF), Color(0xFFEAF5FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D8FFF), Color(0xFF66B9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x291D8FFF),
                      blurRadius: 22,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$dayLabel  ${forecast.shortDateLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            weatherIcon,
                            color: Colors.white,
                            size: 46,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                weatherDescription,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                forecast.temperatureRangeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '降水 ${forecast.precipitationLabel}  '
                                '降水概率 ${forecast.precipitationProbabilityLabel}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _DetailMetricCard(
                    title: '最高温',
                    value: forecast.maxTemperatureLabel,
                    icon: Icons.thermostat_rounded,
                  ),
                  _DetailMetricCard(
                    title: '最低温',
                    value: forecast.minTemperatureLabel,
                    icon: Icons.ac_unit_rounded,
                  ),
                  _DetailMetricCard(
                    title: '降水概率',
                    value: forecast.precipitationProbabilityLabel,
                    icon: Icons.umbrella_rounded,
                  ),
                  _DetailMetricCard(
                    title: '降水总量',
                    value: forecast.precipitationLabel,
                    icon: Icons.grain_rounded,
                  ),
                  _DetailMetricCard(
                    title: '最大风速',
                    value: forecast.windSpeedMaxLabel,
                    icon: Icons.air_rounded,
                  ),
                  _DetailMetricCard(
                    title: '紫外线',
                    value: forecast.uvIndexLabel,
                    icon: Icons.wb_sunny_outlined,
                  ),
                  _DetailMetricCard(
                    title: '日出',
                    value: forecast.sunriseLabel,
                    icon: Icons.wb_twilight_outlined,
                  ),
                  _DetailMetricCard(
                    title: '日落',
                    value: forecast.sunsetLabel,
                    icon: Icons.nights_stay_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailMetricCard extends StatelessWidget {
  const _DetailMetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140A4B8C),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1677FF),
              size: 20,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6F839A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF16314B),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
