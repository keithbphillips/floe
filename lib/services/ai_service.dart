/// Abstract interface for AI analysis services
abstract class AiService {
  /// Test if the AI service is available
  Future<bool> isAvailable();

  /// Analyze a scene using the AI service
  /// [existingThreads] is a list of existing plot thread titles to help AI avoid duplicates
  Future<Map<String, dynamic>?> analyzeScene(String sceneText, {List<String>? existingThreads});

  /// Quick character extraction (fallback without AI)
  List<String> extractCharactersSimple(String text);

  /// Calculate dialogue percentage
  int calculateDialoguePercentage(String text);
}
