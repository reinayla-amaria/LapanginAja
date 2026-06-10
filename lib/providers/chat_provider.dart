import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String text;
  final String senderId;
  final String time;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.senderId,
    required this.time,
    required this.isUser,
  });
}

class ChatProvider with ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://lapanginaja-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  String? _currentUserId;
  String? _currentChatId;

  void listenToChat(String userId, String mitraId) {
    _currentUserId = userId;
    _currentChatId = '${userId}_$mitraId';

    final ref = _db.ref('chats/$_currentChatId/messages');
    ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        _messages = [];
        notifyListeners();
        return;
      }

      final Map<dynamic, dynamic> map = data as Map;
      _messages = map.entries.map((e) {
        final msg = Map<String, dynamic>.from(e.value);
        return ChatMessage(
          text: msg['text'] ?? '',
          senderId: msg['senderId'] ?? '',
          time: msg['time'] ?? '',
          isUser: msg['senderId'] == userId,
        );
      }).toList();

      _messages.sort((a, b) => a.time.compareTo(b.time));
      notifyListeners();
    });
  }

  Future<void> sendMessage(String text, String userId, String mitraId) async {
    final chatId = '${userId}_$mitraId';
    final ref = _db.ref('chats/$chatId/messages');
    await ref.push().set({
      'text': text,
      'senderId': userId,
      'time': DateTime.now().toIso8601String(),
    });
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}
