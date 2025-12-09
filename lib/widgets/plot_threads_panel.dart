import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plot_thread_provider.dart';
import '../providers/scene_analyzer_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/document_provider.dart';
import '../models/plot_thread.dart';
import '../services/openai_service.dart';
import '../services/ollama_service.dart';

class PlotThreadsPanel extends StatefulWidget {
  const PlotThreadsPanel({Key? key}) : super(key: key);

  @override
  State<PlotThreadsPanel> createState() => _PlotThreadsPanelState();
}

class _PlotThreadsPanelState extends State<PlotThreadsPanel> {
  // Track expanded state for each group
  final Map<String, bool> _expandedGroups = {
    'active': true,
    'abandoned': true,
    'resolved': false,
  };

  // Track expanded state for thread types within each status group
  final Map<String, Map<PlotThreadType, bool>> _expandedTypes = {
    'active': {},
    'abandoned': {},
    'resolved': {},
  };

  @override
  Widget build(BuildContext context) {
    final threadProvider = context.watch<PlotThreadProvider>();
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
                Icons.account_tree_outlined,
                size: 20,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plot Threads',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${threadProvider.activeThreads.length} active',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              // Analyze document button (main action)
              IconButton(
                icon: const Icon(Icons.auto_stories, size: 18),
                tooltip: 'Analyze entire document for plot threads',
                onPressed: () => _showAnalyzeDocumentDialog(context, threadProvider),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                color: theme.primaryColor,
              ),
              const SizedBox(width: 4),
              // Consolidate threads button (AI cleanup)
              if (threadProvider.threads.length > 3)
                IconButton(
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  tooltip: 'AI Consolidation: Remove duplicates and non-threads',
                  onPressed: () => _showConsolidationDialog(context, threadProvider),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  color: Colors.blue[400],
                ),
              const SizedBox(width: 4),
              // Clear all button
              if (threadProvider.threads.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 18),
                  tooltip: 'Clear all plot threads',
                  onPressed: () => _showClearConfirmation(context, threadProvider),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  color: Colors.grey[600],
                ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _buildContent(context, threadProvider, theme, isDark),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    PlotThreadProvider provider,
    ThemeData theme,
    bool isDark,
  ) {
    if (provider.threads.isEmpty) {
      return _buildEmptyState(theme);
    }

    final resolvedThreads = provider.threads
        .where((t) => t.status == PlotThreadStatus.resolved)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Active Threads Group
        if (provider.activeThreads.isNotEmpty)
          _buildStatusGroup(
            context,
            'Active Threads',
            'active',
            provider.activeThreads,
            theme,
            isDark,
            Colors.blue,
          ),

        // Abandoned Threads Group
        if (provider.potentiallyAbandonedThreads.isNotEmpty)
          _buildStatusGroup(
            context,
            'Potentially Abandoned',
            'abandoned',
            provider.potentiallyAbandonedThreads,
            theme,
            isDark,
            Colors.orange,
          ),

        // Resolved Threads Group
        if (resolvedThreads.isNotEmpty)
          _buildStatusGroup(
            context,
            'Resolved',
            'resolved',
            resolvedThreads,
            theme,
            isDark,
            Colors.grey,
          ),
      ],
    );
  }

  Widget _buildStatusGroup(
    BuildContext context,
    String title,
    String groupKey,
    List<PlotThread> threads,
    ThemeData theme,
    bool isDark,
    Color accentColor,
  ) {
    final isExpanded = _expandedGroups[groupKey] ?? true;

    // Group threads by type
    final threadsByType = <PlotThreadType, List<PlotThread>>{};
    for (final thread in threads) {
      threadsByType.putIfAbsent(thread.type, () => []).add(thread);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status group header
        InkWell(
          onTap: () {
            setState(() {
              _expandedGroups[groupKey] = !isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? Colors.grey[850] : Colors.grey[50],
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${threads.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded content: Thread types
        if (isExpanded)
          ...threadsByType.entries.map((entry) {
            final type = entry.key;
            final typeThreads = entry.value;
            return _buildTypeGroup(
              context,
              groupKey,
              type,
              typeThreads,
              theme,
              isDark,
            );
          }),
      ],
    );
  }

  Widget _buildTypeGroup(
    BuildContext context,
    String statusGroupKey,
    PlotThreadType type,
    List<PlotThread> threads,
    ThemeData theme,
    bool isDark,
  ) {
    final typeExpanded = _expandedTypes[statusGroupKey]?[type] ?? true;
    final typeInfo = _getTypeInfo(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type group header
        InkWell(
          onTap: () {
            setState(() {
              _expandedTypes[statusGroupKey] ??= {};
              _expandedTypes[statusGroupKey]![type] = !typeExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            color: isDark ? Colors.grey[900]!.withOpacity(0.5) : Colors.white.withOpacity(0.5),
            child: Row(
              children: [
                Icon(
                  typeExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: typeInfo['color'] as Color,
                ),
                const SizedBox(width: 8),
                Icon(
                  typeInfo['icon'] as IconData,
                  size: 14,
                  color: typeInfo['color'] as Color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    typeInfo['label'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (typeInfo['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${threads.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: typeInfo['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded content: Individual threads
        if (typeExpanded)
          ...threads.map((thread) {
            return _buildThreadItem(
              context,
              thread,
              theme,
              isDark,
              statusGroupKey == 'abandoned',
              statusGroupKey == 'resolved',
            );
          }),
      ],
    );
  }

  Widget _buildThreadItem(
    BuildContext context,
    PlotThread thread,
    ThemeData theme,
    bool isDark,
    bool isAbandoned,
    bool isResolved,
  ) {
    final provider = context.read<PlotThreadProvider>();

    // Parse location info from description
    String displayDescription = thread.description;
    String? startsAt;
    String? endsAt;

    if (thread.description.contains('___LOCATION___')) {
      final parts = thread.description.split('___LOCATION___');
      displayDescription = parts[0];
      if (parts.length > 1) {
        final locationParts = parts[1].split('|||');
        if (locationParts.isNotEmpty && locationParts[0].isNotEmpty) {
          startsAt = locationParts[0];
        }
        if (locationParts.length > 1 && locationParts[1].isNotEmpty) {
          endsAt = locationParts[1];
        }
      }
    }

    return InkWell(
      onTap: () => _showThreadDetailsDialog(context, thread, provider),
      child: Container(
        margin: const EdgeInsets.only(left: 48, right: 16, bottom: 1),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAbandoned
              ? Colors.orange.withOpacity(0.08)
              : isResolved
                  ? (isDark ? Colors.grey[850] : Colors.grey[50])
                  : (isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.white),
          border: Border(
            left: BorderSide(
              color: _getTypeInfo(thread.type)['color'] as Color,
              width: 3,
            ),
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            thread.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              decoration: isResolved ? TextDecoration.lineThrough : null,
              color: isResolved ? Colors.grey[600] : null,
            ),
          ),

          // Description
          if (displayDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              displayDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.3,
              ),
            ),
          ],

          // Metadata
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (startsAt != null)
                _buildMetadataChip(
                  Icons.play_arrow,
                  'Starts: $startsAt',
                  theme,
                  color: Colors.green[700],
                ),
              if (endsAt != null)
                _buildMetadataChip(
                  endsAt.toLowerCase() == 'ongoing' ? Icons.trending_flat : Icons.check_circle_outline,
                  endsAt.toLowerCase() == 'ongoing' ? 'Ongoing' : 'Ends: $endsAt',
                  theme,
                  color: endsAt.toLowerCase() == 'ongoing' ? Colors.blue[700] : Colors.grey[700],
                ),
              if (startsAt == null && endsAt == null)
                _buildMetadataChip(
                  Icons.bookmark_outline,
                  'Document',
                  theme,
                ),
              if (isAbandoned)
                _buildMetadataChip(
                  Icons.warning_amber,
                  '${thread.scenesSinceLastMention(provider.currentSceneNumber)} scenes ago',
                  theme,
                  color: Colors.orange,
                ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildMetadataChip(
    IconData icon,
    String text,
    ThemeData theme, {
    Color? color,
  }) {
    final chipColor = color ?? Colors.grey[600]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: chipColor),
        const SizedBox(width: 3),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: chipColor,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getTypeInfo(PlotThreadType type) {
    switch (type) {
      case PlotThreadType.mainPlot:
        return {
          'color': Colors.blue,
          'label': 'Main Plot',
          'icon': Icons.star,
        };
      case PlotThreadType.subplot:
        return {
          'color': Colors.purple,
          'label': 'Subplot',
          'icon': Icons.stars,
        };
      case PlotThreadType.characterArc:
        return {
          'color': Colors.green,
          'label': 'Character Arc',
          'icon': Icons.person,
        };
      case PlotThreadType.mystery:
        return {
          'color': Colors.deepPurple,
          'label': 'Mystery',
          'icon': Icons.help_outline,
        };
      case PlotThreadType.conflict:
        return {
          'color': Colors.red,
          'label': 'Conflict',
          'icon': Icons.flash_on,
        };
      case PlotThreadType.relationship:
        return {
          'color': Colors.pink,
          'label': 'Relationship',
          'icon': Icons.favorite_border,
        };
      default:
        return {
          'color': Colors.grey,
          'label': 'Other',
          'icon': Icons.more_horiz,
        };
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.account_tree_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 12),
        Text(
          'No plot threads yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Click the book icon above to analyze your document for plot threads',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showConsolidationDialog(
    BuildContext context,
    PlotThreadProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_fix_high, color: Colors.blue),
            SizedBox(width: 8),
            Text('AI Thread Consolidation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The AI will analyze your ${provider.threads.length} plot threads and:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('• Remove threads that are just single scene events'),
            const Text('• Merge duplicate or very similar threads'),
            const Text('• Keep legitimate ongoing plot threads'),
            const SizedBox(height: 16),
            Text(
              'This helps keep your thread list focused and manageable.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.auto_fix_high, size: 18),
            label: const Text('Consolidate'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Capture messenger before showing dialog
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('AI is analyzing threads...'),
            ],
          ),
        ),
      );

      try {
        // Get AI service based on current settings
        final settings = context.read<AppSettingsProvider>();
        final aiService = settings.aiProvider == 'openai'
            ? OpenAiService(
                apiKey: settings.openAiApiKey,
                model: settings.openAiModel,
              )
            : OllamaService(
                model: settings.ollamaModel,
              );

        final result = await provider.consolidateThreadsWithAI(aiService);

        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          final removed = result['removed'] ?? 0;
          final merged = result['merged'] ?? 0;
          final kept = result['kept'] ?? 0;

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                'Consolidation complete: $removed removed, $merged merged, $kept threads remaining',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Consolidation failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showClearConfirmation(
    BuildContext context,
    PlotThreadProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Plot Threads?'),
        content: Text(
          'This will remove all ${provider.threads.length} plot threads for this document. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.clearAllThreads();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All plot threads cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _showThreadDetailsDialog(
    BuildContext context,
    PlotThread thread,
    PlotThreadProvider provider,
  ) async {
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getTypeInfo(thread.type)['icon'] as IconData,
              color: _getTypeInfo(thread.type)['color'] as Color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                thread.title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Summary section (if available)
              if (thread.aiSummary != null && thread.aiSummary!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Colors.blue[400]),
                    const SizedBox(width: 6),
                    Text(
                      'AI Summary',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Text(
                    thread.aiSummary!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Generate Summary button (if no summary yet)
              if (thread.aiSummary == null || thread.aiSummary!.isEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    // Capture messenger before showing dialog
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Expanded(child: Text('Generating AI summary from chapter summaries...')),
                          ],
                        ),
                      ),
                    );

                    try {
                      final settings = context.read<AppSettingsProvider>();
                      final aiService = settings.aiProvider == 'openai'
                          ? OpenAiService(
                              apiKey: settings.openAiApiKey,
                              model: settings.openAiModel,
                            )
                          : OllamaService(
                              model: settings.ollamaModel,
                            );

                      final summary = await provider.generateThreadSummary(thread.id, aiService);

                      if (context.mounted) {
                        Navigator.of(context).pop(); // Close loading

                        if (summary != null) {
                          // Close and reopen dialog to show new summary
                          Navigator.of(context).pop();
                          _showThreadDetailsDialog(context, provider.threads.firstWhere((t) => t.id == thread.id), provider);
                        } else {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Failed to generate summary. Make sure chapter summaries exist.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generate AI Summary'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[400],
                    side: BorderSide(color: Colors.blue[400]!),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Description
              if (thread.description.isNotEmpty) ...[
                Text(
                  thread.description.split('___LOCATION___')[0],
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],

              // Status section
              Text(
                'Status',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Status buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    label: 'Introduced',
                    icon: Icons.fiber_new,
                    isSelected: thread.status == PlotThreadStatus.introduced,
                    onTap: () {
                      provider.updateThreadStatus(thread.id, PlotThreadStatus.introduced);
                      Navigator.of(context).pop();
                    },
                  ),
                  _StatusChip(
                    label: 'Developing',
                    icon: Icons.trending_up,
                    isSelected: thread.status == PlotThreadStatus.developing,
                    onTap: () {
                      provider.updateThreadStatus(thread.id, PlotThreadStatus.developing);
                      Navigator.of(context).pop();
                    },
                  ),
                  _StatusChip(
                    label: 'Resolved',
                    icon: Icons.check_circle,
                    isSelected: thread.status == PlotThreadStatus.resolved,
                    onTap: () {
                      provider.updateThreadStatus(thread.id, PlotThreadStatus.resolved);
                      Navigator.of(context).pop();
                    },
                  ),
                  _StatusChip(
                    label: 'Abandoned',
                    icon: Icons.cancel,
                    isSelected: thread.status == PlotThreadStatus.abandoned,
                    onTap: () {
                      provider.updateThreadStatus(thread.id, PlotThreadStatus.abandoned);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Thread info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow('Type', _getTypeInfo(thread.type)['label'] as String),
                    const SizedBox(height: 4),
                    _InfoRow('Introduced', 'Chapter ${thread.introducedAtScene}'),
                    const SizedBox(height: 4),
                    _InfoRow('Last mentioned', 'Chapter ${thread.lastMentionedAtScene}'),
                    const SizedBox(height: 4),
                    _InfoRow('Appearances', '${thread.sceneAppearances.length} chapters'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Thread'),
                  content: Text('Are you sure you want to delete "${thread.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await provider.deleteThread(thread.id);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAnalyzeDocumentDialog(
    BuildContext context,
    PlotThreadProvider provider,
  ) async {
    final documentProvider = context.read<DocumentProvider>();
    final wordCount = documentProvider.content.trim().split(RegExp(r'\s+')).length;

    if (wordCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document is empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: Colors.blue),
            SizedBox(width: 8),
            Text('Analyze Document'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The AI will analyze your entire document ($wordCount words) to identify major plot threads.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('This will:'),
            const Text('• Identify 8-15 major plot threads across the full manuscript'),
            const Text('• Replace any existing threads with the new analysis'),
            const Text('• Focus on threads that span multiple scenes/chapters'),
            const SizedBox(height: 12),
            Text(
              'This may take 30-90 seconds depending on document length.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.auto_stories, size: 18),
            label: const Text('Analyze'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Capture provider reference and messenger before showing dialog
      final threadProvider = context.read<PlotThreadProvider>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      bool dialogClosed = false;

      // Show loading indicator with progress bar
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          content: Consumer<PlotThreadProvider>(
            builder: (context, provider, child) {
              final progress = provider.analysisTotalChapters > 0
                  ? provider.analysisProgress / provider.analysisTotalChapters
                  : 0.0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI is analyzing full document for plot threads...',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  if (provider.analysisTotalChapters > 0)
                    Text(
                      'Analyzing chapter ${provider.analysisProgress} of ${provider.analysisTotalChapters}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take 30-90 seconds.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                threadProvider.cancelAnalysis();
                dialogClosed = true;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      try {
        // Get AI service based on current settings
        final settings = context.read<AppSettingsProvider>();
        final aiService = settings.aiProvider == 'openai'
            ? OpenAiService(
                apiKey: settings.openAiApiKey,
                model: settings.openAiModel,
              )
            : OllamaService(
                model: settings.ollamaModel,
              );

        // Use new two-phase analysis (summarize chapters, then extract threads)
        final result = await provider.analyzeDocumentThreadsViaSummaries(
          documentProvider.content,
          aiService,
        );

        // Only close dialog and show snackbar if dialog wasn't already closed by cancel
        if (!dialogClosed && context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          if (result['success'] == true) {
            final threadsFound = result['threadsFound'] ?? 0;
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Analysis complete: $threadsFound plot threads identified',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            final error = result['error'] ?? 'Unknown error';
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Analysis failed: $error'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        if (!dialogClosed && context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Analysis failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Helper widget for status chips
class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for info rows
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
