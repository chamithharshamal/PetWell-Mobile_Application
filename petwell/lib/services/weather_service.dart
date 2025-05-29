import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String apiKey = '8cd01a60a40870cb26397eca3ad56fa5';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  Map<String, dynamic>? _cachedWeatherData;
  DateTime? _lastFetched;

  Future<Map<String, dynamic>> getWeather(double latitude, double longitude) async {
    if (_cachedWeatherData != null &&
        _lastFetched != null &&
        DateTime.now().difference(_lastFetched!).inMinutes < 30) {
      print('Using cached weather data');
      return _cachedWeatherData!;
    }

    final url = Uri.parse('$baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric');
    print('Requesting weather data from: $url');
    final response = await http.get(url);
    print('API Response Status: ${response.statusCode}');
    print('API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      _cachedWeatherData = jsonDecode(response.body);
      _lastFetched = DateTime.now();
      return _cachedWeatherData!;
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode} - ${response.reasonPhrase}');
    }
  }

  Future<Position> getCurrentLocation() async {
    return Position(
      latitude: 6.9271, // Colombo, Sri Lanka
      longitude: 79.8612,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    /*
  // Tokyo, Japan
  return Position(
    latitude: 35.6762,
    longitude: 139.6503,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
  */
  /*
  // Sydney, Australia
  return Position(
    latitude: -33.8688,
    longitude: 151.2093,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
  */
  /*
  // London, United Kingdom
  return Position(
    latitude: 51.5074,
    longitude: -0.1278,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
  */
  /*
  // New York City, NY, USA
  return Position(
    latitude: 40.7128,
    longitude: -74.0060,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
  */
  }

  Map<String, dynamic> getWeatherSuggestion(Map<String, dynamic> weatherData) {
    final main = weatherData['weather'][0]['main'].toString().toLowerCase();
    final temp = weatherData['main']['temp'] as double;

    String message;
    String icon;

    if (main.contains('clear') && temp >= 15 && temp <= 25) {
      message = 'Great day for a walk with your pet!';
      icon = 'sun'; // Identifier for sunny weather
    } else if (main.contains('rain') || main.contains('drizzle')) {
      message = 'It’s rainy—maybe a cozy indoor play session?';
      icon = 'rain';
    } else if (temp > 25) {
      message = 'It’s warm—keep your pet hydrated!';
      icon = 'hot';
    } else if (temp < 10) {
      message = 'It’s chilly—bundle up for a short walk!';
      icon = 'cold';
    } else {
      message = 'Enjoy some quality time with your pet!';
      icon = 'cloud';
    }

    return {
      'message': message,
      'icon': icon,
    };
  }
}
