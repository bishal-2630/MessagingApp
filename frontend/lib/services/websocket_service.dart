import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'auth_service.dart';

class WebSocketService {
    static final WebSocketService _instance = WebSocketService._internal();
    WebSocketService._internal();

    factory WebSocketService() => _instance;

    WebSocketChannel? _userChannel;
    WebSocketChannel? _chatChannel;

    // Broadcast StreamControllers — allow multiple listeners!
    final StreamController<dynamic> _chatStreamController = 
        StreamController<dynamic>.broadcast();
    final StreamController<dynamic> _userStreamController = 
        StreamController<dynamic>.broadcast();

    Stream<dynamic> get messages => _chatStreamController.stream;
    Stream<dynamic> get userMessages => _userStreamController.stream;

    int? _currentConversationId;

    Future<void> connectUser() async {
        if (_userChannel != null) return;
        final token = await AuthService.getAccessToken();
        final uri = Uri.parse('wss://bishall10-chatme.hf.space/ws/user/?token=$token');
        _userChannel = WebSocketChannel.connect(uri);
        // Pipe all incoming events into the broadcast controller
        _userChannel!.stream.listen(
            (data) => _userStreamController.add(data),
            onError: (e) {
                _userStreamController.addError(e);
                _userChannel = null;
            },
            onDone: () {
                _userChannel = null;
            },
        );
    }

    Future<void> connect(int conversationId) async {
        if (_currentConversationId == conversationId && _chatChannel != null) {
            return;
        }
        _currentConversationId = conversationId;
        await _chatChannel?.sink.close();
        
        final token = await AuthService.getAccessToken();
        final uri = Uri.parse('wss://bishall10-chatme.hf.space/ws/chat/$conversationId/?token=$token');
        _chatChannel = WebSocketChannel.connect(uri);
        // Pipe all incoming events into the broadcast controller
        _chatChannel!.stream.listen(
            (data) => _chatStreamController.add(data),
            onError: (e) {
                _chatStreamController.addError(e);
                _chatChannel = null;
                _currentConversationId = null;
            },
            onDone: () {
                _chatChannel = null;
                _currentConversationId = null;
            },
        );
    }

    Future<void> sendMessage(String content) async {
        if (_chatChannel == null && _currentConversationId != null) {
            await connect(_currentConversationId!);
        }
        _chatChannel?.sink.add(jsonEncode({'content': content}));
    }

    void sendTypingStatus(bool isTyping) {
        _chatChannel?.sink.add(jsonEncode({'type': 'typing', 'is_typing': isTyping}));
    }

    void sendReadReceipt(int conversationId) {
        _chatChannel?.sink.add(jsonEncode({'type': 'read_receipt', 'conversation_id': conversationId}));
    }

    void disconnect() {
        _chatChannel?.sink.close();
        _chatChannel = null;
        _currentConversationId = null;
    }

    void disconnectUser() {
        _userChannel?.sink.close();
        _userChannel = null;
    }
}
