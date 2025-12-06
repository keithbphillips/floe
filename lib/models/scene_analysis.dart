import 'package:flutter/foundation.dart';

/// Represents a plot thread detected in a scene
class PlotThreadMention {
  final String title;
  final String description;
  final String action; // 'introduced', 'advanced', 'resolved'
  final String type; // 'main_plot', 'subplot', 'character_arc', 'mystery', 'conflict', 'relationship', 'other'

  const PlotThreadMention({
    required this.title,
    required this.description,
    required this.action,
    required this.type,
  });

  factory PlotThreadMention.fromJson(Map<String, dynamic> json) {
    return PlotThreadMention(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      action: json['action'] ?? 'advanced',
      type: json['type'] ?? 'other',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'action': action,
      'type': type,
    };
  }
}

class SceneAnalysis {
  final List<String> characters;
  final String? setting;
  final String? timeOfDay;
  final String? pov;
  final String? tone;
  final int? dialoguePercentage;
  final int wordCount;
  final List<String> echoWords;
  final List<String> senses;
  final String? stakes;
  final String? structure;
  final List<String> hunches;
  final List<PlotThreadMention> plotThreads;
  final DateTime analyzedAt;

  const SceneAnalysis({
    this.characters = const [],
    this.setting,
    this.timeOfDay,
    this.pov,
    this.tone,
    this.dialoguePercentage,
    required this.wordCount,
    this.echoWords = const [],
    this.senses = const [],
    this.stakes,
    this.structure,
    this.hunches = const [],
    this.plotThreads = const [],
    required this.analyzedAt,
  });

  factory SceneAnalysis.fromJson(Map<String, dynamic> json) {
    // Process echo words - if LLM returns phrases, split them into individual words
    List<String> processEchoWords(List<dynamic>? rawEchoWords) {
      if (rawEchoWords == null) {
        debugPrint('processEchoWords: rawEchoWords is null');
        return [];
      }

      debugPrint('processEchoWords: processing $rawEchoWords');
      // Simply return the words as-is from the LLM, trust it to return individual words
      final result = rawEchoWords.map((e) => e.toString().toLowerCase().trim()).where((w) => w.isNotEmpty).toList();
      debugPrint('processEchoWords: result = $result');
      return result;
    }

    return SceneAnalysis(
      characters: (json['characters'] as List?)?.cast<String>() ?? [],
      setting: json['setting'] as String?,
      timeOfDay: json['time_of_day'] as String?,
      pov: json['pov'] as String?,
      tone: json['tone'] as String?,
      dialoguePercentage: json['dialogue_percentage'] as int?,
      wordCount: json['word_count'] as int? ?? 0,
      echoWords: processEchoWords(json['echo_words'] as List?),
      senses: (json['senses'] as List?)?.cast<String>() ?? [],
      stakes: json['stakes'] as String?,
      structure: json['structure'] as String?,
      hunches: (json['hunches'] as List?)?.cast<String>() ?? [],
      plotThreads: (json['plot_threads'] as List?)
              ?.map((e) => PlotThreadMention.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      analyzedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'characters': characters,
      'setting': setting,
      'time_of_day': timeOfDay,
      'pov': pov,
      'tone': tone,
      'dialogue_percentage': dialoguePercentage,
      'word_count': wordCount,
      'echo_words': echoWords,
      'senses': senses,
      'stakes': stakes,
      'structure': structure,
      'hunches': hunches,
      'plot_threads': plotThreads.map((t) => t.toJson()).toList(),
    };
  }

  /// Get typical scene length category
  String get lengthCategory {
    if (wordCount < 500) return 'Brief';
    if (wordCount < 1500) return 'Typical';
    if (wordCount < 2500) return 'Substantial';
    return 'Long';
  }

  /// Get dialogue/narrative balance description
  String get dialogueBalance {
    if (dialoguePercentage == null) return 'Unknown';
    if (dialoguePercentage! < 20) return 'Mostly narrative';
    if (dialoguePercentage! < 40) return 'Narrative-heavy';
    if (dialoguePercentage! < 60) return 'Balanced';
    if (dialoguePercentage! < 80) return 'Dialogue-heavy';
    return 'Mostly dialogue';
  }
}
