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
                child: GestureDetector(
                  onTapUp: (details) {
                    // Calculate which scene was clicked
                    final sceneWidth = 40.0;
                    final totalWidth = widget.totalScenes * sceneWidth;
                    final clickX = details.localPosition.dx + scrollOffset;
                    final clickedScene = (clickX / sceneWidth).round().clamp(1, widget.totalScenes);

                    // Check if clicked scene is in this thread's appearances
                    if (thread.sceneAppearances.contains(clickedScene)) {
                      widget.onSceneClick?.call(clickedScene - 1); // Convert to 0-based index
                    }
                  },
                  child: SizedBox(
                    height: 20,
                    child: CustomPaint(
                      painter: _ThreadTimelinePainter(
                        thread: thread,
                        threadColor: typeColor,
                        scrollOffset: scrollOffset,
                        totalScenes: widget.totalScenes,
                        currentSceneIndex: widget.currentSceneIndex,
                      ),
                      child: Container(), // Force the painter to fill available space
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

/// Custom painter that draws the thread timeline without clipping issues
class _ThreadTimelinePainter extends CustomPainter {
  final PlotThread thread;
  final Color threadColor;
  final double scrollOffset;
  final int totalScenes;
  final int currentSceneIndex;

  _ThreadTimelinePainter({
    required this.thread,
    required this.threadColor,
    required this.scrollOffset,
    required this.totalScenes,
    required this.currentSceneIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxScene = totalScenes > 0 ? totalScenes : 1;
    final sceneWidth = 40.0; // Match bubble chart spacing
    final totalWidth = maxScene * sceneWidth;

    // Debug: Log thread info for first render
    if (scrollOffset == 0 && thread.title.contains('Shadow')) {
      print('Drawing timeline for: ${thread.title}');
      print('  introducedAtScene: ${thread.introducedAtScene}');
      print('  lastMentionedAtScene: ${thread.lastMentionedAtScene}');
      print('  sceneAppearances: ${thread.sceneAppearances}');
      print('  totalScenes: $totalScenes');
    }

    // Only clip vertically, not horizontally
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(-scrollOffset, 0, totalWidth + scrollOffset, size.height));

    // Translate for scroll
    canvas.translate(-scrollOffset, 0);

    // Find the earliest and latest appearance in scene list
    int firstAppearance = thread.introducedAtScene > 0 ? thread.introducedAtScene : 1;
    int lastAppearance = thread.lastMentionedAtScene > 0 ? thread.lastMentionedAtScene : firstAppearance;

    if (thread.sceneAppearances.isNotEmpty) {
      firstAppearance = thread.sceneAppearances.reduce((a, b) => a < b ? a : b);
      lastAppearance = thread.sceneAppearances.reduce((a, b) => a > b ? a : b);
    }

    // Draw horizontal line spanning from first to last appearance
    final lineStartX = (firstAppearance / maxScene) * totalWidth;
    final lineEndX = ((lastAppearance + 1) / maxScene) * totalWidth;

    final linePaint = Paint()
      ..color = threadColor.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(lineStartX, size.height / 2),
      Offset(lineEndX, size.height / 2),
      linePaint,
    );

    // Draw light background bar
    final barPaint = Paint()
      ..color = threadColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(lineStartX, 8, lineEndX, size.height - 8),
        const Radius.circular(2),
      ),
      barPaint,
    );

    // Draw dots at each appearance
    final dotPaint = Paint()
      ..style = PaintingStyle.fill;

    for (final sceneNumber in thread.sceneAppearances) {
      final position = (sceneNumber / maxScene) * totalWidth;
      final isCurrentScene = sceneNumber == currentSceneIndex + 1;

      // Only draw if within reasonable range of visible area
      if (position >= scrollOffset - 100 && position <= scrollOffset + size.width + 100) {
        dotPaint.color = isCurrentScene
            ? threadColor
            : threadColor.withOpacity(0.7);

        // Draw dot
        canvas.drawCircle(
          Offset(position, size.height / 2),
          isCurrentScene ? 5 : 4,
          dotPaint,
        );

        // Draw border for current scene
        if (isCurrentScene) {
          final borderPaint = Paint()
            ..color = threadColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;

          canvas.drawCircle(
            Offset(position, size.height / 2),
            6,
            borderPaint,
          );
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThreadTimelinePainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.currentSceneIndex != currentSceneIndex ||
        oldDelegate.thread != thread;
  }
}
