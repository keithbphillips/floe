import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/focus_helper.dart';

class DocumentProvider extends ChangeNotifier {
  static const String _lastFilePathKey = 'last_file_path';
  String _content = '';
  String? _filePath;
  bool _hasUnsavedChanges = false;
  Timer? _autoSaveTimer;
  int _cursorPosition = 0;
  bool _isSaving = false;

  // Focus mode data
  int _focusStart = 0;
  int _focusEnd = 0;

  String get content => _content;
  String? get filePath => _filePath;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  int get cursorPosition => _cursorPosition;
  int get focusStart => _focusStart;
  int get focusEnd => _focusEnd;
  int get wordCount => _content.trim().isEmpty ? 0 : _content.trim().split(RegExp(r'\s+')).length;

  void updateContent(String newContent, int cursorPos) {
    _content = newContent;
    _cursorPosition = cursorPos;
    _hasUnsavedChanges = true;

    // Update focus region based on cursor position
    final focusRange = FocusHelper.getCurrentSentenceRange(_content, cursorPos);
    _focusStart = focusRange.$1;
    _focusEnd = focusRange.$2;

    notifyListeners();
  }

  void startAutoSave(int intervalSeconds) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => autoSave(),
    );
  }

  void stopAutoSave() {
    _autoSaveTimer?.cancel();
  }

  Future<void> autoSave() async {
    if (!_hasUnsavedChanges || _isSaving) return;

    try {
      _isSaving = true;

      final directory = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${directory.path}/Floe');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      // If no file path, create a new file with timestamp
      if (_filePath == null) {
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
        _filePath = '${docsDir.path}/draft_$timestamp.md';
      }

      final file = File(_filePath!);
      await file.writeAsString(_content);
      _hasUnsavedChanges = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Auto-save failed: $e');
    } finally {
      _isSaving = false;
    }
  }

  Future<void> saveAs(String path) async {
    try {
      _isSaving = true;

      // Ensure path has .md extension
      String finalPath = path;
      if (!finalPath.toLowerCase().endsWith('.md')) {
        finalPath = '$finalPath.md';
      }

      final file = File(finalPath);
      await file.writeAsString(_content);

      _filePath = finalPath;
      _hasUnsavedChanges = false;

      // Save this as the last opened file
      await _saveLastFilePath(finalPath);

      notifyListeners();
    } catch (e) {
      debugPrint('Save failed: $e');
      rethrow;
    } finally {
      _isSaving = false;
    }
  }

  Future<void> loadFile(String path) async {
    try {
      final file = File(path);
      _content = await file.readAsString();
      _filePath = path;
      _hasUnsavedChanges = false;
      _cursorPosition = 0;

      // Save this as the last opened file
      await _saveLastFilePath(path);

      notifyListeners();
    } catch (e) {
      debugPrint('Load failed: $e');
      rethrow;
    }
  }

  /// Load the last opened file on startup
  Future<void> loadLastFile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPath = prefs.getString(_lastFilePathKey);

      if (lastPath != null && lastPath.isNotEmpty) {
        final file = File(lastPath);
        if (await file.exists()) {
          debugPrint('Loading last file: $lastPath');
          await loadFile(lastPath);
        } else {
          debugPrint('Last file no longer exists: $lastPath');
          await _clearLastFilePath();
        }
      }
    } catch (e) {
      debugPrint('Failed to load last file: $e');
    }
  }

  /// Save the last file path to preferences
  Future<void> _saveLastFilePath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastFilePathKey, path);
      debugPrint('Saved last file path: $path');
    } catch (e) {
      debugPrint('Failed to save last file path: $e');
    }
  }

  /// Clear the last file path from preferences
  Future<void> _clearLastFilePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastFilePathKey);
    } catch (e) {
      debugPrint('Failed to clear last file path: $e');
    }
  }

  void newDocument() {
    _content = '';
    _filePath = null;
    _hasUnsavedChanges = false;
    _cursorPosition = 0;
    _focusStart = 0;
    _focusEnd = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
