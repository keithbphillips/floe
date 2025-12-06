import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final isDark = settings.isDarkMode;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Appearance', isDark),
                    const SizedBox(height: 16),

                    _buildToggleSetting(
                      'Dark Mode',
                      settings.isDarkMode,
                      settings.toggleDarkMode,
                      isDark,
                    ),

                    const SizedBox(height: 16),

                    _buildToggleSetting(
                      'Focus Mode',
                      settings.focusMode,
                      settings.toggleFocusMode,
                      isDark,
                    ),

                    if (settings.focusMode) ...[
                      const SizedBox(height: 8),
                      _buildSliderSetting(
                        'Focus Intensity',
                        settings.focusIntensity,
                        0.1,
                        0.5,
                        (value) => settings.setFocusIntensity(value),
                        isDark,
                      ),
                    ],

                    const SizedBox(height: 32),
                    _buildSectionTitle('Typography', isDark),
                    const SizedBox(height: 16),

                    _buildDropdownSetting(
                      'Font Family',
                      settings.fontFamily,
                      ['Lora', 'IBMPlexMono', 'Georgia', 'System'],
                      (value) => settings.setFontFamily(value!),
                      isDark,
                    ),

                    const SizedBox(height: 16),

                    _buildSliderSetting(
                      'Font Size',
                      settings.fontSize,
                      12.0,
                      28.0,
                      (value) => settings.setFontSize(value),
                      isDark,
                      showValue: true,
                    ),

                    const SizedBox(height: 16),

                    _buildSliderSetting(
                      'Line Height',
                      settings.lineHeight,
                      1.2,
                      2.5,
                      (value) => settings.setLineHeight(value),
                      isDark,
                      showValue: true,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle('AI Provider', isDark),
                    const SizedBox(height: 16),

                    _buildDropdownSetting(
                      'AI Service',
                      settings.aiProvider,
                      ['ollama', 'openai'],
                      (value) => settings.setAiProvider(value!),
                      isDark,
                    ),

                    if (settings.aiProvider == 'openai') ...[
                      const SizedBox(height: 16),
                      _buildTextFieldSetting(
                        'OpenAI API Key',
                        settings.openAiApiKey,
                        (value) => settings.setOpenAiApiKey(value),
                        isDark,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownSetting(
                        'OpenAI Model',
                        settings.openAiModel,
                        ['gpt-4o-mini', 'gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'],
                        (value) => settings.setOpenAiModel(value!),
                        isDark,
                      ),
                    ],

                    const SizedBox(height: 32),
                    _buildSectionTitle('Auto-Save', isDark),
                    const SizedBox(height: 16),

                    _buildSliderSetting(
                      'Save Interval (seconds)',
                      settings.autoSaveInterval.toDouble(),
                      1.0,
                      30.0,
                      (value) => settings.setAutoSaveInterval(value.round()),
                      isDark,
                      showValue: true,
                      divisions: 29,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Bubble Colors', isDark),
                    const SizedBox(height: 16),

                    _buildColorPickerSetting(
                      'Chapter Bubble (Light Mode)',
                      Color(settings.chapterBubbleColorLight),
                      (color) => settings.setChapterBubbleColorLight(color.value),
                      isDark,
                      context,
                    ),

                    const SizedBox(height: 16),

                    _buildColorPickerSetting(
                      'Chapter Bubble (Dark Mode)',
                      Color(settings.chapterBubbleColorDark),
                      (color) => settings.setChapterBubbleColorDark(color.value),
                      isDark,
                      context,
                    ),

                    const SizedBox(height: 16),

                    _buildColorPickerSetting(
                      'Scene Bubble (Light Mode)',
                      Color(settings.sceneBubbleColorLight),
                      (color) => settings.setSceneBubbleColorLight(color.value),
                      isDark,
                      context,
                    ),

                    const SizedBox(height: 16),

                    _buildColorPickerSetting(
                      'Scene Bubble (Dark Mode)',
                      Color(settings.sceneBubbleColorDark),
                      (color) => settings.setSceneBubbleColorDark(color.value),
                      isDark,
                      context,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle('Scene Analysis Fields', isDark),
                    const SizedBox(height: 8),
                    Text(
                      'Choose which fields to display in the scene analysis panel',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCheckboxSetting(
                      'Characters',
                      settings.showCharacters,
                      (value) => settings.toggleShowCharacters(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'Setting',
                      settings.showSetting,
                      (value) => settings.toggleShowSetting(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'Time of Day',
                      settings.showTimeOfDay,
                      (value) => settings.toggleShowTimeOfDay(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'POV',
                      settings.showPov,
                      (value) => settings.toggleShowPov(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'Tone',
                      settings.showTone,
                      (value) => settings.toggleShowTone(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'Stakes',
                      settings.showStakes,
                      (value) => settings.toggleShowStakes(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'Structure',
                      settings.showStructure,
                      (value) => settings.toggleShowStructure(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'Senses',
                      settings.showSenses,
                      (value) => settings.toggleShowSenses(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'Dialogue Percentage',
                      settings.showDialoguePercentage,
                      (value) => settings.toggleShowDialoguePercentage(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'Echo Words',
                      settings.showEchoWords,
                      (value) => settings.toggleShowEchoWords(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'Word Count',
                      settings.showWordCount,
                      (value) => settings.toggleShowWordCount(value),
                      isDark,
                    ),

                    _buildCheckboxSetting(
                      'Hunches',
                      settings.showHunches,
                      (value) => settings.toggleShowHunches(value),
                      isDark,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                'Keyboard Shortcuts:\nCmd/Ctrl+, : Settings  |  Cmd/Ctrl+D : Dark Mode\nCmd/Ctrl+F : Focus Mode  |  Cmd/Ctrl+Shift+W : Word Count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildToggleSetting(String label, bool value, VoidCallback onToggle, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        Switch(
          value: value,
          onChanged: (_) => onToggle(),
          activeColor: isDark ? Colors.blueAccent : Colors.blue,
        ),
      ],
    );
  }

  Widget _buildCheckboxSetting(String label, bool value, Function(bool) onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: value,
              onChanged: (newValue) => onChanged(newValue ?? false),
              activeColor: isDark ? Colors.blueAccent : Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    bool isDark, {
    bool showValue = false,
    int? divisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            if (showValue)
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: isDark ? Colors.blueAccent : Colors.blue,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextFieldSetting(
    String label,
    String value,
    Function(String) onChanged,
    bool isDark, {
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: value.length),
            ),
          obscureText: obscureText,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: obscureText ? 'Enter your API key' : 'Enter value',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPickerSetting(
    String label,
    Color currentColor,
    Function(Color) onColorChanged,
    bool isDark,
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        InkWell(
          onTap: () => _showColorPicker(context, currentColor, onColorChanged, isDark),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 100,
            height: 36,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  color: _getContrastColor(currentColor),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  void _showColorPicker(BuildContext context, Color currentColor, Function(Color) onColorChanged, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ColorPickerDialog(
          currentColor: currentColor,
          onColorChanged: onColorChanged,
          isDark: isDark,
        );
      },
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color currentColor;
  final Function(Color) onColorChanged;
  final bool isDark;

  const _ColorPickerDialog({
    required this.currentColor,
    required this.onColorChanged,
    required this.isDark,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
    final hsv = HSVColor.fromColor(_selectedColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  void _updateColor() {
    setState(() {
      _selectedColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pick a Color',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black12,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSlider('Hue', _hue, 0, 360, (value) {
              setState(() {
                _hue = value;
                _updateColor();
              });
            }, isDark),
            const SizedBox(height: 12),
            _buildSlider('Saturation', _saturation, 0, 1, (value) {
              setState(() {
                _saturation = value;
                _updateColor();
              });
            }, isDark),
            const SizedBox(height: 12),
            _buildSlider('Brightness', _value, 0, 1, (value) {
              setState(() {
                _value = value;
                _updateColor();
              });
            }, isDark),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        widget.onColorChanged(_selectedColor);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.blueAccent : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              value.toStringAsFixed(label == 'Hue' ? 0 : 2),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: isDark ? Colors.blueAccent : Colors.blue,
        ),
      ],
    );
  }
}
