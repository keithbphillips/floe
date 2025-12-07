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

    // Safe string extraction - handles cases where AI returns list instead of string
    String? extractString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) {
        // If AI returned a list, join it or take first element
        return value.first.toString();
      }
      return value.toString();
    }

    // Safe list extraction - handles cases where AI returns string instead of list
    List<String> extractStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        // If AI returned a single string instead of list, wrap it
        return [value];
      }
      return [];
    }

    return SceneAnalysis(
      characters: extractStringList(json['characters']),
      setting: extractString(json['setting']),
      timeOfDay: extractString(json['time_of_day']),
      pov: extractString(json['pov']),
      tone: extractString(json['tone']),
      dialoguePercentage: json['dialogue_percentage'] as int?,
      wordCount: json['word_count'] as int? ?? 0,
      echoWords: processEchoWords(json['echo_words'] as List?),
      senses: extractStringList(json['senses']),
      stakes: extractString(json['stakes']),
      structure: extractString(json['structure']),
      hunches: extractStringList(json['hunches']),
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

  /// Generate JSON Schema for structured outputs
  /// This schema enforces the exact structure we expect from the LLM
  static Map<String, dynamic> getJsonSchema() {
    return {
      "type": "object",
      "properties": {
        "characters": {
          "type": "array",
          "description": "List of character names present in the scene",
          "items": {"type": "string"}
        },
        "setting": {
          "type": "string",
          "description": "Physical location where the scene takes place"
        },
        "time_of_day": {
          "type": "string",
          "description": "Time of day: morning, afternoon, evening, night, or unknown"
        },
        "pov": {
          "type": "string",
          "description": "Point of view character name or 'unknown'"
        },
        "tone": {
          "type": "string",
          "description": "Brief emotional tone in 1-2 words"
        },
        "dialogue_percentage": {
          "type": "integer",
          "description": "Estimated percentage of dialogue (0-100)"
        },
        "word_count": {
          "type": "integer",
          "description": "Total word count of the scene"
        },
        "echo_words": {
          "type": "array",
          "description": "Words that repeat within close proximity creating unintended rhythmic echo",
          "items": {"type": "string"}
        },
        "senses": {
          "type": "array",
          "description": "Which senses are engaged in the scene",
          "items": {
            "type": "string",
            "enum": ["sight", "sound", "touch", "taste", "smell"]
          }
        },
        "stakes": {
          "type": "string",
          "description": "Brief description of what is at risk in the scene"
        },
        "structure": {
          "type": "string",
          "description": "Evaluation of scene structure and story arc (2-3 sentences max)"
        },
        "hunches": {
          "type": "array",
          "description": "2-3 brief suggestions or observations about the scene",
          "items": {"type": "string"}
        },
        "plot_threads": {
          "type": "array",
          "description": "Plot threads that appear in this scene",
          "items": {
            "type": "object",
            "properties": {
              "title": {
                "type": "string",
                "description": "Brief title for the plot thread (3-5 words)"
              },
              "description": {
                "type": "string",
                "description": "What happens with this thread in this scene (1-2 sentences)"
              },
              "action": {
                "type": "string",
                "enum": ["introduced", "advanced", "resolved"],
                "description": "How this thread is affected"
              },
              "type": {
                "type": "string",
                "enum": ["main_plot", "subplot", "character_arc", "mystery", "conflict", "relationship", "other"],
                "description": "Type of plot thread"
              }
            },
            "required": ["title", "description", "action", "type"],
            "additionalProperties": false
          }
        }
      },
      "required": [
        "characters",
        "setting",
        "time_of_day",
        "pov",
        "tone",
        "dialogue_percentage",
        "word_count",
        "echo_words",
        "senses",
        "stakes",
        "structure",
        "hunches",
        "plot_threads"
      ],
      "additionalProperties": false
    };
  }
}
