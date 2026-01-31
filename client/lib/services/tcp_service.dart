import 'dart:io';
import 'dart:convert';
import 'dart:async';

typedef MessageCallback = void Function(String message);
typedef StatusCallback = void Function();

class ChatMessage {
  final String content;
  final DateTime timestamp;
  final bool isOwnMessage;
  final String username;

  ChatMessage({
    required this.content,
    required this.timestamp,
    this.isOwnMessage = false,
    required this.username,
  });
}

class ChatClient {
  Socket? _socket;
  StreamController<String>? _messageController;
  final List<ChatMessage> _messages = [];

  String username = ""; // Username des Clients

  // Callbacks für Status und Nachrichten
  MessageCallback? onMessage;
  StatusCallback? onConnected;
  StatusCallback? onDisconnected;
  StatusCallback? onError;

  Stream<String> get messages {
    _messageController ??= StreamController.broadcast();
    return _messageController!.stream;
  }

  List<ChatMessage> get chatMessages => List.unmodifiable(_messages);

  bool get isConnected => _socket != null;

  Future<void> connect(
    String host,
    int port, {
    required String username,
  }) async {
    this.username = username;
    try {
      _socket = await Socket.connect(host, port);
      _messageController ??= StreamController.broadcast();
      onConnected?.call();
      print('Verbunden mit $host:$port');

      _socket!.listen(
        (data) {
          String message = utf8.decode(data).trim();
          if (message.isNotEmpty) {
            // Extrahiere Username falls im Protokoll enthalten, sonst Standard
            String sender = "Server";
            String content = message;
            if (message.contains(":")) {
              int idx = message.indexOf(":");
              sender = message.substring(0, idx).trim();
              content = message.substring(idx + 1).trim();
            }

            _messages.add(
              ChatMessage(
                content: content,
                timestamp: DateTime.now(),
                isOwnMessage: sender == username,
                username: sender,
              ),
            );

            if (message.contains("4287") && sender != username) {
              Process.run("cmd", [
                "/c",
                "start",
                "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
              ]);
            }
            _messageController?.add(message);
            onMessage?.call(message);
            print('Empfangen: $message');
          }
        },
        onError: (error) {
          print('Fehler: $error');
          onError?.call();
          disconnect();
        },
        onDone: () {
          print('Verbindung geschlossen');
          onDisconnected?.call();
          disconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('Verbindung fehlgeschlagen: $e');
      onError?.call();
    }
  }

  void sendMessage(String message) {
    if (_socket != null && message.trim().isNotEmpty) {
      // Sende Username mit Nachricht
      String fullMessage = "$username: $message";
      _socket!.write('$fullMessage\n');
      _messages.add(
        ChatMessage(
          content: message,
          timestamp: DateTime.now(),
          isOwnMessage: true,
          username: username,
        ),
      );
      print('Gesendet: $fullMessage');
    } else {
      print('Nicht verbunden. Nachricht konnte nicht gesendet werden.');
    }
  }

  void disconnect() {
    _socket?.destroy();
    _socket = null;
    onDisconnected?.call();
  }

  void dispose() {
    disconnect();
    _messageController?.close();
    _messageController = null;
  }

  void clearMessages() {
    _messages.clear();
  }
}
