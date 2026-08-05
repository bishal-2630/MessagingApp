import 'package:dio/dio.dart';
import 'auth_service.dart';

class ApiService {
    static final Dio _dio = Dio(
        BaseOptions(
            baseUrl: 'https://bishall10-chatme.hf.space/api/',
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
                final path = error.requestOptions.path;
                if (path.contains('login') || 
                    path.contains('register') || 
                    path.contains('token/refresh') ||
                    path.contains('forgot-password') ||
                    path.contains('verify-otp') ||
                    path.contains('reset-password') ||
                    path.contains('verify-email') ||
                    path.contains('resend-verification') ||
                    path.contains('google-login')) {
                    return handler.next(error);
                }

                if(error.response?.statusCode == 401){
                    final refreshToken = await AuthService.getRefreshToken();
                    if(refreshToken != null){
                        try {
                            final response = await Dio().post('https://bishall10-chatme.hf.space/api/token/refresh/',
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

    static Future<List<dynamic>> getMessages(int conversationId) async {
        final response = await _dio.get(
            'messages/',
            queryParameters: {'conversation': conversationId},
        );
        // Handle both paginated (dict with 'results') and unpaginated (list) responses
        if (response.data is Map && response.data.containsKey('results')) {
            return response.data['results'];
        }
        return response.data as List<dynamic>;
    }

    static Future<Map<String, dynamic>> sendMessage(int conversationId, String content) async {
        final response = await _dio.post(
            'messages/',
            data: {
                'conversation': conversationId,
                'content': content,
            },
        );
        return response.data;
    }

    static Future<void> registerFCMToken(String token) async {
        await _dio.post('fcm/token/', data: {'token': token});
    }

    static Future<Map<String, dynamic>> getUserStatus(int userId) async {
        final response = await _dio.get('users/$userId/status/');
        return response.data;
    }

    static Future<Map<String, dynamic>> forgotPassword(String email) async {
        final response = await _dio.post('users/forgot-password/', data: {'email': email});
        return response.data;
    }

    static Future<Map<String, dynamic>> verifyOtp({
        required String email,
        required String otp,
    }) async {
        final response = await _dio.post('users/verify-otp/', data: {'email': email, 'otp': otp});
        return response.data;
    }

    static Future<Map<String, dynamic>> resetPassword({
        required String resetToken,
        required String newPassword,
    }) async {
        final response = await _dio.post('users/reset-password/', data: {
            'reset_token': resetToken,
            'new_password': newPassword,
        });
        return response.data;
    }

    static Future<Map<String, dynamic>> verifyEmail({
        required String email,
        required String otp,
    }) async {
        final response = await _dio.post('users/verify-email/', data: {
            'email': email,
            'otp': otp,
        });
        return response.data;
    }

    static Future<Map<String, dynamic>> resendVerification({
        required String email,
    }) async {
        final response = await _dio.post('users/resend-verification/', data: {
            'email': email,
        });
        return response.data;
    }

    static Future<Map<String, dynamic>> googleLogin({
        required String idToken,
    }) async {
        final response = await _dio.post('users/google-login/', data: {
            'id_token': idToken,
        });
        return response.data;
    }
    

}