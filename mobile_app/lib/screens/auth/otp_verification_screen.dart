import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../widgets/custom_button.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final int resendCooldownSeconds;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.resendCooldownSeconds = 60,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown(widget.resendCooldownSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  String tr(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final payload = await AuthSvc().verifyPasswordResetOtp(
        email: widget.email,
        otp: _otpCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            resetToken: payload['reset_token']?.toString() ?? '',
          ),
        ),
      );
    } catch (e) {
      if (mounted) H.snack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    setState(() => _resending = true);
    try {
      final payload = await AuthSvc().requestPasswordResetOtp(email: widget.email);
      _startCooldown(
        (payload['resend_cooldown_seconds'] as num?)?.toInt() ?? 60,
      );
      if (mounted) H.snack(context, tr('otpSentAgain', 'OTP sent again'));
    } catch (e) {
      if (mounted) H.snack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('verifyOtp', 'Verify OTP')),
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tr('otpSentTo', 'Enter the OTP sent to')} ${widget.email}.',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.trim().length != 6) {
                    return tr('enterSixDigitOtp', 'Enter 6-digit OTP');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: tr('otp', 'OTP'),
                  prefixIcon: const Icon(Icons.password_rounded),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: (_secondsLeft == 0 && !_resending) ? _resend : null,
                child: Text(
                  _secondsLeft == 0
                      ? (_resending
                          ? tr('resending', 'Resending...')
                          : tr('resendOtp', 'Resend OTP'))
                      : '${tr('resendOtpIn', 'Resend OTP in')} ${_secondsLeft}s',
                ),
              ),
              const SizedBox(height: 12),
              Btn(
                label: tr('verifyOtp', 'Verify OTP'),
                loading: _loading,
                icon: Icons.verified_user_outlined,
                onTap: _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
