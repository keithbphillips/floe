class AppSettings {
  final bool isDarkMode;
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final bool focusMode;
  final double focusIntensity;
  final int autoSaveInterval; // in seconds
  final String aiProvider; // 'ollama' or 'openai'
  final String openAiApiKey;
  final String openAiModel;
  final int chapterBubbleColorLight; // ARGB color value
  final int chapterBubbleColorDark; // ARGB color value
  final int sceneBubbleColorLight; // ARGB color value
  final int sceneBubbleColorDark; // ARGB color value

  const AppSettings({
    this.isDarkMode = false,
    this.fontFamily = 'Lora',
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.focusMode = false,
    this.focusIntensity = 0.3,
    this.autoSaveInterval = 3,
    this.aiProvider = 'ollama',
    this.openAiApiKey = '',
    this.openAiModel = 'gpt-4o-mini',
    this.chapterBubbleColorLight = 0xFF1976D2, // Colors.blue[600]
    this.chapterBubbleColorDark = 0xFF42A5F5, // Colors.blue[400]
    this.sceneBubbleColorLight = 0xFFFFB300, // Colors.amber[600]
    this.sceneBubbleColorDark = 0xFFFFA726, // Colors.amber[700]
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
    String? openAiApiKey,
    String? openAiModel,
    int? chapterBubbleColorLight,
    int? chapterBubbleColorDark,
    int? sceneBubbleColorLight,
    int? sceneBubbleColorDark,
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
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
      openAiModel: openAiModel ?? this.openAiModel,
      chapterBubbleColorLight: chapterBubbleColorLight ?? this.chapterBubbleColorLight,
      chapterBubbleColorDark: chapterBubbleColorDark ?? this.chapterBubbleColorDark,
      sceneBubbleColorLight: sceneBubbleColorLight ?? this.sceneBubbleColorLight,
      sceneBubbleColorDark: sceneBubbleColorDark ?? this.sceneBubbleColorDark,
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
      'openAiApiKey': openAiApiKey,
      'openAiModel': openAiModel,
      'chapterBubbleColorLight': chapterBubbleColorLight,
      'chapterBubbleColorDark': chapterBubbleColorDark,
      'sceneBubbleColorLight': sceneBubbleColorLight,
      'sceneBubbleColorDark': sceneBubbleColorDark,
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
      openAiApiKey: json['openAiApiKey'] ?? '',
      openAiModel: json['openAiModel'] ?? 'gpt-4o-mini',
      chapterBubbleColorLight: json['chapterBubbleColorLight'] ?? 0xFF1976D2,
      chapterBubbleColorDark: json['chapterBubbleColorDark'] ?? 0xFF42A5F5,
      sceneBubbleColorLight: json['sceneBubbleColorLight'] ?? 0xFFFFB300,
      sceneBubbleColorDark: json['sceneBubbleColorDark'] ?? 0xFFFFA726,
    );
  }
}
