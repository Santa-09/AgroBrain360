import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/language_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';

class ServiceSearchScreen extends StatefulWidget {
  const ServiceSearchScreen({super.key});

  @override
  State<ServiceSearchScreen> createState() => _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends State<ServiceSearchScreen> {
  final _q = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _cat = 'All';
  bool _loading = false;
  bool _findingLocation = false;
  List<Map<String, dynamic>> _svcs = [];
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSub;
  String _locationLabel = '';

  static const _cats = [
    'All',
    'Vets',
    'Input Dealers',
    'Repair Centers',
    'Mandis'
  ];

  static const _manualLocations = {
    'bhubaneswar': {'label': 'Bhubaneswar, Odisha', 'lat': 20.2961, 'lng': 85.8245},
    'cuttack': {'label': 'Cuttack, Odisha', 'lat': 20.4625, 'lng': 85.8830},
    'puri': {'label': 'Puri, Odisha', 'lat': 19.8135, 'lng': 85.8312},
    'sambalpur': {'label': 'Sambalpur, Odisha', 'lat': 21.4669, 'lng': 83.9812},
    'berhampur': {'label': 'Berhampur, Odisha', 'lat': 19.3149, 'lng': 84.7941},
    'rourkela': {'label': 'Rourkela, Odisha', 'lat': 22.2604, 'lng': 84.8536},
  };

  static const _serviceCoordinates = {
    'svc_1': {'place': 'Bhubaneswar', 'lat': 20.3055, 'lng': 85.8174},
    'svc_2': {'place': 'Bhubaneswar', 'lat': 20.3018, 'lng': 85.8402},
    'svc_3': {'place': 'Cuttack', 'lat': 20.4706, 'lng': 85.8792},
    'svc_4': {'place': 'Bhubaneswar', 'lat': 20.2877, 'lng': 85.8349},
    'svc_5': {'place': 'Cuttack', 'lat': 20.4561, 'lng': 85.8911},
    'svc_6': {'place': 'Puri', 'lat': 19.8203, 'lng': 85.8267},
    'svc_7': {'place': 'Sambalpur', 'lat': 21.4722, 'lng': 83.9877},
    'svc_8': {'place': 'Rourkela', 'lat': 22.2538, 'lng': 84.8602},
  };

  String t(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  String _catLabel(String value) => switch (value) {
        'All' => t('allLabel', 'All'),
        'Vets' => t('vetsLabel', 'Vets'),
        'Input Dealers' => t('inputDealersLabel', 'Input Dealers'),
        'Repair Centers' => t('repairCentersLabel', 'Repair Centers'),
        'Mandis' => t('mandisLabel', 'Mandis'),
        _ => value,
      };

  @override
  void initState() {
    super.initState();
    LangSvc().addListener(_onLanguageChanged);
    _locationLabel =
        t('servicesLocationDefault', 'Set location to see nearest services');
    _applyManualLocation(silent: true);
    _load();
  }

  @override
  void dispose() {
    LangSvc().removeListener(_onLanguageChanged);
    _positionSub?.cancel();
    _q.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {
      if (_locationCtrl.text.trim().isEmpty && _currentPosition == null) {
        _locationLabel =
            t('servicesLocationDefault', 'Set location to see nearest services');
      } else if (_locationCtrl.text.trim().isEmpty &&
          _currentPosition != null) {
        _locationLabel =
            t('servicesLiveLocationDetected', 'Live location detected');
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final online = await ConnSvc().check();
      if (online) {
        final params = <String, String>{
          'category': _cat,
          'q': _q.text,
          if (_currentPosition != null) 'lat': _currentPosition!.latitude.toString(),
          if (_currentPosition != null) 'lng': _currentPosition!.longitude.toString(),
        };
        final response = await ApiSvc()
            .get(ApiK.services, q: params)
            .timeout(const Duration(seconds: 4));
        if (response.ok && response.data != null) {
          final payload = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
          final list = payload['services'] as List?;
          if (list != null) {
            if (!mounted) return;
            setState(() {
              _svcs = _prepareServices(
                list.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
              );
              _loading = false;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Fall back to bundled offline data below.
    }

    final local = await _loadOfflineServices();
    if (!mounted) return;
    setState(() {
      _svcs = _prepareServices(local);
      _loading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _loadOfflineServices() async {
    final raw =
        await rootBundle.loadString('assets/data/offline_services.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  List<Map<String, dynamic>> _prepareServices(List<Map<String, dynamic>> input) {
    final services = input.map(_normalizeService).toList();
    if (_currentPosition == null) {
      services.sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));
      return services;
    }

    for (final service in services) {
      final lat = (service['lat'] as num?)?.toDouble();
      final lng = (service['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        continue;
      }
      service['distance'] = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lng,
          ) /
          1000;
    }
    services.sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));
    return services;
  }

  Map<String, dynamic> _normalizeService(Map<String, dynamic> source) {
    final service = Map<String, dynamic>.from(source);
    final id = service['id']?.toString();
    final coords = id == null ? null : _serviceCoordinates[id];
    final baseDistance = (service['distance'] as num?)?.toDouble() ??
        (service['distance_km'] as num?)?.toDouble();

    service['baseDistance'] = baseDistance ?? 9999.0;
    service['distance'] = service['baseDistance'];
    if (coords != null) {
      service.putIfAbsent('lat', () => coords['lat']);
      service.putIfAbsent('lng', () => coords['lng']);
      service.putIfAbsent('place', () => coords['place']);
    }
    return service;
  }

  double _distanceKm(Map<String, dynamic> service) =>
      (service['distance'] as num?)?.toDouble() ?? 9999;

  Future<void> _detectLocation() async {
    setState(() => _findingLocation = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          H.snack(
            context,
            t('servicesEnableLocation',
                'Enable location services to fetch nearby services.'),
            error: true,
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          H.snack(
            context,
            t('servicesLocationPermission',
                'Location permission is needed for real-time nearby services.'),
            error: true,
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _currentPosition = position;
        _locationLabel =
            t('servicesLiveLocationDetected', 'Live location detected');
        _svcs = _prepareServices(_svcs);
      });
      if (_positionSub != null) {
        await _positionSub!.cancel();
      }
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 25,
        ),
      ).listen((position) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
          _locationLabel =
              t('servicesLiveLocationUpdating', 'Live location updating');
          _svcs = _prepareServices(_svcs);
        });
      });
      await _load();
    } catch (_) {
      if (mounted) {
        H.snack(
          context,
          t('servicesLocationFetchFailed',
              'Unable to fetch current location.'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _findingLocation = false);
    }
  }

  void _applyManualLocation({bool silent = false}) {
    final input = _locationCtrl.text.trim().toLowerCase();
    if (input.isEmpty) {
      _positionSub?.cancel();
      _positionSub = null;
      setState(() {
        _currentPosition = null;
        _locationLabel =
            t('servicesLocationDefault', 'Set location to see nearest services');
        _svcs = _prepareServices(_svcs);
      });
      return;
    }

    Map<String, dynamic>? match;
    for (final entry in _manualLocations.entries) {
      if (input.contains(entry.key)) {
        match = entry.value;
        break;
      }
    }

    if (match == null) {
      if (!silent && mounted) {
        H.snack(
          context,
          t(
            'servicesManualLocationHelp',
            'Manual location not recognized. Try Bhubaneswar, Cuttack, Puri, Sambalpur, Berhampur, or Rourkela.',
          ),
          error: true,
        );
      }
      return;
    }

    final resolved = match;
    _positionSub?.cancel();
    _positionSub = null;
    setState(() {
      _currentPosition = Position(
        longitude: (resolved['lng'] as num).toDouble(),
        latitude: (resolved['lat'] as num).toDouble(),
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _locationLabel = resolved['label'] as String;
      _svcs = _prepareServices(_svcs);
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final text = _q.text.toLowerCase();
    return _svcs.where((service) {
      final matchCat = _cat == 'All' || service['category'] == _cat;
      final matchQ = text.isEmpty ||
          (service['name'] as String).toLowerCase().contains(text) ||
          (service['specialty'] as String).toLowerCase().contains(text);
      return matchCat && matchQ;
    }).toList()
      ..sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('nearbyServices', 'Nearby Services')),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4C5C), Color(0xFF2D6A4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.map_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('servicesMapTitle', 'SERVICE MAP'),
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _locationLabel,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _locationCtrl,
                  onChanged: (_) => _applyManualLocation(silent: true),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        t('locationAutoInput', 'Location (Auto / Input)'),
                    hintText: t(
                        'machineryLocationHint',
                        'Use current location or type city'),
                    prefixIcon: const Icon(Icons.pin_drop_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _findingLocation ? null : _detectLocation,
                        icon: Icon(
                          _findingLocation ? Icons.gps_not_fixed_rounded : Icons.my_location_rounded,
                        ),
                        label: Text(
                          _findingLocation
                              ? t('locating', 'Locating...')
                              : t('useMyLocation', 'Use My Location'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _applyManualLocation();
                          _load();
                        },
                        icon: const Icon(Icons.travel_explore_rounded),
                        label: Text(t('updateNearby', 'Update Nearby')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: t('serviceSearchHint', 'Search vets, shops, or mandis...'),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textTertiary, size: 20),
                suffixIcon: _q.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textTertiary),
                        onPressed: () {
                          _q.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _cats.length,
              itemBuilder: (_, index) {
                final selected = _cats[index] == _cat;
                return GestureDetector(
                  onTap: () {
                    setState(() => _cat = _cats[index]);
                    _load();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.indigoDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? AppColors.indigoDark
                              : AppColors.border),
                    ),
                    child: Text(
                      _catLabel(_cats[index]),
                      style: GoogleFonts.dmSans(
                        color:
                            selected ? Colors.white : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.indigoDark))
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.location_off_rounded,
                        title: t('noServicesFound', 'No services found'),
                        sub: t('tryDifferentSearch', 'Try a different search or category'),
                        btnLabel: t('clearFilters', 'Clear Filters'),
                        onBtn: () {
                          _q.clear();
                          setState(() => _cat = 'All');
                          _load();
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: _filtered.length,
                        itemBuilder: (_, index) => _card(_filtered[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> svc) {
    final open = svc['open'] as bool? ?? false;
    final dist = (svc['distance'] as num? ?? 0).toDouble();
    final rating = (svc['rating'] as num? ?? 0).toDouble();

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, Routes.svcContact, arguments: svc),
      child: ACard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.indigoFaint,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_catIcon(svc['category'] as String? ?? ''),
                      color: AppColors.indigoDark, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        svc['name'] as String? ?? '',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        svc['specialty'] as String? ?? '',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        open ? AppColors.successFaint : AppColors.dangerFaint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    open ? t('openLabel', 'Open') : t('closedLabel', 'Closed'),
                    style: GoogleFonts.dmSans(
                      color: open ? AppColors.success : AppColors.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppColors.textTertiary, size: 13),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    svc['address'] as String? ?? '',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                ),
                const Icon(Icons.near_me_rounded,
                    color: AppColors.indigoDark, size: 13),
                const SizedBox(width: 3),
                Text(
                  H.dist(dist * 1000),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.indigoDark,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.star_rounded,
                    color: AppColors.amber, size: 13),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _catIcon(String cat) => switch (cat) {
        'Vets' => Icons.local_hospital_rounded,
        'Input Dealers' => Icons.storefront_rounded,
        'Repair Centers' => Icons.build_rounded,
        'Mandis' => Icons.store_rounded,
        _ => Icons.location_on_rounded,
      };
}
