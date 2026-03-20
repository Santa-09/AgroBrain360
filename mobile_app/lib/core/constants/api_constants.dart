class ApiK {
  static const String base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://agrobrain-backend.onrender.com',
  );
  static const String local = String.fromEnvironment(
    'API_LOCAL_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static bool useLocal = const bool.fromEnvironment(
    'USE_LOCAL_API',
    defaultValue: false,
  );
  static String get root => useLocal ? local : base;
  static String resolveUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$root$value';
    }
    return '$root/$value';
  }

  static const String supabaseUrl = 'https://mqqgsclxjuqbnddfmice.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_evzbmXCI0KNl3W0J9X1ZIA_PBicz_3O';
  static const String supabaseLegacyAnonJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xcWdzY2x4anVxYm5kZGZtaWNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3NTI1NDEsImV4cCI6MjA4OTMyODU0MX0.QSlYoi5CFfsgVQvngvkZ5SwX3GB62BFNxw-YcTdZ1sw';
  static String get supabaseSignup => '$supabaseUrl/auth/v1/signup';
  static String get supabaseLogin =>
      '$supabaseUrl/auth/v1/token?grant_type=password';
  static String get authProfile => '$root/auth/profile';
  static String get authProfileMe => '$root/auth/profile/me';
  static String get authProfileFeedback => '$root/auth/profile/feedback';
  static String get forgotPasswordRequestOtp =>
      '$root/auth/forgot-password/request-otp';
  static String get forgotPasswordVerifyOtp =>
      '$root/auth/forgot-password/verify-otp';
  static String get forgotPasswordReset =>
      '$root/auth/forgot-password/reset';
  static String get cropPredict => '$root/crop/predict';
  static String get cropRecommend => '$root/crop/recommend';
  static String get fertilizerPredict => '$root/fertilizer/predict';
  static String get livestock => '$root/livestock/diagnose';
  static String get residue => '$root/residue/analyze';
  static String get fhi => '$root/health/score';
  static String get services => '$root/services/nearby';
  static String get sync => '$root/sync';
  static String get syncHistory => '$root/sync/history';
  static String get voice => '$root/voice';
  static String get voiceTranscribe => '$root/voice/transcribe';
  static String get llmAdvise => '$root/llm/advise';
  static String get chatCase => '$root/chat/case';

  static Map<String, String> headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Map<String, String> get supabaseHeaders => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'apikey': supabaseAnonKey,
      };

  static const int timeoutMs = 20000;
}
