import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../models/scene_analysis.dart';
import '../services/ai_service.dart';
import '../services/ollama_service.dart';
import '../services/openai_service.dart';

class SceneAnalyzerProvider extends ChangeNotifier {
  AiService? _aiService;
  SceneAnalysis? _currentAnalysis;
  bool _isAnalyzing = false;
  bool _aiAvailable = false;
  String? _error;
  String _currentProvider = 'ollama';

  // Storage for scene analyses
  final Map<String, SceneAnalysis> _sceneAnalyses = {};
  String? _currentDocumentPath;
  String? _currentSceneId;

  SceneAnalyzerProvider() {
    _aiService = OllamaService();
    _checkAiAvailability();
  }

  /// Update the AI service based on settings
  void updateAiService(String provider, {String? apiKey, String? openAiModel, String? ollamaModel}) {
    _currentProvider = provider;

    if (provider == 'openai') {
      _aiService = OpenAiService(
        apiKey: apiKey ?? '',
        model: openAiModel ?? 'gpt-4o-mini',
      );
    } else {
      _aiService = OllamaService(
        model: ollamaModel ?? 'llama3.2:3b',
      );
    }

    _checkAiAvailability();
  }

  SceneAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isAnalyzing => _isAnalyzing;
  bool get aiAvailable => _aiAvailable;
  bool get ollamaAvailable => _aiAvailable; // Keep for backwards compatibility
  String? get error => _error;
  String get currentProvider => _currentProvider;

  Future<void> _checkAiAvailability() async {
    if (_aiService != null) {
      _aiAvailable = await _aiService!.isAvailable();
      notifyListeners();
    }
  }

  /// Analyze the current scene
  /// [existingPlotThreads] is a list of existing plot thread titles to help AI avoid duplicates
  /// [fullText] and [cursorPosition] are used to generate scene ID for storage
  /// [isChapterLevel] indicates whether this is a chapter-level analysis (vs scene-level)
  Future<void> analyzeScene(
    String sceneText, {
    List<String>? existingPlotThreads,
    String? fullText,
    int? cursorPosition,
    bool isChapterLevel = false,
  }) async {
    if (sceneText.trim().isEmpty) return;

    _isAnalyzing = true;
    _error = null;
    notifyListeners();

    try {
      // Re-check AI availability before each analysis
      // This handles cases where Ollama wasn't running at startup
      if (_aiService != null) {
        final isNowAvailable = await _aiService!.isAvailable();
        if (isNowAvailable != _aiAvailable) {
          debugPrint('AI availability changed: $_aiAvailable -> $isNowAvailable');
          _aiAvailable = isNowAvailable;
        }
      }

      if (_aiAvailable && _aiService != null) {
        // Use AI for full analysis
        final analysisType = isChapterLevel ? 'chapter' : 'scene';
        debugPrint('=== Analyzing $analysisType with $_currentProvider (${sceneText.length} chars) ===');
        if (existingPlotThreads != null && existingPlotThreads.isNotEmpty) {
          debugPrint('Passing ${existingPlotThreads.length} existing plot threads to AI');
        }
        final analysisData = await _aiService!.analyzeScene(sceneText, existingThreads: existingPlotThreads);

        if (analysisData != null && !analysisData.containsKey('error')) {
          debugPrint('AI analysis data: $analysisData');
          debugPrint('Echo words from AI: ${analysisData['echo_words']}');
          debugPrint('Plot threads from AI (raw): ${analysisData['plot_threads']}');
          debugPrint('Plot threads count: ${(analysisData['plot_threads'] as List?)?.length ?? 0}');
          _currentAnalysis = SceneAnalysis.fromJson(analysisData);
          debugPrint('After parsing, echo words: ${_currentAnalysis?.echoWords}');
          debugPrint('After parsing, plot threads: ${_currentAnalysis?.plotThreads.length} threads');
          if (_currentAnalysis != null && _currentAnalysis!.plotThreads.isNotEmpty) {
            for (var thread in _currentAnalysis!.plotThreads) {
              debugPrint('  - "${thread.title}" (${thread.type}): ${thread.action}');
            }
          }
          debugPrint('Word count: ${_currentAnalysis?.wordCount}');
        } else {
          // Fallback to simple analysis
          debugPrint('AI analysis failed, using simple analysis');
          _currentAnalysis = _createSimpleAnalysis(sceneText);
          _error = 'AI analysis failed, using simple analysis';
        }
      } else {
        // AI not available, use simple analysis
        debugPrint('$_currentProvider not available, using simple analysis');
        _currentAnalysis = _createSimpleAnalysis(sceneText);
        _error = '$_currentProvider not available - using basic analysis';
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
      _error = 'Analysis error: $e';
      _currentAnalysis = _createSimpleAnalysis(sceneText);
    } finally {
      _isAnalyzing = false;

      // Save the analysis to cache if we have the necessary context
      if (_currentAnalysis != null && fullText != null && cursorPosition != null) {
        final sceneId = _generateSceneId(fullText, cursorPosition, isChapterLevel: isChapterLevel);
        _currentSceneId = sceneId;
        _sceneAnalyses[sceneId] = _currentAnalysis!;
        await _saveSceneAnalyses();
        debugPrint('Saved analysis for $sceneId (${isChapterLevel ? "chapter-level" : "scene-level"})');
      }

      notifyListeners();
    }
  }

  /// Create simple analysis without AI
  SceneAnalysis _createSimpleAnalysis(String text) {
    final wordCount = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;

    final characters = _aiService?.extractCharactersSimple(text) ?? [];
    final dialoguePercentage = _aiService?.calculateDialoguePercentage(text) ?? 0;

    debugPrint('Simple analysis created - word count: $wordCount (no echo words - AI only)');

    return SceneAnalysis(
      characters: characters,
      wordCount: wordCount,
      echoWords: [], // Only use AI-detected echo words, no fallback
      dialoguePercentage: dialoguePercentage,
      analyzedAt: DateTime.now(),
    );
  }

  /// Clear current analysis
  void clearAnalysis() {
    _currentAnalysis = null;
    _error = null;
    notifyListeners();
  }

  /// Extract current scene from document using the same logic as bubble chart
  /// Chapters always contain scenes - either a single scene if no scene breaks,
  /// or multiple scenes if scene breaks exist within the chapter
  /// If [extractFullChapter] is true, returns the entire chapter content instead of individual scene
  String extractCurrentScene(String fullText, int cursorPosition, {bool extractFullChapter = false}) {
    if (fullText.isEmpty) return '';

    final chapterPattern = RegExp(r'(?:^|\n)Chapter\s+(\d+)', caseSensitive: false);
    final chapterMatches = chapterPattern.allMatches(fullText).toList();
    final sceneBreakPattern = RegExp(r'\n\s*\n\s*\n');

    if (chapterMatches.isEmpty) {
      // No chapters - treat document as scenes divided by scene breaks
      final sceneBreaks = sceneBreakPattern.allMatches(fullText).toList();

      if (sceneBreaks.isEmpty) {
        // No structure - entire document is one scene
        debugPrint('No structure found, returning full text (${fullText.length} chars)');
        return fullText;
      }

      // Multiple scenes without chapters - find which scene contains cursor
      final boundaries = <int>[0];
      for (final match in sceneBreaks) {
        boundaries.add(match.end);
      }
      boundaries.add(fullText.length);

      for (int i = 0; i < boundaries.length - 1; i++) {
        final start = boundaries[i];
        final end = boundaries[i + 1];
        if (cursorPosition >= start && cursorPosition < end) {
          final sceneText = fullText.substring(start, end).trim();
          debugPrint('Extracted scene ${i + 1}: ${sceneText.length} chars');
          return sceneText;
        }
      }
    } else {
      // Has chapters - find which chapter contains cursor, then find scene within it
      for (int chapterIdx = 0; chapterIdx < chapterMatches.length; chapterIdx++) {
        final chapterMatch = chapterMatches[chapterIdx];
        final chapterStart = chapterMatch.start;
        final chapterEnd = chapterIdx < chapterMatches.length - 1
            ? chapterMatches[chapterIdx + 1].start
            : fullText.length;

        if (cursorPosition >= chapterStart && cursorPosition < chapterEnd) {
          // Cursor is in this chapter
          final chapterNumber = chapterMatch.group(1);

          // Get chapter content (excluding chapter heading)
          final chapterHeadingEnd = fullText.indexOf('\n', chapterStart);
          final chapterContentStart = chapterHeadingEnd != -1 ? chapterHeadingEnd + 1 : chapterStart;
          final chapterContent = fullText.substring(chapterContentStart, chapterEnd);

          // If requesting full chapter, return it now
          if (extractFullChapter) {
            debugPrint('Extracted full Ch $chapterNumber: ${chapterContent.length} chars');
            return chapterContent.trim();
          }

          // Find scene breaks within this chapter
          final scenesInChapter = sceneBreakPattern.allMatches(chapterContent).toList();

          if (scenesInChapter.isEmpty) {
            // Chapter has no scene breaks - entire chapter content is one scene
            debugPrint('Extracted Ch $chapterNumber (single scene): ${chapterContent.length} chars');
            return chapterContent.trim();
          } else {
            // Chapter has multiple scenes - find which scene contains cursor
            final sceneBoundaries = <int>[0];
            for (final match in scenesInChapter) {
              sceneBoundaries.add(match.end);
            }
            sceneBoundaries.add(chapterContent.length);

            // Convert cursor position to relative position within chapter content
            final relativeCursorPos = cursorPosition - chapterContentStart;

            for (int i = 0; i < sceneBoundaries.length - 1; i++) {
              final relativeStart = sceneBoundaries[i];
              final relativeEnd = sceneBoundaries[i + 1];

              if (relativeCursorPos >= relativeStart && relativeCursorPos < relativeEnd) {
                final sceneText = chapterContent.substring(relativeStart, relativeEnd).trim();
                debugPrint('Extracted Ch $chapterNumber.${i + 1}: ${sceneText.length} chars');
                return sceneText;
              }
            }
          }
        }
      }
    }

    // Fallback - return entire document
    debugPrint('Fallback: returning full text');
    return fullText;
  }

  int _getLineNumber(String text, int position) {
    return text.substring(0, position).split('\n').length - 1;
  }

  /// Generate a unique identifier for a scene based on its position in the document
  /// If [isChapterLevel] is true, returns a chapter-level ID (e.g., 'ch7') instead of scene-level (e.g., 'ch7_scene_2')
  String _generateSceneId(String fullText, int cursorPosition, {bool isChapterLevel = false}) {
    final chapterPattern = RegExp(r'(?:^|\n)Chapter\s+(\d+)', caseSensitive: false);
    final chapterMatches = chapterPattern.allMatches(fullText).toList();
    final sceneBreakPattern = RegExp(r'\n\s*\n\s*\n');

    if (chapterMatches.isEmpty) {
      // No chapters - count scene number
      final sceneBreaks = sceneBreakPattern.allMatches(fullText).toList();

      if (sceneBreaks.isEmpty) {
        return 'scene_1';
      }

      final boundaries = <int>[0];
      for (final match in sceneBreaks) {
        boundaries.add(match.end);
      }
      boundaries.add(fullText.length);

      for (int i = 0; i < boundaries.length - 1; i++) {
        if (cursorPosition >= boundaries[i] && cursorPosition < boundaries[i + 1]) {
          return 'scene_${i + 1}';
        }
      }
      return 'scene_1';
    } else {
      // Has chapters - find chapter and scene within chapter
      for (int chapterIdx = 0; chapterIdx < chapterMatches.length; chapterIdx++) {
        final chapterMatch = chapterMatches[chapterIdx];
        final chapterStart = chapterMatch.start;
        final chapterEnd = chapterIdx < chapterMatches.length - 1
            ? chapterMatches[chapterIdx + 1].start
            : fullText.length;

        if (cursorPosition >= chapterStart && cursorPosition < chapterEnd) {
          final chapterNumber = chapterMatch.group(1);

          // If requesting chapter-level ID, return it now
          if (isChapterLevel) {
            return 'ch$chapterNumber';
          }

          // Get chapter content (excluding chapter heading)
          final chapterHeadingEnd = fullText.indexOf('\n', chapterStart);
          final chapterContentStart = chapterHeadingEnd != -1 ? chapterHeadingEnd + 1 : chapterStart;
          final chapterContent = fullText.substring(chapterContentStart, chapterEnd);

          // Find scene breaks within this chapter
          final scenesInChapter = sceneBreakPattern.allMatches(chapterContent).toList();

          if (scenesInChapter.isEmpty) {
            return 'ch${chapterNumber}_scene_1';
          }

          final sceneBoundaries = <int>[0];
          for (final match in scenesInChapter) {
            sceneBoundaries.add(match.end);
          }
          sceneBoundaries.add(chapterContent.length);

          final relativeCursorPos = cursorPosition - chapterContentStart;

          for (int i = 0; i < sceneBoundaries.length - 1; i++) {
            if (relativeCursorPos >= sceneBoundaries[i] && relativeCursorPos < sceneBoundaries[i + 1]) {
              return 'ch${chapterNumber}_scene_${i + 1}';
            }
          }

          return 'ch${chapterNumber}_scene_1';
        }
      }
    }

    return 'scene_1';
  }

  /// Set the current document path and load saved analyses
  Future<void> setDocumentPath(String? filePath) async {
    if (_currentDocumentPath == filePath) return;

    _currentDocumentPath = filePath;
    _sceneAnalyses.clear();
    _currentAnalysis = null;
    _currentSceneId = null;

    if (filePath != null && filePath.isNotEmpty) {
      await _loadSceneAnalyses();
    }

    notifyListeners();
  }

  /// Get the storage file path for scene analyses
  String? _getStorageFilePath() {
    if (_currentDocumentPath == null || _currentDocumentPath!.isEmpty) {
      return null;
    }

    final docDir = path.dirname(_currentDocumentPath!);
    final docName = path.basenameWithoutExtension(_currentDocumentPath!);
    final storageDir = path.join(docDir, '.floe');

    return path.join(storageDir, '${docName}_scene_analyses.json');
  }

  /// Load scene analyses from disk
  Future<void> _loadSceneAnalyses() async {
    final storagePath = _getStorageFilePath();
    if (storagePath == null) return;

    try {
      final file = File(storagePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

        _sceneAnalyses.clear();
        jsonData.forEach((sceneId, analysisJson) {
          try {
            _sceneAnalyses[sceneId] = SceneAnalysis.fromJson(analysisJson as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Error loading analysis for scene $sceneId: $e');
          }
        });

        debugPrint('Loaded ${_sceneAnalyses.length} scene analyses from $storagePath');
      }
    } catch (e) {
      debugPrint('Error loading scene analyses: $e');
    }
  }

  /// Save scene analyses to disk
  Future<void> _saveSceneAnalyses() async {
    final storagePath = _getStorageFilePath();
    if (storagePath == null) return;

    try {
      final file = File(storagePath);
      final storageDir = file.parent;

      // Create .floe directory if it doesn't exist
      if (!await storageDir.exists()) {
        await storageDir.create(recursive: true);
      }

      // Convert all scene analyses to JSON
      final jsonData = <String, dynamic>{};
      _sceneAnalyses.forEach((sceneId, analysis) {
        jsonData[sceneId] = analysis.toJson();
      });

      // Write to file
      await file.writeAsString(jsonEncode(jsonData));
      debugPrint('Saved ${_sceneAnalyses.length} scene analyses to $storagePath');
    } catch (e) {
      debugPrint('Error saving scene analyses: $e');
    }
  }

  /// Load cached analysis for a specific scene
  void loadSceneAnalysis(String fullText, int cursorPosition) {
    final sceneId = _generateSceneId(fullText, cursorPosition);

    if (_currentSceneId == sceneId && _currentAnalysis != null) {
      // Already showing this scene's analysis
      return;
    }

    _currentSceneId = sceneId;

    if (_sceneAnalyses.containsKey(sceneId)) {
      _currentAnalysis = _sceneAnalyses[sceneId];
      _error = null;
      debugPrint('Loaded cached analysis for $sceneId');
      notifyListeners();
    } else {
      // No cached analysis for this scene
      _currentAnalysis = null;
      _error = null;
      debugPrint('No cached analysis found for $sceneId');
      notifyListeners();
    }
  }
}
