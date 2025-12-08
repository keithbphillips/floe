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
      } else {
        // Non-200 status code - log the error details
        debugPrint('Ollama API error: Status ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            debugPrint('Error message: ${errorData['error']}');
          }
        } catch (e) {
          // Response body wasn't JSON
        }
        return null;
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

3. structure: Evaluate if scene has clear story arc. Identify which beats are present: inciting incident, turning point, crisis, climax, resolution. Keep brief (2-3 sentences max).

4. hunches: 2-3 brief observations about pacing, clarity, emotional resonance, missing elements, or opportunities.

5. senses: Use only these values: sight, sound, touch, taste, smell

NOTE: Plot thread analysis is now done separately at the document level, not per-scene.''';
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

  /// Analyze a single chapter to generate a summary
  @override
  Future<Map<String, dynamic>?> analyzeChapterForSummary(String chapterText, int chapterNumber) async {
    if (chapterText.trim().isEmpty) return null;

    final wordCount = chapterText.trim().split(RegExp(r'\s+')).length;
    debugPrint('=== Analyzing Chapter $chapterNumber for summary ($wordCount words) ===');

    try {
      final prompt = _buildChapterSummaryPrompt(chapterText, chapterNumber, wordCount);
      final schema = _getChapterSummarySchema();

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
            'num_predict': 1000,
          },
        }),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysisText = data['response'] as String;

        try {
          final parsedResult = json.decode(analysisText) as Map<String, dynamic>;
          debugPrint('Chapter $chapterNumber summary generated successfully');
          return parsedResult;
        } catch (e) {
          debugPrint('Failed to parse chapter summary: $e');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Chapter summary analysis error: $e');
    }

    return null;
  }

  /// Build prompt for chapter summary
  String _buildChapterSummaryPrompt(String chapterText, int chapterNumber, int wordCount) {
    return '''You are an editorial assistant analyzing a chapter of literary fiction. Generate a concise summary of this chapter that captures key plot developments, character actions, and important events.

CHAPTER $chapterNumber ($wordCount words):
"""
$chapterText
"""

YOUR TASK:
Create a summary that includes:
1. KEY EVENTS: What actually happens in this chapter (3-5 bullet points)
2. CHARACTERS: Who appears or is mentioned in this chapter
3. PLOT DEVELOPMENTS: Any plot threads that are introduced, advanced, or resolved
4. CONFLICTS: Any conflicts or tensions present in this chapter
5. LOCATIONS: Where the chapter takes place

IMPORTANT:
- Focus on WHAT HAPPENS, not analysis or interpretation
- Be specific about character actions and events
- Note when plot elements are first introduced vs. continuing from earlier
- Keep the summary factual and detailed enough to identify plot threads later
- Aim for 150-250 words total''';
  }

  /// Get JSON schema for chapter summary
  Map<String, dynamic> _getChapterSummarySchema() {
    return {
      "type": "object",
      "properties": {
        "chapter_number": {
          "type": "integer",
          "description": "The chapter number being summarized"
        },
        "key_events": {
          "type": "array",
          "description": "3-5 bullet points of key events that happen in this chapter",
          "items": {"type": "string"}
        },
        "characters": {
          "type": "array",
          "description": "List of characters who appear or are mentioned",
          "items": {"type": "string"}
        },
        "plot_developments": {
          "type": "array",
          "description": "Plot threads introduced, advanced, or resolved",
          "items": {"type": "string"}
        },
        "conflicts": {
          "type": "array",
          "description": "Conflicts or tensions present in this chapter",
          "items": {"type": "string"}
        },
        "locations": {
          "type": "array",
          "description": "Locations where the chapter takes place",
          "items": {"type": "string"}
        }
      },
      "required": ["chapter_number", "key_events", "characters", "plot_developments", "conflicts", "locations"],
      "additionalProperties": false
    };
  }

  /// Generate a detailed narrative summary for a specific plot thread
  @override
  Future<String?> generateThreadSummary(
    String threadTitle,
    List<int> chapterNumbers,
    List<Map<String, dynamic>> chapterSummaries,
  ) async {
    if (chapterNumbers.isEmpty || chapterSummaries.isEmpty) return null;

    debugPrint('=== Generating summary for thread: "$threadTitle" ===');

    try {
      // Filter summaries to only chapters where this thread appears
      final relevantSummaries = chapterSummaries
          .where((s) => chapterNumbers.contains(s['chapter_number'] as int))
          .toList();

      if (relevantSummaries.isEmpty) {
        debugPrint('No relevant chapter summaries found for thread');
        return null;
      }

      final summariesText = relevantSummaries.map((summary) {
        final chNum = summary['chapter_number'] ?? 0;
        final events = (summary['key_events'] as List?)?.join('\n  • ') ?? '';
        final plotDevs = (summary['plot_developments'] as List?)?.join('\n  • ') ?? '';
        final conflicts = (summary['conflicts'] as List?)?.join('\n  • ') ?? '';
        final chars = (summary['characters'] as List?)?.join(', ') ?? '';

        return '''
CHAPTER $chNum:
Characters: $chars
Key Events:
  • $events
Plot Developments:
  • $plotDevs
Conflicts:
  • $conflicts
''';
      }).join('\n---\n');

      final prompt = '''You are an editorial assistant creating a narrative summary for a specific plot thread. Based on the chapter summaries provided, write a cohesive, engaging summary of how this plot thread develops across the story.

PLOT THREAD: "$threadTitle"

APPEARS IN CHAPTERS: ${chapterNumbers.join(', ')}

RELEVANT CHAPTER SUMMARIES:
$summariesText

YOUR TASK:
Write a 2-3 paragraph narrative summary (150-200 words) that:
1. Describes how this thread is introduced
2. Explains how it develops and evolves across the chapters
3. Notes key turning points or significant moments
4. Describes its current status (resolved, ongoing, or abandoned)
5. Uses engaging, descriptive language that captures the dramatic arc

IMPORTANT:
- Write in past tense, as if narrating the story
- Focus specifically on THIS thread, not the entire plot
- Make it read like a cohesive narrative, not a bullet list
- Highlight the emotional or dramatic stakes involved
- Keep it concise but engaging''';

      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': model,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': 0.7, // Slightly higher for more engaging prose
            'num_predict': 500,
          },
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final summaryText = data['response'] as String;
        debugPrint('Thread summary generated successfully (${summaryText.length} chars)');
        return summaryText.trim();
      }
    } catch (e) {
      debugPrint('Thread summary generation error: $e');
    }

    return null;
  }

  /// Analyze chapter summaries to extract plot threads
  @override
  Future<List<Map<String, dynamic>>?> analyzeChapterSummariesForThreads(List<Map<String, dynamic>> chapterSummaries) async {
    if (chapterSummaries.isEmpty) return null;

    debugPrint('=== Analyzing ${chapterSummaries.length} chapter summaries for plot threads ===');

    try {
      final prompt = _buildThreadExtractionPrompt(chapterSummaries);
      final schema = _getDocumentThreadsSchema();

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
            'num_predict': 3000,
          },
        }),
      ).timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysisText = data['response'] as String;

        try {
          final parsedResult = json.decode(analysisText) as Map<String, dynamic>;
          debugPrint('Thread extraction from summaries completed successfully');

          final threadsList = parsedResult['plot_threads'] as List<dynamic>?;
          if (threadsList == null) {
            debugPrint('No plot_threads field in response');
            return null;
          }

          return threadsList.map((item) => item as Map<String, dynamic>).toList();
        } catch (e) {
          debugPrint('Failed to parse thread extraction output: $e');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Thread extraction error: $e');
    }

    return null;
  }

  /// Build prompt for extracting threads from chapter summaries
  String _buildThreadExtractionPrompt(List<Map<String, dynamic>> chapterSummaries) {
    final summariesText = chapterSummaries.map((summary) {
      final chNum = summary['chapter_number'] ?? 0;
      final events = (summary['key_events'] as List?)?.join('\n  • ') ?? '';
      final plotDevs = (summary['plot_developments'] as List?)?.join('\n  • ') ?? '';
      final conflicts = (summary['conflicts'] as List?)?.join('\n  • ') ?? '';
      final chars = (summary['characters'] as List?)?.join(', ') ?? '';

      return '''
CHAPTER $chNum:
Characters: $chars
Key Events:
  • $events
Plot Developments:
  • $plotDevs
Conflicts:
  • $conflicts
''';
    }).join('\n---\n');

    return '''You are an editorial assistant analyzing plot structure. You have summaries of ${chapterSummaries.length} chapters. Identify ALL major plot threads that span multiple chapters.

CHAPTER SUMMARIES:
$summariesText

YOUR TASK:
Identify the major ongoing plot threads across these chapters. Focus on:
- Main plot lines that drive the narrative forward
- Character arcs that develop over multiple chapters
- Subplots that recur throughout the story
- Mysteries or questions that are introduced and developed
- Conflicts that persist across chapters
- Relationships that evolve over time

IMPORTANT GUIDELINES:
- Each thread MUST appear in multiple chapters (not just one-off events)
- Each thread MUST have a UNIQUE, SPECIFIC title
- Limit to 8-15 most significant threads (don't list every minor detail)
- NOT a thread: Single events, descriptions, settings, or background information that don't carry forward
- Provide a clear description of how each thread develops across the document
- Classify each thread's current status: introduced, developing, or resolved
- Types: main_plot, subplot, character_arc, mystery, conflict, relationship, other

CRITICAL LOCATION TRACKING - Follow these steps for EACH thread:

STEP 1: SCAN SEQUENTIALLY through the chapter summaries from beginning to end
- As you read through each chapter summary, note ONLY the chapters where this specific thread is explicitly mentioned, shown, or discussed
- DO NOT assume a thread continues between mentions - only record actual appearances in the summaries

STEP 2: IDENTIFY BOUNDARIES with precision:
- starts_at: The EXACT chapter number where this thread FIRST appears (e.g., "1", "5", "7")
  * This is where the character first appears, the conflict first emerges, or the mystery is first introduced
  * DO NOT write "1" as a default - find the actual first mention by scanning from the beginning

- ends_at: The EXACT chapter number where this thread LAST appears (e.g., "10" or "ongoing")
  * If resolved (conflict ends, mystery solved): use that chapter number (e.g., "10")
  * If still unresolved but thread stops being mentioned: use the last chapter it appears in
  * Only use "ongoing" if: (a) the thread is unresolved AND (b) it appears in the final chapter

- chapters: Array of ONLY the chapter numbers where this thread actually appears in the summaries [e.g., 1, 3, 5, 8]
  * DO NOT fill in gaps - if a thread appears in chapters 1, 5, and 8, write [1, 5, 8] NOT [1, 2, 3, 4, 5, 6, 7, 8]
  * Each number must correspond to a chapter where the thread is explicitly present in the summary

STEP 3: VERIFY YOUR WORK:
- Double-check: Does starts_at match the first number in chapters array?
- Double-check: Does ends_at match the last number in chapters array (or is "ongoing")?
- Double-check: Did you skip any chapters in the chapters array? Good! Only include actual mentions.

COMMON MISTAKES TO AVOID:
❌ WRONG: Thread introduced in Ch 1, so it must run through all chapters → [1, 2, 3, 4, 5, 6]
✅ RIGHT: Thread introduced in Ch 1, appears in Ch 1, 4, 6 → [1, 4, 6]

❌ WRONG: Thread feels like it spans the whole story, so starts_at="1"
✅ RIGHT: Thread first mentioned in Ch 3, so starts_at="3"

❌ WRONG: Thread unresolved, so ends_at="ongoing" (even though last mention was Ch 8)
✅ RIGHT: Thread last appears in Ch 8, so ends_at="8"

Focus on threads that have narrative momentum and contribute to the story's structure.''';
  }

  /// Analyze entire document for plot threads (legacy method)
  @override
  Future<List<Map<String, dynamic>>?> analyzeDocumentForPlotThreads(String fullText) async {
    if (fullText.trim().isEmpty) return null;

    final wordCount = fullText.trim().split(RegExp(r'\s+')).length;
    debugPrint('=== Analyzing full document for plot threads ($wordCount words) ===');

    try {
      final prompt = _buildDocumentThreadsPrompt(fullText, wordCount);
      final schema = _getDocumentThreadsSchema();

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
            'num_predict': 3000,
          },
        }),
      ).timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysisText = data['response'] as String;

        try {
          final parsedResult = json.decode(analysisText) as Map<String, dynamic>;
          debugPrint('Ollama document thread analysis completed successfully');

          // Safely cast the list
          final threadsList = parsedResult['plot_threads'] as List<dynamic>?;
          if (threadsList == null) {
            debugPrint('No plot_threads field in response');
            return null;
          }

          // Convert to List<Map<String, dynamic>>
          return threadsList.map((item) => item as Map<String, dynamic>).toList();
        } catch (e) {
          debugPrint('Failed to parse Ollama document thread output: $e');
          debugPrint('Response was: $analysisText');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Document thread analysis error: $e');
    }

    return null;
  }

  /// Build prompt for full document thread analysis
  String _buildDocumentThreadsPrompt(String fullText, int wordCount) {
    return '''You are an editorial assistant analyzing plot structure. Analyze this entire literary fiction manuscript and identify ALL major plot threads that span multiple scenes or chapters.

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

CRITICAL LOCATION TRACKING - Follow these steps for EACH thread:

STEP 1: SCAN SEQUENTIALLY through the document from beginning to end
- As you read through each chapter, note ONLY the chapters where this specific thread is explicitly mentioned, shown, or discussed
- DO NOT assume a thread continues between mentions - only record actual appearances

STEP 2: IDENTIFY BOUNDARIES with precision:
- starts_at: The EXACT chapter number where this thread FIRST appears (e.g., "1", "5", "7")
  * This is where the character first appears, the conflict first emerges, or the mystery is first introduced
  * DO NOT write "1" as a default - find the actual first mention by scanning from the beginning

- ends_at: The EXACT chapter number where this thread LAST appears (e.g., "10" or "ongoing")
  * If resolved (conflict ends, mystery solved): use that chapter number (e.g., "10")
  * If still unresolved but thread stops being mentioned: use the last chapter it appears in
  * Only use "ongoing" if: (a) the thread is unresolved AND (b) it appears in the final chapter

- chapters: Array of ONLY the chapter numbers where this thread actually appears [e.g., 1, 3, 5, 8]
  * DO NOT fill in gaps - if a thread appears in chapters 1, 5, and 8, write [1, 5, 8] NOT [1, 2, 3, 4, 5, 6, 7, 8]
  * Each number must correspond to a chapter where the thread is explicitly present

STEP 3: VERIFY YOUR WORK:
- Double-check: Does starts_at match the first number in chapters array?
- Double-check: Does ends_at match the last number in chapters array (or is "ongoing")?
- Double-check: Did you skip any chapters in the chapters array? Good! Only include actual mentions.

COMMON MISTAKES TO AVOID:
❌ WRONG: Thread introduced in Ch 1, so it must run through all chapters → [1, 2, 3, 4, 5, 6]
✅ RIGHT: Thread introduced in Ch 1, appears in Ch 1, 4, 6 → [1, 4, 6]

❌ WRONG: Thread feels like it spans the whole story, so starts_at="1"
✅ RIGHT: Thread first mentioned in Ch 3, so starts_at="3"

❌ WRONG: Thread unresolved, so ends_at="ongoing" (even though last mention was Ch 8)
✅ RIGHT: Thread last appears in Ch 8, so ends_at="8"

Look for "Chapter X" markers in the text to identify chapter boundaries. Base your answer ONLY on what you actually read, not on assumptions about story structure.

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
