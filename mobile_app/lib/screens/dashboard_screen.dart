import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/helpers.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/language_service.dart';
import '../services/local_db_service.dart';
import '../services/weather_service.dart';
import '../models/health_index_model.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_card.dart';
import '../widgets/health_score_widget.dart';
import '../widgets/language_selector.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int unreadNotifs;
  final VoidCallback? onNotifRead;
  const DashboardScreen({
    super.key,
    this.unreadNotifs = 0,
    this.onNotifRead,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _user;
  FHIModel _fhi = FHIModel.empty();
  bool _online = true;
  List<Map<String, dynamic>> _scans = [];
  Map<String, dynamic>? _weather;
  bool _weatherLoading = false;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    _load();
    ConnSvc().stream.listen((v) {
      if (!mounted) return;
      setState(() => _online = v);
      if (v) _loadWeather();
    });
  }

  void _load() {
    _user = DB.getUser();
    final raw = DB.getFHI();
    if (raw != null) _fhi = FHIModel.fromJson(raw);
    _scans = DB.getScans().take(4).toList();
    if (_online) {
      _loadWeather();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadWeather() async {
    if (_weatherLoading || !_online) return;
    if (mounted) {
      setState(() {
        _weatherLoading = true;
        _weatherError = null;
      });
    }

    try {
      final result = await WeatherSvc().getCurrentWeather();
      if (!mounted) return;
      setState(() {
        _weather = result;
        _weatherError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _weatherLoading = false);
      }
    }
  }

  String get _firstName =>
      (_user?['name'] as String? ?? 'Farmer').split(' ').first;

  String t(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
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
    final topInset = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Stack(
          children: [
            if (topInset > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topInset,
                child: Container(color: AppColors.primaryDark),
              ),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => _load(),
                child: Container(
                  color: AppColors.background,
                  child: CustomScrollView(
                    slivers: [
                      _buildHeader(),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (!_online) _offlineBanner(),
                            const SizedBox(height: 12),
                            _weatherCard(),
                            const SizedBox(height: 16),
                            _fhiCard(),
                            const SizedBox(height: 24),
                            SectionLabel(
                              t('quickActions', 'Quick Actions'),
                              action: t('seeAll', 'See all'),
                              onAction: () {},
                            ),
                            const SizedBox(height: 12),
                            _moduleGrid(),
                            const SizedBox(height: 24),
                            SectionLabel(
                              t('recentActivity', 'Recent Activity'),
                              action: t('history', 'History'),
                              onAction: () =>
                                  Navigator.pushNamed(context, Routes.history),
                            ),
                            const SizedBox(height: 12),
                            _recentScans(),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weatherCard() {
    final condition = _weather?['condition']?.toString() ?? t('weather', 'Weather');
    final location =
        _weather?['location']?.toString() ?? t('currentLocation', 'Current location');
    final temperature = (_weather?['temperature'] as num?)?.toDouble();
    final humidity = (_weather?['humidity'] as num?)?.toInt();
    final wind = (_weather?['windSpeed'] as num?)?.toDouble();
    final icon = _weatherIcon(condition);
    final errorCode = _weatherError;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B3C5D), Color(0xFF1E6091), Color(0xFF58A4B0)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('liveWeather', 'Live Weather'),
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _weatherLoading ? null : _loadWeather,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _weatherLoading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t('refresh', 'Refresh'),
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!_online)
            _weatherMessage(
              t('weatherOffline', 'Connect to the internet to see live weather.'),
            )
          else if (errorCode != null)
            _weatherMessage(_weatherErrorText(errorCode))
          else if (temperature == null)
            _weatherMessage(
              t('weatherLoading', 'Fetching current weather conditions...'),
            )
          else
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${temperature.round()}°C',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        condition,
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _weatherMetric(
                        Icons.water_drop_rounded,
                        t('humidity', 'Humidity'),
                        humidity == null ? '--' : '$humidity%',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _weatherMetric(
                        Icons.air_rounded,
                        t('wind', 'Wind'),
                        wind == null ? '--' : '${wind.toStringAsFixed(1)} km/h',
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _weatherMessage(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      );

  Widget _weatherMetric(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  String _weatherErrorText(String code) {
    switch (code) {
      case 'location_disabled':
        return t(
          'weatherEnableLocation',
          'Enable location services to see live weather.',
        );
      case 'location_permission_denied':
        return t(
          'weatherLocationPermission',
          'Location permission is needed for real-time weather.',
        );
      case 'weather_fetch_failed':
        return t(
          'weatherFetchFailed',
          'Unable to fetch live weather right now.',
        );
      default:
        return t(
          'weatherUnavailable',
          'Live weather is currently unavailable.',
        );
    }
  }

  IconData _weatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'cloudy':
        return Icons.cloud_rounded;
      case 'rain':
        return Icons.grain_rounded;
      case 'fog':
        return Icons.blur_on_rounded;
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      default:
        return Icons.cloud_queue_rounded;
    }
  }

  Widget _buildHeader() {
    final notifCount = widget.unreadNotifs;
    return SliverAppBar(
      pinned: true,
      floating: true,
      expandedHeight: 0,
      backgroundColor: AppColors.primaryDark,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppLogo(
                size: 36,
                padding: 5,
                backgroundColor: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${H.greeting()}, $_firstName',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    t('appName', 'AgroBrain 360'),
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
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
                    child: const Center(
                      child: Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  if (notifCount > 0)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.primaryDark, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            notifCount > 9 ? '9+' : '$notifCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            LangPicker(
              onChange: (value) async {
                await AuthSvc().updateLanguagePreference(value);
                if (mounted) _load();
              },
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
      ),
    );
  }

  Widget _offlineBanner() => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warningFaint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.warning, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t(
                  'offlineBanner',
                  'Working offline - results powered by on-device AI',
                ),
                style: GoogleFonts.dmSans(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _fhiCard() => GestureDetector(
        onTap: () => Navigator.pushNamed(context, Routes.farmInput),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primaryMid],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              FHIGauge(score: _fhi.overall, size: 92),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('farmHealth', 'Farm Health Index'),
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      H.fhiLabel(_fhi.overall),
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _miniBar(t('cropLabel', 'Crop'), _fhi.crop),
                    const SizedBox(height: 4),
                    _miniBar(t('soilLabel', 'Soil'), _fhi.soil),
                    const SizedBox(height: 4),
                    _miniBar(t('waterLabel', 'Water'), _fhi.water),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                    const SizedBox(height: 2),
                    Text(
                      t('update', 'Update'),
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _miniBar(String label, int score) => Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(AppColors.amberBright),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$score',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );

  Widget _moduleGrid() {
    final mods = [
      _Mod(
        t('cropDisease', 'Crop Section'),
        t('cropModuleSub', 'Disease detection • Crop detection'),
        Icons.grass_rounded,
        AppColors.cropGreen,
        AppColors.cropFaint,
        Routes.cropScan,
        'AI',
      ),
      _Mod(
        t('livestock', 'Livestock Health'),
        t('livestockSub', 'Symptoms • Care plan'),
        Icons.pets_rounded,
        AppColors.tealDark,
        AppColors.tealFaint,
        Routes.livestockIn,
        null,
      ),
      _Mod(
        t('machinery', 'Machinery'),
        t('machinerySub', 'Recommendation • Maintenance • Rentals'),
        Icons.agriculture_rounded,
        AppColors.orangeDark,
        AppColors.orangeFaint,
        Routes.machScan,
        'AR',
      ),
      _Mod(
        t('residue', 'Residue Income'),
        t('residueSub', 'Turn waste into cash'),
        Icons.recycling_rounded,
        AppColors.purpleDark,
        AppColors.purpleFaint,
        Routes.residueScan,
        null,
      ),
      _Mod(
        t('nearbyServices', 'Nearby Services'),
        t('servicesSub', 'Vets, dealers & shops'),
        Icons.location_on_rounded,
        AppColors.indigoDark,
        AppColors.indigoFaint,
        Routes.svcSearch,
        null,
      ),
      _Mod(
        t('farmHealthModule', 'Farm Health'),
        t('farmHealthSub', 'Track your farm score'),
        Icons.monitor_heart_rounded,
        AppColors.goldDark,
        AppColors.goldFaint,
        Routes.farmInput,
        null,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: mods.length,
      itemBuilder: (_, i) => ModCard(
        title: mods[i].title,
        sub: mods[i].sub,
        icon: mods[i].icon,
        accent: mods[i].accent,
        faint: mods[i].faint,
        tag: mods[i].tag,
        onTap: () => Navigator.pushNamed(context, mods[i].route),
      ),
    );
  }

  Widget _recentScans() {
    if (_scans.isEmpty) {
      return ACard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const Icon(Icons.history_rounded,
                  color: AppColors.textTertiary, size: 32),
              const SizedBox(height: 8),
              Text(
                t('noScansYet', 'No scans yet'),
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                t('startScanning', 'Start scanning your farm'),
                style: GoogleFonts.dmSans(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: _scans.map(_scanTile).toList());
  }

  Widget _scanTile(Map<String, dynamic> scan) {
    final type = scan['type'] as String? ?? 'crop';
    final (icon, color, bg) = _meta(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ACard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
                  BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan['title'] as String? ?? t('scan', 'Scan'),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    H.ago(DateTime.tryParse(scan['ts'] as String? ?? '') ??
                        DateTime.now()),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (scan['result'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration:
                    BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  scan['result'] as String,
                  style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _meta(String type) => switch (type) {
        'livestock' => (
            Icons.pets_rounded,
            AppColors.tealDark,
            AppColors.tealFaint
          ),
        'machinery' => (
            Icons.agriculture_rounded,
            AppColors.orangeDark,
            AppColors.orangeFaint
          ),
        'residue' => (
            Icons.recycling_rounded,
            AppColors.purpleDark,
            AppColors.purpleFaint
          ),
        _ => (Icons.grass_rounded, AppColors.cropGreen, AppColors.cropFaint),
      };
}

class _Mod {
  final String title, sub, route;
  final IconData icon;
  final Color accent, faint;
  final String? tag;
  const _Mod(
      this.title, this.sub, this.icon, this.accent, this.faint, this.route, this.tag);
}
