import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherSvc {
  static final WeatherSvc _i = WeatherSvc._();
  factory WeatherSvc() => _i;
  WeatherSvc._();

  Future<Map<String, dynamic>> getCurrentWeather() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const WeatherException('location_disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const WeatherException('location_permission_denied');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final forecastUri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${position.latitude}'
      '&longitude=${position.longitude}'
      '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
      '&timezone=auto',
    );

    final forecastRes = await http
        .get(forecastUri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));

    if (forecastRes.statusCode < 200 || forecastRes.statusCode >= 300) {
      throw const WeatherException('weather_fetch_failed');
    }

    final forecastBody = jsonDecode(forecastRes.body) as Map<String, dynamic>;
    final current = forecastBody['current'] as Map<String, dynamic>? ?? const {};
    final code = (current['weather_code'] as num?)?.toInt() ?? -1;

    final place = await _resolvePlaceName(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return {
      'temperature': (current['temperature_2m'] as num?)?.toDouble(),
      'humidity': (current['relative_humidity_2m'] as num?)?.toInt(),
      'windSpeed': (current['wind_speed_10m'] as num?)?.toDouble(),
      'weatherCode': code,
      'condition': _conditionFromCode(code),
      'isDay': ((current['is_day'] as num?)?.toInt() ?? 1) == 1,
      'location': place,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'fetchedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<String> _resolvePlaceName({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final geoUri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/reverse'
        '?latitude=$latitude&longitude=$longitude&language=en&format=json',
      );
      final geoRes = await http
          .get(geoUri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));
      if (geoRes.statusCode < 200 || geoRes.statusCode >= 300) {
        return 'Current location';
      }
      final geoBody = jsonDecode(geoRes.body) as Map<String, dynamic>;
      final results = geoBody['results'];
      if (results is! List || results.isEmpty) return 'Current location';
      final first = Map<String, dynamic>.from(results.first as Map);
      final name = first['name']?.toString().trim();
      final admin = first['admin1']?.toString().trim();
      if (name != null && name.isNotEmpty && admin != null && admin.isNotEmpty) {
        return '$name, $admin';
      }
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return 'Current location';
  }

  String _conditionFromCode(int code) {
    switch (code) {
      case 0:
        return 'Clear';
      case 1:
      case 2:
      case 3:
        return 'Cloudy';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 'Rain';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'Snow';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Weather';
    }
  }
}

class WeatherException implements Exception {
  final String code;
  const WeatherException(this.code);

  @override
  String toString() => code;
}
