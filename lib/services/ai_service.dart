import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  // Groq API Configuration
  static const _baseUrl = 'https://api.groq.com/openai/v1';
  static const _apiKey = 'API_KEY'; // Replace with your actual Groq API key
  
  // Groq's fastest and smartest free model (Llama 3.3 70B)
  static const _model = 'openai/gpt-oss-120b'; 

  static const _systemInstruction = '''
You are GymGen AI, a knowledgeable, supportive fitness and wellness coach.
Answer the user's question directly and clearly. You may answer general questions,
but prioritize exercise, strength training, cardio, mobility, sports performance,
recovery, sleep, nutrition, healthy habits, fitness motivation, and progress.
Give practical steps, explain important trade-offs, and ask a brief follow-up when
key details such as experience, equipment, schedule, or goal are missing. Do not
pretend to know personal details the user has not shared. Keep answers easy to scan.

Safety: You are not a doctor, dietitian, or emergency service. Do not diagnose,
prescribe treatment, or guarantee results. For chest pain, fainting, severe
shortness of breath, or a serious injury, tell the user to stop exercising and
seek urgent medical care. For persistent pain, medical conditions, pregnancy,
medication questions, or eating-disorder concerns, recommend a qualified health
professional. Do not recommend crash diets, extreme weight loss, dangerous
supplements, or performance-enhancing drugs. Give general, balanced guidance,
and note when advice needs personalization. Be respectful and non-judgmental.
''';

  /// Send a message to Groq and return the reply text.
  /// Requires the user to be logged in via Firebase Auth.
  Future<String> sendMessage(
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    // 1. Keep Firebase Auth: only logged-in users can call AI
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Sign in to use the AI fitness coach.');
    }

    // 2. Build OpenAI-format message list (system + history + current message)
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemInstruction},
      ...history.map((turn) => {
            'role': turn['role'] == 'model' ? 'assistant' : 'user',
            'content': turn['text'] ?? '',
          }),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      // 3. Call Groq (OpenAI-compatible endpoint)
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'max_tokens': 900,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 20)); // Groq is super fast, 20s timeout is plenty

      if (response.statusCode != 200) {
        throw Exception(
          'Groq API error (${response.statusCode}): ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices']?[0]?['message']?['content'] as String?;

      if (content == null || content.trim().isEmpty) {
        throw Exception('Groq returned an empty response.');
      }

      return content.trim();
    } catch (e) {
      if (e.toString().contains('429')) {
        throw Exception('The AI Coach is receiving too many requests right now. Please wait a few seconds and try again.');
      }
      rethrow;
    }
  }
}