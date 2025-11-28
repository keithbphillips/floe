import 'dart:async';
import 'package:flutter/material.dart';

class FindDialog extends StatefulWidget {
  final String initialSearchText;
  final Function(String) onSearch;
  final VoidCallback onClose;
  final String documentContent;
  final Function(int, int, FocusNode)? onNavigateToMatch;
  final Function(String, String)? onReplace;
  final Function(String, String)? onReplaceAll;

  const FindDialog({
    Key? key,
    this.initialSearchText = '',
    required this.onSearch,
    required this.onClose,
    required this.documentContent,
    this.onNavigateToMatch,
    this.onReplace,
    this.onReplaceAll,
  }) : super(key: key);

  @override
  State<FindDialog> createState() => _FindDialogState();
}

class _FindDialogState extends State<FindDialog> {
  late TextEditingController _searchController;
  late TextEditingController _replaceController;
  late FocusNode _searchFocusNode;
  late FocusNode _replaceFocusNode;
  int _currentMatchIndex = 0;
  List<Match> _matches = [];
  bool _showReplace = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchText);
    _replaceController = TextEditingController();
    _searchFocusNode = FocusNode();
    _replaceFocusNode = FocusNode();

    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      if (_searchController.text.isNotEmpty) {
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _replaceController.dispose();
    _searchFocusNode.dispose();
    _replaceFocusNode.dispose();
    super.dispose();
  }

  void _updateMatches({bool navigate = true}) {
    if (_searchController.text.isEmpty) {
      _matches = [];
      _currentMatchIndex = 0;
      return;
    }

    final searchLower = _searchController.text.toLowerCase();
    final contentLower = widget.documentContent.toLowerCase();
    _matches = searchLower.allMatches(contentLower).toList();
    _currentMatchIndex = _matches.isEmpty ? 0 : 0;

    // Navigate to first match only if requested
    if (navigate && _matches.isNotEmpty) {
      _navigateToCurrentMatch();
    }
  }

  void _navigateToCurrentMatch() {
    if (_matches.isEmpty || widget.onNavigateToMatch == null) return;

    final match = _matches[_currentMatchIndex];
    widget.onNavigateToMatch!(match.start, match.end, _searchFocusNode);
  }

  void _nextMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
      _navigateToCurrentMatch();
    });
  }

  void _previousMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matches.length) % _matches.length;
      _navigateToCurrentMatch();
    });
  }

  void _replace() {
    if (_searchController.text.isEmpty || widget.onReplace == null) return;
    widget.onReplace!(_searchController.text, _replaceController.text);
  }

  void _replaceAll() {
    if (_searchController.text.isEmpty || widget.onReplaceAll == null) return;
    widget.onReplaceAll!(_searchController.text, _replaceController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final matchCount = _matches.length;

    return Container(
      width: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.search,
                size: 20,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                _showReplace ? 'Find & Replace' : 'Find',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Toggle replace button
              IconButton(
                icon: Icon(
                  _showReplace ? Icons.unfold_less : Icons.find_replace,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showReplace = !_showReplace;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: _showReplace ? 'Hide replace' : 'Show replace',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search field
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search in document...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearch('');
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              // Don't do anything on change - wait for Enter key
              // Just trigger a rebuild to update the UI if needed
              setState(() {});
            },
            onSubmitted: (value) {
              // Trigger search when Enter is pressed
              widget.onSearch(value);
              setState(() {
                _updateMatches();
              });
            },
          ),

          // Replace field (shown when _showReplace is true)
          if (_showReplace) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _replaceController,
              focusNode: _replaceFocusNode,
              decoration: InputDecoration(
                hintText: 'Replace with...',
                prefixIcon: const Icon(Icons.edit, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onSubmitted: (value) {
                _replace();
              },
            ),
            const SizedBox(height: 12),
            // Replace buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: matchCount > 0 ? _replace : null,
                    icon: const Icon(Icons.change_circle, size: 16),
                    label: const Text('Replace'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: matchCount > 0 ? _replaceAll : null,
                    icon: const Icon(Icons.find_replace, size: 16),
                    label: const Text('Replace All'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Match count, navigation buttons, and help text
          Row(
            children: [
              if (matchCount > 0) ...[
                Text(
                  '${_currentMatchIndex + 1} of $matchCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: _previousMatch,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: 'Previous match',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  onPressed: _nextMatch,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: 'Next match',
                ),
                const SizedBox(width: 12),
              ],
              Text(
                'Press ESC to close • Enter for next',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
