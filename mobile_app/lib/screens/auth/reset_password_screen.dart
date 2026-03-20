import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../widgets/custom_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String tr(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthSvc().resetPasswordWithOtp(
        email: widget.email,
        resetToken: widget.resetToken,
        newPassword: _passwordCtrl.text,
      );
      if (!mounted) return;
      H.snack(
        context,
        tr('passwordUpdatedSignIn', 'Password updated. Please sign in.'),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.login,
        (_) => false,
      );
    } catch (e) {
      if (mounted) H.snack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('resetPassword', 'Reset Password')),
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                validator: V.strongPassword,
                decoration: InputDecoration(
                  labelText: tr('newPassword', 'New Password'),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                validator: (value) {
                  if (value != _passwordCtrl.text) {
                    return tr(
                        'passwordsDoNotMatch', 'Passwords do not match');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: tr('confirmPassword', 'Confirm Password'),
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                ),
              ),
              const SizedBox(height: 20),
              Btn(
                label: tr('updatePassword', 'Update Password'),
                loading: _loading,
                icon: Icons.save_rounded,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
