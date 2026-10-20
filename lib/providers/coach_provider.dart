import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymgen_ai/models/chat_message_model.dart';
import 'package:gymgen_ai/services/ai_service.dart';
import 'package:gymgen_ai/services/local_storage_service.dart';

class CoachProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _responding = false;
  bool _streamStarted = false;
  String? _error;
  String _uid = '';
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;

  List<ChatMessage> get messages => _messages;
  bool get responding => _responding;
  bool get streamStarted => _streamStarted;
  String? get error => _error;

  Future<void> load(String uid) async {
    await _messagesSubscription?.cancel();
    if (_uid != uid) _messages = [];
    _uid = uid;

    List<Map<String, dynamic>> data;
    try {
      data = await LocalStorageService.instance.loadChatMessages(uid);
      _error = null;
    } catch (e) {
      data = [];
      _error = 'Chat history could not be loaded: $e';
    }

    if (data.isEmpty) {
      _messages = [
        ChatMessage(
          id: 'welcome',
          content:
              'Hi! I\'m your AI Fitness Coach. 💪\n\nHow can I help you today? You can ask me about:\n• Workout tips and form\n• Nutrition and diet advice\n• Recovery and rest\n• Motivation and mindset\n• Progress tracking',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    } else {
      _messages = data.map((d) => ChatMessage.fromJson(d)).toList();
    }

    _messagesSubscription = LocalStorageService.instance
        .watchListData(uid, 'chat')
        .listen((items) {
      if (_responding) return;
      _messages = items.isEmpty
          ? [
              ChatMessage(
                id: 'welcome',
                content: 'Hi! I\'m your AI Fitness Coach. 💪\n\nHow can I help you today?',
                isUser: false,
                timestamp: DateTime.now(),
              ),
            ]
          : items.map(ChatMessage.fromJson).toList();
      notifyListeners();
    }, onError: (Object error) {
      _error = 'Chat sync failed: $error';
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _responding) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages = [..._messages, userMsg];
    _responding = true;
    _streamStarted = false;
    _error = null;
    notifyListeners();

    try {
      final previousMessages = _messages
          .where(
            (message) =>
                message.id != 'welcome' && message.id != userMsg.id,
          )
          .where((message) => message.content.trim().isNotEmpty)
          .toList();

      final recentMessages = previousMessages.length > 20
          ? previousMessages.sublist(previousMessages.length - 20)
          : previousMessages;

      final history = recentMessages
          .map(
            (message) => {
              'role': message.isUser ? 'user' : 'model',
              'text': message.content,
            },
          )
          .toList();

      final aiMessageId =
          (DateTime.now().millisecondsSinceEpoch + 1).toString();
      final responseBuffer = StringBuffer();

      final answer = await AiService.instance.sendMessage(text, history);
      responseBuffer.write(answer);
      final aiMsg = ChatMessage(
        id: aiMessageId,
        content: answer,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages = [..._messages, aiMsg];
      _streamStarted = true;
      notifyListeners();

      try {
        await _save();
      } catch (e) {
        _error = 'The AI replied, but chat history could not be saved. '
            'Details: $e';
      }
    } catch (e) {
      _error = 'The AI coach could not respond. Check your connection and '
          'make sure Firebase AI Logic and App Check are configured. Details: $e';
    }

    _responding = false;
    _streamStarted = false;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _messages = [
      ChatMessage(
        id: 'welcome',
        content:
            'Hi! I\'m your AI Fitness Coach. 💪\n\nHow can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
    try {
      await _save();
      _error = null;
    } catch (e) {
      _error = 'Chat reset on this device; cloud sync failed: $e';
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await LocalStorageService.instance.saveChatMessages(
      _uid,
      _messages.map((m) => m.toJson()).toList(),
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
