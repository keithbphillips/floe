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

  /// Analyze a scene using the local LLM with structured outputs
  @override
  Future<Map<String, dynamic>?> analyzeScene(String sceneText, {List<String>? existingThreads}) async {
    if (sceneText.trim().isEmpty) return null;

    // Calculate word count upfront
    final actualWordCount = sceneText.trim().split(RegExp(r'\s+')).length;

    try {
      final prompt = _buildAnalysisPrompt(sceneText, actualWordCount, existingThreads: existingThreads);
      final schema = _getSceneAnalysisSchema();

      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': model,
          'prompt': prompt,
          'stream': false,
          'format': schema, // Ollama structured outputs via JSON schema
          'options': {
            'temperature': 0.0, // 0 for deterministic structured output
            'num_predict': 1500,
          },
        }),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysisText = data['response'] as String;

        debugPrint('Ollama response length: ${analysisText.length} chars');

        // With structured outputs, Ollama guarantees valid JSON matching schema
        try {
          final parsedResult = json.decode(analysisText) as Map<String, dynamic>;
          debugPrint('Ollama structured output parsed successfully');
          debugPrint('Parsed result keys: ${parsedResult.keys}');
          return parsedResult;
        } catch (e) {
          debugPrint('Failed to parse Ollama structured output: $e');
          debugPrint('Response was: $analysisText');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Scene analysis error: $e');
    }

    return null;
  }

  /// Build the analysis prompt for the LLM (simplified for structured outputs)
  String _buildAnalysisPrompt(String sceneText, int actualWordCount, {List<String>? existingThreads}) {
    // Build existing threads context if provided
    final threadsContext = existingThreads != null && existingThreads.isNotEmpty
        ? '\n\nEXISTING PLOT THREADS IN THIS DOCUMENT:\n${existingThreads.map((t) => '- $t').join('\n')}\n\nIMPORTANT: When identifying plot threads, use the EXACT title from the existing threads list above if the thread is already being tracked. Only create a new thread if it\'s truly different from existing ones.'
        : '';

    return '''You are an editorial assistant. Analyze this literary fiction scene and extract key information.$threadsContext

Scene text:
"""
$sceneText
"""

ANALYSIS INSTRUCTIONS:

1. word_count: Use EXACTLY $actualWordCount

2. echo_words: Identify "echo words" - words repeated too closely together creating unintended rhythmic echo when read aloud.
   - NEVER include: the, a, an, I, you, he, she, it, they, we, his, her, their, my, your, this, that, these, those, and, but, or, of, in, on, at, to, from, for, with, by, was, is, are, had, has, have, been, said, like, will, would, could, should, can, may, might, do, does, did, so, as, if, when, where, who, what, which, how, why, not, no, yes, all, some, any, each, every, both, few, many, more, most, much, such, very, just, now, then, than, there, here
   - ONLY include words appearing 3+ times within the SAME paragraph OR 2-3 consecutive sentences
   - Must be content words (nouns, verbs, adjectives, adverbs), NOT pronouns, articles, prepositions, conjunctions
   - EXCLUDE character names (they naturally repeat)
   - Maximum 8 echo words
   - If no true echo words exist, return empty array

3. plot_threads: Identify ONLY plot threads in THIS scene
   - "introduced": New goal, conflict, question, or mystery
   - "advanced": Progress, complication, or revelation
   - "resolved": Goal achieved, conflict resolved, question answered
   - Types: main_plot, subplot, character_arc, mystery, conflict, relationship, other
   - 1-3 most important threads only
   - Empty array if purely transitional scene

   CRITICAL: Each thread MUST have a UNIQUE, SPECIFIC title that describes THAT PARTICULAR thread.
   - ✓ GOOD: "Michelle's Childhood Trauma", "Uncle Bill's Warning", "Journey to Vancouver"
   - ✗ BAD: "Fire in the Home", "Fire in the Home", "Fire in the Home" (same title repeated)
   - Each thread is a SEPARATE story element and needs its OWN distinct title
   - If you identify multiple threads, they MUST have DIFFERENT titles

4. structure: Evaluate if scene has clear story arc. Identify which beats are present: inciting incident, turning point, crisis, climax, resolution. Keep brief (2-3 sentences max).

5. hunches: 2-3 brief observations about pacing, clarity, emotional resonance, missing elements, or opportunities.

6. senses: Use only these values: sight, sound, touch, taste, smell''';
  }

  /// Get the JSON schema for scene analysis
  /// Ollama uses this schema to constrain output format
  Map<String, dynamic> _getSceneAnalysisSchema() {
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

  /// Consolidate plot threads - analyze all threads and clean up duplicates/non-threads
  @override
  Future<Map<String, dynamic>?> consolidateThreads(List<Map<String, dynamic>> threads) async {
    if (threads.isEmpty) return null;

    try {
      final prompt = _buildConsolidationPrompt(threads);
      final schema = _getConsolidationSchema();

      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': model,
          'prompt': prompt,
          'stream': false,
          'format': schema,
          'options': {
            'temperature': 0.0,
            'num_predict': 2000,
          },
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysisText = data['response'] as String;

        try {
          final parsedResult = json.decode(analysisText) as Map<String, dynamic>;
          debugPrint('Ollama thread consolidation completed successfully');
          return parsedResult;
        } catch (e) {
          debugPrint('Failed to parse Ollama consolidation output: $e');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Thread consolidation error: $e');
    }

    return null;
  }

  /// Build the consolidation prompt
  String _buildConsolidationPrompt(List<Map<String, dynamic>> threads) {
    final threadsList = threads.map((t) {
      final title = t['title'] ?? 'Unknown';
      final type = t['type'] ?? 'unknown';
      final status = t['status'] ?? 'unknown';
      final scenes = t['sceneAppearances'] ?? [];
      final description = t['description'] ?? '';
      return '- "$title" ($type, $status, appears in ${scenes.length} scenes): $description';
    }).join('\n');

    return '''You are an editorial assistant helping to clean up plot thread tracking. Review the following plot threads and determine which should be kept, merged, or removed.

CURRENT PLOT THREADS:
$threadsList

YOUR TASK:
Analyze these threads and identify:
1. REMOVE: Threads that are not actually ongoing plot threads, but just single scene events with no continuation
2. MERGE: Threads that are actually the same thread but have different titles (provide the best title to use)
3. KEEP: Legitimate threads that track ongoing story elements

GUIDELINES:
- A true plot thread appears across multiple scenes and has narrative momentum
- Single events or descriptions that don't carry forward are NOT threads
- Threads about the same topic/conflict should be merged (e.g., "Sarah's Quest" + "Sarah Searches for Answers" = same thread)
- Character arcs that span multiple scenes are legitimate threads
- Mysteries, conflicts, and relationships that develop over time are legitimate threads

For MERGE actions, choose the most clear and specific title from the duplicates, or create a better one.''';
  }

  /// Get JSON schema for consolidation response
  Map<String, dynamic> _getConsolidationSchema() {
    return {
      "type": "object",
      "properties": {
        "actions": {
          "type": "array",
          "description": "List of actions to take on each thread",
          "items": {
            "type": "object",
            "properties": {
              "thread_title": {
                "type": "string",
                "description": "The title of the thread being evaluated"
              },
              "action": {
                "type": "string",
                "enum": ["keep", "remove", "merge"],
                "description": "What to do with this thread"
              },
              "reason": {
                "type": "string",
                "description": "Brief explanation for this action"
              },
              "merge_into": {
                "type": "string",
                "description": "If action is 'merge', the title to merge into (can be existing or new improved title)"
              }
            },
            "required": ["thread_title", "action", "reason"],
            "additionalProperties": false
          }
        }
      },
      "required": ["actions"],
      "additionalProperties": false
    };
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
