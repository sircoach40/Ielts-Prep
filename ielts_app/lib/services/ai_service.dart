import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AIService {
  // Replace with your Anthropic API key
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY';
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';

  static Future<AIFeedback> evaluateWriting({
    required String essay,
    required String taskPrompt,
    required bool isTask1,
  }) async {
    final taskType = isTask1 ? 'Task 1 (150+ words)' : 'Task 2 (250+ words)';
    final prompt = '''
You are an expert IELTS examiner. Evaluate the following IELTS Writing $taskType response.

TASK PROMPT:
$taskPrompt

STUDENT RESPONSE:
$essay

Provide a detailed evaluation in this EXACT JSON format:
{
  "task_achievement": <score 1-9>,
  "coherence_cohesion": <score 1-9>,
  "lexical_resource": <score 1-9>,
  "grammatical_range": <score 1-9>,
  "overall_band": <overall band score 1-9>,
  "task_achievement_comment": "<specific feedback on task achievement>",
  "coherence_comment": "<specific feedback on coherence and cohesion>",
  "lexical_comment": "<specific feedback on vocabulary>",
  "grammatical_comment": "<specific feedback on grammar>",
  "overall_feedback": "<comprehensive 3-4 sentence overall feedback>",
  "strengths": ["<strength 1>", "<strength 2>", "<strength 3>"],
  "improvements": ["<improvement 1>", "<improvement 2>", "<improvement 3>"],
  "improved_version": "<a sample improved opening paragraph>"
}

Be specific, constructive, and accurate to IELTS band descriptors.
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-6',
          'max_tokens': 1500,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          final json = jsonDecode(jsonMatch.group(0)!);
          return _buildFeedbackFromJson(json);
        }
      }
    } catch (e) {
      // Fall through to mock response
    }

    // Mock response for demo (when API key not set)
    return _getMockWritingFeedback(essay);
  }

  static Future<AIFeedback> evaluateSpeaking({
    required String transcription,
    required String questionText,
    required String partType,
  }) async {
    final prompt = '''
You are an expert IELTS examiner. Evaluate this IELTS Speaking $partType response.

QUESTION: $questionText
TRANSCRIPTION: $transcription

Evaluate on all 4 IELTS Speaking criteria and respond in JSON:
{
  "task_achievement": <fluency score 1-9>,
  "coherence_cohesion": <coherence score 1-9>,
  "lexical_resource": <vocabulary score 1-9>,
  "grammatical_range": <grammar score 1-9>,
  "overall_band": <overall band 1-9>,
  "task_achievement_comment": "<fluency and coherence feedback>",
  "coherence_comment": "<coherence feedback>",
  "lexical_comment": "<vocabulary feedback>",
  "grammatical_comment": "<grammar feedback>",
  "overall_feedback": "<overall speaking feedback>",
  "strengths": ["<strength 1>", "<strength 2>"],
  "improvements": ["<improvement 1>", "<improvement 2>"]
}
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-6',
          'max_tokens': 1000,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          return _buildFeedbackFromJson(jsonDecode(jsonMatch.group(0)!));
        }
      }
    } catch (e) {
      // Fall through
    }

    return _getMockSpeakingFeedback();
  }

  static AIFeedback _buildFeedbackFromJson(Map<String, dynamic> json) {
    return AIFeedback(
      taskAchievementScore: (json['task_achievement'] ?? 6.0).toDouble(),
      coherenceCohesionScore: (json['coherence_cohesion'] ?? 6.0).toDouble(),
      lexicalResourceScore: (json['lexical_resource'] ?? 6.0).toDouble(),
      grammaticalRangeScore: (json['grammatical_range'] ?? 6.0).toDouble(),
      overallBand: (json['overall_band'] ?? 6.0).toDouble(),
      overallFeedback: json['overall_feedback'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      improvedVersion: json['improved_version'],
    );
  }

  static AIFeedback _getMockWritingFeedback(String essay) {
    final wordCount = essay.split(' ').length;
    final band = wordCount < 100 ? 4.5 : wordCount < 200 ? 5.5 : 6.5;
    return AIFeedback(
      taskAchievementScore: band,
      coherenceCohesionScore: band - 0.5,
      lexicalResourceScore: band,
      grammaticalRangeScore: band + 0.5,
      overallBand: band,
      overallFeedback: 'Your response demonstrates a reasonable understanding of the task. The essay presents relevant ideas with some development. To improve your score, focus on expanding your arguments with more specific examples and ensuring your paragraphing is logical and clear.',
      strengths: [
        'Clear introduction that addresses the topic',
        'Appropriate use of linking words and phrases',
        'Relevant vocabulary for the topic area',
      ],
      improvements: [
        'Develop each point with more specific examples and evidence',
        'Vary sentence structure more to demonstrate grammatical range',
        'Expand vocabulary range by avoiding word repetition',
      ],
      improvedVersion: 'Here is how you might improve your opening: "The question of whether individuals should accept or challenge difficult circumstances is one that strikes at the heart of human resilience. While some argue that acceptance fosters mental peace, others maintain that a proactive approach to adversity ultimately leads to greater fulfilment."',
    );
  }

  static AIFeedback _getMockSpeakingFeedback() {
    return AIFeedback(
      taskAchievementScore: 6.5,
      coherenceCohesionScore: 6.0,
      lexicalResourceScore: 6.5,
      grammaticalRangeScore: 6.0,
      overallBand: 6.5,
      overallFeedback: 'Your speaking response shows good fluency with only occasional hesitation. You demonstrated a reasonable range of vocabulary and grammar structures. To reach Band 7, focus on reducing filler words and extending your responses with more specific details.',
      strengths: [
        'Good overall fluency with natural pacing',
        'Appropriate use of topic-specific vocabulary',
      ],
      improvements: [
        'Reduce use of filler sounds (um, uh, like)',
        'Use more complex grammatical structures',
        'Provide more specific examples to support your points',
      ],
    );
  }
}
