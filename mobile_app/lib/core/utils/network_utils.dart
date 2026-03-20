import 'dart:io';

class NetUtil {
  static Future<bool> hasInternet() async {
    try {
      final r = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return r.isNotEmpty && r[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool ok(int code) => code >= 200 && code < 300;

  static String errMsg(int code) => switch (code) {
        400 => 'Invalid request.',
        401 => 'Session expired. Please sign in again.',
        403 => 'Access denied.',
        404 => 'Not found.',
        422 => 'Validation error. Check your input.',
        500 => 'Server error. Try again later.',
        _ => 'Something went wrong.',
      };
}
