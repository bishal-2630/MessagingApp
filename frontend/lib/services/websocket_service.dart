import 'dart:async';
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

    Future<void> connectUser() async {
        final token = await AuthService.getAccessToken();
        final uri = Uri.parse('wss://bishall10-chatme.hf.space/ws/user/?token=$token');
        _userChannel = WebSocketChannel.connect(uri);
        // Pipe all incoming events into the broadcast controller
        _userChannel!.stream.listen(
            (data) => _userStreamController.add(data),
            onError: (e) => _userStreamController.addError(e),
        );
    }

    Future<void> connect(int conversationId) async {
        // Disconnect old channel first if switching conversations
        await _chatChannel?.sink.close();
        
        final token = await AuthService.getAccessToken();
        final uri = Uri.parse('wss://bishall10-chatme.hf.space/ws/chat/$conversationId/?token=$token');
        _chatChannel = WebSocketChannel.connect(uri);
        // Pipe all incoming events into the broadcast controller
        _chatChannel!.stream.listen(
            (data) => _chatStreamController.add(data),
            onError: (e) => _chatStreamController.addError(e),
        );
    }

    void sendMessage(String content) {
        _chatChannel?.sink.add('{"content": "$content"}');
    }

    void sendTypingStatus(bool isTyping) {
        _chatChannel?.sink.add('{"type": "typing", "is_typing": $isTyping}');
    }

    void sendReadReceipt(int conversationId) {
        _chatChannel?.sink.add('{"type": "read_receipt", "conversation_id": $conversationId}');
    }

    void disconnect() {
        _chatChannel?.sink.close();
        _chatChannel = null;
    }

    void disconnectUser() {
        _userChannel?.sink.close();
        _userChannel = null;
    }
}
