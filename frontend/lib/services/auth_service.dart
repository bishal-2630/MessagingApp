import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
    static const _storage = FlutterSecureStorage();
    static const _tokenkey = 'auth_token';

    static Future<void> saveToken(String token) async {
        await _storage.write(key: _tokenkey, value: token);
    }

    static Future<String?> getToken() async {
        return await _storage.read(key: _tokenkey);
    }

    static Future<void> deleteToken() async {
        await _storage.delete(key: _tokenkey);
    }

}