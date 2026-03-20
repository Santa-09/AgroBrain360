import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/api_constants.dart';
import 'api_service.dart';
import 'connectivity_service.dart';
import 'language_service.dart';
import 'local_db_service.dart';
import '../models/response_model.dart';
import 'sync_service.dart';

class AuthSvc {
  static final AuthSvc _i = AuthSvc._();
  factory AuthSvc() => _i;
  AuthSvc._();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String language,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final online = await ConnSvc().check();
    if (!online) {
      return _createOfflineSession(
        name: name.trim().isEmpty ? 'Farmer' : name.trim(),
        phone: phone,
        language: language,
        email: normalizedEmail,
      );
    }

    try {
      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'language': language,
          'email': normalizedEmail,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Sign up failed. Supabase did not return a user.');
      }

      final session = response.session;
      if (session == null) {
        throw const AuthException(
          'Account created. Please verify your email first, then sign in.',
        );
      }

      return _completeProfile(
        accessToken: session.accessToken,
        userId: user.id,
        name: name,
        phone: phone,
        language: language,
        email: normalizedEmail,
        metadata: user.userMetadata,
      );
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } on http.ClientException catch (e) {
      throw AuthException('Network error during sign up: $e');
    } catch (e) {
      throw AuthException('Sign up failed: $e');
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    required String fallbackName,
    required String language,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final online = await ConnSvc().check();
    if (!online) {
      return _signInOffline(
        email: normalizedEmail,
        fallbackName: fallbackName,
        language: language,
      );
    }

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = response.user;
      final session = response.session;
      if (user == null || session == null) {
        throw const AuthException('Invalid credentials');
      }

      final metadata = user.userMetadata;
      return _completeProfile(
        accessToken: session.accessToken,
        userId: user.id,
        name: fallbackName,
        phone: metadata?['phone']?.toString() ?? '',
        language: language,
        email: normalizedEmail,
        metadata: metadata,
      );
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await ApiSvc().clearToken();
    await DB.clearUser();
  }

  Future<Map<String, dynamic>> requestPasswordResetOtp({
    required String email,
  }) async {
    final response = await _postWithLocalFallback(
      ApiK.forgotPasswordRequestOtp,
      '${ApiK.local}/auth/forgot-password/request-otp',
      {
      'email': email.trim().toLowerCase(),
      },
    );
    if (!response.ok || response.data == null) {
      throw AuthException(response.error ?? 'Failed to send OTP');
    }
    return response.data!['data'] as Map<String, dynamic>? ?? response.data!;
  }

  Future<Map<String, dynamic>> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _postWithLocalFallback(
      ApiK.forgotPasswordVerifyOtp,
      '${ApiK.local}/auth/forgot-password/verify-otp',
      {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
      },
    );
    if (!response.ok || response.data == null) {
      throw AuthException(response.error ?? 'OTP verification failed');
    }
    return response.data!['data'] as Map<String, dynamic>? ?? response.data!;
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await _postWithLocalFallback(
      ApiK.forgotPasswordReset,
      '${ApiK.local}/auth/forgot-password/reset',
      {
      'email': email.trim().toLowerCase(),
      'reset_token': resetToken,
      'new_password': newPassword,
      },
    );
    if (!response.ok) {
      throw AuthException(response.error ?? 'Password reset failed');
    }
  }

  Future<Res<Map<String, dynamic>>> _postWithLocalFallback(
    String primaryUrl,
    String localUrl,
    Map<String, dynamic> body,
  ) async {
    final primary = await ApiSvc().post(primaryUrl, body);
    if (primary.ok) return primary;

    final shouldTryLocal = !ApiK.useLocal &&
        primaryUrl != localUrl &&
        ((primary.error?.contains('404') ?? false) ||
            (primary.error?.contains('Error 404') ?? false));
    if (!shouldTryLocal) return primary;

    return ApiSvc().post(localUrl, body);
  }

  Future<void> updateLanguagePreference(String language) async {
    final normalizedLanguage = _normalizeLanguage(language);
    if (LangSvc().lang != normalizedLanguage) {
      await LangSvc().set(normalizedLanguage);
    }
    final existing = DB.getUser();
    if (existing == null) return;

    final updated = <String, dynamic>{
      ...existing,
      'language': normalizedLanguage,
    };
    await DB.saveUser(updated);

    final accessToken = await ApiSvc().token;
    final offlineLocalSession = updated['session_mode'] == 'offline_local';
    if (accessToken == null || accessToken.isEmpty || offlineLocalSession) {
      return;
    }

    final response = await _upsertRemoteProfile(
      accessToken: accessToken,
      name: updated['name']?.toString().trim().isNotEmpty == true
          ? updated['name'].toString().trim()
          : 'Farmer',
      phone: updated['phone']?.toString() ?? '',
      language: normalizedLanguage,
      email: updated['email']?.toString() ?? '',
    );

    if (response != null &&
        response.statusCode >= 200 &&
        response.statusCode < 300) {
      final profileBody = _decode(response);
      _mergeProfileBody(updated, profileBody, fallbackLanguage: normalizedLanguage);
      await DB.saveUser(updated);
    }
  }

  Future<Map<String, dynamic>> submitAppFeedback({
    required int rating,
    String? feedback,
  }) async {
    final existing = DB.getUser() ?? <String, dynamic>{};
    final updated = <String, dynamic>{
      ...existing,
      'app_rating': rating,
      'app_feedback': feedback?.trim().isEmpty == true ? null : feedback?.trim(),
      'app_feedback_updated_at': DateTime.now().toIso8601String(),
      'feedback_sync_pending': false,
    };
    await DB.saveUser(updated);

    final accessToken = await ApiSvc().token;
    final offlineLocalSession = updated['session_mode'] == 'offline_local';
    if (accessToken == null || accessToken.isEmpty || offlineLocalSession) {
      if (!offlineLocalSession) {
        updated['feedback_sync_pending'] = true;
        await DB.saveUser(updated);
        await DB.addSyncRecord(
          module: 'profile_feedback',
          payload: {
            'rating': rating,
            'feedback': updated['app_feedback'],
          },
        );
      }
      return updated;
    }

    final response = await ApiSvc().post(ApiK.authProfileFeedback, {
      'rating': rating,
      'feedback': updated['app_feedback'],
    });
    if (response.ok && response.data != null) {
      final payload =
          response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      _mergeProfileBody(updated, payload, fallbackLanguage: updated['language']?.toString() ?? 'en');
      updated['feedback_sync_pending'] = false;
      await DB.saveUser(updated);
      return updated;
    }

    updated['feedback_sync_pending'] = true;
    await DB.saveUser(updated);
    await DB.addSyncRecord(
      module: 'profile_feedback',
      payload: {
        'rating': rating,
        'feedback': updated['app_feedback'],
      },
    );
    return updated;
  }

  Future<Map<String, dynamic>> _completeProfile({
    required String accessToken,
    required String userId,
    required String name,
    required String phone,
    required String language,
    required String email,
    Map<String, dynamic>? metadata,
  }) async {
    await ApiSvc().saveToken(accessToken);

    final metadataName = metadata?['name']?.toString().trim();
    final metadataPhone = metadata?['phone']?.toString().trim();
    final resolvedName = metadataName == null || metadataName.isEmpty ? name : metadataName;
    final resolvedPhone = metadataPhone == null || metadataPhone.isEmpty ? phone : metadataPhone;

    final normalized = <String, dynamic>{
      'user_id': userId,
      'id': userId,
      'name': resolvedName.isEmpty ? 'Farmer' : resolvedName,
      'phone': resolvedPhone,
      'language': _normalizeLanguage(language),
      'email': email,
      'token': accessToken,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final profileRes = await _fetchRemoteProfile(accessToken);
      if (profileRes != null &&
          profileRes.statusCode >= 200 &&
          profileRes.statusCode < 300) {
        final profileBody = _decode(profileRes);
        _mergeProfileBody(
          normalized,
          profileBody,
          fallbackLanguage: normalized['language'].toString(),
        );
      } else if (profileRes?.statusCode == 404) {
        final upsertRes = await _upsertRemoteProfile(
          accessToken: accessToken,
          name: normalized['name'].toString(),
          phone: normalized['phone']?.toString() ?? '',
          language: normalized['language'].toString(),
          email: email,
        );
        if (upsertRes != null &&
            upsertRes.statusCode >= 200 &&
            upsertRes.statusCode < 300) {
          final profileBody = _decode(upsertRes);
          _mergeProfileBody(
            normalized,
            profileBody,
            fallbackLanguage: normalized['language'].toString(),
          );
        }
      }
    } catch (_) {
      // Keep auth usable even when backend profile sync is unavailable.
    }

    final effectiveLanguage =
        _normalizeLanguage(normalized['language']?.toString() ?? language);
    normalized['language'] = effectiveLanguage;
    await DB.saveUser(normalized);
    if (LangSvc().lang != effectiveLanguage) {
      await LangSvc().set(effectiveLanguage);
    }
    try {
      await SyncSvc().sync();
      await SyncSvc().restoreHistory();
    } catch (_) {
      // Keep auth usable even when history sync is unavailable.
    }
    return normalized;
  }

  Future<Map<String, dynamic>> _signInOffline({
    required String email,
    required String fallbackName,
    required String language,
  }) async {
    final existing = DB.getUser();
    if (existing != null && (existing['email']?.toString().toLowerCase() ?? '') == email) {
      final updated = <String, dynamic>{
        ...existing,
        'language': language,
        'email': existing['email'] ?? email,
        'session_mode': existing['session_mode'] ?? 'offline_local',
        'last_login_at': DateTime.now().toIso8601String(),
      };
      await DB.saveUser(updated);
      return updated;
    }

    return _createOfflineSession(
      name: fallbackName.trim().isEmpty ? 'Farmer' : fallbackName.trim(),
      phone: existing?['phone']?.toString() ?? '',
      language: language,
      email: email,
    );
  }

  Future<Map<String, dynamic>> _createOfflineSession({
    required String name,
    required String phone,
    required String language,
    required String email,
  }) async {
    final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final emailKey = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final localId = phoneDigits.isNotEmpty ? 'offline_$phoneDigits' : 'offline_$emailKey';
    final normalized = <String, dynamic>{
      'user_id': localId,
      'id': localId,
      'name': name,
      'phone': phone,
      'language': language,
      'email': email,
      'token': null,
      'session_mode': 'offline_local',
      'created_at': DateTime.now().toIso8601String(),
    };
    await DB.saveUser(normalized);
    return normalized;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      return {
        'message': 'Unexpected non-JSON response (${response.statusCode})',
        'raw': response.body,
      };
    }
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  String _message(Map<String, dynamic> body, String fallback) {
    return body['msg']?.toString() ??
        body['message']?.toString() ??
        body['error_description']?.toString() ??
        body['error']?.toString() ??
        fallback;
  }

  String _normalizeLanguage(String code) {
    return LangSvc.supported.containsKey(code) ? code : 'en';
  }

  void _mergeProfileBody(
    Map<String, dynamic> target,
    Map<String, dynamic> profileBody, {
    required String fallbackLanguage,
  }) {
    target.addAll({
      'user_id': profileBody['user_id'] ?? target['user_id'],
      'id': profileBody['user_id'] ?? target['id'],
      'name': profileBody['name'] ?? target['name'],
      'phone': profileBody['phone'] ?? target['phone'],
      'language': _normalizeLanguage(
        profileBody['language']?.toString() ?? fallbackLanguage,
      ),
      'email': profileBody['email'] ?? target['email'],
      'app_rating': profileBody['app_rating'] ?? target['app_rating'],
      'app_feedback': profileBody['app_feedback'] ?? target['app_feedback'],
      'app_feedback_updated_at': profileBody['app_feedback_updated_at'] ??
          target['app_feedback_updated_at'],
      'feedback_sync_pending': false,
    });
  }

  Future<http.Response?> _fetchRemoteProfile(String accessToken) async {
    try {
      return await http
          .get(
            Uri.parse(ApiK.authProfileMe),
            headers: ApiK.headers(token: accessToken),
          )
          .timeout(const Duration(milliseconds: ApiK.timeoutMs));
    } catch (_) {
      return null;
    }
  }

  Future<http.Response?> _upsertRemoteProfile({
    required String accessToken,
    required String name,
    required String phone,
    required String language,
    required String email,
  }) async {
    try {
      return await http
          .post(
            Uri.parse(ApiK.authProfile),
            headers: ApiK.headers(token: accessToken),
            body: jsonEncode({
              'name': name,
              'phone': phone,
              'language': language,
              'email': email,
            }),
          )
          .timeout(const Duration(milliseconds: ApiK.timeoutMs));
    } catch (_) {
      return null;
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
