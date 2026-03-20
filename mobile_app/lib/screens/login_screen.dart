// FILE PATH: lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/helpers.dart';
import '../core/utils/validators.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/language_selector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _isLogin = true, _obscure = true, _loading = false;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  String t(String key) => LangSvc().t(key);
  String tr(String key, String fallback) {
    final value = t(key);
    return value == key ? fallback : value;
  }

  @override
  void initState() {
    super.initState();
    LangSvc().addListener(_onLanguageChanged);
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LangSvc().removeListener(_onLanguageChanged);
    _anim.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _email.text.trim().toLowerCase();
      final phone = _phone.text.trim();
      final language = LangSvc().lang;
      late final Map<String, dynamic> session;
      if (!mounted) return;
      if (_isLogin) {
        session = await AuthSvc().signIn(
          email: email,
          password: _pass.text,
          fallbackName:
              _name.text.trim().isEmpty ? 'Farmer' : _name.text.trim(),
          language: language,
        );
      } else {
        session = await AuthSvc().signUp(
          name: _name.text.trim(),
          email: email,
          phone: phone,
          password: _pass.text,
          language: language,
        );
      }
      if (!mounted) return;
      if (session['session_mode'] == 'offline_local') {
        H.snack(context,
            tr('offlineSessionStarted',
                'Offline session started. Cloud sync will resume when internet is back.'));
      }
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    } catch (e) {
      if (!mounted) return;
      H.snack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(slivers: [
          // ── Hero ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.brandGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo + language change
                      Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AppLogo(
                            size: 44,
                            padding: 8,
                            backgroundColor: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 34,
                          child: LangPicker(
                            onChange: (value) async {
                              await AuthSvc().updateLanguagePreference(value);
                            },
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      Text(
                        _isLogin ? t('welcomeBack') : t('createAccount'),
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isLogin ? t('signInSubtitle') : t('joinFarmers'),
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Form ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Form(
                  key: _key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isLogin) ...[
                        _field(
                            ctrl: _name,
                            label: t('fullName'),
                            icon: Icons.person_outline_rounded,
                            validator: V.name),
                        const SizedBox(height: 14),
                      ],
                      _field(
                          ctrl: _email,
                          label: tr('email', 'Email'),
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: V.email),
                      const SizedBox(height: 14),
                      if (!_isLogin) ...[
                        _field(
                            ctrl: _phone,
                            label: t('phoneNumber'),
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            prefix: '+91 ',
                            validator: V.phone),
                        const SizedBox(height: 14),
                      ],
                      _field(
                          ctrl: _pass,
                          label: t('password'),
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          validator: V.password,
                          suffix: IconButton(
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textTertiary,
                                size: 20),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          )),
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, Routes.forgotPassword),
                            child: Text(
                              t('forgotPassword'),
                              style: GoogleFonts.dmSans(
                                  color: AppColors.primary, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 20),
                      Btn(
                        label: _isLogin ? t('signIn') : t('createAccount'),
                        onTap: _submit,
                        loading: _loading,
                        icon: _isLogin
                            ? Icons.login_rounded
                            : Icons.person_add_rounded,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        tr('languageAppliesAppWide',
                            'Language changes update the full app and all modules.'),
                        style: GoogleFonts.dmSans(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin ? t('newToApp') : t('haveAccount'),
                            style: GoogleFonts.dmSans(
                                color: AppColors.textTertiary, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _isLogin = !_isLogin);
                              _key.currentState?.reset();
                            },
                            child: Text(
                              _isLogin ? t('createAccount') : t('signIn'),
                              style: GoogleFonts.dmSans(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      // Feature badges
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFaint,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          _badge(Icons.wifi_off_rounded, t('offlineAI')),
                          _divider(),
                          _badge(Icons.psychology_rounded, t('smartScan')),
                          _divider(),
                          _badge(Icons.language_rounded, t('fiveLangs')),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffix,
    String? prefix,
  }) =>
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
          prefixText: prefix,
          prefixStyle:
              GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14),
          suffixIcon: suffix,
        ),
      );

  Widget _badge(IconData icon, String label) => Expanded(
        child: Column(children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 5),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ]),
      );

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.border);
}
