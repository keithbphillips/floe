import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plot_thread_provider.dart';
import '../models/plot_thread.dart';

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

    return Container(
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
          if (thread.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              thread.description,
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
              _buildMetadataChip(
                Icons.bookmark_outline,
                'Scene ${thread.introducedAtScene}',
                theme,
              ),
              _buildMetadataChip(
                Icons.update,
                '${thread.sceneAppearances.length} mentions',
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
            'Plot threads will appear as you write and analyze scenes',
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
}
