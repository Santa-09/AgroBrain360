import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/ai_case_chat_args.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import 'assistant_module/ai_case_chat_screen.dart';
import 'dashboard_screen.dart';
import 'crop_module/crop_scan_screen.dart';
import 'services_module/service_search_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _index = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    LangSvc().addListener(_onLanguageChanged);
    _refreshNotifCount();
  }

  @override
  void dispose() {
    LangSvc().removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  void _refreshNotifCount() {
    if (!mounted) return;
    setState(() => _unreadCount = NotificationSvc().unreadCount());
  }

  static const _activeIcons = [
    Icons.home_rounded,
    Icons.document_scanner_rounded,
    Icons.smart_toy_rounded,
    Icons.location_on_rounded,
    Icons.person_rounded,
  ];

  List<String> get _labels => [
        _tr('home', 'Home'),
        _tr('scan', 'Scan'),
        _tr('aiHelpCenter', 'AI Help'),
        _tr('services', 'Services'),
        _tr('profile', 'Profile'),
      ];

  String _tr(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  static const _inactiveIcons = [
    Icons.home_outlined,
    Icons.document_scanner_outlined,
    Icons.smart_toy_outlined,
    Icons.location_on_outlined,
    Icons.person_outline_rounded,
  ];

  List<Widget> get _screens => [
        DashboardScreen(
          unreadNotifs: _unreadCount,
          onNotifRead: _refreshNotifCount,
        ),
        const CropScanScreen(),
        const AiCaseChatScreen(
          args: AiCaseChatArgs(
            module: 'assistant',
            title: 'AI Help Center',
            context: {'entry': 'global_help_center'},
          ),
        ),
        const ServiceSearchScreen(),
        ProfileScreen(
          unreadNotifs: _unreadCount,
          onNotifRead: _refreshNotifCount,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyedSubtree(
        key: ValueKey(LangSvc().lang),
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(5, (i) => Expanded(child: _navItem(i))),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i) {
    final selected = i == _index;
    final showBadge = _unreadCount > 0 && (i == 0 || i == 4);
    final isCenter = i == 2;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _index = i);
        _refreshNotifCount();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: isCenter ? 0 : 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isCenter
                ? Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  )
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryFaint
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          selected ? _activeIcons[i] : _inactiveIcons[i],
                          size: 22,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (showBadge)
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
                                _unreadCount > 9 ? '9+' : '$_unreadCount',
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
            SizedBox(height: isCenter ? 5 : 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.dmSans(
                fontSize: isCenter ? 11 : 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: isCenter
                    ? AppColors.primary
                    : (selected
                        ? AppColors.primary
                        : AppColors.textTertiary),
              ),
              child: Text(_labels[i]),
            ),
          ],
        ),
      ),
    );
  }
}
