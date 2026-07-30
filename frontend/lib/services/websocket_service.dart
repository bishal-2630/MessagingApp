import 'package:web_socket_channel/web_socket_channel.dart';
import 'auth_service.dart';

class WebSocketService {
    static final WebSocketService _instance = WebSocketService._internal();
    WebSocketService._internal();

    factory WebSocketService() => _instance;

    WebSocketChannel? _userChannel;
    WebSocketChannel? _chatChannel;

    Future<void> connectUser() async {
        final token = await AuthService.getAccessToken();
        final uri = Uri.parse('wss://bishall10-chatme.hf.space/ws/user/?token=$token');
        _userChannel = WebSocketChannel.connect(uri);
    } 

    Stream<dynamic> get userMessages => _userChannel!.stream;

    Future<void> connect(int conversationId) async {
        final token = await AuthService.getAccessToken();
        final uri = Uri.parse('wss://bishall10-chatme.hf.space/ws/chat/$conversationId/?token=$token');
        _chatChannel = WebSocketChannel.connect(uri);
    }

    Stream<dynamic> get messages => _chatChannel!.stream;

    void sendMessage(String content) {
        _chatChannel?.sink.add('{"content": "$content"}');
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