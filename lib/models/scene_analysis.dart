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
  final List<String> hunches;
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
    this.hunches = const [],
    required this.analyzedAt,
  });

  factory SceneAnalysis.fromJson(Map<String, dynamic> json) {
    return SceneAnalysis(
      characters: (json['characters'] as List?)?.cast<String>() ?? [],
      setting: json['setting'] as String?,
      timeOfDay: json['time_of_day'] as String?,
      pov: json['pov'] as String?,
      tone: json['tone'] as String?,
      dialoguePercentage: json['dialogue_percentage'] as int?,
      wordCount: json['word_count'] as int? ?? 0,
      echoWords: (json['echo_words'] as List?)?.cast<String>() ?? [],
      senses: (json['senses'] as List?)?.cast<String>() ?? [],
      stakes: json['stakes'] as String?,
      hunches: (json['hunches'] as List?)?.cast<String>() ?? [],
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
      'hunches': hunches,
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
