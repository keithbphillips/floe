import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/app_settings_provider.dart';
import '../providers/document_provider.dart';
import '../providers/scene_analyzer_provider.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/word_count_overlay.dart';
import '../widgets/file_menu.dart';
import '../widgets/scene_info_panel.dart';
import '../widgets/find_dialog.dart';
import '../widgets/structure_bubble_chart.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({Key? key}) : super(key: key);

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late _SearchableTextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _showWordCount = false;
  bool _showFileMenu = false;
  bool _showFindDialog = false;
  bool _isFullscreen = false;
  String _searchText = '';

  int _lastAnalyzedWordCount = 0;
  DateTime? _lastEditTime;
  DateTime? _lastAnalysisTime;

  @override
  void initState() {
    super.initState();
    final docProvider = context.read<DocumentProvider>();
    final settingsProvider = context.read<AppSettingsProvider>();

    // Initialize controller with current content
    _controller = _SearchableTextEditingController(text: docProvider.content);
    _controller.addListener(_onControllerChanged);

    docProvider.startAutoSave(settingsProvider.autoSaveInterval);

    // Load last file and request focus on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Try to load the last opened file
      await docProvider.loadLastFile();

      // Update controller if content was loaded
      if (docProvider.content.isNotEmpty && _controller.text != docProvider.content) {
        _controller.text = docProvider.content;
      }

      _focusNode.requestFocus();

      // Initial analysis if there's content
      if (_controller.text.trim().isNotEmpty) {
        _checkAndAnalyze();
      }
    });

    // Start periodic check for automatic analysis
    _startAutoAnalysisTimer();
  }

  void _onControllerChanged() {
    // This will be called whenever controller text changes
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for changes in the document provider
    final document = context.watch<DocumentProvider>();
    if (_controller.text != document.content) {
      // Content changed externally (e.g., file loaded via menu)
      _controller.value = TextEditingValue(
        text: document.content,
        selection: TextSelection.collapsed(offset: document.content.length),
      );
    }
  }

  void _startAutoAnalysisTimer() {
    // Check every 3 seconds if we should analyze
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkAndAnalyze();
        _startAutoAnalysisTimer();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    context.read<DocumentProvider>().stopAutoSave();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final isCtrlOrCmd = event.isControlPressed || event.isMetaPressed;

    // Cmd/Ctrl + M : Insert em dash
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyM) {
      _insertEmDash();
    }
    // Cmd/Ctrl + I : Toggle italics (markdown style)
    else if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyI) {
      _toggleItalics();
    }
    // Cmd/Ctrl + , : Open settings
    else if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.comma) {
      _showSettings();
    }
    // Cmd/Ctrl + D : Toggle dark mode
    else if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyD) {
      context.read<AppSettingsProvider>().toggleDarkMode();
    }
    // Cmd/Ctrl + F : Toggle find dialog
    else if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyF && !event.isShiftPressed) {
      setState(() {
        _showFindDialog = !_showFindDialog;
        if (!_showFindDialog) {
          _searchText = '';
          _controller.updateSearchText('');
        }
      });
    }
    // Cmd/Ctrl + Shift + F : Toggle focus mode
    else if (isCtrlOrCmd && event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
      context.read<AppSettingsProvider>().toggleFocusMode();
    }
    // Cmd/Ctrl + Shift + W : Toggle word count
    else if (isCtrlOrCmd && event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.keyW) {
      setState(() {
        _showWordCount = !_showWordCount;
      });
    }
    // Cmd/Ctrl + Shift + A : Analyze scene
    else if (isCtrlOrCmd && event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
      _analyzeCurrentScene();
    }
    // F11 : Toggle fullscreen
    else if (event.logicalKey == LogicalKeyboardKey.f11) {
      _toggleFullscreen();
    }
    // Escape : Close find dialog, toggle file menu (or exit fullscreen)
    else if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_showFindDialog) {
        setState(() {
          _showFindDialog = false;
          _searchText = '';
          _controller.updateSearchText('');
        });
      } else if (_isFullscreen) {
        _toggleFullscreen();
      } else {
        setState(() {
          _showFileMenu = !_showFileMenu;
        });
      }
    }
  }

  void _insertEmDash() {
    final selection = _controller.selection;
    final text = _controller.text;
    final emDash = '—';

    if (selection.isValid) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        emDash,
      );

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + emDash.length,
        ),
      );

      // Update document
      final document = context.read<DocumentProvider>();
      document.updateContent(newText, selection.start + emDash.length);
    }
  }

  void _toggleItalics() {
    final selection = _controller.selection;
    final text = _controller.text;

    if (!selection.isValid) return;

    // If there's a selection, wrap it with asterisks for markdown italics
    if (selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);

      // Check if already italicized
      final beforeStart = selection.start > 0 ? text[selection.start - 1] : '';
      final afterEnd = selection.end < text.length ? text[selection.end] : '';

      String newText;
      int newCursorPos;

      if (beforeStart == '*' && afterEnd == '*') {
        // Remove italics
        newText = text.substring(0, selection.start - 1) +
                  selectedText +
                  text.substring(selection.end + 1);
        newCursorPos = selection.start - 1;
      } else {
        // Add italics
        newText = text.substring(0, selection.start) +
                  '*$selectedText*' +
                  text.substring(selection.end);
        newCursorPos = selection.end + 2;
      }

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );

      // Update document
      final document = context.read<DocumentProvider>();
      document.updateContent(newText, newCursorPos);
    } else {
      // No selection - insert asterisks and position cursor between them
      final newText = text.substring(0, selection.start) +
                      '**' +
                      text.substring(selection.start);

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + 1,
        ),
      );

      // Update document
      final document = context.read<DocumentProvider>();
      document.updateContent(newText, selection.start + 1);
    }
  }

  void _toggleFullscreen() async {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      await windowManager.setFullScreen(true);
    } else {
      await windowManager.setFullScreen(false);
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  Future<void> _newDocument() async {
    final document = context.read<DocumentProvider>();

    if (document.hasUnsavedChanges) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Create a new document?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('New Document'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    _controller.text = '';
    document.newDocument();
    _focusNode.requestFocus();
  }

  Future<void> _openDocument() async {
    debugPrint('_openDocument called');

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt'],
      dialogTitle: 'Open Document',
    );

    debugPrint('File picker result: ${result != null}');

    if (result == null || result.files.isEmpty) {
      debugPrint('No file selected');
      return;
    }

    final filePath = result.files.first.path;
    debugPrint('Selected file path: $filePath');

    if (filePath == null) {
      debugPrint('File path is null');
      return;
    }

    try {
      final document = context.read<DocumentProvider>();
      debugPrint('Loading file: $filePath');

      await document.loadFile(filePath);

      debugPrint('File loaded, content length: ${document.content.length}');
      debugPrint('Content preview: ${document.content.substring(0, document.content.length > 100 ? 100 : document.content.length)}');

      // Update controller with new value
      _controller.value = TextEditingValue(
        text: document.content,
        selection: TextSelection.collapsed(offset: document.content.length),
      );

      debugPrint('Controller updated, text length: ${_controller.text.length}');

      // Trigger rebuild
      setState(() {});

      _focusNode.requestFocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opened: ${result.files.first.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAs() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Document As',
      fileName: 'untitled.md',
      type: FileType.custom,
      allowedExtensions: ['md'],
    );

    if (path == null) return;

    try {
      final document = context.read<DocumentProvider>();
      await document.saveAs(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: ${path.split('\\').last}.md'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _checkAndAnalyze() {
    final document = context.read<DocumentProvider>();
    final analyzer = context.read<SceneAnalyzerProvider>();

    // Don't analyze if already analyzing
    if (analyzer.isAnalyzing) return;

    final now = DateTime.now();
    final currentWordCount = document.wordCount;

    // Conditions for automatic analysis:
    // 1. User has stopped typing for 5 seconds
    // 2. At least 50 words have been added since last analysis
    // 3. At least 30 seconds since last analysis

    final shouldAnalyze = _lastEditTime != null &&
        now.difference(_lastEditTime!).inSeconds >= 5 &&
        (currentWordCount - _lastAnalyzedWordCount).abs() >= 50 &&
        (_lastAnalysisTime == null || now.difference(_lastAnalysisTime!).inSeconds >= 30);

    if (shouldAnalyze) {
      _performAnalysis();
    }
  }

  void _analyzeCurrentScene() {
    // Force analysis immediately (triggered by Ctrl+A)
    _performAnalysis();
  }

  void _performAnalysis() {
    final document = context.read<DocumentProvider>();
    final analyzer = context.read<SceneAnalyzerProvider>();

    // Extract current scene based on cursor position
    final cursorPosition = _controller.selection.baseOffset;
    debugPrint('=== _performAnalysis called ===');
    debugPrint('Cursor position: $cursorPosition');
    debugPrint('Full document length: ${document.content.length}');
    debugPrint('Document word count: ${document.wordCount}');

    final sceneText = analyzer.extractCurrentScene(document.content, cursorPosition);

    debugPrint('Extracted scene length: ${sceneText.length}');
    debugPrint('Scene word count: ${sceneText.trim().isEmpty ? 0 : sceneText.trim().split(RegExp(r'\s+')).length}');
    debugPrint('Scene preview (first 200 chars): ${sceneText.substring(0, sceneText.length > 200 ? 200 : sceneText.length)}');

    if (sceneText.isNotEmpty) {
      // Start analysis
      analyzer.analyzeScene(sceneText);

      // Update tracking variables
      _lastAnalyzedWordCount = document.wordCount;
      _lastAnalysisTime = DateTime.now();
    } else {
      debugPrint('ERROR: sceneText is empty, analysis skipped');
    }
  }

  void _replaceCurrentMatch(String searchText, String replaceText) {
    if (searchText.isEmpty) return;

    final document = context.read<DocumentProvider>();
    final selection = _controller.selection;

    // Check if current selection matches the search text
    if (selection.isValid && selection.start != selection.end) {
      final selectedText = document.content.substring(selection.start, selection.end);

      if (selectedText.toLowerCase() == searchText.toLowerCase()) {
        // Replace the selected text
        final newText = document.content.replaceRange(
          selection.start,
          selection.end,
          replaceText,
        );

        // Update controller and document
        final newCursorPos = selection.start + replaceText.length;
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursorPos),
        );

        document.updateContent(newText, newCursorPos);

        // Update search highlighting
        _controller.updateSearchText(searchText);

        setState(() {});
      }
    }
  }

  void _replaceAllMatches(String searchText, String replaceText) {
    if (searchText.isEmpty) return;

    final document = context.read<DocumentProvider>();
    final searchLower = searchText.toLowerCase();
    final contentLower = document.content.toLowerCase();

    // Find all matches
    final matches = searchLower.allMatches(contentLower).toList();

    if (matches.isEmpty) return;

    // Replace all matches (work backwards to maintain correct indices)
    String newText = document.content;
    for (int i = matches.length - 1; i >= 0; i--) {
      final match = matches[i];
      newText = newText.replaceRange(match.start, match.end, replaceText);
    }

    // Update controller and document
    final newCursorPos = _controller.selection.baseOffset;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    document.updateContent(newText, newCursorPos);

    // Clear search highlighting since there are no more matches
    _controller.updateSearchText('');

    setState(() {
      _searchText = '';
    });

    // Show feedback to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Replaced ${matches.length} occurrence${matches.length == 1 ? '' : 's'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final document = context.watch<DocumentProvider>();
    final theme = Theme.of(context);

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: Scaffold(
        body: Row(
          children: [
            // Main editor area
            Expanded(
              child: Column(
                children: [
                  // Bubble chart at the top
                  if (!_isFullscreen)
                    StructureBubbleChart(
                      documentContent: document.content,
                      onNavigate: (position) {
                        // Navigate to the position
                        _controller.selection = TextSelection.collapsed(offset: position);
                        _focusNode.requestFocus();

                        // Scroll to the position
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            final text = document.content.substring(0, position);
                            final lineCount = '\n'.allMatches(text).length;

                            // Get viewport height
                            final viewportHeight = _scrollController.position.viewportDimension;

                            // Estimate line height
                            final theme = Theme.of(context);
                            final fontSize = theme.textTheme.bodyLarge?.fontSize ?? 18.0;
                            final lineHeight = fontSize * 1.5;

                            // Calculate position
                            final targetPosition = lineCount * lineHeight;

                            // Center it vertically in viewport
                            final scrollTo = (targetPosition - (viewportHeight / 2)).clamp(
                              0.0,
                              _scrollController.position.maxScrollExtent
                            );

                            _scrollController.animateTo(
                              scrollTo,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        });
                      },
                    ),

                  // Editor area
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        maxLines: null,
                        expands: true,
                        textAlign: TextAlign.left,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: settings.focusMode
                              ? theme.primaryColor.withOpacity(settings.focusIntensity)
                              : theme.primaryColor,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Start writing...',
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (text) {
                          final cursorPos = _controller.selection.baseOffset;

                          // Update document content immediately to preserve cursor position
                          document.updateContent(text, cursorPos);

                          // Track edit time for automatic analysis
                          _lastEditTime = DateTime.now();
                        },
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      ),
                    ),
                  ),

                  // Focus mode overlay - highlights current sentence
                  if (settings.focusMode)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _buildFocusOverlay(document, settings, theme),
                      ),
                    ),

                  // Find dialog
                  if (_showFindDialog)
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FindDialog(
                          key: const ValueKey('find_dialog'),
                          initialSearchText: '',
                          documentContent: document.content,
                          onSearch: (searchText) {
                            setState(() {
                              _searchText = searchText;
                              _controller.updateSearchText(searchText);
                            });
                          },
                          onReplace: (searchText, replaceText) {
                            _replaceCurrentMatch(searchText, replaceText);
                          },
                          onReplaceAll: (searchText, replaceText) {
                            _replaceAllMatches(searchText, replaceText);
                          },
                          onNavigateToMatch: (start, end, searchFocusNode) {
                            // Update text selection to highlight the found text
                            _controller.selection = TextSelection(
                              baseOffset: start,
                              extentOffset: end,
                            );

                            // Give focus to TextField to show selection and trigger scroll
                            _focusNode.requestFocus();

                            // Calculate scroll position to center the match vertically
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_scrollController.hasClients) {
                                final text = document.content.substring(0, start);
                                final lineCount = '\n'.allMatches(text).length;

                                // Get viewport height
                                final viewportHeight = _scrollController.position.viewportDimension;

                                // Estimate line height (using theme settings)
                                final theme = Theme.of(context);
                                final fontSize = theme.textTheme.bodyLarge?.fontSize ?? 18.0;
                                final lineHeight = fontSize * 1.5; // Approximate line height

                                // Calculate position of the matched text
                                final matchPosition = lineCount * lineHeight;

                                // Center it vertically in viewport
                                final scrollTo = (matchPosition - (viewportHeight / 2)).clamp(
                                  0.0,
                                  _scrollController.position.maxScrollExtent
                                );

                                _scrollController.animateTo(
                                  scrollTo,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );

                                // Return focus to search field after a brief delay
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  if (_showFindDialog && mounted) {
                                    // Explicitly request focus back to the search field
                                    searchFocusNode.requestFocus();
                                  }
                                });
                              }
                            });
                          },
                          onClose: () {
                            setState(() {
                              _showFindDialog = false;
                              _searchText = '';
                              _controller.updateSearchText('');
                            });
                            _focusNode.requestFocus();
                          },
                        ),
                      ),
                    ),

                  // Word count overlay
                  if (_showWordCount)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: WordCountOverlay(
                        wordCount: document.wordCount,
                        onClose: () => setState(() => _showWordCount = false),
                      ),
                    ),

                  // File menu (shown on Escape key)
                  if (_showFileMenu)
                    Positioned(
                      top: 20,
                      left: 20,
                      child: FileMenu(
                        onClose: () {
                          setState(() {
                            _showFileMenu = false;
                          });
                        },
                      ),
                    ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right margin - Scene info panel (always visible)
            if (!_isFullscreen)
              Container(
                width: 340,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.grey[50],
                  border: Border(
                    left: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: SceneInfoPanel(
                  onClose: () {}, // No close button needed for margin
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusOverlay(DocumentProvider document, AppSettingsProvider settings, ThemeData theme) {
    return CustomPaint(
      painter: FocusModePainter(
        focusStart: document.focusStart,
        focusEnd: document.focusEnd,
        fullText: document.content,
        textStyle: theme.textTheme.bodyLarge!,
        normalOpacity: settings.focusIntensity,
        focusOpacity: 1.0,
      ),
    );
  }

}

class FocusModePainter extends CustomPainter {
  final int focusStart;
  final int focusEnd;
  final String fullText;
  final TextStyle textStyle;
  final double normalOpacity;
  final double focusOpacity;

  FocusModePainter({
    required this.focusStart,
    required this.focusEnd,
    required this.fullText,
    required this.textStyle,
    required this.normalOpacity,
    required this.focusOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // This is a simplified version - in production you'd want to
    // calculate exact text positions and overlay dims
  }

  @override
  bool shouldRepaint(FocusModePainter oldDelegate) {
    return focusStart != oldDelegate.focusStart ||
           focusEnd != oldDelegate.focusEnd ||
           normalOpacity != oldDelegate.normalOpacity;
  }
}

class _SearchableTextEditingController extends TextEditingController {
  String _searchText = '';

  _SearchableTextEditingController({String? text}) : super(text: text);

  void updateSearchText(String searchText) {
    _searchText = searchText;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_searchText.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final List<TextSpan> spans = [];
    final String searchLower = _searchText.toLowerCase();
    final String textLower = text.toLowerCase();

    int lastMatchEnd = 0;
    int matchCount = 0;
    const maxMatches = 50; // Limit matches to prevent performance issues

    for (final match in searchLower.allMatches(textLower)) {
      if (matchCount >= maxMatches) break; // Stop after 50 matches

      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }

      // Add the matched text with yellow color
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style?.copyWith(
          color: Colors.amber.shade700,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastMatchEnd = match.end;
      matchCount++;
    }

    // Add remaining text after the last match
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: style,
      ));
    }

    return TextSpan(children: spans, style: style);
  }
}
