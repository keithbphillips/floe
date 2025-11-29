/// Abstract interface for AI analysis services
abstract class AiService {
  /// Test if the AI service is available
  Future<bool> isAvailable();

  /// Analyze a scene using the AI service
  Future<Map<String, dynamic>?> analyzeScene(String sceneText);

  /// Quick character extraction (fallback without AI)
  List<String> extractCharactersSimple(String text);

  /// Calculate dialogue percentage
  int calculateDialoguePercentage(String text);
}
