import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scene_analyzer_provider.dart';
import '../models/scene_analysis.dart';

class SceneInfoPanel extends StatelessWidget {
  final VoidCallback onClose;

  const SceneInfoPanel({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final analyzer = context.watch<SceneAnalyzerProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      analyzer.error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
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
          _buildSection(
            theme,
            isDark,
            '⚠️ Echo Words',
            analysis.echoWords.map((w) => '"$w"').join(', '),
            warning: true,
          ),

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
