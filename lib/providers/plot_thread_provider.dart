import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plot_thread.dart';
import '../models/scene_analysis.dart';

class PlotThreadProvider extends ChangeNotifier {
  List<PlotThread> _threads = [];
  int _currentSceneNumber = 0;
  String? _currentDocumentPath;
  static const String _storageKeyPrefix = 'plot_threads_';
  static const String _sceneNumberKeyPrefix = 'scene_number_';

  // Track processed analysis timestamps to prevent duplicate processing
  final Set<String> _processedAnalysisIds = {};

  // Counter to ensure unique IDs even when created in the same millisecond
  int _threadIdCounter = 0;

  PlotThreadProvider() {
    // Don't load threads in constructor - wait for document to be set
  }

  List<PlotThread> get threads => _threads;
  int get currentSceneNumber => _currentSceneNumber;
  String? get currentDocumentPath => _currentDocumentPath;

  /// Get active threads (not resolved or abandoned)
  List<PlotThread> get activeThreads => _threads
      .where((t) =>
          t.status != PlotThreadStatus.resolved &&
          t.status != PlotThreadStatus.abandoned)
      .toList();

  /// Get threads by type
  List<PlotThread> getThreadsByType(PlotThreadType type) =>
      _threads.where((t) => t.type == type).toList();

  /// Get potentially abandoned threads (not mentioned in 10+ scenes)
  List<PlotThread> get potentiallyAbandonedThreads =>
      _threads.where((t) => t.isPotentiallyAbandoned(_currentSceneNumber)).toList();

  /// Set the current document path and load its threads
  Future<void> setDocumentPath(String? documentPath) async {
    // Save current document's threads before switching
    if (_currentDocumentPath != null) {
      await _saveThreads();
    }

    _currentDocumentPath = documentPath;
    await _loadThreads();
    notifyListeners();
  }

  /// Get storage key for current document
  String _getStorageKey() {
    if (_currentDocumentPath == null || _currentDocumentPath!.isEmpty) {
      return '${_storageKeyPrefix}untitled';
    }
    // Use base64 encoding of path to handle special characters
    final pathBytes = utf8.encode(_currentDocumentPath!);
    final encodedPath = base64Url.encode(pathBytes);
    return '$_storageKeyPrefix$encodedPath';
  }

  String _getSceneNumberKey() {
    if (_currentDocumentPath == null || _currentDocumentPath!.isEmpty) {
      return '${_sceneNumberKeyPrefix}untitled';
    }
    final pathBytes = utf8.encode(_currentDocumentPath!);
    final encodedPath = base64Url.encode(pathBytes);
    return '$_sceneNumberKeyPrefix$encodedPath';
  }

  Future<void> _loadThreads() async {
    final prefs = await SharedPreferences.getInstance();

    // Load threads for current document
    final threadsJson = prefs.getString(_getStorageKey());
    if (threadsJson != null) {
      final List<dynamic> threadsList = json.decode(threadsJson);
      _threads = threadsList
          .map((t) => PlotThread.fromJson(t as Map<String, dynamic>))
          .toList();
    } else {
      _threads = [];
    }

    // Load current scene number for this document
    _currentSceneNumber = prefs.getInt(_getSceneNumberKey()) ?? 0;
  }

  Future<void> _saveThreads() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _getStorageKey(),
      json.encode(_threads.map((t) => t.toJson()).toList()),
    );
    await prefs.setInt(_getSceneNumberKey(), _currentSceneNumber);
  }

  /// Process plot threads from a scene analysis
  /// [analysisId] is a unique identifier (timestamp) to prevent duplicate processing
  Future<void> processSceneThreads(List<PlotThreadMention> mentions, {String? analysisId}) async {
    // Generate analysis ID from mentions if not provided
    final id = analysisId ?? DateTime.now().toIso8601String();

    // Check if we've already processed this exact analysis
    if (_processedAnalysisIds.contains(id)) {
      debugPrint('⚠️  SKIPPING duplicate analysis processing: $id');
      return;
    }

    // Mark this analysis as processed
    _processedAnalysisIds.add(id);

    _currentSceneNumber++;
    debugPrint('=== Processing ${mentions.length} plot thread mentions (Scene #$_currentSceneNumber, ID: $id) ===');
    debugPrint('Existing threads (${_threads.length}): ${_threads.map((t) => '"${t.title}" (${_normalizeTitle(t.title)})').join(", ")}');

    for (final mention in mentions) {
      final normalizedMentionTitle = _normalizeTitle(mention.title);
      debugPrint('Processing mention: "${mention.title}" (normalized: "$normalizedMentionTitle")');

      // Try to find existing thread with matching normalized title
      final existing = _findMatchingThread(mention.title);

      if (existing != null) {
        debugPrint('→ UPDATING existing thread: "${existing.title}"');
        // Update existing thread
        _updateThread(existing, mention);
      } else {
        debugPrint('→ CREATING new thread: "${mention.title}"');
        // Create new thread
        _createThread(mention);
      }
    }

    debugPrint('After processing, total threads: ${_threads.length}');

    // Check for abandoned threads
    _updateAbandonedThreads();

    await _saveThreads();
    notifyListeners();
  }

  /// Find a matching thread by title
  /// Uses normalized title as the unique identifier - if titles match after normalization, they're the same thread
  PlotThread? _findMatchingThread(String title) {
    final titleNormalized = _normalizeTitle(title);

    // Exact match after normalization is the ONLY way to match
    // This prevents any fuzzy matching confusion
    for (final thread in _threads) {
      final threadNormalized = _normalizeTitle(thread.title);
      if (threadNormalized == titleNormalized) {
        debugPrint('✓ MATCHED: "${thread.title}" == "$title" (normalized: "$threadNormalized")');
        return thread;
      }
    }

    debugPrint('✗ NO MATCH: "$title" (normalized: "$titleNormalized")');
    debugPrint('  Existing threads: ${_threads.map((t) => _normalizeTitle(t.title)).join(", ")}');
    return null;
  }

  /// Normalize a title for comparison
  /// Converts to lowercase, removes possessives, punctuation, extra spaces, and handles singular/plural
  /// This is the SOLE determinant of whether two threads are the same
  String _normalizeTitle(String title) {
    var normalized = title
        .toLowerCase()                        // Case insensitive
        .replaceAll("'s", '')                 // Remove possessives (e.g., "Varathon's" -> "Varathon")
        .replaceAll("'", '')                  // Remove apostrophes
        .replaceAll(RegExp(r'[^\w\s]'), '')   // Remove all punctuation
        .replaceAll(RegExp(r'\s+'), ' ')      // Normalize whitespace
        .trim();

    // Handle common singular/plural variations
    // Convert common plural forms to singular for matching
    // This prevents "Mystery" and "Mysteries" or "Phenomenon" and "Phenomena" from being treated as different
    if (normalized.endsWith('ies')) {
      // mysteries -> mystery, skies -> sky
      normalized = normalized.substring(0, normalized.length - 3) + 'y';
    } else if (normalized.endsWith('phenomena')) {
      // phenomena -> phenomenon
      normalized = normalized.substring(0, normalized.length - 8) + 'phenomenon';
    } else if (normalized.endsWith('ves')) {
      // wolves -> wolf, lives -> life
      normalized = normalized.substring(0, normalized.length - 3) + 'f';
    } else if (normalized.endsWith('ses')) {
      // crises -> crisis
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.endsWith('s') && !normalized.endsWith('ss')) {
      // fires -> fire, threads -> thread (but not glass -> glas)
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// Create a new thread from a mention
  void _createThread(PlotThreadMention mention) {
    // Generate unique ID by combining timestamp with counter
    final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_${_threadIdCounter++}';

    final thread = PlotThread(
      id: uniqueId,
      title: mention.title,
      description: mention.description,
      type: _parseThreadType(mention.type),
      status: mention.action == 'resolved'
          ? PlotThreadStatus.resolved
          : PlotThreadStatus.introduced,
      introducedAtScene: _currentSceneNumber,
      lastMentionedAtScene: _currentSceneNumber,
      sceneAppearances: [_currentSceneNumber],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    debugPrint('   Thread count BEFORE create: ${_threads.length}');
    debugPrint('   Creating new thread ID: ${thread.id}, title: "${thread.title}"');
    _threads.add(thread);
    debugPrint('   Thread count AFTER create: ${_threads.length}');
    debugPrint('   All thread IDs after create: ${_threads.map((t) => '${t.id}:"${t.title}"').join(", ")}');
  }

  /// Update an existing thread with new mention
  void _updateThread(PlotThread existing, PlotThreadMention mention) {
    PlotThreadStatus newStatus = existing.status;

    if (mention.action == 'resolved') {
      newStatus = PlotThreadStatus.resolved;
    } else if (mention.action == 'advanced') {
      newStatus = PlotThreadStatus.developing;
    }

    final updatedThread = existing.copyWith(
      description: mention.description, // Update with latest description
      status: newStatus,
      lastMentionedAtScene: _currentSceneNumber,
      sceneAppearances: [...existing.sceneAppearances, _currentSceneNumber],
      updatedAt: DateTime.now(),
    );

    debugPrint('   Thread count BEFORE update: ${_threads.length}');
    debugPrint('   Updating thread ID: ${existing.id}, title: "${existing.title}"');
    final oldCount = _threads.length;
    _threads = _threads.map((t) => t.id == existing.id ? updatedThread : t).toList();
    debugPrint('   Thread count AFTER update: ${_threads.length}');
    if (_threads.length != oldCount) {
      debugPrint('   ❌ WARNING: Thread count changed during update! $oldCount → ${_threads.length}');
    }
    debugPrint('   All thread IDs after update: ${_threads.map((t) => '${t.id}:"${t.title}"').join(", ")}');
  }

  /// Mark threads as abandoned if not mentioned recently
  void _updateAbandonedThreads() {
    _threads = _threads.map((thread) {
      if (thread.isPotentiallyAbandoned(_currentSceneNumber)) {
        return thread.copyWith(
          status: PlotThreadStatus.abandoned,
          updatedAt: DateTime.now(),
        );
      }
      return thread;
    }).toList();
  }

  /// Manually update a thread's status
  Future<void> updateThreadStatus(String threadId, PlotThreadStatus status) async {
    _threads = _threads.map((t) {
      if (t.id == threadId) {
        return t.copyWith(status: status, updatedAt: DateTime.now());
      }
      return t;
    }).toList();

    await _saveThreads();
    notifyListeners();
  }

  /// Delete a thread
  Future<void> deleteThread(String threadId) async {
    _threads = _threads.where((t) => t.id != threadId).toList();
    await _saveThreads();
    notifyListeners();
  }

  /// AI-powered thread consolidation
  /// Analyzes all threads and removes duplicates/non-threads, merges similar ones
  Future<Map<String, dynamic>> consolidateThreadsWithAI(dynamic aiService) async {
    if (_threads.isEmpty) {
      return {'removed': 0, 'merged': 0, 'kept': _threads.length};
    }

    debugPrint('=== Starting AI thread consolidation for ${_threads.length} threads ===');

    // Convert threads to simple maps for AI analysis
    final threadData = _threads.map((t) => {
      'title': t.title,
      'description': t.description,
      'type': t.type.name,
      'status': t.status.name,
      'sceneAppearances': t.sceneAppearances,
    }).toList();

    // Call AI service
    final result = await aiService.consolidateThreads(threadData);
    if (result == null) {
      debugPrint('AI consolidation failed');
      return {'error': 'AI consolidation failed', 'removed': 0, 'merged': 0, 'kept': _threads.length};
    }

    int removedCount = 0;
    int mergedCount = 0;
    final List<String> toRemove = [];
    final Map<String, String> mergeMap = {}; // old title -> new title

    // Process AI recommendations
    final actions = result['actions'] as List<dynamic>?;
    if (actions == null) {
      debugPrint('No actions returned from AI');
      return {'error': 'No actions returned', 'removed': 0, 'merged': 0, 'kept': _threads.length};
    }

    for (final action in actions) {
      final threadTitle = action['thread_title'] as String;
      final actionType = action['action'] as String;
      final reason = action['reason'] as String;

      debugPrint('Action for "$threadTitle": $actionType - $reason');

      if (actionType == 'remove') {
        final thread = _threads.where((t) => t.title == threadTitle).firstOrNull;
        if (thread != null) {
          toRemove.add(thread.id);
          removedCount++;
        }
      } else if (actionType == 'merge') {
        final mergeInto = action['merge_into'] as String?;
        if (mergeInto != null) {
          mergeMap[threadTitle] = mergeInto;
          mergedCount++;
        }
      }
    }

    // Remove threads marked for deletion
    _threads = _threads.where((t) => !toRemove.contains(t.id)).toList();

    // Process merges
    final Map<String, PlotThread> mergedThreads = {};
    final List<String> processedTitles = [];

    for (final thread in _threads.toList()) {
      if (processedTitles.contains(thread.title)) continue;

      // Check if this thread should be merged into another
      String finalTitle = thread.title;
      if (mergeMap.containsKey(thread.title)) {
        finalTitle = mergeMap[thread.title]!;
      }

      // Find all threads that should merge into this title
      final threadsToMerge = _threads.where((t) =>
        t.title == finalTitle || mergeMap[t.title] == finalTitle
      ).toList();

      if (threadsToMerge.length > 1) {
        // Merge all appearances
        final allAppearances = threadsToMerge
          .expand((t) => t.sceneAppearances)
          .toSet()
          .toList()
          ..sort();

        final latestThread = threadsToMerge.reduce((a, b) =>
          a.lastMentionedAtScene > b.lastMentionedAtScene ? a : b
        );

        mergedThreads[finalTitle] = latestThread.copyWith(
          title: finalTitle,
          sceneAppearances: allAppearances,
          lastMentionedAtScene: allAppearances.last,
          updatedAt: DateTime.now(),
        );

        processedTitles.addAll(threadsToMerge.map((t) => t.title));
      } else if (!mergedThreads.containsKey(finalTitle)) {
        mergedThreads[finalTitle] = thread;
        processedTitles.add(thread.title);
      }
    }

    _threads = mergedThreads.values.toList();

    await _saveThreads();
    notifyListeners();

    debugPrint('Consolidation complete: removed=$removedCount, merged=$mergedCount, final count=${_threads.length}');

    return {
      'removed': removedCount,
      'merged': mergedCount,
      'kept': _threads.length,
    };
  }

  /// Manually merge two threads
  Future<void> mergeThreads(String keepId, String removeId) async {
    final keep = _threads.firstWhere((t) => t.id == keepId);
    final remove = _threads.firstWhere((t) => t.id == removeId);

    // Merge scene appearances
    final mergedAppearances = {...keep.sceneAppearances, ...remove.sceneAppearances}.toList()
      ..sort();

    final mergedThread = keep.copyWith(
      sceneAppearances: mergedAppearances,
      lastMentionedAtScene: [keep.lastMentionedAtScene, remove.lastMentionedAtScene]
          .reduce((a, b) => a > b ? a : b),
      updatedAt: DateTime.now(),
    );

    _threads = _threads.where((t) => t.id != removeId).map((t) {
      return t.id == keepId ? mergedThread : t;
    }).toList();

    await _saveThreads();
    notifyListeners();
  }

  /// Clear all threads for the current document
  Future<void> clearAllThreads() async {
    _threads = [];
    _currentSceneNumber = 0;
    await _saveThreads();
    notifyListeners();
  }

  /// Clear threads for a specific document (by path)
  Future<void> clearThreadsForDocument(String documentPath) async {
    final prefs = await SharedPreferences.getInstance();
    final pathBytes = utf8.encode(documentPath);
    final encodedPath = base64Url.encode(pathBytes);
    await prefs.remove('$_storageKeyPrefix$encodedPath');
    await prefs.remove('$_sceneNumberKeyPrefix$encodedPath');

    // If this is the current document, also clear memory
    if (documentPath == _currentDocumentPath) {
      _threads = [];
      _currentSceneNumber = 0;
      notifyListeners();
    }
  }

  /// Parse thread type from string
  PlotThreadType _parseThreadType(String type) {
    switch (type.toLowerCase()) {
      case 'main_plot':
        return PlotThreadType.mainPlot;
      case 'subplot':
        return PlotThreadType.subplot;
      case 'character_arc':
        return PlotThreadType.characterArc;
      case 'mystery':
        return PlotThreadType.mystery;
      case 'conflict':
        return PlotThreadType.conflict;
      case 'relationship':
        return PlotThreadType.relationship;
      default:
        return PlotThreadType.other;
    }
  }
}
