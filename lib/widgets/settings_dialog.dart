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
}
