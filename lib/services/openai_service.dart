import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'ai_service.dart';

class OpenAiService implements AiService {
  final String apiKey;
  final String model;
  static const String baseUrl = 'https://api.openai.com/v1';

  OpenAiService({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
  });

  /// Test if OpenAI API is available (by checking if API key is set)
  @override
  Future<bool> isAvailable() async {
    if (apiKey.isEmpty) return false;

    try {
      // Quick validation call to models endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('OpenAI not available: $e');
      return false;
    }
  }

  /// Analyze a scene using OpenAI's API
  @override
  Future<Map<String, dynamic>?> analyzeScene(String sceneText) async {
    if (sceneText.trim().isEmpty || apiKey.isEmpty) return null;

    // Calculate word count upfront so we can use it as fallback
    final actualWordCount = sceneText.trim().split(RegExp(r'\s+')).length;

    try {
      final prompt = _buildAnalysisPrompt(sceneText);

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are an editorial assistant that analyzes literary fiction. Respond ONLY with valid JSON, no other text.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.3,
          'max_tokens': 1000,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysisText = data['choices'][0]['message']['content'] as String;
        final parsedResult = _parseAnalysis(analysisText);

        // Ensure word_count is always present
        if (parsedResult != null && !parsedResult.containsKey('word_count')) {
          parsedResult['word_count'] = actualWordCount;
        }

        return parsedResult;
      } else {
        debugPrint('OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Scene analysis error: $e');
    }

    return null;
  }

  /// Build the analysis prompt for the AI
  String _buildAnalysisPrompt(String sceneText) {
    // Pre-calculate word count to ensure accuracy
    final actualWordCount = sceneText.trim().isEmpty
        ? 0
        : sceneText.trim().split(RegExp(r'\s+')).length;

    return '''Analyze this literary fiction scene and extract key information. Respond ONLY with valid JSON, no other text.

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
  "hunches": ["2-3 brief suggestions or observations about the scene - things like pacing, clarity, emotional resonance, missing elements, or opportunities"]
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

Respond with ONLY the JSON object, nothing else.''';
  }

  /// Parse the AI response into structured data
  Map<String, dynamic>? _parseAnalysis(String analysisText) {
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

  /// Quick character extraction (fallback without AI)
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
}
