class FocusHelper {
  // Find the current sentence boundaries based on cursor position
  static (int, int) getCurrentSentenceRange(String text, int cursorPosition) {
    if (text.isEmpty) return (0, 0);

    // Sentence delimiters
    final sentenceEndings = RegExp(r'[.!?]\s');

    // Find start of current sentence (look backwards for sentence ending)
    int start = 0;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (i > 0 && sentenceEndings.hasMatch(text.substring(i - 1, i + 1))) {
        start = i;
        break;
      }
    }

    // Find end of current sentence (look forwards for sentence ending)
    int end = text.length;
    final matches = sentenceEndings.allMatches(text.substring(cursorPosition));
    if (matches.isNotEmpty) {
      end = cursorPosition + matches.first.end;
    }

    return (start, end);
  }

  // Alternative: Get current paragraph range
  static (int, int) getCurrentParagraphRange(String text, int cursorPosition) {
    if (text.isEmpty) return (0, 0);

    // Find start of current paragraph
    int start = text.lastIndexOf('\n\n', cursorPosition);
    start = start == -1 ? 0 : start + 2;

    // Find end of current paragraph
    int end = text.indexOf('\n\n', cursorPosition);
    end = end == -1 ? text.length : end;

    return (start, end);
  }
}
