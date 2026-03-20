// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/language_service.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _slide;
  late final Animation<double> _glow;
  late final Animation<double> _orbit;
  late final Animation<double> _ringPulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900));
    _fade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.52, curve: Curves.easeOut));
    _scale = Tween(begin: 0.58, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.58, curve: Curves.easeOutBack)));
    _slide = Tween(begin: 30.0, end: 0.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.18, 0.72, curve: Curves.easeOutCubic)));
    _glow = Tween(begin: 0.72, end: 1.12).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.08, 0.7, curve: Curves.easeInOutCubic)));
    _orbit = Tween(begin: 18.0, end: 0.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.8, curve: Curves.easeOutCubic)));
    _ringPulse = Tween(begin: 0.84, end: 1.08).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.05, 0.62, curve: Curves.easeInOut)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2600), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final langChosen = prefs.containsKey('lang');
    final user = DB.getUser();
    final hasToken = await ApiSvc().hasToken();
    final online = await ConnSvc().check();
    final offlineLocalSession = user?['session_mode'] == 'offline_local';

    if (!langChosen) {
      // First launch — go to language picker
      Navigator.pushReplacementNamed(context, Routes.langPicker);
    } else if (user != null && (hasToken || offlineLocalSession || !online)) {
      if (hasToken && online && !offlineLocalSession) {
        try {
          await SyncSvc().sync();
          await SyncSvc().restoreHistory();
        } catch (_) {}
      }
      // Already logged in
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    } else {
      if (user != null && !hasToken && online && !offlineLocalSession) {
        await DB.clearUser();
      }
      // Language chosen but not logged in
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String tr(String key, String fallback) {
      final value = LangSvc().t(key);
      return value == key ? fallback : value;
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Stack(
              fit: StackFit.expand,
              children: [
                _backgroundAura(
                  top: -110,
                  left: -60,
                  size: 240,
                  color: Colors.white.withValues(alpha: 0.09),
                ),
                _backgroundAura(
                  bottom: -130,
                  right: -70,
                  size: 280,
                  color: AppColors.amberBright.withValues(alpha: 0.11),
                ),
                Column(
                  children: [
                    const Spacer(flex: 3),
                    FadeTransition(
                      opacity: _fade,
                      child: Transform.translate(
                        offset: Offset(0, _slide.value),
                        child: Column(
                          children: [
                            Transform.scale(
                              scale: _scale.value,
                              child: _plantMark(),
                            ),
                            const SizedBox(height: 28),
                            Opacity(
                              opacity: _fade.value,
                              child: Column(
                                children: [
                                  Text(
                                    'AgroBrain 360',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    tr('appTagline',
                                        'Smart farming, rooted in every field'),
                                    style: GoogleFonts.dmSans(
                                      color:
                                          Colors.white.withValues(alpha: 0.72),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 26),
                      child: Opacity(
                        opacity: (_fade.value * 0.9).clamp(0.0, 1.0),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 110,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: (_ctrl.value * 1.08).clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.14),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.amberBright
                                        .withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tr('preparingWorkspace',
                                  'Preparing your farm workspace'),
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backgroundAura({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Transform.scale(
        scale: _glow.value,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _plantMark() {
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _ringPulse.value,
            child: Container(
              width: 154,
              height: 154,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(0, _orbit.value * -0.35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.eco_rounded,
                  size: 54,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 18,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(-42, _orbit.value),
            child: _seedDot(10, Colors.white.withValues(alpha: 0.78)),
          ),
          Transform.translate(
            offset: Offset(46, -_orbit.value * 0.8),
            child: _seedDot(8, AppColors.amberBright.withValues(alpha: 0.95)),
          ),
          Transform.translate(
            offset: Offset(0, 48 + (_orbit.value * 0.25)),
            child: Container(
              width: 58,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seedDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
