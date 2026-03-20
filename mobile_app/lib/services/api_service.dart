import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/response_model.dart';

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
      String url, Map<String, dynamic> body) async {
    try {
      final tok = await _tok;
      final res = await http
          .post(Uri.parse(url),
              headers: ApiK.headers(token: tok), body: jsonEncode(body))
          .timeout(const Duration(milliseconds: ApiK.timeoutMs));
      return _parse(res);
    } on SocketException {
      return Res.fail('No internet connection');
    } catch (e) {
      return Res.fail(e.toString());
    }
  }

  Future<Res<Map<String, dynamic>>> get(String url,
      {Map<String, String>? q}) async {
    try {
      final tok = await _tok;
      final uri = Uri.parse(url).replace(queryParameters: q);
      final res = await http
          .get(uri, headers: ApiK.headers(token: tok))
          .timeout(const Duration(milliseconds: ApiK.timeoutMs));
      return _parse(res);
    } catch (e) {
      return Res.fail(e.toString());
    }
  }

  Future<Res<Map<String, dynamic>>> multipart(String url, File f,
      [Map<String, String>? fields]) async {
    try {
      final tok = await _tok;
      final req = http.MultipartRequest('POST', Uri.parse(url));
      if (tok != null) req.headers['Authorization'] = 'Bearer $tok';
      req.files.add(await http.MultipartFile.fromPath('file', f.path));
      if (fields != null) req.fields.addAll(fields);
      final streamed = await req
          .send()
          .timeout(const Duration(milliseconds: ApiK.timeoutMs));
      final res = await http.Response.fromStream(streamed);
      return _parse(res);
    } catch (e) {
      return Res.fail(e.toString());
    }
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
    return Res.fail(message);
  }
}
