import 'package:dio/dio.dart';
import 'auth_service.dart';

class ApiService {
    static final Dio _dio = Dio(
        BaseOptions(
            baseUrl: 'http://10.0.2.2:8000/api/',
            contentType: 'application/json',
        ),
    )..interceptors.add(
        InterceptorsWrapper(
            onRequest: (options, handler) async {
                final token = await AuthService.getAccessToken();
                if (token != null) {
                    options.headers['Authorization'] = 'Bearer $token';
                }
                return handler.next(options);
            },
            onError: (DioException error, handler) async {
                if(error.response?.statusCode == 401){
                    final refreshToken = await AuthService.getRefreshToken();
                    if(refreshToken != null){
                        try {
                            final response = await Dio().post('http://10.0.2.2:8000/api/token/refresh/',
                            data: {'refresh': refreshToken},
                            );
                            final newAccessToken = response.data['access'];
                            await AuthService.saveTokens(
                                access: newAccessToken,
                                refresh: refreshToken
                            );
                            error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                            final retryResponse = await _dio.fetch(error.requestOptions);
                            return handler.resolve(retryResponse);
                        } catch (_) {
                            await AuthService.deleteTokens();
                        } 

                        }
                    }
                    return handler.next(error);
                },
        ),
    );

    static Future<Map<String, dynamic>> register({
        required String username,
        required String email,
        required String password,
    }) async {
        final response = await _dio.post('register/',
        data: {
            'username': username,
            'email': email,
            'password': password,
        },
        );
        return response.data;
    }

    static Future<Map<String, dynamic>> login({
        required String email,
        required String password,
    }) async {
        final response = await _dio.post('login/',
        data: {
            'email': email,
            'password': password,
        },
        );
        return response.data;
    }


static Future<Map<String, dynamic>> searchUser(String username) async {
    final response = await _dio.get('users/search/', queryParameters: {'username': username},
    );
    return response.data;
}

static Future<Map<String, dynamic>> getOrCreateConversation(int targetUserId) async {
    final response = await _dio.post('conversations/', data: {'target_user_id': targetUserId});
    return response.data;
}

static Future<List<dynamic>> getConversations() async {
    final response = await _dio.get('conversations/');
    return response.data['results'];
}
}