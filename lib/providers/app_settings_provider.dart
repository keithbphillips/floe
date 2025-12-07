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
  String get ollamaModel => _settings.ollamaModel;
  String get openAiApiKey => _settings.openAiApiKey;
  String get openAiModel => _settings.openAiModel;
  int get chapterBubbleColorLight => _settings.chapterBubbleColorLight;
  int get chapterBubbleColorDark => _settings.chapterBubbleColorDark;
  int get sceneBubbleColorLight => _settings.sceneBubbleColorLight;
  int get sceneBubbleColorDark => _settings.sceneBubbleColorDark;
  // Analysis field visibility getters
  bool get showCharacters => _settings.showCharacters;
  bool get showSetting => _settings.showSetting;
  bool get showTimeOfDay => _settings.showTimeOfDay;
  bool get showPov => _settings.showPov;
  bool get showTone => _settings.showTone;
  bool get showStakes => _settings.showStakes;
  bool get showStructure => _settings.showStructure;
  bool get showSenses => _settings.showSenses;
  bool get showDialoguePercentage => _settings.showDialoguePercentage;
  bool get showEchoWords => _settings.showEchoWords;
  bool get showWordCount => _settings.showWordCount;
  bool get showHunches => _settings.showHunches;

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

  void setOllamaModel(String model) {
    _settings = _settings.copyWith(ollamaModel: model);
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

  void setChapterBubbleColorLight(int color) {
    _settings = _settings.copyWith(chapterBubbleColorLight: color);
    _saveSettings();
    notifyListeners();
  }

  void setChapterBubbleColorDark(int color) {
    _settings = _settings.copyWith(chapterBubbleColorDark: color);
    _saveSettings();
    notifyListeners();
  }

  void setSceneBubbleColorLight(int color) {
    _settings = _settings.copyWith(sceneBubbleColorLight: color);
    _saveSettings();
    notifyListeners();
  }

  void setSceneBubbleColorDark(int color) {
    _settings = _settings.copyWith(sceneBubbleColorDark: color);
    _saveSettings();
    notifyListeners();
  }

  // Analysis field visibility toggles
  void toggleShowCharacters(bool value) {
    _settings = _settings.copyWith(showCharacters: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowSetting(bool value) {
    _settings = _settings.copyWith(showSetting: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowTimeOfDay(bool value) {
    _settings = _settings.copyWith(showTimeOfDay: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowPov(bool value) {
    _settings = _settings.copyWith(showPov: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowTone(bool value) {
    _settings = _settings.copyWith(showTone: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowStakes(bool value) {
    _settings = _settings.copyWith(showStakes: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowStructure(bool value) {
    _settings = _settings.copyWith(showStructure: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowSenses(bool value) {
    _settings = _settings.copyWith(showSenses: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowDialoguePercentage(bool value) {
    _settings = _settings.copyWith(showDialoguePercentage: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowEchoWords(bool value) {
    _settings = _settings.copyWith(showEchoWords: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowWordCount(bool value) {
    _settings = _settings.copyWith(showWordCount: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowHunches(bool value) {
    _settings = _settings.copyWith(showHunches: value);
    _saveSettings();
    notifyListeners();
  }
}
