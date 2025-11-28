import 'package:flutter/material.dart';
import '../models/scene_analysis.dart';
import '../services/ollama_service.dart';

class SceneAnalyzerProvider extends ChangeNotifier {
  final OllamaService _ollamaService;
  SceneAnalysis? _currentAnalysis;
  bool _isAnalyzing = false;
  bool _ollamaAvailable = false;
  String? _error;

  SceneAnalyzerProvider({OllamaService? ollamaService})
      : _ollamaService = ollamaService ?? OllamaService() {
    _checkOllamaAvailability();
  }

  SceneAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isAnalyzing => _isAnalyzing;
  bool get ollamaAvailable => _ollamaAvailable;
  String? get error => _error;

  Future<void> _checkOllamaAvailability() async {
    _ollamaAvailable = await _ollamaService.isAvailable();
    notifyListeners();
  }

  /// Analyze the current scene
  Future<void> analyzeScene(String sceneText) async {
    if (sceneText.trim().isEmpty) return;

    _isAnalyzing = true;
    _error = null;
    notifyListeners();

    try {
      if (_ollamaAvailable) {
        // Use LLM for full analysis
        debugPrint('=== Analyzing scene (${sceneText.length} chars) ===');
        final analysisData = await _ollamaService.analyzeScene(sceneText);

        if (analysisData != null && !analysisData.containsKey('error')) {
          debugPrint('LLM analysis data: $analysisData');
          debugPrint('Echo words from LLM: ${analysisData['echo_words']}');
          _currentAnalysis = SceneAnalysis.fromJson(analysisData);
          debugPrint('After parsing, echo words: ${_currentAnalysis?.echoWords}');
          debugPrint('Word count: ${_currentAnalysis?.wordCount}');
        } else {
          // Fallback to simple analysis
          debugPrint('LLM analysis failed, using simple analysis');
          _currentAnalysis = _createSimpleAnalysis(sceneText);
          _error = 'LLM analysis failed, using simple analysis';
        }
      } else {
        // Ollama not available, use simple analysis
        debugPrint('Ollama not available, using simple analysis');
        _currentAnalysis = _createSimpleAnalysis(sceneText);
        _error = 'Ollama not available - using basic analysis';
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
      _error = 'Analysis error: $e';
      _currentAnalysis = _createSimpleAnalysis(sceneText);
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Create simple analysis without LLM
  SceneAnalysis _createSimpleAnalysis(String text) {
    final wordCount = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;

    final characters = _ollamaService.extractCharactersSimple(text);
    final dialoguePercentage = _ollamaService.calculateDialoguePercentage(text);

    debugPrint('Simple analysis created - word count: $wordCount (no echo words - LLM only)');

    return SceneAnalysis(
      characters: characters,
      wordCount: wordCount,
      echoWords: [], // Only use LLM-detected echo words, no fallback
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
  String extractCurrentScene(String fullText, int cursorPosition) {
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
          // Cursor is in this chapter - now find the scene within it
          final chapterNumber = chapterMatch.group(1);

          // Get chapter content (excluding chapter heading)
          final chapterHeadingEnd = fullText.indexOf('\n', chapterStart);
          final chapterContentStart = chapterHeadingEnd != -1 ? chapterHeadingEnd + 1 : chapterStart;
          final chapterContent = fullText.substring(chapterContentStart, chapterEnd);

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
}
