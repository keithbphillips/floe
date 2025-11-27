import 'package:flutter/material.dart';

class FindDialog extends StatefulWidget {
  final String initialSearchText;
  final Function(String) onSearch;
  final VoidCallback onClose;
  final String documentContent;
  final Function(int, int, FocusNode)? onNavigateToMatch;

  const FindDialog({
    Key? key,
    this.initialSearchText = '',
    required this.onSearch,
    required this.onClose,
    required this.documentContent,
    this.onNavigateToMatch,
  }) : super(key: key);

  @override
  State<FindDialog> createState() => _FindDialogState();
}

class _FindDialogState extends State<FindDialog> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  int _currentMatchIndex = 0;
  List<Match> _matches = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchText);
    _searchFocusNode = FocusNode();

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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _updateMatches() {
    if (_searchController.text.isEmpty) {
      _matches = [];
      _currentMatchIndex = 0;
      return;
    }

    final searchLower = _searchController.text.toLowerCase();
    final contentLower = widget.documentContent.toLowerCase();
    _matches = searchLower.allMatches(contentLower).toList();
    _currentMatchIndex = _matches.isEmpty ? 0 : 0;

    // Navigate to first match
    if (_matches.isNotEmpty) {
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
                'Find',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
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
              widget.onSearch(value);
              setState(() {
                _updateMatches();
              });
            },
            onSubmitted: (value) {
              _nextMatch();
            },
          ),
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
