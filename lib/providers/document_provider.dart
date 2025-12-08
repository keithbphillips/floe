import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import '../services/focus_helper.dart';

class DocumentProvider extends ChangeNotifier {
  static const String _lastFilePathKey = 'last_file_path';
  static const String _lastFileBookmarkKey = 'last_file_bookmark';
  final SecureBookmarks _secureBookmarks = SecureBookmarks();
  String _content = '';
  String? _filePath;
  bool _hasUnsavedChanges = false;
  bool _hasExplicitFilePath = false; // Track if user has explicitly saved with a filename
  Timer? _autoSaveTimer;
  int _cursorPosition = 0;
  bool _isSaving = false;

  // Focus mode data
  int _focusStart = 0;
  int _focusEnd = 0;

  // Throttle focus updates
  Timer? _focusUpdateTimer;
  int _pendingCursorPos = 0;

  String get content => _content;
  String? get filePath => _filePath;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get hasExplicitFilePath => _hasExplicitFilePath;
  int get cursorPosition => _cursorPosition;
  int get focusStart => _focusStart;
  int get focusEnd => _focusEnd;
  int get wordCount => _content.trim().isEmpty ? 0 : _content.trim().split(RegExp(r'\s+')).length;

  String get documentTitle {
    if (_filePath == null) {
      return 'Untitled';
    }
    final fileName = _filePath!.split(Platform.pathSeparator).last;
    // Remove file extension
    if (fileName.contains('.')) {
      return fileName.substring(0, fileName.lastIndexOf('.'));
    }
    return fileName;
  }

  void updateContent(String newContent, int cursorPos) {
    _content = newContent;
    _cursorPosition = cursorPos;
    _hasUnsavedChanges = true;

    // Throttle focus updates to improve performance in large documents
    // Cancel any pending focus update
    _focusUpdateTimer?.cancel();
    _pendingCursorPos = cursorPos;

    // Schedule a throttled focus update (200ms delay)
    // This will also handle notifyListeners() to prevent rebuilds on every keystroke
    _focusUpdateTimer = Timer(const Duration(milliseconds: 200), () {
      // Update focus region based on cursor position
      final focusRange = FocusHelper.getCurrentSentenceRange(_content, _pendingCursorPos);
      _focusStart = focusRange.$1;
      _focusEnd = focusRange.$2;
      notifyListeners();
    });

    // DO NOT call notifyListeners() here - it causes rebuilds on every keystroke
    // which severely impacts performance in large documents (20k+ words)
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
      _hasExplicitFilePath = true; // User explicitly saved the file

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
      final bytes = await file.readAsBytes();

      // Decode as UTF-8 with lenient mode to handle any encoding quirks
      final content = utf8.decode(bytes, allowMalformed: true);
      debugPrint('Successfully decoded file using UTF-8');

      _content = content;
      _filePath = path;
      _hasUnsavedChanges = false;
      _hasExplicitFilePath = true; // Loaded file has an explicit path
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
        // On macOS, resolve the security bookmark first to restore access
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          final bookmark = prefs.getString(_lastFileBookmarkKey);
          if (bookmark != null) {
            try {
              // Resolve the bookmark to get the file entity
              final resolvedEntity = await _secureBookmarks.resolveBookmark(bookmark);
              if (resolvedEntity != null) {
                debugPrint('Resolved security bookmark to: ${resolvedEntity.path}');

                // Start accessing the security-scoped resource
                await _secureBookmarks.startAccessingSecurityScopedResource(resolvedEntity);

                try {
                  // Use the resolved path from the bookmark
                  final resolvedFile = File(resolvedEntity.path);
                  await _loadFileWithAccess(resolvedEntity.path, resolvedFile);
                  return;
                } finally {
                  // Always stop accessing when done, even if an error occurs
                  await _secureBookmarks.stopAccessingSecurityScopedResource(resolvedEntity);
                }
              } else {
                debugPrint('Failed to resolve security bookmark, bookmark may be stale');
              }
            } catch (e) {
              debugPrint('Error resolving security bookmark: $e');
            }
          }
        }

        // Fallback for non-macOS or if bookmark resolution fails
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

  /// Load file content with security-scoped access already granted
  Future<void> _loadFileWithAccess(String path, File resolvedFile) async {
    try {
      final bytes = await resolvedFile.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      debugPrint('Successfully decoded file using UTF-8');

      _content = content;
      _filePath = path;
      _hasUnsavedChanges = false;
      _hasExplicitFilePath = true; // Loaded file has an explicit path
      _cursorPosition = 0;

      notifyListeners();
    } catch (e) {
      debugPrint('Load failed: $e');
      rethrow;
    }
  }

  /// Save the last file path to preferences
  Future<void> _saveLastFilePath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastFilePathKey, path);

      // On macOS, also create and store a security bookmark
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        try {
          final bookmark = await _secureBookmarks.bookmark(File(path));
          if (bookmark != null) {
            await prefs.setString(_lastFileBookmarkKey, bookmark);
            debugPrint('Saved security bookmark for: $path');
          }
        } catch (e) {
          debugPrint('Failed to create security bookmark: $e');
        }
      }

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

      // Also remove the bookmark on macOS
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        await prefs.remove(_lastFileBookmarkKey);
      }
    } catch (e) {
      debugPrint('Failed to clear last file path: $e');
    }
  }

  void newDocument() {
    _content = '';
    _filePath = null;
    _hasUnsavedChanges = false;
    _hasExplicitFilePath = false; // New document has no explicit path yet
    _cursorPosition = 0;
    _focusStart = 0;
    _focusEnd = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _focusUpdateTimer?.cancel();
    super.dispose();
  }
}
