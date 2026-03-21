// FILE PATH: lib/main.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/api_constants.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/local_db_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart';
import 'services/tflite_service.dart';
import 'services/voice_service.dart';

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) {
      return host == 'mqqgsclxjuqbnddfmice.supabase.co' ||
          host == 'agrobrain-backend.onrender.com' ||
          host == 'fonts.gstatic.com' ||
          host == 'fonts.googleapis.com';
    };
    return client;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(() {
    HttpOverrides.global = _DevHttpOverrides();
    return true;
  }());
  GoogleFonts.config.allowRuntimeFetching = true;

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Supabase.initialize(
    url: ApiK.supabaseUrl,
    anonKey: ApiK.supabaseAnonKey,
  );
  await DB.init();
  await LangSvc().init(); // loads saved language
  await ThemeSvc().init();
  await VoiceSvc().init();
  ConnSvc().init();
  SyncSvc().init();
  await TFSvc().load();

  runApp(const AgroBrain360App());
}

class AgroBrain360App extends StatelessWidget {
  const AgroBrain360App({super.key});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder rebuilds MaterialApp whenever LangSvc.notifyListeners()
    // is called — i.e. when the user changes language anywhere in the app.
    return ListenableBuilder(
      listenable: Listenable.merge([LangSvc(), ThemeSvc()]),
      builder: (_, __) => MaterialApp(
        title: LangSvc().t('appName'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeSvc().mode,
        // First launch → language picker
        // Already picked → splash
        initialRoute: Routes.splash,
        routes: Routes.table,
        onGenerateRoute: Routes.generate,
      ),
    );
  }
}
