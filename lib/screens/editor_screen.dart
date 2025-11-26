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

class EditorScreen extends StatefulWidget {
  const EditorScreen({Key? key}) : super(key: key);

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showWordCount = false;
  bool _showFileMenu = false;
  bool _isFullscreen = false;

  int _lastAnalyzedWordCount = 0;
  DateTime? _lastEditTime;
  DateTime? _lastAnalysisTime;

  @override
  void initState() {
    super.initState();
    final docProvider = context.read<DocumentProvider>();
    final settingsProvider = context.read<AppSettingsProvider>();

    // Initialize controller with current content
    _controller.text = docProvider.content;
    _controller.addListener(_onControllerChanged);

    docProvider.startAutoSave(settingsProvider.autoSaveInterval);

    // Request focus on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // Cmd/Ctrl + F : Toggle focus mode
    else if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyF) {
      context.read<AppSettingsProvider>().toggleFocusMode();
    }
    // Cmd/Ctrl + Shift + W : Toggle word count
    else if (isCtrlOrCmd && event.isShiftPressed && event.logicalKey == LogicalKeyboardKey.keyW) {
      setState(() {
        _showWordCount = !_showWordCount;
      });
    }
    // Cmd/Ctrl + A : Analyze scene
    else if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyA) {
      _analyzeCurrentScene();
    }
    // F11 : Toggle fullscreen
    else if (event.logicalKey == LogicalKeyboardKey.f11) {
      _toggleFullscreen();
    }
    // Escape : Toggle file menu (or exit fullscreen)
    else if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isFullscreen) {
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
    final sceneText = analyzer.extractCurrentScene(document.content, cursorPosition);

    if (sceneText.isNotEmpty) {
      // Start analysis
      analyzer.analyzeScene(sceneText);

      // Update tracking variables
      _lastAnalyzedWordCount = document.wordCount;
      _lastAnalysisTime = DateTime.now();
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
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
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
                          document.updateContent(text, cursorPos);
                          // Track edit time for automatic analysis
                          setState(() {
                            _lastEditTime = DateTime.now();
                          });
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
                      child: FileMenu(),
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
