import 'package:flutter/material.dart';

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

  const StructureBubbleChart({
    Key? key,
    required this.documentContent,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<StructureBubbleChart> createState() => _StructureBubbleChartState();
}

class _StructureBubbleChartState extends State<StructureBubbleChart> {
  List<StructureUnit>? _cachedUnits;
  String? _lastProcessedContent;

  @override
  void didUpdateWidget(StructureBubbleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recompute if content changed significantly (avoid recomputing on every keystroke)
    if (_lastProcessedContent == null ||
        (widget.documentContent.length - (_lastProcessedContent?.length ?? 0)).abs() > 100) {
      _cachedUnits = null; // Clear cache to force recompute
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
    final sceneBreaks = sceneBreakPattern.allMatches(widget.documentContent).toList();

    // Build list of all boundaries (chapters and scene breaks)
    final boundaries = <int>[0]; // Start of document

    // Add chapter positions
    for (final match in chapterMatches) {
      boundaries.add(match.start);
    }

    // Add scene break positions
    for (final match in sceneBreaks) {
      boundaries.add(match.end);
    }

    boundaries.add(widget.documentContent.length); // End of document

    // Sort and deduplicate
    boundaries.sort();
    final uniqueBoundaries = boundaries.toSet().toList()..sort();

    // Create structure units
    for (int i = 0; i < uniqueBoundaries.length - 1; i++) {
      final start = uniqueBoundaries[i];
      final end = uniqueBoundaries[i + 1];
      final sectionText = widget.documentContent.substring(start, end);

      // Calculate word count
      final wordCount = sectionText.trim().isEmpty
          ? 0
          : sectionText.trim().split(RegExp(r'\s+')).length;

      // Check if this section starts with a chapter heading
      final trimmedText = sectionText.trim();
      final chapterMatch = RegExp(r'^Chapter\s+(\d+)', caseSensitive: false).firstMatch(trimmedText);

      if (chapterMatch != null) {
        units.add(StructureUnit(
          type: 'chapter',
          startPosition: start,
          endPosition: end,
          wordCount: wordCount,
          label: chapterMatch.group(1),
        ));
      } else if (wordCount > 10) { // Only show scenes with meaningful content
        units.add(StructureUnit(
          type: 'scene',
          startPosition: start,
          endPosition: end,
          wordCount: wordCount,
        ));
      }
    }

    // Cache the results
    _cachedUnits = units;
    _lastProcessedContent = widget.documentContent;

    return units;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
        scrollDirection: Axis.horizontal,
        itemCount: units.length,
        itemBuilder: (context, index) {
          final unit = units[index];
          final isChapter = unit.type == 'chapter';

          // Calculate bubble size based on word count
          final sizeRatio = maxWordCount > 0 ? unit.wordCount / maxWordCount : 0.5;
          final bubbleSize = minBubbleSize + (sizeRatio * (maxBubbleSize - minBubbleSize));

          final bubbleColor = isChapter
              ? (isDark ? Colors.blue[400]! : Colors.blue[600]!)
              : (isDark ? Colors.amber[700]! : Colors.amber[600]!);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: isChapter
                  ? 'Chapter ${unit.label}\n${unit.wordCount} words'
                  : 'Scene ${index + 1}\n${unit.wordCount} words',
              child: InkWell(
                onTap: () => widget.onNavigate(unit.startPosition),
                borderRadius: BorderRadius.circular(bubbleSize / 2),
                child: Container(
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
              ),
            ),
          );
        },
      ),
    );
  }
}
