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
    final echoWords = _ollamaService.findEchoWords(text);
    final dialoguePercentage = _ollamaService.calculateDialoguePercentage(text);

    debugPrint('Simple analysis created - word count: $wordCount, echo words: ${echoWords.keys.toList()}');

    return SceneAnalysis(
      characters: characters,
      wordCount: wordCount,
      echoWords: echoWords.keys.toList(),
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

  /// Extract current scene from document
  String extractCurrentScene(String fullText, int cursorPosition) {
    if (fullText.isEmpty) return '';

    // Find all scene break positions (two blank lines = three newlines)
    // This is the standard manuscript format for scene breaks
    final breakPattern = RegExp(r'\n\s*\n\s*\n');
    final matches = breakPattern.allMatches(fullText);

    if (matches.isEmpty) {
      // No scene breaks, return entire text
      debugPrint('No scene breaks found, returning full text (${fullText.length} chars)');
      return fullText;
    }

    // Build list of scene boundaries
    final breakPositions = <int>[0]; // Start of first scene
    for (final match in matches) {
      breakPositions.add(match.end); // Start of next scene after break
    }
    breakPositions.add(fullText.length); // End of last scene

    // Find which scene contains the cursor
    for (int i = 0; i < breakPositions.length - 1; i++) {
      final sceneStart = breakPositions[i];
      final sceneEnd = breakPositions[i + 1];

      if (cursorPosition >= sceneStart && cursorPosition <= sceneEnd) {
        final scene = fullText.substring(sceneStart, sceneEnd).trim();
        debugPrint('Extracted scene ${i + 1}/${breakPositions.length - 1}: ${scene.length} chars, cursor at $cursorPosition');
        debugPrint('Scene preview: ${scene.substring(0, scene.length > 200 ? 200 : scene.length)}...');
        return scene;
      }
    }

    // Fallback: return last scene
    final lastScene = fullText.substring(breakPositions[breakPositions.length - 2]).trim();
    debugPrint('Cursor beyond scenes, returning last scene: ${lastScene.length} chars');
    return lastScene;
  }

  int _getLineNumber(String text, int position) {
    return text.substring(0, position).split('\n').length - 1;
  }
}
