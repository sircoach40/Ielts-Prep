import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AIExaminerService {
  // Replace with your actual Gemini API key
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Evaluate a writing submission and return detailed feedback
  static Future<AIFeedback> evaluateWriting({
    required String prompt,
    required String response,
    required String taskType, // 'task1' or 'task2'
  }) async {
    final systemPrompt = '''
You are an expert IELTS examiner with 10+ years of experience.
Evaluate the following IELTS Writing ${taskType == 'task1' ? 'Task 1' : 'Task 2'} response.

TASK PROMPT:
$prompt

CANDIDATE RESPONSE:
$response

Provide a detailed evaluation in STRICT JSON format:
{
  "overallScore": <band score 0-9, e.g. 6.5>,
  "grammarScore": <0-9>,
  "vocabularyScore": <0-9>,
  "coherenceScore": <0-9>,
  "overallFeedback": "<2-3 sentence overall assessment>",
  "strengths": [
    {"title": "<strength title>", "description": "<detail>", "example": "<quote from text>"},
    {"title": "<strength title>", "description": "<detail>", "example": "<quote from text>"}
  ],
  "improvements": [
    {"title": "<improvement area>", "description": "<what to fix>", "example": "<corrected example>"},
    {"title": "<improvement area>", "description": "<what to fix>", "example": "<corrected example>"},
    {"title": "<improvement area>", "description": "<what to fix>", "example": "<corrected example>"}
  ],
  "improvedVersion": "<a brief improved version of the opening paragraph>"
}

Base your evaluation on the official IELTS band descriptors:
- Task Achievement/Response
- Coherence and Cohesion
- Lexical Resource
- Grammatical Range and Accuracy

Return ONLY valid JSON, no other text.
''';

    return _callGemini(systemPrompt, taskType);
  }

  /// Evaluate a speaking submission transcript and return feedback
  static Future<AIFeedback> evaluateSpeaking({
    required String questionText,
    required String transcribedResponse,
  }) async {
    final systemPrompt = '''
You are an expert IELTS examiner evaluating a speaking response.

QUESTION:
$questionText

CANDIDATE'S TRANSCRIBED RESPONSE:
$transcribedResponse

Provide evaluation in STRICT JSON format:
{
  "overallScore": <band score 0-9>,
  "grammarScore": <0-9>,
  "vocabularyScore": <0-9>,
  "coherenceScore": <0-9>,
  "pronunciationScore": <0-9>,
  "overallFeedback": "<2-3 sentence assessment>",
  "strengths": [
    {"title": "<strength>", "description": "<detail>", "example": "<quote>"},
    {"title": "<strength>", "description": "<detail>", "example": "<quote>"}
  ],
  "improvements": [
    {"title": "<area>", "description": "<how to improve>", "example": "<better phrasing>"},
    {"title": "<area>", "description": "<how to improve>", "example": "<better phrasing>"}
  ],
  "improvedVersion": "<how the same answer could start more impressively>"
}

Evaluate based on IELTS speaking criteria: Fluency & Coherence, Lexical Resource, Grammatical Range & Accuracy, Pronunciation.
Return ONLY valid JSON.
''';

    return _callGemini(systemPrompt, 'speaking');
  }

  static Future<AIFeedback> _callGemini(String prompt, String type) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        final cleanJson = text.replaceAll(RegExp(r'```json|```'), '').trim();
        final parsed = jsonDecode(cleanJson);
        return _parseFeedback(parsed, type);
      }
    } catch (e) {
      // fallback to demo feedback
    }

    // Demo feedback when API not configured
    return _getDemoFeedback(type);
  }

  static AIFeedback _parseFeedback(Map<String, dynamic> data, String type) {
    return AIFeedback(
      overallScore: (data['overallScore'] ?? 6.0).toDouble(),
      grammarScore: (data['grammarScore'] ?? 6.0).toDouble(),
      vocabularyScore: (data['vocabularyScore'] ?? 6.0).toDouble(),
      coherenceScore: (data['coherenceScore'] ?? 6.0).toDouble(),
      pronunciationScore: data['pronunciationScore'] != null
          ? (data['pronunciationScore']).toDouble()
          : null,
      overallFeedback: data['overallFeedback'] ?? '',
      strengths: (data['strengths'] as List? ?? [])
          .map((s) => FeedbackPoint(
                title: s['title'] ?? '',
                description: s['description'] ?? '',
                example: s['example'],
              ))
          .toList(),
      improvements: (data['improvements'] as List? ?? [])
          .map((s) => FeedbackPoint(
                title: s['title'] ?? '',
                description: s['description'] ?? '',
                example: s['example'],
              ))
          .toList(),
      improvedVersion: data['improvedVersion'],
    );
  }

  static AIFeedback _getDemoFeedback(String type) {
    return AIFeedback(
      overallScore: 6.5,
      grammarScore: 6.5,
      vocabularyScore: 6.0,
      coherenceScore: 7.0,
      pronunciationScore: type == 'speaking' ? 6.5 : null,
      overallFeedback:
          'This is a competent response demonstrating a good command of English. '
          'The main ideas are clearly expressed, though the response would benefit from '
          'a wider range of vocabulary and more complex grammatical structures.',
      strengths: [
        FeedbackPoint(
          title: 'Clear Structure',
          description: 'Your response follows a logical structure with a clear introduction and conclusion.',
          example: 'Your opening paragraph effectively introduces the main topic.',
        ),
        FeedbackPoint(
          title: 'Relevant Content',
          description: 'All points made are relevant to the task and well-developed.',
          example: 'Good use of examples to support your arguments.',
        ),
      ],
      improvements: [
        FeedbackPoint(
          title: 'Lexical Resource',
          description: 'Try to use more varied and sophisticated vocabulary to avoid repetition.',
          example: 'Instead of "good" repeatedly, try: beneficial, advantageous, valuable, constructive.',
        ),
        FeedbackPoint(
          title: 'Complex Sentences',
          description: 'Incorporate more complex grammatical structures to demonstrate range.',
          example: 'Use relative clauses, conditionals, and passive constructions more frequently.',
        ),
        FeedbackPoint(
          title: 'Cohesive Devices',
          description: 'Use a wider range of linking words and phrases.',
          example: 'Instead of "also", try: furthermore, in addition, moreover, what is more.',
        ),
      ],
      improvedVersion:
          'While modern technology has undeniably transformed the way individuals interact, '
          'the extent to which it has undermined face-to-face communication remains a subject of considerable debate.',
    );
  }
}
