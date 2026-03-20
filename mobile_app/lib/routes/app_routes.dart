import 'dart:io';

// FILE PATH: lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import '../models/fertilizer_model.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/language_picker_screen.dart';
import '../screens/main_shell.dart';
import '../screens/notifications_screen.dart';
import '../screens/auth/forgot_password_email_screen.dart';
import '../screens/crop_module/crop_options_screen.dart';
import '../screens/crop_module/crop_scan_screen.dart';
import '../screens/crop_module/crop_result_screen.dart';
import '../screens/crop_module/crop_recommendation_screen.dart';
import '../screens/crop_module/crop_recommendation_result_screen.dart';
import '../screens/crop_module/fertilizer_input_screen.dart';
import '../screens/crop_module/fertilizer_result_screen.dart';
import '../screens/livestock_module/livestock_input_screen.dart';
import '../screens/livestock_module/livestock_result_screen.dart';
import '../screens/assistant_module/ai_case_chat_screen.dart';
import '../screens/machinery_module/machinery_ar_guide_screen.dart';
import '../screens/machinery_module/machinery_scan_screen.dart';
import '../models/ai_case_chat_args.dart';
import '../screens/residue_module/residue_scan_screen.dart';
import '../screens/residue_module/residue_income_screen.dart';
import '../screens/health_index/farm_input_screen.dart';
import '../screens/health_index/health_score_screen.dart';
import '../screens/services_module/service_search_screen.dart';
import '../screens/services_module/service_contact_screen.dart';
import '../screens/history/scan_history_screen.dart';

class Routes {
  static const langPicker = '/lang';
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const notifications = '/notifications';
  static const cropScan = '/crop';
  static const cropDiseaseScan = '/crop/scan/disease';
  static const cropDetectScan = '/crop/scan/detect';
  static const cropResult = '/crop/result';
  static const cropRecommendation = '/crop/recommendation';
  static const cropRecommendationResult = '/crop/recommendation/result';
  static const fertilizerInput = '/crop/fertilizer/input';
  static const fertilizerResult = '/crop/fertilizer/result';
  static const livestockIn = '/livestock/input';
  static const livestockRes = '/livestock/result';
  static const aiCaseChat = '/assistant/case-chat';
  static const machScan = '/mach/scan';
  static const machArGuide = '/mach/ar-guide';
  static const residueScan = '/residue/scan';
  static const residueIncome = '/residue/income';
  static const farmInput = '/fhi/input';
  static const healthScore = '/fhi/score';
  static const svcSearch = '/svc/search';
  static const svcContact = '/svc/contact';
  static const history = '/history';

  static Map<String, WidgetBuilder> get table => {
        langPicker: (_) => const LanguagePickerScreen(),
        splash: (_) => const SplashScreen(),
        login: (_) => const LoginScreen(),
        forgotPassword: (_) => const ForgotPasswordEmailScreen(),
        dashboard: (_) => const MainShell(),
        notifications: (_) => const NotificationsScreen(),
        cropScan: (_) => const CropOptionsScreen(),
        cropRecommendation: (_) => const CropRecommendationScreen(),
        cropDiseaseScan: (_) =>
            const CropScanScreen(mode: CropScanMode.diseaseDetection),
        cropDetectScan: (_) =>
            const CropScanScreen(mode: CropScanMode.cropDetection),
        fertilizerInput: (_) => const FertilizerInputScreen(),
        livestockIn: (_) => const LivestockInputScreen(),
        machScan: (_) => const MachineryScanScreen(),
        residueScan: (_) => const ResidueScanScreen(),
        farmInput: (_) => const FarmInputScreen(),
        svcSearch: (_) => const ServiceSearchScreen(),
        history: (_) => const ScanHistoryScreen(),
      };

  static Route<dynamic> generate(RouteSettings s) {
    switch (s.name) {
      case cropResult:
        return _slide(
            CropResultScreen(data: s.arguments as Map<String, dynamic>));
      case cropRecommendationResult:
        return _slide(CropRecommendationResultScreen(
            data: s.arguments as Map<String, dynamic>));
      case livestockRes:
        return _slide(
            LivestockResultScreen(data: s.arguments as Map<String, dynamic>));
      case aiCaseChat:
        return _slide(
            AiCaseChatScreen(args: s.arguments as AiCaseChatArgs));
      case machArGuide:
        final args = s.arguments as Map<String, dynamic>;
        return _slide(
          MachineryArGuideScreen(
            machine: args['machine'] as String,
            issue: args['issue'] as String,
            imageFile: args['imageFile'] as File,
          ),
        );
      case fertilizerResult:
        return _slide(FertilizerResultScreen(
            data: s.arguments as FertilizerRecommendation));
      case residueIncome:
        return _slide(
            ResidueIncomeScreen(data: s.arguments as Map<String, dynamic>));
      case healthScore:
        return _slide(
            HealthScoreScreen(data: s.arguments as Map<String, dynamic>));
      case svcContact:
        return _slide(
            ServiceContactScreen(svc: s.arguments as Map<String, dynamic>));
      default:
        return _slide(const SplashScreen());
    }
  }

  static PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(a),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      );
}
