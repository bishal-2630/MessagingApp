import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
    static const _storage = FlutterSecureStorage();
    static const _accesskey = 'access_token';
    static const _refreshkey = 'refresh_token';
    static const _usernameKey = 'username';

    static Future<void> saveTokens({required String access, required String refresh, String? username}) async {
        await _storage.write(key: _accesskey, value: access);
        await _storage.write(key: _refreshkey, value: refresh);
        if (username != null) {
            await _storage.write(key: _usernameKey, value: username);
        }
    }

    static Future<String?> getAccessToken() async {
        return await _storage.read(key: _accesskey);
    }

    static Future<String?> getRefreshToken() async {
        return await _storage.read(key: _refreshkey);
    }

    static Future<String?> getUsername() async {
        return await _storage.read(key: _usernameKey);
    }

    static Future<void> deleteTokens() async {
        await _storage.delete(key: _accesskey);
        await _storage.delete(key: _refreshkey);
        await _storage.delete(key: _usernameKey);
    }

}