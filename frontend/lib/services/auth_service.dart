import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
    static const _storage = FlutterSecureStorage();
    static const _accesskey = 'access_token';
    static const _refreshkey = 'refresh_token';

    static Future<void> saveTokens({required String access, required String refresh}) async {
        await _storage.write(key: _accesskey, value: access);
        await _storage.write(key: _refreshkey, value: refresh);
    }

    static Future<String?> getAccessToken() async {
        return await _storage.read(key: _accesskey);
    }

    static Future<String?> getRefreshToken() async {
        return await _storage.read(key: _refreshkey);
    }

    static Future<void> deleteTokens() async {
        await _storage.delete(key: _accesskey);
        await _storage.delete(key: _refreshkey);
    }

}