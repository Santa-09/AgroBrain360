import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/helpers.dart';
import '../models/ai_case_chat_args.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/local_db_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/voice_service.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int unreadNotifs;
  final VoidCallback? onNotifRead;
  const ProfileScreen({
    super.key,
    this.unreadNotifs = 0,
    this.onNotifRead,
  });
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _notifEnabled = true;
  bool _offlineMode = true;
  bool _voiceEnabled = true;
  String _lang = 'en';
  ThemeMode _themeMode = ThemeMode.system;
  int _scanCount = 0;
  int _appRating = 0;
  String _appFeedback = '';

  @override
  void initState() {
    super.initState();
    LangSvc().addListener(_onLanguageChanged);
    _load();
  }

  @override
  void dispose() {
    LangSvc().removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      _load();
    }
  }

  void _load() {
    _user = DB.getUser();
    _lang = LangSvc().lang;
    _themeMode = ThemeSvc().mode;
    _voiceEnabled = VoiceSvc().enabled;
    _scanCount = DB.getScans().length;
    _appRating = (_user?['app_rating'] as num?)?.toInt() ?? 0;
    _appFeedback = _user?['app_feedback'] as String? ?? '';
    setState(() {});
  }

  String get _name => _user?['name'] as String? ?? 'Farmer';
  String get _phone => _user?['phone'] as String? ?? 'â€”';
  String t(String key) => LangSvc().t(key);
  String tr(String key, String fallback) {
    final value = t(key);
    return value == key ? fallback : value;
  }
  String _languageName(String code) => LangSvc().languageName(code);
  String _nativeLanguageName(String code) => LangSvc().nativeLanguageName(code);
  String _languageFlag(String code) => LangSvc().languageFlag(code);

  String _themeLabel() => switch (_themeMode) {
        ThemeMode.light => tr('lightMode', 'Light'),
        ThemeMode.dark => tr('darkMode', 'Dark'),
        ThemeMode.system => tr('systemTheme', 'System'),
      };

  String _profileNotificationsLabel() => tr('notifications', 'Notifications');

  String _fhiLabel(int score) {
    if (score >= 80) return tr('excellent', 'Excellent');
    if (score >= 60) return tr('good', 'Good');
    if (score >= 40) return tr('fair', 'Fair');
    if (score >= 20) return tr('poor', 'Poor');
    return tr('critical', 'Critical');
  }

  String get _initials {
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _name.isNotEmpty ? _name[0].toUpperCase() : 'F';
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    widget.onNotifRead?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(slivers: [
            _buildHeader(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                _statsRow(),
                const SizedBox(height: 24),

              // â”€â”€ Notifications card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _sectionTitle(_profileNotificationsLabel()),
              const SizedBox(height: 10),
              _card([
                GestureDetector(
                  onTap: _openNotifications,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    child: Row(children: [
                      Stack(clipBehavior: Clip.none, children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: widget.unreadNotifs > 0
                                ? AppColors.dangerFaint
                                : AppColors.primaryFaint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            color: widget.unreadNotifs > 0
                                ? AppColors.danger
                                : AppColors.primary,
                            size: 18,
                          ),
                        ),
                        if (widget.unreadNotifs > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.surface, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  '${widget.unreadNotifs}',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_profileNotificationsLabel(),
                                style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            if (widget.unreadNotifs > 0)
                              Text(
                                '${widget.unreadNotifs} ${tr('unreadLabel', 'unread')}',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.unreadNotifs > 0
                              ? AppColors.dangerFaint
                              : AppColors.primaryFaint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.unreadNotifs > 0
                              ? '${tr('view', 'View')} ${widget.unreadNotifs} ${tr('newLabel', 'new')}'
                              : tr('viewAll', 'View all'),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.unreadNotifs > 0
                                ? AppColors.danger
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),

              const SizedBox(height: 20),
              // â”€â”€ Account â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _sectionTitle(tr('account', 'Account')),
              const SizedBox(height: 10),
              _card([
                _tile(Icons.person_outline_rounded, tr('fullName', 'Full Name'),
                    trailing: Text(_name, style: _trailStyle())),
                _divider(),
                _tile(Icons.phone_outlined, tr('phoneNumber', 'Phone'),
                    trailing: Text(_phone, style: _trailStyle())),
                _divider(),
                _tile(Icons.location_on_outlined, tr('location', 'Location'),
                    trailing: Text(tr('defaultLocation', 'Odisha, India'),
                        style: _trailStyle())),
              ]),

              const SizedBox(height: 20),
              // â”€â”€ Preferences â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _sectionTitle(tr('preferences', 'Preferences')),
              const SizedBox(height: 10),
              _card([
                GestureDetector(
                  onTap: () async {
                    final selected = await _pickLanguage();
                    if (selected == null) return;
                    await AuthSvc().updateLanguagePreference(selected);
                    if (!mounted) return;
                    _load();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    child: Row(children: [
                      const Icon(Icons.language_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('language'),
                                style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                              tr('languageSavedAfterSignOut',
                                  'Applied across all modules and kept after sign out.'),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.primaryFaint,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(_languageName(_lang),
                            style: GoogleFonts.dmSans(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textTertiary, size: 18),
                    ]),
                  ),
                ),
                _divider(),
                GestureDetector(
                  onTap: _pickThemeMode,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    child: Row(children: [
                      const Icon(Icons.palette_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('appTheme', 'App Theme'),
                                style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                              tr('appThemeHelp',
                                  'Choose light, dark, or follow the device theme.'),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.primaryFaint,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(_themeLabel(),
                            style: GoogleFonts.dmSans(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textTertiary, size: 18),
                    ]),
                  ),
                ),
                _divider(),
                _switchTile(
                    Icons.notifications_outlined,
                    tr('pushNotifications', 'Push Notifications'),
                    _notifEnabled,
                    (v) => setState(() => _notifEnabled = v)),
                _divider(),
                _switchTile(Icons.wifi_off_rounded,
                    tr('offlineMode', 'Offline Mode'), _offlineMode,
                    (v) => setState(() => _offlineMode = v)),
                _divider(),
                _switchTile(Icons.mic_outlined,
                    tr('voiceInput', 'Voice Input'), _voiceEnabled,
                    (v) async {
                      await VoiceSvc().setEnabled(v);
                      if (!mounted) return;
                      setState(() => _voiceEnabled = v);
                    }),
              ]),

              const SizedBox(height: 20),
              // â”€â”€ App links â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _sectionTitle(tr('app', 'App')),
              const SizedBox(height: 10),
              _card([
                _tile(Icons.history_rounded, tr('scanHistory', 'Scan History'),
                    onTap: () => Navigator.pushNamed(context, Routes.history)),
                _divider(),
                _tile(Icons.monitor_heart_rounded,
                    tr('farmHealthScore', 'Farm Health Score'),
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.farmInput)),
                _divider(),
                _tile(Icons.share_rounded, tr('shareApp', 'Share App'),
                    onTap: () {}),
                _divider(),
                _tile(
                  Icons.star_rounded,
                  tr('rateUs', 'Rate Us'),
                  trailing: _ratingBadge(),
                  onTap: _openRateUsSheet,
                ),
              ]),

              const SizedBox(height: 20),
              // â”€â”€ Support â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _sectionTitle(tr('support', 'Support')),
              const SizedBox(height: 10),
              _card([
                _tile(Icons.help_outline_rounded, tr('helpFaq', 'Help & FAQ'),
                    onTap: () => Navigator.pushNamed(
                          context,
                          Routes.aiCaseChat,
                          arguments: AiCaseChatArgs(
                            module: 'assistant',
                            title: tr('aiHelpCenter', 'AI Help Center'),
                            context: {'entry': 'profile_support'},
                          ),
                        )),
                _divider(),
                _tile(Icons.privacy_tip_outlined,
                    tr('privacyPolicy', 'Privacy Policy'),
                    onTap: () {}),
                _divider(),
                _tile(Icons.description_outlined,
                    tr('termsOfService', 'Terms of Service'),
                    onTap: () {}),
                _divider(),
                _tile(Icons.info_outline_rounded,
                    tr('aboutApp', 'About AgroBrain 360'),
                    trailing:
                        Text(tr('versionLabel', 'v1.0.0'), style: _trailStyle())),
              ]),

              const SizedBox(height: 24),
              // â”€â”€ Sign out â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              GestureDetector(
                onTap: _confirmLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.dangerFaint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Text(t('signOut'),
                          style: GoogleFonts.dmSans(
                              color: AppColors.danger,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader() => SliverToBoxAdapter(
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(children: [
                // Top row: spacer + notification bell
                Row(children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: _openNotifications,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 19),
                        ),
                        if (widget.unreadNotifs > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primaryDark, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  '${widget.unreadNotifs}',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(_name,
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                const SizedBox(height: 3),
                Text(_phone,
                    style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13)),
                const SizedBox(height: 14),
                // Edit profile button
                GestureDetector(
                  onTap: _editProfile,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(tr('editProfile', 'Edit Profile'),
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
          ),
        ),
      );

  // â”€â”€ Stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _statsRow() {
    final fhiRaw = DB.getFHI();
    final fhiScore =
        fhiRaw != null ? (fhiRaw['overall_score'] as num? ?? 0).toInt() : 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        _stat('$_scanCount', tr('totalScans', 'Total Scans')),
        _vDivider(),
        _stat('6', tr('modules', 'Modules')),
        _vDivider(),
        _stat(_fhiLabel(fhiScore), tr('farmHealth', 'Farm Health')),
      ]),
    );
  }

  Widget _stat(String val, String label) => Expanded(
        child: Column(children: [
          Text(val,
              style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 3),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppColors.textTertiary),
              textAlign: TextAlign.center),
        ]),
      );

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: AppColors.border);

  // â”€â”€ Reusable widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.4));

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );

  Widget _tile(IconData icon, String label,
      {Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
          if (trailing != null) trailing,
          if (onTap != null && trailing == null)
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 18),
        ]),
      ),
    );
  }

  Widget _switchTile(
      IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 48);

  Widget _ratingBadge() {
    if (_appRating <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryFaint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          tr('tapToRate', 'Tap to rate'),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFE7A500)),
          const SizedBox(width: 4),
          Text(
            '$_appRating/5',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFF9A6A00),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _trailStyle() =>
      GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary);

  Future<String?> _pickLanguage() async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                tr('language', 'Language'),
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  'languageSavedAfterSignOut',
                  'Applied across all modules and kept after sign out.',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 18),
              ...LangSvc.supported.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _lang == entry.key
                            ? AppColors.primaryFaint
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _lang == entry.key
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _languageFlag(entry.key),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nativeLanguageName(entry.key),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _languageName(entry.key),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_lang == entry.key)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€ Edit profile bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickThemeMode() async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                tr('appTheme', 'App Theme'),
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('appThemeHelp',
                    'Choose light, dark, or follow the device theme.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 18),
              _themeOption(
                ctx,
                mode: ThemeMode.light,
                icon: Icons.light_mode_rounded,
                title: tr('lightMode', 'Light'),
              ),
              const SizedBox(height: 8),
              _themeOption(
                ctx,
                mode: ThemeMode.dark,
                icon: Icons.dark_mode_rounded,
                title: tr('darkMode', 'Dark'),
              ),
              const SizedBox(height: 8),
              _themeOption(
                ctx,
                mode: ThemeMode.system,
                icon: Icons.phone_android_rounded,
                title: tr('systemTheme', 'System'),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null) return;
    await ThemeSvc().setMode(selected);
    if (!mounted) return;
    _load();
  }

  Widget _themeOption(
    BuildContext ctx, {
    required ThemeMode mode,
    required IconData icon,
    required String title,
  }) {
    final selected = _themeMode == mode;
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryFaint : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRateUsSheet() async {
    final rating = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RateUsSheet(
        initialRating: _appRating,
        initialFeedback: _appFeedback,
        title: tr('rateUs', 'Rate Us'),
        subtitle: tr(
          'rateUsHelp',
          'Share your app experience so we can improve it for every farmer.',
        ),
        hintText: tr(
          'feedbackHint',
          'Tell us what worked well and what we should improve.',
        ),
        submitLabel: tr('submitFeedback', 'Submit Feedback'),
        savingLabel: tr('saving', 'Saving...'),
      ),
    );

    if (rating == null) return;
    _load();
    if (!mounted) return;
    final pending = DB.getUser()?['feedback_sync_pending'] == true;
    H.snack(
      context,
      pending
          ? tr(
              'feedbackSavedPendingSync',
              'Feedback saved. It will sync when you are online.',
            )
          : tr('feedbackSaved', 'Thanks for rating the app.'),
    );
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: _name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(tr('editProfile', 'Edit Profile'),
              style: GoogleFonts.dmSans(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextFormField(
            controller: nameCtrl,
            style: GoogleFonts.dmSans(fontSize: 14),
            decoration: InputDecoration(
              labelText: tr('fullName', 'Full Name'),
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  color: AppColors.textTertiary, size: 18),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  final updated = Map<String, dynamic>.from(_user ?? {});
                  updated['name'] = nameCtrl.text.trim();
                  final result = await ApiSvc().post(ApiK.authProfile, {
                    'name': updated['name'],
                    'phone': updated['phone'],
                    'language': updated['language'] ?? _lang,
                    if (updated['email'] != null) 'email': updated['email'],
                  });
                  if (!result.ok) {
                    H.snack(
                        context,
                        result.error ??
                            tr('profileUpdateFailed', 'Profile update failed'),
                        error: true);
                    return;
                  }
                  updated.addAll(result.data ?? const {});
                  await DB.saveUser(updated);
                  _load();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(tr('saveChanges', 'Save Changes'),
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  // â”€â”€ Sign out â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(tr('signOutConfirm', 'Sign out?'),
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
            tr('signOutBody', 'Your offline data will remain on this device.'),
            style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel', 'Cancel'),
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('signOut', 'Sign Out'),
                style: GoogleFonts.dmSans(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ApiSvc().clearToken();
      await DB.clearUser();
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
    }
  }
}

class _RateUsSheet extends StatefulWidget {
  final int initialRating;
  final String initialFeedback;
  final String title;
  final String subtitle;
  final String hintText;
  final String submitLabel;
  final String savingLabel;

  const _RateUsSheet({
    required this.initialRating,
    required this.initialFeedback,
    required this.title,
    required this.subtitle,
    required this.hintText,
    required this.submitLabel,
    required this.savingLabel,
  });

  @override
  State<_RateUsSheet> createState() => _RateUsSheetState();
}

class _RateUsSheetState extends State<_RateUsSheet> {
  late final TextEditingController _feedbackCtrl;
  late int _rating;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _feedbackCtrl = TextEditingController(text: widget.initialFeedback);
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.title,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final filled = _rating > index;
              return IconButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _rating = index + 1;
                        }),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled ? const Color(0xFFE7A500) : AppColors.textTertiary,
                  size: 34,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _feedbackCtrl,
            minLines: 4,
            maxLines: 6,
            maxLength: 1000,
            style: GoogleFonts.dmSans(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hintText,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saving || _rating < 1 ? null : _submit,
              child: Text(
                _saving ? widget.savingLabel : widget.submitLabel,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final saved = await AuthSvc().submitAppFeedback(
        rating: _rating,
        feedback: _feedbackCtrl.text,
      );
      if (!mounted) return;
      Navigator.pop(context, saved['app_rating'] as int? ?? _rating);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}



