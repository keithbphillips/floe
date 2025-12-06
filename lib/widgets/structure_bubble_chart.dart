import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';

class StructureUnit {
  final String type; // 'chapter' or 'scene'
  final int startPosition;
  final int endPosition;
  final int wordCount;
  final String? label; // Chapter number if applicable

  StructureUnit({
    required this.type,
    required this.startPosition,
    required this.endPosition,
    required this.wordCount,
    this.label,
  });
}

class StructureBubbleChart extends StatefulWidget {
  final String documentContent;
  final Function(int) onNavigate;
  final int? currentCursorPosition;

  const StructureBubbleChart({
    Key? key,
    required this.documentContent,
    required this.onNavigate,
    this.currentCursorPosition,
  }) : super(key: key);

  @override
  State<StructureBubbleChart> createState() => _StructureBubbleChartState();
}

class _StructureBubbleChartState extends State<StructureBubbleChart> {
  List<StructureUnit>? _cachedUnits;
  String? _lastProcessedContent;
  final ScrollController _scrollController = ScrollController();
  int? _lastCenteredIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StructureBubbleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recompute if content changed significantly (avoid recomputing on every keystroke)
    if (_lastProcessedContent == null ||
        (widget.documentContent.length - (_lastProcessedContent?.length ?? 0)).abs() > 100) {
      _cachedUnits = null; // Clear cache to force recompute
    }

    // Auto-scroll to center current bubble when cursor position changes
    if (widget.currentCursorPosition != oldWidget.currentCursorPosition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentBubble();
      });
    }
  }

  List<StructureUnit> _extractStructure() {
    // Return cached units if available
    if (_cachedUnits != null && _lastProcessedContent == widget.documentContent) {
      return _cachedUnits!;
    }

    final units = <StructureUnit>[];

    if (widget.documentContent.isEmpty) return units;

    // First, find all chapters (lines containing "Chapter" followed by a number)
    final chapterPattern = RegExp(r'(?:^|\n)Chapter\s+(\d+)', caseSensitive: false);
    final chapterMatches = chapterPattern.allMatches(widget.documentContent).toList();

    // Find all scene breaks (two blank lines = three newlines)
    final sceneBreakPattern = RegExp(r'\n\s*\n\s*\n');

    if (chapterMatches.isEmpty) {
      // No chapters - treat entire document as scenes divided by scene breaks
      final sceneBreaks = sceneBreakPattern.allMatches(widget.documentContent).toList();

      if (sceneBreaks.isEmpty) {
        // No structure at all - single scene
        final wordCount = widget.documentContent.trim().isEmpty
            ? 0
            : widget.documentContent.trim().split(RegExp(r'\s+')).length;
        if (wordCount > 10) {
          units.add(StructureUnit(
            type: 'scene',
            startPosition: 0,
            endPosition: widget.documentContent.length,
            wordCount: wordCount,
            label: '1',
          ));
        }
      } else {
        // Multiple scenes without chapters
        final boundaries = <int>[0];
        for (final match in sceneBreaks) {
          boundaries.add(match.end);
        }
        boundaries.add(widget.documentContent.length);

        int sceneNumber = 1;
        for (int i = 0; i < boundaries.length - 1; i++) {
          final start = boundaries[i];
          final end = boundaries[i + 1];
          final sectionText = widget.documentContent.substring(start, end);
          final wordCount = sectionText.trim().isEmpty
              ? 0
              : sectionText.trim().split(RegExp(r'\s+')).length;

          if (wordCount > 10) {
            units.add(StructureUnit(
              type: 'scene',
              startPosition: start,
              endPosition: end,
              wordCount: wordCount,
              label: sceneNumber.toString(),
            ));
            sceneNumber++;
          }
        }
      }
    } else {
      // Has chapters - show both chapter bubbles and scene bubbles
      for (int chapterIdx = 0; chapterIdx < chapterMatches.length; chapterIdx++) {
        final chapterMatch = chapterMatches[chapterIdx];
        final chapterNumber = chapterMatch.group(1);
        final chapterStart = chapterMatch.start;

        // Find where this chapter ends (next chapter or end of document)
        final chapterEnd = chapterIdx < chapterMatches.length - 1
            ? chapterMatches[chapterIdx + 1].start
            : widget.documentContent.length;

        // Calculate total chapter word count
        final chapterText = widget.documentContent.substring(chapterStart, chapterEnd);
        final chapterWordCount = chapterText.trim().isEmpty
            ? 0
            : chapterText.trim().split(RegExp(r'\s+')).length;

        // Add chapter bubble
        if (chapterWordCount > 10) {
          units.add(StructureUnit(
            type: 'chapter',
            startPosition: chapterStart,
            endPosition: chapterEnd,
            wordCount: chapterWordCount,
            label: chapterNumber,
          ));
        }

        // Get chapter content (excluding the chapter heading line)
        final chapterHeadingEnd = widget.documentContent.indexOf('\n', chapterStart);
        final chapterContentStart = chapterHeadingEnd != -1 ? chapterHeadingEnd + 1 : chapterStart;
        final chapterContent = widget.documentContent.substring(chapterContentStart, chapterEnd);

        // Find scene breaks within this chapter
        final scenesInChapter = sceneBreakPattern.allMatches(chapterContent).toList();

        if (scenesInChapter.isEmpty) {
          // Chapter has no scene breaks - entire chapter is one scene
          final wordCount = chapterContent.trim().isEmpty
              ? 0
              : chapterContent.trim().split(RegExp(r'\s+')).length;

          if (wordCount > 10) {
            units.add(StructureUnit(
              type: 'scene',
              startPosition: chapterContentStart,
              endPosition: chapterEnd,
              wordCount: wordCount,
              label: 'Ch $chapterNumber',
            ));
          }
        } else {
          // Chapter has scene breaks - create multiple scenes
          final sceneBoundaries = <int>[0]; // Relative to chapter content start
          for (final match in scenesInChapter) {
            sceneBoundaries.add(match.end);
          }
          sceneBoundaries.add(chapterContent.length);

          int sceneNumber = 1;
          for (int i = 0; i < sceneBoundaries.length - 1; i++) {
            final relativeStart = sceneBoundaries[i];
            final relativeEnd = sceneBoundaries[i + 1];
            final absoluteStart = chapterContentStart + relativeStart;
            final absoluteEnd = chapterContentStart + relativeEnd;

            final sceneText = widget.documentContent.substring(absoluteStart, absoluteEnd);
            final wordCount = sceneText.trim().isEmpty
                ? 0
                : sceneText.trim().split(RegExp(r'\s+')).length;

            if (wordCount > 10) {
              units.add(StructureUnit(
                type: 'scene',
                startPosition: absoluteStart,
                endPosition: absoluteEnd,
                wordCount: wordCount,
                label: 'Ch $chapterNumber.$sceneNumber',
              ));
              sceneNumber++;
            }
          }
        }
      }
    }

    // Cache the results
    _cachedUnits = units;
    _lastProcessedContent = widget.documentContent;

    return units;
  }

  void _scrollToCurrentBubble() {
    if (!_scrollController.hasClients) return;
    if (widget.currentCursorPosition == null) return;

    final units = _extractStructure();
    if (units.isEmpty) return;

    // Find which bubble contains the current cursor position
    int currentIndex = -1;
    for (int i = 0; i < units.length; i++) {
      final unit = units[i];
      if (widget.currentCursorPosition! >= unit.startPosition &&
          widget.currentCursorPosition! < unit.endPosition) {
        // Prefer scenes over chapters if cursor is in both
        if (unit.type == 'scene') {
          currentIndex = i;
          break;
        } else if (currentIndex == -1) {
          currentIndex = i;
        }
      }
    }

    if (currentIndex == -1 || currentIndex == _lastCenteredIndex) return;

    _lastCenteredIndex = currentIndex;

    // Calculate bubble position and scroll to center it
    // Each bubble has width (bubbleSize) + padding (8px total)
    final maxWordCount = units.map((u) => u.wordCount).reduce((a, b) => a > b ? a : b);
    const minBubbleSize = 12.0;
    const maxBubbleSize = 32.0;

    double totalOffset = 0;
    for (int i = 0; i < currentIndex; i++) {
      final unit = units[i];
      final sizeRatio = maxWordCount > 0 ? unit.wordCount / maxWordCount : 0.5;
      final bubbleSize = minBubbleSize + (sizeRatio * (maxBubbleSize - minBubbleSize));
      totalOffset += bubbleSize + 8; // bubble width + horizontal padding
    }

    // Add half of current bubble size to center it
    final currentUnit = units[currentIndex];
    final currentSizeRatio = maxWordCount > 0 ? currentUnit.wordCount / maxWordCount : 0.5;
    final currentBubbleSize = minBubbleSize + (currentSizeRatio * (maxBubbleSize - minBubbleSize));
    totalOffset += currentBubbleSize / 2;

    // Center in viewport
    final viewportWidth = _scrollController.position.viewportDimension;
    final targetScroll = (totalOffset - (viewportWidth / 2)).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Determine if this bubble is currently selected based on cursor position
  bool _isBubbleSelected(StructureUnit unit, List<StructureUnit> allUnits) {
    if (widget.currentCursorPosition == null) return false;

    // Check if cursor is within this unit's range
    if (widget.currentCursorPosition! >= unit.startPosition &&
        widget.currentCursorPosition! < unit.endPosition) {
      // For scenes, this is sufficient
      if (unit.type == 'scene') return true;

      // For chapters, only highlight if there are no scenes within it at cursor position
      // (i.e., prefer highlighting the scene over the chapter)
      final hasSceneAtCursor = allUnits.any((other) =>
          other.type == 'scene' &&
          widget.currentCursorPosition! >= other.startPosition &&
          widget.currentCursorPosition! < other.endPosition);

      return !hasSceneAtCursor;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<AppSettingsProvider>();
    final units = _extractStructure();

    if (units.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate max word count for sizing
    final maxWordCount = units.map((u) => u.wordCount).reduce((a, b) => a > b ? a : b);
    final minBubbleSize = 12.0;
    final maxBubbleSize = 32.0;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: units.length,
        itemBuilder: (context, index) {
          final unit = units[index];
          final isChapter = unit.type == 'chapter';
          final isSelected = _isBubbleSelected(unit, units);

          // Calculate bubble size based on word count
          final sizeRatio = maxWordCount > 0 ? unit.wordCount / maxWordCount : 0.5;
          final bubbleSize = minBubbleSize + (sizeRatio * (maxBubbleSize - minBubbleSize));

          final bubbleColor = isChapter
              ? (isDark
                  ? Color(settings.chapterBubbleColorDark)
                  : Color(settings.chapterBubbleColorLight))
              : (isDark
                  ? Color(settings.sceneBubbleColorDark)
                  : Color(settings.sceneBubbleColorLight));

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: isChapter
                  ? 'Chapter ${unit.label}\n${unit.wordCount} words'
                  : 'Scene ${unit.label}\n${unit.wordCount} words',
              child: GestureDetector(
                onTap: () => widget.onNavigate(unit.startPosition),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Highlight circle (outer ring) - only show when selected
                    if (isSelected)
                      Container(
                        width: bubbleSize + 8,
                        height: bubbleSize + 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.blue[300]! : Colors.blue[600]!,
                            width: 2,
                          ),
                        ),
                      ),
                    // Main bubble
                    Container(
                      width: bubbleSize,
                      height: bubbleSize,
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                          width: 1,
                        ),
                      ),
                      child: isChapter
                          ? Center(
                              child: Text(
                                unit.label ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: bubbleSize * 0.35,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
