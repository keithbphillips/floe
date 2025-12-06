import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'ai_service.dart';

class OllamaService implements AiService {
  final String baseUrl;
  final String model;

  OllamaService({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'llama3.2:3b',
  });

  /// Test if Ollama is available
  @override
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 5), // Increased from 2 to 5 seconds
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Ollama not available: $e');
      return false;
    }
  }

  /// Analyze a scene using the local LLM
  @override
  Future<Map<String, dynamic>?> analyzeScene(String sceneText) async {
    if (sceneText.trim().isEmpty) return null;

    // Calculate word count upfront so we can use it as fallback
    final actualWordCount = sceneText.trim().split(RegExp(r'\s+')).length;

    try {
      final prompt = _buildAnalysisPrompt(sceneText);

      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': model,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': 0.3, // Lower for more consistent analysis
            'num_predict': 500, // Limit response length
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysisText = data['response'] as String;
        var parsedResult = _parseAnalysis(analysisText);

        if (parsedResult != null) {
          // Unwrap raw_response if it exists (LLM sometimes wraps the JSON)
          if (parsedResult.containsKey('raw_response') && parsedResult['raw_response'] is Map) {
            // Extract the inner data
            final innerData = Map<String, dynamic>.from(parsedResult['raw_response']);
            // Preserve any top-level keys that aren't in the inner data
            parsedResult.forEach((key, value) {
              if (key != 'raw_response' && !innerData.containsKey(key)) {
                innerData[key] = value;
              }
            });
            parsedResult = innerData;
          }

          // Ensure word_count is always present
          if (!parsedResult.containsKey('word_count')) {
            parsedResult['word_count'] = actualWordCount;
          }

          // Debug logging
          debugPrint('Parsed result keys: ${parsedResult.keys}');
          debugPrint('Echo words in parsed result: ${parsedResult['echo_words']}');
        }

        return parsedResult;
      }
    } catch (e) {
      debugPrint('Scene analysis error: $e');
    }

    return null;
  }

  /// Build the analysis prompt for the LLM
  String _buildAnalysisPrompt(String sceneText) {
    // Pre-calculate word count to ensure accuracy
    final actualWordCount = sceneText.trim().isEmpty
        ? 0
        : sceneText.trim().split(RegExp(r'\s+')).length;

    return '''You are an editorial assistant. Analyze this literary fiction scene and extract key information. Respond ONLY with valid JSON, no other text.

Scene text:
"""
$sceneText
"""

Extract and return JSON with these fields:
{
  "characters": ["list of character names present"],
  "setting": "physical location",
  "time_of_day": "morning/afternoon/evening/night or unknown",
  "pov": "whose perspective (character name or unknown)",
  "tone": "brief emotional tone (1-2 words)",
  "dialogue_percentage": estimated percentage (0-100),
  "word_count": $actualWordCount,
  "echo_words": ["words that repeat within close proximity - see instructions below"],
  "senses": ["which senses engaged: sight/sound/touch/taste/smell"],
  "stakes": "brief description of what's at risk",
  "structure": "evaluate if scene has clear story arc - identify which structural beats are present: inciting incident (what starts the scene), turning point (shift in direction), crisis (key decision point), climax (peak moment), resolution (how it ends). Keep response brief (2-3 sentences max).",
  "hunches": ["2-3 brief suggestions or observations about the scene - things like pacing, clarity, emotional resonance, missing elements, or opportunities"],
  "plot_threads": [
    {
      "title": "brief title for the plot thread (3-5 words)",
      "description": "what happens with this thread in this scene (1-2 sentences)",
      "action": "introduced|advanced|resolved",
      "type": "main_plot|subplot|character_arc|mystery|conflict|relationship|other"
    }
  ]
}

CRITICAL INSTRUCTIONS:

1. word_count: Use EXACTLY $actualWordCount

2. echo_words: Analyze the text for "echo words," meaning any word or short phrase repeated too closely together in a way that creates an unintended rhythmic echo when read aloud.

   CRITICAL: NEVER include these words regardless of repetition: the, a, an, I, you, he, she, it, they, we, his, her, their, my, your, this, that, these, those, and, but, or, of, in, on, at, to, from, for, with, by, was, is, are, had, has, have, been, said, like, will, would, could, should, can, may, might, do, does, did, so, as, if, when, where, who, what, which, how, why, not, no, yes, all, some, any, each, every, both, few, many, more, most, much, such, very, just, now, then, than, there, here

   ONLY include words that meet ALL these criteria:
   - The SAME word appears 3+ times within the SAME paragraph OR within 2-3 consecutive sentences
   - The repetition creates an unintended rhythmic echo that would be noticeable when reading aloud
   - MUST be content words (nouns like "door", "room", "hospital"; verbs like "walked", "smiled", "opened"; adjectives like "heavy", "quiet"; or adverbs like "slowly", "quickly")
   - NEVER include pronouns, articles, prepositions, conjunctions, or auxiliary verbs
   - EXCLUDE character names (they naturally repeat)
   - Return MAXIMUM 8 echo words, prioritizing the most noticeable repetitions that disrupt the reading flow
   - If no true echo words exist, return empty array []

Example: "She walked to the door. The door was locked. She tried the door again." → echo_words: ["door"]
Example: "He smiled at her. She smiled back. They both smiled." → echo_words: ["smiled"]
Counter-example: "Martin looked around" (paragraph 1) ... "Martin looked up" (paragraph 5) → NOT an echo (too far apart)

3. plot_threads: Identify ONLY plot threads that appear in THIS scene. A plot thread is a story element that creates forward momentum:

   Action types:
   - "introduced": This scene starts a new thread (new goal, conflict, question, mystery)
   - "advanced": This scene develops an existing thread (progress, complication, revelation)
   - "resolved": This scene concludes a thread (goal achieved, conflict resolved, question answered)

   Thread types:
   - "main_plot": Primary story arc driving the overall narrative
   - "subplot": Secondary story arc running parallel to main plot
   - "character_arc": Character growth, change, or transformation
   - "mystery": Question raised that needs answering, unknown to be revealed
   - "conflict": Ongoing tension, opposition, or problem
   - "relationship": Development of connection between characters
   - "other": Anything else (worldbuilding, thematic elements, etc.)

   Guidelines:
   - Identify 1-3 plot threads per scene (most important ones only)
   - Be specific but concise in titles and descriptions
   - Focus on threads that create story momentum or need tracking
   - If a scene is purely transitional with no plot development, return empty array []

   Examples:
   - Title: "Sarah's Missing Sister", Description: "Sarah discovers her sister hasn't been seen in 3 days", Action: "introduced", Type: "mystery"
   - Title: "Jack Learns to Trust", Description: "Jack reluctantly accepts help from Maria, beginning to overcome his isolation", Action: "advanced", Type: "character_arc"
   - Title: "The Artifact Quest", Description: "Heroes finally retrieve the stolen artifact from the temple", Action: "resolved", Type: "main_plot"

Respond with ONLY the JSON object, nothing else.''';
  }

  /// Parse the LLM response into structured data
  Map<String, dynamic> _parseAnalysis(String analysisText) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(analysisText);
      if (jsonMatch != null) {
        final parsed = json.decode(jsonMatch.group(0)!);
        return parsed;
      }

      // If no JSON found, return the raw text
      return {'raw_response': analysisText};
    } catch (e) {
      debugPrint('Failed to parse analysis: $e');
      debugPrint('Analysis text was: $analysisText');
      return {'error': 'Failed to parse analysis', 'raw_response': analysisText};
    }
  }

  /// Quick character extraction (fallback without LLM)
  @override
  List<String> extractCharactersSimple(String text) {
    // Simple capitalized word detection
    final capitalizedWords = RegExp(r'\b[A-Z][a-z]+\b').allMatches(text);
    final names = <String>{};

    for (final match in capitalizedWords) {
      final word = match.group(0)!;
      // Filter out common words that aren't names
      if (!_commonWords.contains(word.toLowerCase())) {
        names.add(word);
      }
    }

    return names.toList()..sort();
  }

  /// Find echo words (words repeated within close proximity)
  /// Only flags words that appear 2+ times within a 50-word window
  Map<String, int> findEchoWords(String text) {
    final words = text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3 && !_stopWords.contains(w))
        .toList();

    final echoWords = <String, int>{};
    const windowSize = 50; // Check within 50-word windows

    // Scan through the text with a sliding window
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final windowEnd = (i + windowSize < words.length) ? i + windowSize : words.length;

      // Count occurrences of this word within the window
      int countInWindow = 0;
      for (int j = i; j < windowEnd; j++) {
        if (words[j] == word) {
          countInWindow++;
        }
      }

      // If word appears 2+ times in this window, flag it as an echo
      if (countInWindow >= 2) {
        echoWords[word] = (echoWords[word] ?? 0) + 1;
      }
    }

    // Return words sorted by frequency
    return Map.fromEntries(
      echoWords.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Calculate dialogue percentage
  @override
  int calculateDialoguePercentage(String text) {
    final lines = text.split('\n');
    int dialogueLines = 0;

    for (final line in lines) {
      if (line.trim().contains('"') || line.trim().contains("'")) {
        dialogueLines++;
      }
    }

    return lines.isEmpty ? 0 : ((dialogueLines / lines.length) * 100).round();
  }

  static final Set<String> _commonWords = {
    'the', 'and', 'but', 'that', 'this', 'with', 'from', 'have',
    'they', 'would', 'there', 'their', 'what', 'about', 'which',
    'when', 'make', 'like', 'time', 'just', 'know', 'take', 'people',
    'into', 'year', 'your', 'good', 'some', 'could', 'them', 'see',
    'other', 'than', 'then', 'now', 'look', 'only', 'come', 'its',
    'over', 'think', 'also', 'back', 'after', 'use', 'two', 'how',
    'our', 'work', 'first', 'well', 'way', 'even', 'new', 'want',
    'because', 'any', 'these', 'give', 'day', 'most', 'us', 'chapter',
    'myself', 'himself', 'herself', 'themselves', 'something', 'nothing',
    'everything', 'anything', 'someone', 'anyone', 'everyone', 'before',
  };

  static final Set<String> _stopWords = {
    'the', 'and', 'that', 'this', 'with', 'from', 'have', 'they',
    'was', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'her',
    'his', 'she', 'had', 'has', 'said', 'been', 'will', 'more',
    'were', 'their', 'would', 'there', 'could', 'should', 'about',
    'which', 'these', 'those', 'them', 'some', 'into', 'like',
  };
}
