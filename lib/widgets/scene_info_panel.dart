import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scene_analyzer_provider.dart';
import '../providers/document_provider.dart';
import '../models/scene_analysis.dart';

class SceneInfoPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Function(int start, int end)? onNavigateToMatch;
  final int currentCursorPosition;

  const SceneInfoPanel({
    Key? key,
    required this.onClose,
    this.onNavigateToMatch,
    this.currentCursorPosition = 0,
  }) : super(key: key);

  @override
  State<SceneInfoPanel> createState() => _SceneInfoPanelState();
}

class _SceneInfoPanelState extends State<SceneInfoPanel> {
  // Track which occurrence index we're on for each word
  final Map<String, int> _echoWordIndices = {};

  // Cache the last analyzed scene text and its start position
  String? _lastAnalyzedSceneText;
  int? _lastAnalyzedSceneStart;

  @override
  Widget build(BuildContext context) {
    final analyzer = context.watch<SceneAnalyzerProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Cache the analyzed scene when analysis updates
    if (analyzer.currentAnalysis != null) {
      final document = context.read<DocumentProvider>();
      final sceneText = analyzer.extractCurrentScene(document.content, widget.currentCursorPosition);
      final sceneStart = document.content.indexOf(sceneText);

      if (sceneStart != -1) {
        _lastAnalyzedSceneText = sceneText;
        _lastAnalyzedSceneStart = sceneStart;
      }
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[100],
          ),
          child: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 20,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scene Analysis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildContent(context, analyzer, theme),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, SceneAnalyzerProvider analyzer, ThemeData theme) {
    if (analyzer.isAnalyzing) {
      return _buildLoadingState(theme);
    }

    if (analyzer.currentAnalysis == null) {
      return _buildEmptyState(theme);
    }

    return _buildAnalysisContent(context, analyzer, theme);
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Analyzing scene...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.article_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 12),
        Text(
          'Start writing',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Scene analysis will appear automatically as you write',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[800]?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Ctrl+Shift+A to force analysis',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAnalysisContent(BuildContext context, SceneAnalyzerProvider analyzer, ThemeData theme) {
    final analysis = analyzer.currentAnalysis!;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Error message if any
        if (analyzer.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          analyzer.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (analyzer.error!.contains('not available'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Make sure Ollama is running with llama3.2:3b installed, then use Ctrl+Shift+A to retry analysis.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Characters
        if (analysis.characters.isNotEmpty)
          _buildSection(
            theme,
            isDark,
            '👤 Characters',
            analysis.characters.join(', '),
          ),

        // Setting and Time
        if (analysis.setting != null || analysis.timeOfDay != null)
          _buildSection(
            theme,
            isDark,
            '📍 Setting',
            [
              analysis.setting,
              analysis.timeOfDay,
            ].where((e) => e != null).join(', '),
          ),

        // POV
        if (analysis.pov != null)
          _buildSection(
            theme,
            isDark,
            '🎭 POV',
            analysis.pov!,
          ),

        // Tone
        if (analysis.tone != null)
          _buildSection(
            theme,
            isDark,
            '💭 Tone',
            analysis.tone!,
          ),

        // Stakes
        if (analysis.stakes != null)
          _buildSection(
            theme,
            isDark,
            '⚡ Stakes',
            analysis.stakes!,
          ),

        // Senses
        if (analysis.senses.isNotEmpty)
          _buildSection(
            theme,
            isDark,
            '👁️ Senses',
            analysis.senses.join(', '),
          ),

        // Dialogue/Narrative Balance
        if (analysis.dialoguePercentage != null)
          _buildDialogueBalance(theme, isDark, analysis),

        // Echo Words
        if (analysis.echoWords.isNotEmpty)
          _buildEchoWordsSection(context, theme, isDark, analysis.echoWords),

        // Word Count and Length Category
        _buildSection(
          theme,
          isDark,
          '📊 Length',
          '${analysis.wordCount}w (${analysis.lengthCategory})',
        ),

        // Hunches (AI suggestions)
        if (analysis.hunches.isNotEmpty)
          _buildHunchesSection(theme, isDark, analysis.hunches),

        // Timestamp
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            'Analyzed ${_formatTimestamp(analysis.analyzedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme,
    bool isDark,
    String label,
    String value, {
    bool warning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: warning
                  ? Colors.orange.withOpacity(0.1)
                  : (isDark ? Colors.grey[850] : Colors.grey[100]),
              borderRadius: BorderRadius.circular(6),
              border: warning
                  ? Border.all(color: Colors.orange.withOpacity(0.3))
                  : null,
            ),
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: warning ? Colors.orange : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueBalance(ThemeData theme, bool isDark, SceneAnalysis analysis) {
    final percentage = analysis.dialoguePercentage!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💬 Dialogue/Narrative',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[700],
                          valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  analysis.dialogueBalance,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHunchesSection(ThemeData theme, bool isDark, List<String> hunches) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Hunches',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...hunches.map((hunch) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      hunch,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildEchoWordsSection(BuildContext context, ThemeData theme, bool isDark, List<String> echoWords) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠️ Echo Words',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: echoWords.map((word) => GestureDetector(
                onTap: widget.onNavigateToMatch != null
                    ? () => _findAndNavigateToEchoWord(context, word)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '"$word"',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.onNavigateToMatch != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.search,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                      ],
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _findAndNavigateToEchoWord(BuildContext context, String word) {
    if (widget.onNavigateToMatch == null) return;

    // Use the cached analyzed scene instead of re-extracting
    if (_lastAnalyzedSceneText == null || _lastAnalyzedSceneStart == null) {
      debugPrint('No analyzed scene cached');
      return;
    }

    final sceneText = _lastAnalyzedSceneText!;
    final sceneStart = _lastAnalyzedSceneStart!;

    // Search for ALL occurrences of the echo word within the current scene
    // Use word boundary matching to find whole words only
    final sceneLower = sceneText.toLowerCase();
    final searchWord = word.toLowerCase();

    final List<int> occurrences = [];
    int searchIndex = 0;

    while (searchIndex < sceneLower.length) {
      final index = sceneLower.indexOf(searchWord, searchIndex);
      if (index == -1) break;

      // Check for word boundaries (before and after the match)
      final isWordStart = index == 0 || !_isWordChar(sceneLower[index - 1]);
      final isWordEnd = (index + searchWord.length >= sceneLower.length) ||
                        !_isWordChar(sceneLower[index + searchWord.length]);

      if (isWordStart && isWordEnd) {
        occurrences.add(index);
      }

      searchIndex = index + 1;
    }

    if (occurrences.isEmpty) {
      debugPrint('Echo word "$word" not found in current scene');
      return;
    }

    // Get current index for this word, or start at 0
    final currentIndex = _echoWordIndices[word] ?? 0;

    // Cycle to next occurrence
    final nextIndex = (currentIndex + 1) % occurrences.length;

    // Update the index for next click
    setState(() {
      _echoWordIndices[word] = nextIndex;
    });

    // Get the relative position of this occurrence
    final relativeIndex = occurrences[nextIndex];

    // Convert relative position to absolute position in document
    final absoluteIndex = sceneStart + relativeIndex;

    // Navigate to the found word with highlighting
    widget.onNavigateToMatch!(absoluteIndex, absoluteIndex + word.length);
    debugPrint('Navigating to echo word "$word" occurrence ${nextIndex + 1}/${occurrences.length} at position $absoluteIndex');
  }

  bool _isWordChar(String char) {
    // Check if character is a letter, digit, or underscore
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||   // A-Z
           (code >= 97 && code <= 122) ||  // a-z
           (code >= 48 && code <= 57) ||   // 0-9
           code == 95;                      // underscore
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
