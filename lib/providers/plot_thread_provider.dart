import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plot_thread.dart';
import '../models/scene_analysis.dart';

class PlotThreadProvider extends ChangeNotifier {
  List<PlotThread> _threads = [];
  int _currentSceneNumber = 0;
  static const String _storageKey = 'plot_threads';
  static const String _sceneNumberKey = 'current_scene_number';

  PlotThreadProvider() {
    _loadThreads();
  }

  List<PlotThread> get threads => _threads;
  int get currentSceneNumber => _currentSceneNumber;

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

  Future<void> _loadThreads() async {
    final prefs = await SharedPreferences.getInstance();

    // Load threads
    final threadsJson = prefs.getString(_storageKey);
    if (threadsJson != null) {
      final List<dynamic> threadsList = json.decode(threadsJson);
      _threads = threadsList
          .map((t) => PlotThread.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    // Load current scene number
    _currentSceneNumber = prefs.getInt(_sceneNumberKey) ?? 0;

    notifyListeners();
  }

  Future<void> _saveThreads() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      json.encode(_threads.map((t) => t.toJson()).toList()),
    );
    await prefs.setInt(_sceneNumberKey, _currentSceneNumber);
  }

  /// Process plot threads from a scene analysis
  Future<void> processSceneThreads(List<PlotThreadMention> mentions) async {
    _currentSceneNumber++;

    for (final mention in mentions) {
      // Try to find existing thread with similar title
      final existing = _findMatchingThread(mention.title);

      if (existing != null) {
        // Update existing thread
        _updateThread(existing, mention);
      } else {
        // Create new thread
        _createThread(mention);
      }
    }

    // Check for abandoned threads
    _updateAbandonedThreads();

    await _saveThreads();
    notifyListeners();
  }

  /// Find a matching thread by title (fuzzy match)
  PlotThread? _findMatchingThread(String title) {
    final titleLower = title.toLowerCase();

    // First try exact match
    for (final thread in _threads) {
      if (thread.title.toLowerCase() == titleLower) {
        return thread;
      }
    }

    // Then try partial match (for threads with similar names)
    for (final thread in _threads) {
      if (thread.title.toLowerCase().contains(titleLower) ||
          titleLower.contains(thread.title.toLowerCase())) {
        return thread;
      }
    }

    return null;
  }

  /// Create a new thread from a mention
  void _createThread(PlotThreadMention mention) {
    final thread = PlotThread(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

    _threads.add(thread);
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

    _threads = _threads.map((t) => t.id == existing.id ? updatedThread : t).toList();
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

  /// Clear all threads (for testing or resetting)
  Future<void> clearAllThreads() async {
    _threads = [];
    _currentSceneNumber = 0;
    await _saveThreads();
    notifyListeners();
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
