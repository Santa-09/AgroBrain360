import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../models/response_model.dart';
import 'language_service.dart';

class ApiSvc {
  static final ApiSvc _i = ApiSvc._();
  factory ApiSvc() => _i;
  ApiSvc._();

  String? _token;

  Future<String?> get _tok async {
    if (_token != null) return _token;
    final p = await SharedPreferences.getInstance();
    return _token = p.getString('token');
  }

  Future<String?> get token async => _tok;

  Future<bool> hasToken() async => (await _tok)?.isNotEmpty == true;

  Future<void> saveToken(String t) async {
    _token = t;
    (await SharedPreferences.getInstance()).setString('token', t);
  }

  Future<void> clearToken() async {
    _token = null;
    (await SharedPreferences.getInstance()).remove('token');
  }

  Future<Res<Map<String, dynamic>>> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final tok = await _tok;
    final payload = _withAppLanguage(url, body);
    Object? lastError;
    for (final candidate in _candidateUrls(url)) {
      try {
        final res = await http
            .post(
              Uri.parse(candidate),
              headers: ApiK.headers(token: tok),
              body: jsonEncode(payload),
            )
            .timeout(const Duration(milliseconds: ApiK.timeoutMs));
        return _parse(res);
      } on SocketException catch (e) {
        lastError = e;
      } on TimeoutException catch (e) {
        lastError = e;
      } catch (e) {
        return Res.fail(_friendlyError(e));
      }
    }
    return _failureFrom(lastError);
  }

  Future<Res<Map<String, dynamic>>> get(
    String url, {
    Map<String, String>? q,
  }) async {
    final tok = await _tok;
    Object? lastError;
    for (final candidate in _candidateUrls(url)) {
      try {
        final uri = Uri.parse(candidate).replace(queryParameters: q);
        final res = await http
            .get(uri, headers: ApiK.headers(token: tok))
            .timeout(const Duration(milliseconds: ApiK.timeoutMs));
        return _parse(res);
      } on SocketException catch (e) {
        lastError = e;
      } on TimeoutException catch (e) {
        lastError = e;
      } catch (e) {
        return Res.fail(_friendlyError(e));
      }
    }
    return _failureFrom(lastError);
  }

  Future<Res<Map<String, dynamic>>> multipart(
    String url,
    File f, [
    Map<String, String>? fields,
    int timeoutMs = ApiK.timeoutMs,
  ]) async {
    final tok = await _tok;
    Object? lastError;
    for (final candidate in _candidateUrls(url)) {
      try {
        final req = http.MultipartRequest('POST', Uri.parse(candidate));
        if (tok != null) req.headers['Authorization'] = 'Bearer $tok';
        req.files.add(await http.MultipartFile.fromPath('file', f.path));
        if (fields != null) req.fields.addAll(fields);
        final streamed =
            await req.send().timeout(Duration(milliseconds: timeoutMs));
        final res = await http.Response.fromStream(streamed);
        return _parse(res);
      } on SocketException catch (e) {
        lastError = e;
      } on TimeoutException catch (e) {
        lastError = e;
      } catch (e) {
        return Res.fail(_friendlyError(e));
      }
    }
    return _failureFrom(lastError);
  }

  Res<Map<String, dynamic>> _parse(http.Response res) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body != null) return Res.success(body);
      return Res.success({});
    }
    final message = body?['error']?.toString() ??
        body?['detail']?.toString() ??
        'Error ${res.statusCode}';
    return Res.fail(_friendlyText(message));
  }

  String _tr(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  Map<String, dynamic> _withAppLanguage(
    String url,
    Map<String, dynamic> body,
  ) {
    if (url != ApiK.llmAdvise && url != ApiK.chatCase) {
      return body;
    }

    final language = LangSvc().lang;
    final payload = Map<String, dynamic>.from(body);
    payload['language'] = language;
    return payload;
  }

  String _networkErrorMessage() {
    if (ApiK.useLocal) {
      return 'Local backend unreachable. Start FastAPI with --host 0.0.0.0. Tried: ${ApiK.localCandidates.join(', ')}';
    }
    return _tr('noInternetConnection', 'No internet connection');
  }

  List<String> _candidateUrls(String url) {
    if (!ApiK.useLocal) return [url];
    return ApiK.localCandidates
        .map((host) => url.replaceFirst(ApiK.root, host))
        .toSet()
        .toList();
  }

  Res<Map<String, dynamic>> _failureFrom(Object? error) {
    if (error is TimeoutException) {
      return Res.fail(
        _tr('requestTimedOut', 'Request timed out. Please try again.'),
      );
    }
    if (error is SocketException) {
      return Res.fail(_networkErrorMessage());
    }
    if (error != null) {
      return Res.fail(_friendlyError(error));
    }
    return Res.fail(
      _tr('somethingWentWrong', 'Something went wrong. Please try again.'),
    );
  }

  String _friendlyError(Object error) => _friendlyText(error.toString());

  String _friendlyText(String text) {
    final trimmed = text.replaceFirst('Exception: ', '').trim();
    if (trimmed.contains('TimeoutException')) {
      return _tr('requestTimedOut', 'Request timed out. Please try again.');
    }
    if (trimmed.contains('SocketException')) {
      return _networkErrorMessage();
    }
    return trimmed.isEmpty
        ? _tr('somethingWentWrong', 'Something went wrong. Please try again.')
        : trimmed;
  }
}
