import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class AppSettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  static const String _storageKey = 'app_settings';

  AppSettingsProvider() {
    _loadSettings();
  }

  bool get isDarkMode => _settings.isDarkMode;
  String get fontFamily => _settings.fontFamily;
  double get fontSize => _settings.fontSize;
  double get lineHeight => _settings.lineHeight;
  bool get focusMode => _settings.focusMode;
  double get focusIntensity => _settings.focusIntensity;
  int get autoSaveInterval => _settings.autoSaveInterval;
  String get aiProvider => _settings.aiProvider;
  String get openAiApiKey => _settings.openAiApiKey;
  String get openAiModel => _settings.openAiModel;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      _settings = AppSettings.fromJson(json.decode(jsonString));
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(_settings.toJson()));
  }

  void toggleDarkMode() {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    _saveSettings();
    notifyListeners();
  }

  void toggleFocusMode() {
    _settings = _settings.copyWith(focusMode: !_settings.focusMode);
    _saveSettings();
    notifyListeners();
  }

  void setFontFamily(String fontFamily) {
    _settings = _settings.copyWith(fontFamily: fontFamily);
    _saveSettings();
    notifyListeners();
  }

  void setFontSize(double fontSize) {
    _settings = _settings.copyWith(fontSize: fontSize);
    _saveSettings();
    notifyListeners();
  }

  void setLineHeight(double lineHeight) {
    _settings = _settings.copyWith(lineHeight: lineHeight);
    _saveSettings();
    notifyListeners();
  }

  void setFocusIntensity(double intensity) {
    _settings = _settings.copyWith(focusIntensity: intensity);
    _saveSettings();
    notifyListeners();
  }

  void setAutoSaveInterval(int seconds) {
    _settings = _settings.copyWith(autoSaveInterval: seconds);
    _saveSettings();
    notifyListeners();
  }

  void setAiProvider(String provider) {
    _settings = _settings.copyWith(aiProvider: provider);
    _saveSettings();
    notifyListeners();
  }

  void setOpenAiApiKey(String apiKey) {
    _settings = _settings.copyWith(openAiApiKey: apiKey);
    _saveSettings();
    notifyListeners();
  }

  void setOpenAiModel(String model) {
    _settings = _settings.copyWith(openAiModel: model);
    _saveSettings();
    notifyListeners();
  }
}
