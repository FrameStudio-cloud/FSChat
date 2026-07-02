import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GroqAnalysis {
  final String transcript;
  final int wordCount;
  final int fillerWordCount;
  final List<String> fillerWords;
  final int pace;
  final int score;
  final String tips;

  GroqAnalysis({
    required this.transcript,
    required this.wordCount,
    required this.fillerWordCount,
    required this.fillerWords,
    required this.pace,
    required this.score,
    required this.tips,
  });
}

class GroqService {
  static const _baseUrl = 'https://api.groq.com/openai/v1';
  final String _apiKey;
  final http.Client _client;

  GroqService({http.Client? client})
      : _apiKey = ApiConfig.groqApiKey,
        _client = client ?? http.Client();

  Future<GroqAnalysis> transcribeAndAnalyze(
      String filePath, int durationSec) async {
    final transcript = await _transcribeAudio(filePath);
    return await _analyzeTranscript(transcript, durationSec);
  }

  Future<String> _transcribeAudio(String filePath) async {
    final uri = Uri.parse('$_baseUrl/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..fields['model'] = 'whisper-large-v3'
      ..fields['response_format'] = 'json'
      ..fields['language'] = 'en'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception(
          'Groq transcription failed: ${streamed.statusCode} $body');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }

  Future<GroqAnalysis> _analyzeTranscript(
      String transcript, int durationSec) async {
    if (transcript.isEmpty) {
      return GroqAnalysis(
        transcript: '',
        wordCount: 0,
        fillerWordCount: 0,
        fillerWords: [],
        pace: 0,
        score: 0,
        tips: 'No speech detected. Try speaking closer to the microphone.',
      );
    }

    final uri = Uri.parse('$_baseUrl/chat/completions');
    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a speech coach. Analyze the transcript and return JSON. '
                'Count total words and filler words (um, uh, like, you know, actually, basically, literally, sort of, kind of, I mean, right, so, well, just, really). '
                'Calculate pace as words / (durationSec / 60). '
                'Score 0-100 based on filler density and pace. '
                'Return: {"wordCount":int,"fillerWordCount":int,"fillerWords":[...],"pace":int,"score":int,"tips":"2-3 sentence improvement tip"}',
          },
          {
            'role': 'user',
            'content': 'Transcript: "$transcript"\nDuration: ${durationSec}s',
          },
        ],
        'response_format': {'type': 'json_object'},
        'temperature': 0.3,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Groq analysis failed: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Groq analysis returned no choices');
    }

    final content = choices[0]['message']['content'] as String? ?? '{}';
    final result = jsonDecode(content) as Map<String, dynamic>;

    final wordCount =
        result['wordCount'] as int? ?? transcript.split(RegExp(r'\s+')).length;
    final fillerWordCount = result['fillerWordCount'] as int? ?? 0;
    final fillerWords =
        (result['fillerWords'] as List?)?.map((e) => e.toString()).toList() ??
            [];
    final pace = result['pace'] as int? ??
        (durationSec > 0 ? (wordCount / (durationSec / 60)).round() : 0);
    final score = result['score'] as int? ?? 50;
    final tips = result['tips'] as String? ??
        'Good start! Keep practicing to improve your speaking skills.';

    return GroqAnalysis(
      transcript: transcript,
      wordCount: wordCount,
      fillerWordCount: fillerWordCount,
      fillerWords: fillerWords,
      pace: pace,
      score: score,
      tips: tips,
    );
  }

  void dispose() {
    _client.close();
  }
}
