import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthState {
    final bool isAuthenticated;
    final String? username;

    AuthState({
        required this.isAuthenticated,
        this.username,
    });

    factory AuthState.unauthenticated() {
        return AuthState(isAuthenticated: false,
        username: null);
    }
}

class AuthNotifier extends StateNotifier<AuthState> {
    AuthNotifier(): super(AuthState.unauthenticated()) {
        _init();
    }

    Future<void> _init() async {
        final token = await AuthService.getAccessToken();
        final username = await AuthService.getUsername();
        if(token != null) {
            state = AuthState(isAuthenticated: true, username: username);
        }
    }

    Future<void> login({required String access, required String refresh, String? username}) async {
        await AuthService.saveTokens(access: access, refresh: refresh, username: username);
        state = AuthState(isAuthenticated: true, username: username);
    }

    Future<void> logout() async {
        await AuthService.deleteTokens();
        state = AuthState.unauthenticated();
    }

}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
    return AuthNotifier();
});