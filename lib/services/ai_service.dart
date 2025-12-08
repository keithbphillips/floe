/// Abstract interface for AI analysis services
abstract class AiService {
  /// Test if the AI service is available
  Future<bool> isAvailable();

  /// Analyze a scene using the AI service
  /// [existingThreads] is a list of existing plot thread titles to help AI avoid duplicates
  Future<Map<String, dynamic>?> analyzeScene(String sceneText, {List<String>? existingThreads});

  /// Analyze a single chapter to generate a summary
  /// Returns a summary with key events, characters, and plot developments
  Future<Map<String, dynamic>?> analyzeChapterForSummary(String chapterText, int chapterNumber);

  /// Analyze chapter summaries to extract plot threads
  /// Takes a list of chapter summaries and identifies threads across them
  Future<List<Map<String, dynamic>>?> analyzeChapterSummariesForThreads(List<Map<String, dynamic>> chapterSummaries);

  /// Generate a detailed narrative summary for a specific plot thread
  /// Uses chapter summaries to create a cohesive description of how the thread develops
  Future<String?> generateThreadSummary(
    String threadTitle,
    List<int> chapterNumbers,
    List<Map<String, dynamic>> chapterSummaries,
  );

  /// Analyze entire document for plot threads (legacy method - consider using summary-based approach)
  /// Returns a list of plot threads found across the full document
  Future<List<Map<String, dynamic>>?> analyzeDocumentForPlotThreads(String fullText);

  /// Consolidate and clean up plot threads
  /// Reviews all threads and identifies ones to keep, merge, or remove
  Future<Map<String, dynamic>?> consolidateThreads(List<Map<String, dynamic>> threads);

  /// Quick character extraction (fallback without AI)
  List<String> extractCharactersSimple(String text);

  /// Calculate dialogue percentage
  int calculateDialoguePercentage(String text);
}
