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

  /// Analyze a scene using OpenAI's API with structured outputs
  @override
  Future<Map<String, dynamic>?> analyzeScene(String sceneText, {List<String>? existingThreads}) async {
    if (sceneText.trim().isEmpty || apiKey.isEmpty) return null;

    // Calculate word count upfront
    final actualWordCount = sceneText.trim().split(RegExp(r'\s+')).length;

    try {
      final prompt = _buildAnalysisPrompt(sceneText, actualWordCount, existingThreads: existingThreads);

      // Import the schema from SceneAnalysis model
      final schema = _getSceneAnalysisSchema();

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
              'content': 'You are an editorial assistant that analyzes literary fiction scenes.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.3,
          'max_tokens': 1500,
          'response_format': {
            'type': 'json_schema',
            'json_schema': {
              'name': 'scene_analysis',
              'strict': true,
              'schema': schema,
            }
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysisText = data['choices'][0]['message']['content'] as String;

        // With structured outputs, we can directly parse the JSON
        final parsedResult = json.decode(analysisText) as Map<String, dynamic>;

        debugPrint('OpenAI structured output received successfully');
        return parsedResult;
      } else {
        debugPrint('OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Scene analysis error: $e');
    }

    return null;
  }

  /// Build the analysis prompt for the AI (simplified for structured outputs)
  String _buildAnalysisPrompt(String sceneText, int actualWordCount, {List<String>? existingThreads}) {
    // Build existing threads context if provided
    final threadsContext = existingThreads != null && existingThreads.isNotEmpty
        ? '\n\nEXISTING PLOT THREADS IN THIS DOCUMENT:\n${existingThreads.map((t) => '- $t').join('\n')}\n\nIMPORTANT: When identifying plot threads, use the EXACT title from the existing threads list above if the thread is already being tracked. Only create a new thread if it\'s truly different from existing ones.'
        : '';

    return '''Analyze this literary fiction scene and extract key information.$threadsContext

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

3. structure: Evaluate if scene has clear story arc. Identify which beats are present: inciting incident, turning point, crisis, climax, resolution. Keep brief (2-3 sentences max).

4. hunches: 2-3 brief observations about pacing, clarity, emotional resonance, missing elements, or opportunities.

5. senses: Use only these values: sight, sound, touch, taste, smell

NOTE: Plot thread analysis is now done separately at the document level, not per-scene.''';
  }

  /// Get the JSON schema for scene analysis
  /// Uses the schema from SceneAnalysis model
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
        "hunches"
      ],
      "additionalProperties": false
    };
  }

  /// Analyze entire document for plot threads
  @override
  Future<List<Map<String, dynamic>>?> analyzeDocumentForPlotThreads(String fullText) async {
    if (fullText.trim().isEmpty || apiKey.isEmpty) return null;

    final wordCount = fullText.trim().split(RegExp(r'\s+')).length;
    debugPrint('=== Analyzing full document for plot threads ($wordCount words) ===');

    try {
      final prompt = _buildDocumentThreadsPrompt(fullText, wordCount);
      final schema = _getDocumentThreadsSchema();

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
              'content': 'You are an editorial assistant that analyzes plot structure in literary fiction.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.2,
          'max_tokens': 3000,
          'response_format': {
            'type': 'json_schema',
            'json_schema': {
              'name': 'document_threads',
              'strict': true,
              'schema': schema,
            }
          }
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysisText = data['choices'][0]['message']['content'] as String;
        final parsedResult = json.decode(analysisText) as Map<String, dynamic>;

        debugPrint('Document thread analysis completed successfully');

        // Safely cast the list
        final threadsList = parsedResult['plot_threads'] as List<dynamic>?;
        if (threadsList == null) {
          debugPrint('No plot_threads field in response');
          return null;
        }

        // Convert to List<Map<String, dynamic>>
        return threadsList.map((item) => item as Map<String, dynamic>).toList();
      } else {
        debugPrint('OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Document thread analysis error: $e');
    }

    return null;
  }

  /// Build prompt for full document thread analysis
  String _buildDocumentThreadsPrompt(String fullText, int wordCount) {
    return '''Analyze this entire literary fiction manuscript and identify ALL major plot threads that span multiple scenes or chapters.

DOCUMENT TEXT ($wordCount words):
"""
$fullText
"""

YOUR TASK:
Identify the major ongoing plot threads in this document. Focus on:
- Main plot lines that drive the narrative forward
- Character arcs that develop over multiple scenes
- Subplots that recur throughout the story
- Mysteries or questions that are introduced and developed
- Conflicts that persist across scenes
- Relationships that evolve over time

IMPORTANT GUIDELINES:
- Each thread MUST appear in multiple scenes/chapters (not just one-off events)
- Each thread MUST have a UNIQUE, SPECIFIC title
- Limit to 8-15 most significant threads (don't list every minor detail)
- NOT a thread: Single events, descriptions, settings, or background information that don't carry forward
- Provide a clear description of how each thread develops across the document
- Classify each thread's current status: introduced, developing, or resolved
- Types: main_plot, subplot, character_arc, mystery, conflict, relationship, other

CRITICAL: For each thread, carefully identify WHERE it appears:
- starts_at: The EXACT chapter number where this thread is FIRST introduced (e.g., "1", "5", "7"). Read carefully through the text to find the FIRST mention of this character/event. DO NOT guess or assume - if Todd doesn't appear until Chapter 7, write "7" not "1"
- ends_at: The LAST chapter number where this thread is mentioned or relevant. If the thread is resolved (conflict ends, question answered, arc completes), use that chapter number. Only use "ongoing" if the thread is still unresolved AND appears in the final chapter.
- chapters: A list of ALL chapter numbers where this thread appears or is mentioned (e.g., [7, 8, 10, 11, 12]). Include every chapter where the thread is relevant. If a thread appears in chapters 7, 8, 10, don't include 9 if it's not mentioned there.

IMPORTANT:
- Look for "Chapter X" markers in the text to identify chapter boundaries
- Track which chapters each thread actually appears in by reading carefully
- For ends_at: Use the ACTUAL last chapter where mentioned, not the document's last chapter
- A thread that resolves in Chapter 10 should have ends_at="10", NOT "ongoing" or the last chapter
- Be PRECISE - base your answer on what you actually read, not assumptions

Focus on threads that have narrative momentum and contribute to the story's structure.''';
  }

  /// Get JSON schema for document thread analysis
  Map<String, dynamic> _getDocumentThreadsSchema() {
    return {
      "type": "object",
      "properties": {
        "plot_threads": {
          "type": "array",
          "description": "Major plot threads found across the entire document",
          "items": {
            "type": "object",
            "properties": {
              "title": {
                "type": "string",
                "description": "Brief, unique title for the plot thread (3-6 words)"
              },
              "description": {
                "type": "string",
                "description": "How this thread develops across the document (2-3 sentences)"
              },
              "status": {
                "type": "string",
                "enum": ["introduced", "developing", "resolved"],
                "description": "Current status of this thread"
              },
              "type": {
                "type": "string",
                "enum": ["main_plot", "subplot", "character_arc", "mystery", "conflict", "relationship", "other"],
                "description": "Type of plot thread"
              },
              "starts_at": {
                "type": "string",
                "description": "Chapter number where this thread begins (e.g., '1', '5', '7')"
              },
              "ends_at": {
                "type": "string",
                "description": "Chapter number where resolved, or 'ongoing'"
              },
              "chapters": {
                "type": "array",
                "description": "List of all chapter numbers where this thread appears",
                "items": {
                  "type": "integer"
                }
              }
            },
            "required": ["title", "description", "status", "type", "starts_at", "ends_at", "chapters"],
            "additionalProperties": false
          }
        }
      },
      "required": ["plot_threads"],
      "additionalProperties": false
    };
  }

  /// Consolidate plot threads - analyze all threads and clean up duplicates/non-threads
  @override
  Future<Map<String, dynamic>?> consolidateThreads(List<Map<String, dynamic>> threads) async {
    if (threads.isEmpty || apiKey.isEmpty) return null;

    try {
      final prompt = _buildConsolidationPrompt(threads);
      final schema = _getConsolidationSchema();

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
              'content': 'You are an editorial assistant helping to organize and clean up plot thread tracking.'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.0,
          'max_tokens': 2000,
          'response_format': {
            'type': 'json_schema',
            'json_schema': {
              'name': 'thread_consolidation',
              'strict': true,
              'schema': schema,
            }
          }
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysisText = data['choices'][0]['message']['content'] as String;
        final parsedResult = json.decode(analysisText) as Map<String, dynamic>;

        debugPrint('OpenAI thread consolidation completed successfully');
        return parsedResult;
      } else {
        debugPrint('OpenAI API error: ${response.statusCode} - ${response.body}');
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

    return '''Review the following plot threads and determine which should be kept, merged, or removed.

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
