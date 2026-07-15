import 'package:dio/dio.dart';

class ApiService {
    static final Dio _dio = Dio(
        BaseOptions(
            baseUrl: 'http://10.0.2.2:8000/api/',
            contentType: 'application/json',
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
}