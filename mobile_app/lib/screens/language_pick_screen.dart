// lib/screens/language_pick_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../services/language_service.dart';

class LanguagePickScreen extends StatefulWidget {
  /// fromProfile = true means opened from Profile settings (not first-launch)
  final bool fromProfile;
  const LanguagePickScreen({super.key, this.fromProfile = false});
  @override
  State<LanguagePickScreen> createState() => _LanguagePickScreenState();
}

class _LanguagePickScreenState extends State<LanguagePickScreen>
    with SingleTickerProviderStateMixin {
  String _selected = LangSvc().lang;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (widget.fromProfile) {
      if (!mounted) return;
      Navigator.pop(context, _selected);
    } else {
      await LangSvc().set(_selected);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langs = LangSvc.supported;
    final t = LangSvc().t;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button (only when from profile)
                  if (widget.fromProfile) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Header
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.language_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t('chooseLanguage'),
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t('languageSubtitle'),
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Language cards
                  Expanded(
                    child: ListView.separated(
                      itemCount: langs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final code = langs.keys.elementAt(i);
                        final name = langs.values.elementAt(i);
                        final native = LangSvc.nativeNames[code] ?? name;
                        final flag = LangSvc.flags[code] ?? '🌐';
                        final sel = code == _selected;

                        return GestureDetector(
                          onTap: () => setState(() => _selected = code),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: sel
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: sel
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.25),
                                width: sel ? 0 : 1,
                              ),
                            ),
                            child: Row(children: [
                              // Flag circle
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primaryFaint
                                      : Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(flag,
                                      style: const TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      native,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: sel
                                            ? AppColors.primary
                                            : Colors.white,
                                      ),
                                    ),
                                    if (code != 'en')
                                      Text(
                                        name,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: sel
                                              ? AppColors.textSecondary
                                              : Colors.white
                                                  .withValues(alpha: 0.55),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Tick
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.primary
                                        : Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: sel
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 14)
                                    : null,
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _confirm,
                      child: Text(
                        t('continueBtn'),
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
