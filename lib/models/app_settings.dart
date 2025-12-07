class AppSettings {
  final bool isDarkMode;
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final bool focusMode;
  final double focusIntensity;
  final int autoSaveInterval; // in seconds
  final String aiProvider; // 'ollama' or 'openai'
  final String ollamaModel;
  final String openAiApiKey;
  final String openAiModel;
  final int chapterBubbleColorLight; // ARGB color value
  final int chapterBubbleColorDark; // ARGB color value
  final int sceneBubbleColorLight; // ARGB color value
  final int sceneBubbleColorDark; // ARGB color value
  // Analysis field visibility toggles
  final bool showCharacters;
  final bool showSetting;
  final bool showTimeOfDay;
  final bool showPov;
  final bool showTone;
  final bool showStakes;
  final bool showStructure;
  final bool showSenses;
  final bool showDialoguePercentage;
  final bool showEchoWords;
  final bool showWordCount;
  final bool showHunches;

  const AppSettings({
    this.isDarkMode = false,
    this.fontFamily = 'Lora',
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.focusMode = false,
    this.focusIntensity = 0.3,
    this.autoSaveInterval = 3,
    this.aiProvider = 'ollama',
    this.ollamaModel = 'llama3.2:3b',
    this.openAiApiKey = '',
    this.openAiModel = 'gpt-4o-mini',
    this.chapterBubbleColorLight = 0xFF1976D2, // Colors.blue[600]
    this.chapterBubbleColorDark = 0xFF42A5F5, // Colors.blue[400]
    this.sceneBubbleColorLight = 0xFFFFB300, // Colors.amber[600]
    this.sceneBubbleColorDark = 0xFFFFA726, // Colors.amber[700]
    // Default all analysis fields to visible
    this.showCharacters = true,
    this.showSetting = true,
    this.showTimeOfDay = true,
    this.showPov = true,
    this.showTone = true,
    this.showStakes = true,
    this.showStructure = true,
    this.showSenses = true,
    this.showDialoguePercentage = true,
    this.showEchoWords = true,
    this.showWordCount = true,
    this.showHunches = true,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    bool? focusMode,
    double? focusIntensity,
    int? autoSaveInterval,
    String? aiProvider,
    String? ollamaModel,
    String? openAiApiKey,
    String? openAiModel,
    int? chapterBubbleColorLight,
    int? chapterBubbleColorDark,
    int? sceneBubbleColorLight,
    int? sceneBubbleColorDark,
    bool? showCharacters,
    bool? showSetting,
    bool? showTimeOfDay,
    bool? showPov,
    bool? showTone,
    bool? showStakes,
    bool? showStructure,
    bool? showSenses,
    bool? showDialoguePercentage,
    bool? showEchoWords,
    bool? showWordCount,
    bool? showHunches,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      focusMode: focusMode ?? this.focusMode,
      focusIntensity: focusIntensity ?? this.focusIntensity,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      aiProvider: aiProvider ?? this.aiProvider,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
      openAiModel: openAiModel ?? this.openAiModel,
      chapterBubbleColorLight: chapterBubbleColorLight ?? this.chapterBubbleColorLight,
      chapterBubbleColorDark: chapterBubbleColorDark ?? this.chapterBubbleColorDark,
      sceneBubbleColorLight: sceneBubbleColorLight ?? this.sceneBubbleColorLight,
      sceneBubbleColorDark: sceneBubbleColorDark ?? this.sceneBubbleColorDark,
      showCharacters: showCharacters ?? this.showCharacters,
      showSetting: showSetting ?? this.showSetting,
      showTimeOfDay: showTimeOfDay ?? this.showTimeOfDay,
      showPov: showPov ?? this.showPov,
      showTone: showTone ?? this.showTone,
      showStakes: showStakes ?? this.showStakes,
      showStructure: showStructure ?? this.showStructure,
      showSenses: showSenses ?? this.showSenses,
      showDialoguePercentage: showDialoguePercentage ?? this.showDialoguePercentage,
      showEchoWords: showEchoWords ?? this.showEchoWords,
      showWordCount: showWordCount ?? this.showWordCount,
      showHunches: showHunches ?? this.showHunches,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'focusMode': focusMode,
      'focusIntensity': focusIntensity,
      'autoSaveInterval': autoSaveInterval,
      'aiProvider': aiProvider,
      'ollamaModel': ollamaModel,
      'openAiApiKey': openAiApiKey,
      'openAiModel': openAiModel,
      'chapterBubbleColorLight': chapterBubbleColorLight,
      'chapterBubbleColorDark': chapterBubbleColorDark,
      'sceneBubbleColorLight': sceneBubbleColorLight,
      'sceneBubbleColorDark': sceneBubbleColorDark,
      'showCharacters': showCharacters,
      'showSetting': showSetting,
      'showTimeOfDay': showTimeOfDay,
      'showPov': showPov,
      'showTone': showTone,
      'showStakes': showStakes,
      'showStructure': showStructure,
      'showSenses': showSenses,
      'showDialoguePercentage': showDialoguePercentage,
      'showEchoWords': showEchoWords,
      'showWordCount': showWordCount,
      'showHunches': showHunches,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: json['isDarkMode'] ?? false,
      fontFamily: json['fontFamily'] ?? 'Lora',
      fontSize: json['fontSize'] ?? 18.0,
      lineHeight: json['lineHeight'] ?? 1.8,
      focusMode: json['focusMode'] ?? false,
      focusIntensity: json['focusIntensity'] ?? 0.3,
      autoSaveInterval: json['autoSaveInterval'] ?? 3,
      aiProvider: json['aiProvider'] ?? 'ollama',
      ollamaModel: json['ollamaModel'] ?? 'llama3.2:3b',
      openAiApiKey: json['openAiApiKey'] ?? '',
      openAiModel: json['openAiModel'] ?? 'gpt-4o-mini',
      chapterBubbleColorLight: json['chapterBubbleColorLight'] ?? 0xFF1976D2,
      chapterBubbleColorDark: json['chapterBubbleColorDark'] ?? 0xFF42A5F5,
      sceneBubbleColorLight: json['sceneBubbleColorLight'] ?? 0xFFFFB300,
      sceneBubbleColorDark: json['sceneBubbleColorDark'] ?? 0xFFFFA726,
      showCharacters: json['showCharacters'] ?? true,
      showSetting: json['showSetting'] ?? true,
      showTimeOfDay: json['showTimeOfDay'] ?? true,
      showPov: json['showPov'] ?? true,
      showTone: json['showTone'] ?? true,
      showStakes: json['showStakes'] ?? true,
      showStructure: json['showStructure'] ?? true,
      showSenses: json['showSenses'] ?? true,
      showDialoguePercentage: json['showDialoguePercentage'] ?? true,
      showEchoWords: json['showEchoWords'] ?? true,
      showWordCount: json['showWordCount'] ?? true,
      showHunches: json['showHunches'] ?? true,
    );
  }
}
