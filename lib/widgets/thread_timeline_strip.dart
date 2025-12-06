import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plot_thread_provider.dart';
import '../models/plot_thread.dart';

class ThreadTimelineStrip extends StatefulWidget {
  final int totalScenes;
  final int currentSceneIndex;
  final Function(int sceneIndex)? onSceneClick;
  final Function(PlotThread thread)? onThreadClick;
  final ScrollController? scrollController;

  const ThreadTimelineStrip({
    Key? key,
    required this.totalScenes,
    required this.currentSceneIndex,
    this.onSceneClick,
    this.onThreadClick,
    this.scrollController,
  }) : super(key: key);

  @override
  State<ThreadTimelineStrip> createState() => _ThreadTimelineStripState();
}

class _ThreadTimelineStripState extends State<ThreadTimelineStrip> {
  // Track expanded state for thread groups
  final Map<String, bool> _expandedGroups = {
    'active': true,
    'abandoned': true,
    'resolved': false,
  };

  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    // Listen to bubble scroll to update our offset
    widget.scrollController?.addListener(_onBubbleScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onBubbleScroll);
    super.dispose();
  }

  void _onBubbleScroll() {
    if (mounted) {
      setState(() {}); // Rebuild with new scroll offset
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadProvider = context.watch<PlotThreadProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (threadProvider.threads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(theme, isDark, threadProvider),

          // Timeline content
          if (!_isCollapsed) _buildTimeline(threadProvider, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, PlotThreadProvider provider) {
    return InkWell(
      onTap: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              _isCollapsed ? Icons.chevron_right : Icons.expand_more,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.timeline,
              size: 16,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Plot Thread Timeline',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              '${provider.activeThreads.length} active',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(PlotThreadProvider provider, ThemeData theme, bool isDark) {
    final resolvedThreads = provider.threads
        .where((t) => t.status == PlotThreadStatus.resolved)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active threads
          if (provider.activeThreads.isNotEmpty)
            _buildThreadGroup(
              'Active',
              'active',
              provider.activeThreads,
              theme,
              isDark,
              Colors.blue,
            ),

          // Abandoned threads
          if (provider.potentiallyAbandonedThreads.isNotEmpty)
            _buildThreadGroup(
              'Abandoned',
              'abandoned',
              provider.potentiallyAbandonedThreads,
              theme,
              isDark,
              Colors.orange,
            ),

          // Resolved threads
          if (resolvedThreads.isNotEmpty)
            _buildThreadGroup(
              'Resolved',
              'resolved',
              resolvedThreads,
              theme,
              isDark,
              Colors.grey,
            ),
        ],
      ),
    );
  }

  Widget _buildThreadGroup(
    String label,
    String groupKey,
    List<PlotThread> threads,
    ThemeData theme,
    bool isDark,
    Color accentColor,
  ) {
    final isExpanded = _expandedGroups[groupKey] ?? true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        InkWell(
          onTap: () {
            setState(() {
              _expandedGroups[groupKey] = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 14,
                  color: accentColor,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${threads.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Thread lanes
        if (isExpanded)
          ...threads.map((thread) => _buildThreadLane(thread, theme, isDark)),
      ],
    );
  }

  Widget _buildThreadLane(PlotThread thread, ThemeData theme, bool isDark) {
    final typeColor = _getThreadTypeColor(thread.type);
    final scrollOffset = widget.scrollController?.hasClients == true
        ? widget.scrollController!.offset
        : 0.0;

    return InkWell(
      onTap: () => widget.onThreadClick?.call(thread),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            // Thread label (fixed width, doesn't scroll)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SizedBox(
                width: 120,
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        thread.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          decoration: thread.status == PlotThreadStatus.resolved
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Timeline visualization (synced with bubble scroll)
            Expanded(
              child: ClipRect(
                child: Transform.translate(
                  offset: Offset(-scrollOffset, 0),
                  child: _buildThreadTimeline(thread, typeColor, theme, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadTimeline(
    PlotThread thread,
    Color threadColor,
    ThemeData theme,
    bool isDark,
  ) {
    final maxScene = widget.totalScenes > 0 ? widget.totalScenes : 1;

    // Calculate width based on number of scenes
    // Each scene needs about 40px (similar to bubble chart spacing)
    final width = maxScene * 40.0;

    return SizedBox(
      height: 20,
      width: width,
      child: Stack(
        children: [
          // Background bar (full thread lifecycle)
          Positioned(
            left: (thread.introducedAtScene / maxScene) * width,
            right: width - ((thread.lastMentionedAtScene + 1) / maxScene) * width,
            top: 8,
            bottom: 8,
            child: Container(
              decoration: BoxDecoration(
                color: threadColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Scene appearance markers
          ...thread.sceneAppearances.map((sceneNumber) {
            final position = (sceneNumber / maxScene) * width;
            final isCurrentScene = sceneNumber == widget.currentSceneIndex + 1;

            return Positioned(
              left: position - 3,
              top: 5,
              child: Container(
                width: 6,
                height: 10,
                decoration: BoxDecoration(
                  color: isCurrentScene
                      ? threadColor
                      : threadColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(3),
                  border: isCurrentScene
                      ? Border.all(color: threadColor, width: 1.5)
                      : null,
                ),
              ),
            );
          }),

          // Current scene indicator (vertical line)
          if (widget.totalScenes > 0) ...[
            Positioned(
              left: ((widget.currentSceneIndex + 1) / maxScene) * width - 0.5,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color: theme.primaryColor.withOpacity(0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getThreadTypeColor(PlotThreadType type) {
    switch (type) {
      case PlotThreadType.mainPlot:
        return Colors.blue;
      case PlotThreadType.subplot:
        return Colors.purple;
      case PlotThreadType.characterArc:
        return Colors.green;
      case PlotThreadType.mystery:
        return Colors.deepPurple;
      case PlotThreadType.conflict:
        return Colors.red;
      case PlotThreadType.relationship:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
