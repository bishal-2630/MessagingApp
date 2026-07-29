import 'package:web_socket_channel/web_socket_channel.dart';
import 'auth_service.dart';

class WebSocketService {
    WebSocketChannel? _channel;

    Future<void> connect(int conversationId) async {
        final token = await AuthService.getAccessToken();
        final uri = Uri.parse('wss://bishall10-chatme.hf.space/ws/chat/$conversationId/?token=$token');
        _channel = WebSocketChannel.connect(uri);
    }

    Stream<dynamic> get messages {
        return _channel!.stream;
    }

    void sendMessage(String content) {
        _channel?.sink.add('{"content": "$content"}');
    }

    void disconnect() {
        _channel?.sink.close();
        _channel = null;
    }
}