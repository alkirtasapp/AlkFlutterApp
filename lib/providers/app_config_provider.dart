import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alkirtas/utils/logging/logger.dart';

class AppConfigProvider extends ChangeNotifier {
  static const String _configUrl = 'https://www.alkirtas.com/banners/app_config.json';
  static const String _firstColorKey = 'app_first_color';
  static const String _secColorKey = 'app_sec_color';

  // Default colors (fallback)
  static const Color _defaultFirstColor = Color.fromARGB(255, 169, 26, 212);
  static const Color _defaultSecColor = Color.fromARGB(255, 165, 64, 185);

  Color _appFirstColor = _defaultFirstColor;
  Color _appSecColor = _defaultSecColor;
  bool _isLoaded = false;

  // Singleton instance for static access from AlkColors
  static AppConfigProvider? _instance;
  static AppConfigProvider get instance {
    _instance ??= AppConfigProvider();
    return _instance!;
  }

  Color get appFirstColor => _appFirstColor;
  Color get appSecColor => _appSecColor;
  bool get isLoaded => _isLoaded;

  AppConfigProvider() {
    _instance = this;
  }

  /// Load config from cache first, then fetch from server
  Future<void> loadConfig() async {
    // Load from cache first for instant display
    await _loadFromCache();

    // Then fetch from server to get latest
    await _fetchFromServer();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstColorHex = prefs.getString(_firstColorKey);
      final secColorHex = prefs.getString(_secColorKey);

      if (firstColorHex != null) {
        _appFirstColor = _parseColor(firstColorHex) ?? _defaultFirstColor;
      }
      if (secColorHex != null) {
        _appSecColor = _parseColor(secColorHex) ?? _defaultSecColor;
      }

      _isLoaded = true;
      notifyListeners();
      AlkLoggerHelper.info("AppConfig loaded from cache");
    } catch (e) {
      AlkLoggerHelper.warning("AppConfig cache load failed: $e");
    }
  }

  Future<void> _fetchFromServer() async {
    try {
      final response = await http.get(Uri.parse(_configUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final firstColorHex = data['AppFirstColor'] as String?;
        final secColorHex = data['AppSecColor'] as String?;

        bool changed = false;

        if (firstColorHex != null) {
          final newColor = _parseColor(firstColorHex);
          if (newColor != null && newColor != _appFirstColor) {
            _appFirstColor = newColor;
            changed = true;
          }
        }

        if (secColorHex != null) {
          final newColor = _parseColor(secColorHex);
          if (newColor != null && newColor != _appSecColor) {
            _appSecColor = newColor;
            changed = true;
          }
        }

        if (changed) {
          await _saveToCache();
          notifyListeners();
          AlkLoggerHelper.info("AppConfig updated from server");
        }
      }
    } catch (e) {
      AlkLoggerHelper.warning("AppConfig fetch failed: $e (using cached/default)");
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_firstColorKey, _colorToHex(_appFirstColor));
      await prefs.setString(_secColorKey, _colorToHex(_appSecColor));
    } catch (e) {
      AlkLoggerHelper.warning("AppConfig cache save failed: $e");
    }
  }

  /// Parse hex color string to Color
  /// Supports: #RRGGBB, #AARRGGBB, RRGGBB, AARRGGBB
  Color? _parseColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add full opacity
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      AlkLoggerHelper.warning("Invalid color format: $hex");
      return null;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
