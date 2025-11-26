class AppSettings {
  final bool isDarkMode;
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final bool focusMode;
  final double focusIntensity;
  final int autoSaveInterval; // in seconds

  const AppSettings({
    this.isDarkMode = false,
    this.fontFamily = 'Lora',
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.focusMode = false,
    this.focusIntensity = 0.3,
    this.autoSaveInterval = 3,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    bool? focusMode,
    double? focusIntensity,
    int? autoSaveInterval,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      focusMode: focusMode ?? this.focusMode,
      focusIntensity: focusIntensity ?? this.focusIntensity,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
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
    );
  }
}
