import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/ai_case_chat_args.dart';
import '../../routes/app_routes.dart';
import '../../services/language_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class MachineryScanScreen extends StatefulWidget {
  const MachineryScanScreen({super.key});

  @override
  State<MachineryScanScreen> createState() => _MachineryScanScreenState();
}

class _MachineryScanScreenState extends State<MachineryScanScreen> {
  final _cropCtrl = TextEditingController();
  final _landCtrl = TextEditingController();
  final _lastServiceCtrl = TextEditingController();
  final _usageCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _voiceNoteCtrl = TextEditingController();
  final _picker = ImagePicker();

  String _recommendationMachine = 'Tractor';
  String _maintenanceMachine = 'Tractor';
  String _costMachine = 'Tractor';
  String _rentalMachine = 'Tractor';

  Map<String, dynamic>? _recommendation;
  Map<String, dynamic>? _maintenance;
  Map<String, dynamic>? _costEstimate;
  List<Map<String, dynamic>> _rentals = [];
  String? _machineryAdvisory;
  bool _listening = false;
  bool _backendRecording = false;

  Position? _currentPosition;
  String _locationLabel = '';
  bool _findingLocation = false;
  File? _repairImage;
  String _repairMachine = 'Tractor';
  String _repairIssue = 'Engine Noise';

  static const _machines = [
    'Tractor',
    'Power Tiller',
    'Seed Drill',
    'Sprayer',
    'Rotavator',
    'Harvester',
    'Water Pump',
    'Cultivator',
  ];

  static const _repairIssues = [
    'Engine Noise',
    'Oil Leak',
    'Overheating',
    'Low Spray Pressure',
    'Battery Issue',
    'Loose Belt',
  ];

  static const _hourlyRates = {
    'Tractor': 900.0,
    'Power Tiller': 550.0,
    'Seed Drill': 420.0,
    'Sprayer': 180.0,
    'Rotavator': 650.0,
    'Harvester': 1500.0,
    'Water Pump': 140.0,
    'Cultivator': 480.0,
  };

  static const _manualLocations = {
    'bhubaneswar': {'label': 'Bhubaneswar, Odisha', 'lat': 20.2961, 'lng': 85.8245},
    'cuttack': {'label': 'Cuttack, Odisha', 'lat': 20.4625, 'lng': 85.8830},
    'puri': {'label': 'Puri, Odisha', 'lat': 19.8135, 'lng': 85.8312},
    'sambalpur': {'label': 'Sambalpur, Odisha', 'lat': 21.4669, 'lng': 83.9812},
    'berhampur': {'label': 'Berhampur, Odisha', 'lat': 19.3149, 'lng': 84.7941},
    'rourkela': {'label': 'Rourkela, Odisha', 'lat': 22.2604, 'lng': 84.8536},
  };

  static const _rentalData = [
    {
      'machineType': 'Tractor',
      'ownerName': 'Ramesh Agro Rentals',
      'pricePerHour': 850,
      'phone': '+919876543210',
      'place': 'Bhubaneswar',
      'lat': 20.3055,
      'lng': 85.8174,
    },
    {
      'machineType': 'Harvester',
      'ownerName': 'Green Field Harvesters',
      'pricePerHour': 1600,
      'phone': '+919912345678',
      'place': 'Cuttack',
      'lat': 20.4706,
      'lng': 85.8792,
    },
    {
      'machineType': 'Power Tiller',
      'ownerName': 'Maa Tarini Farm Machines',
      'pricePerHour': 520,
      'phone': '+919834567890',
      'place': 'Puri',
      'lat': 19.8079,
      'lng': 85.8406,
    },
    {
      'machineType': 'Sprayer',
      'ownerName': 'Kisan Spray Point',
      'pricePerHour': 170,
      'phone': '+919845612307',
      'place': 'Bhubaneswar',
      'lat': 20.2830,
      'lng': 85.8052,
    },
    {
      'machineType': 'Rotavator',
      'ownerName': 'Delta Implements Hub',
      'pricePerHour': 640,
      'phone': '+919955551234',
      'place': 'Berhampur',
      'lat': 19.3058,
      'lng': 84.8015,
    },
    {
      'machineType': 'Water Pump',
      'ownerName': 'Jal Rakshak Rentals',
      'pricePerHour': 150,
      'phone': '+919811112222',
      'place': 'Sambalpur',
      'lat': 21.4722,
      'lng': 83.9877,
    },
    {
      'machineType': 'Cultivator',
      'ownerName': 'Eastern Soil Tech',
      'pricePerHour': 460,
      'phone': '+919822223333',
      'place': 'Rourkela',
      'lat': 22.2538,
      'lng': 84.8602,
    },
    {
      'machineType': 'Seed Drill',
      'ownerName': 'Precision Seeder Network',
      'pricePerHour': 410,
      'phone': '+919833334444',
      'place': 'Cuttack',
      'lat': 20.4561,
      'lng': 85.8911,
    },
    {
      'machineType': 'Tractor',
      'ownerName': 'Jagannath Tractor Service',
      'pricePerHour': 880,
      'phone': '+919844445555',
      'place': 'Puri',
      'lat': 19.8203,
      'lng': 85.8267,
    },
  ];

  String tr(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  String _machineLabel(String machine) => switch (machine) {
        'Tractor' => tr('machineTractor', 'Tractor'),
        'Power Tiller' => tr('machinePowerTiller', 'Power Tiller'),
        'Seed Drill' => tr('machineSeedDrill', 'Seed Drill'),
        'Sprayer' => tr('machineSprayer', 'Sprayer'),
        'Rotavator' => tr('machineRotavator', 'Rotavator'),
        'Harvester' => tr('machineHarvester', 'Harvester'),
        'Water Pump' => tr('machineWaterPump', 'Water Pump'),
        'Cultivator' => tr('machineCultivator', 'Cultivator'),
        _ => machine,
      };

  String _issueLabel(String issue) => switch (issue) {
        'Engine Noise' => tr('issueEngineNoise', 'Engine Noise'),
        'Oil Leak' => tr('issueOilLeak', 'Oil Leak'),
        'Overheating' => tr('issueOverheating', 'Overheating'),
        'Low Spray Pressure' =>
          tr('issueLowSprayPressure', 'Low Spray Pressure'),
        'Battery Issue' => tr('issueBatteryIssue', 'Battery Issue'),
        'Loose Belt' => tr('issueLooseBelt', 'Loose Belt'),
        _ => issue,
      };

  @override
  void initState() {
    super.initState();
    LangSvc().addListener(_onLanguageChanged);
    _locationLabel = tr('machineryLocationDefault', 'Set location to see nearest rentals');
    _applyManualLocation(silent: true);
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    final hasRecommendation = _recommendation != null;
    final hasMaintenance = _maintenance != null;
    final hasCostEstimate = _costEstimate != null;

    setState(() {
      if (_locationCtrl.text.trim().isEmpty && _currentPosition == null) {
        _locationLabel = tr(
            'machineryLocationDefault', 'Set location to see nearest rentals');
      } else if (_locationCtrl.text.trim().isEmpty &&
          _currentPosition != null) {
        _locationLabel =
            tr('machineryLiveLocationDetected', 'Live location detected');
      }
    });

    if (hasRecommendation) {
      _suggestMachine();
    }
    if (hasMaintenance) {
      _checkStatus();
    }
    if (hasCostEstimate) {
      _calculateCost();
    }
  }

  @override
  void dispose() {
    LangSvc().removeListener(_onLanguageChanged);
    _cropCtrl.dispose();
    _landCtrl.dispose();
    _lastServiceCtrl.dispose();
    _usageCtrl.dispose();
    _hoursCtrl.dispose();
    _locationCtrl.dispose();
    _voiceNoteCtrl.dispose();
    unawaited(VoiceSvc().stop());
    unawaited(VoiceSvc().cancelBackendRecording());
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_backendRecording) {
      final res = await VoiceSvc().stopBackendRecordingAndTranscribe(
        lang: LangSvc().lang,
        detectIntent: false,
        prompt: 'Transcribe machinery issue or request clearly.',
      );
      if (!mounted) return;
      setState(() => _backendRecording = false);
      if (res.ok && res.data != null) {
        final payload = res.data!;
        final data = payload['data'] as Map<String, dynamic>? ?? payload;
        final text = (data['text'] ?? '').toString().trim();
        if (text.isNotEmpty) {
          setState(() => _voiceNoteCtrl.text = text);
        } else {
          H.snack(context, tr('noSpeechDetected', 'No speech detected'), error: true);
        }
      } else if (mounted) {
        H.snack(context, res.error ?? tr('voiceFailed', 'AI voice request failed'), error: true);
      }
      return;
    }
    if (_listening) {
      await VoiceSvc().stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    final started = await VoiceSvc().listen(
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _voiceNoteCtrl.text = text;
          _listening = false;
        });
      },
      lang: LangSvc().lang,
    );
    if (!started && mounted) {
      setState(() => _listening = false);
      final backendStarted = await VoiceSvc().startBackendRecording();
      if (!mounted) return;
      if (backendStarted) {
        setState(() => _backendRecording = true);
        H.snack(context, tr('recordingAiVoice', 'Recording for AI voice... tap Stop when finished.'));
      } else {
        H.snack(context, tr('voiceUnavailable', 'Voice input is unavailable right now'), error: true);
      }
    }
  }

  Future<void> _toggleAiVoice() async {
    if (_backendRecording) {
      final res = await VoiceSvc().stopBackendRecordingAndProcessVoice(
        module: 'machinery',
        context: {
          'crop': _cropCtrl.text.trim(),
          'land_size': _landCtrl.text.trim(),
          'machine': _recommendationMachine,
          'usage': _usageCtrl.text.trim(),
          'hours': _hoursCtrl.text.trim(),
          'notes': _voiceNoteCtrl.text.trim(),
        },
        lang: LangSvc().lang,
        prompt: 'Transcribe machinery issue or request clearly and give practical farm machinery advice.',
      );
      if (!mounted) return;
      setState(() => _backendRecording = false);
      if (res.ok && res.data != null) {
        final payload = res.data!;
        final data = payload['data'] as Map<String, dynamic>? ?? payload;
        setState(() {
          _voiceNoteCtrl.text = (data['user_text'] ?? '').toString();
          _machineryAdvisory = (data['ai_response'] ?? '')
              .toString()
              .replaceAll('**', '');
        });
        await VoiceSvc().setLang(LangSvc().lang);
        await VoiceSvc().speakWithFallback(
          audioUrl: data['audio_url']?.toString(),
          fallbackText: _machineryAdvisory ?? '',
        );
        if (mounted) {
          H.snack(context, tr('voiceProcessed', 'AI voice response ready'));
        }
      } else if (mounted) {
        H.snack(context, res.error ?? tr('voiceFailed', 'AI voice request failed'), error: true);
      }
      return;
    }

    if (_listening) {
      await VoiceSvc().stop();
      if (mounted) setState(() => _listening = false);
    }
    final started = await VoiceSvc().startBackendRecording();
    if (!mounted) return;
    if (!started) {
      H.snack(context, tr('whisperNeedsInternet', 'AI voice needs internet and microphone permission'), error: true);
      return;
    }
    setState(() => _backendRecording = true);
  }

  void _suggestMachine() {
    final crop = _cropCtrl.text.trim().toLowerCase();
    final land = double.tryParse(_landCtrl.text.trim()) ?? 0;

    String machine = 'Tractor';
    String reason = tr('machineryReasonBalanced',
        'Balanced choice for tillage, haulage, and field preparation.');
    final tasks = <String>[
      tr('machineryTaskTillage', 'Primary tillage'),
      tr('machineryTaskTransport', 'Transport'),
      tr('machineryTaskFieldWork', 'General field work')
    ];

    if (crop.contains('rice')) {
      if (land <= 2) {
        machine = 'Power Tiller';
        reason = tr('machineryReasonRiceSmall',
            'Fits small wetland plots and reduces turning effort in rice fields.');
        tasks
          ..clear()
          ..addAll([
            tr('machineryTaskPuddling', 'Puddling'),
            tr('machineryTaskInterCultivation', 'Inter-cultivation'),
            tr('machineryTaskSmallPlot', 'Small-plot tillage')
          ]);
      } else {
        machine = 'Harvester';
        reason = tr('machineryReasonRiceLarge',
            'Larger rice acreage benefits from faster harvesting and lower labor dependence.');
        tasks
          ..clear()
          ..addAll([
            tr('machineryTaskHarvesting', 'Harvesting'),
            tr('machineryTaskThreshing', 'Threshing support'),
            tr('machineryTaskLaborSaving', 'Peak-season labor savings')
          ]);
      }
    } else if (crop.contains('wheat') || crop.contains('maize')) {
      machine = land >= 4 ? 'Seed Drill' : 'Cultivator';
      reason = land >= 4
          ? tr('machineryReasonCerealLarge',
              'Improves sowing speed and spacing consistency on medium to large plots.')
          : tr('machineryReasonCerealSmall',
              'Efficient for seedbed prep and interculture on smaller cereal plots.');
      tasks
        ..clear()
        ..addAll(land >= 4
            ? [
                tr('machineryTaskLineSowing', 'Line sowing'),
                tr('machineryTaskSeedPlacement', 'Seed placement'),
                tr('machineryTaskCoverageSpeed', 'Coverage speed')
              ]
            : [
                tr('machineryTaskWeeding', 'Weeding'),
                tr('machineryTaskSoilLoosening', 'Soil loosening'),
                tr('machineryTaskBedPreparation', 'Bed preparation')
              ]);
    } else if (crop.contains('vegetable') || crop.contains('chilli') || crop.contains('tomato')) {
      machine = 'Sprayer';
      reason = tr('machineryReasonVegetable',
          'Best for frequent protection sprays and nutrient application in intensive crops.');
      tasks
        ..clear()
        ..addAll([
          tr('machineryTaskPesticideSpray', 'Pesticide spray'),
          tr('machineryTaskFoliarFeeding', 'Foliar feeding'),
          tr('machineryTaskTargetedCare', 'Targeted crop care')
        ]);
    } else if (crop.contains('sugarcane')) {
      machine = 'Rotavator';
      reason = tr('machineryReasonSugarcane',
          'Useful for residue mixing and deep field preparation before ratoon or replanting.');
      tasks
        ..clear()
        ..addAll([
          tr('machineryTaskResidueMixing', 'Residue mixing'),
          tr('machineryTaskSoilBreakup', 'Soil breakup'),
          tr('machineryTaskFieldPreparation', 'Field preparation')
        ]);
    }

    setState(() {
      _recommendationMachine = machine;
      _recommendation = {
        'machine': machine,
        'land': land,
        'reason': reason,
        'tasks': tasks,
      };
      _rentalMachine = machine;
      _refreshRentals();
    });
  }

  void _checkStatus() {
    final usage = double.tryParse(_usageCtrl.text.trim()) ?? 0;
    final serviceDate = DateTime.tryParse(_lastServiceCtrl.text.trim());

    final days = serviceDate == null ? 999 : DateTime.now().difference(serviceDate).inDays;
    String status = tr('statusGood', 'Good');
    String note = tr('machineryStatusGoodNote',
        'Machine is within a safe maintenance window.');
    Color color = AppColors.success;

    if (days > 180 || usage > 450) {
      status = tr('statusUrgent', 'Urgent');
      note = tr('machineryStatusUrgentNote',
          'Service immediately before next heavy operation to avoid breakdown risk.');
      color = AppColors.danger;
    } else if (days > 120 || usage > 300) {
      status = tr('statusDueSoon', 'Due Soon');
      note = tr('machineryStatusDueSoonNote',
          'Maintenance window is close. Plan service this week.');
      color = AppColors.warning;
    } else if (serviceDate == null) {
      status = tr('statusCheckRecord', 'Check Record');
      note = tr('machineryStatusCheckRecordNote',
          'Enter the last service date to assess maintenance risk accurately.');
      color = AppColors.info;
    }

    setState(() {
      _maintenance = {
        'status': status,
        'note': note,
        'days': serviceDate == null ? null : days,
        'usage': usage,
        'color': color,
      };
    });
  }

  void _calculateCost() {
    final hours = double.tryParse(_hoursCtrl.text.trim()) ?? 0;
    final rate = _hourlyRates[_costMachine] ?? 0;
    final fuel = hours * rate * 0.18;
    final operator = hours * rate * 0.12;
    final total = (hours * rate) + fuel + operator;

    setState(() {
      _costEstimate = {
        'rate': rate,
        'hours': hours,
        'fuel': fuel,
        'operator': operator,
        'total': total,
      };
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 30)),
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked != null) {
      _lastServiceCtrl.text = picked.toIso8601String().split('T').first;
      _checkStatus();
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _findingLocation = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) H.snack(context, tr('machineryEnableLocation',
            'Enable location services to fetch nearby rentals.'), error: true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) H.snack(context, tr('machineryLocationPermission',
            'Location permission is needed for real-time rentals.'), error: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _currentPosition = position;
        _locationLabel = tr('machineryLiveLocationDetected', 'Live location detected');
      });
      _refreshRentals();
    } catch (_) {
      if (mounted) H.snack(context, tr('machineryLocationFetchFailed',
          'Unable to fetch current location.'), error: true);
    } finally {
      if (mounted) setState(() => _findingLocation = false);
    }
  }

  void _applyManualLocation({bool silent = false}) {
    final input = _locationCtrl.text.trim().toLowerCase();
    if (input.isEmpty) {
      _refreshRentals();
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
        H.snack(context, tr('machineryManualLocationHelp',
            'Manual location not recognized. Try Bhubaneswar, Cuttack, Puri, Sambalpur, Berhampur, or Rourkela.'), error: true);
      }
      return;
    }

    final resolved = match!;
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
    });
    _refreshRentals();
  }

  void _refreshRentals() {
    final rentals = _rentalData
        .where((item) => item['machineType'] == _rentalMachine)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (_currentPosition != null) {
      for (final item in rentals) {
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          (item['lat'] as num).toDouble(),
          (item['lng'] as num).toDouble(),
        );
        item['distance'] = distance;
      }
      rentals.sort(
        (a, b) => ((a['distance'] as num?) ?? 1e9).compareTo((b['distance'] as num?) ?? 1e9),
      );
    }

    setState(() => _rentals = rentals);
  }

  Future<void> _contactOwner(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri)) {
      if (mounted) H.snack(context, tr('machineryDialerFailed',
          'Unable to open phone dialer.'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('machinery', 'Machinery')),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(),
            const SizedBox(height: 16),
            _recommendationCard(),
            const SizedBox(height: 14),
            _maintenanceCard(),
            const SizedBox(height: 14),
            _costCard(),
            const SizedBox(height: 14),
            _repairAssistCard(),
            const SizedBox(height: 14),
            _rentalsCard(),
          ],
        ),
      ),
    );
  }

  Widget _hero() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.orangeDark,
              AppColors.amber,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('machineryModuleTitle', 'MACHINERY MODULE'),
              style: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('machineryModuleSubtitle',
                  'Recommendation, maintenance, rental cost, and nearby machine rentals in one place.'),
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _locationLabel,
              style: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Future<void> _pickRepairImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() => _repairImage = File(picked.path));
  }

  void _openAiChat() {
    final contextData = <String, dynamic>{
      'crop': _cropCtrl.text.trim(),
      'land_size': _landCtrl.text.trim(),
      'machine': _recommendationMachine,
      'voice_notes': _voiceNoteCtrl.text.trim(),
      if (_recommendation != null) ..._recommendation!,
      if (_maintenance != null) ..._maintenance!,
      if (_costEstimate != null) ..._costEstimate!,
      if (_machineryAdvisory != null) 'advisory': _machineryAdvisory,
      'image_url': _repairImage?.path ?? '',
    };

    Navigator.pushNamed(
      context,
      Routes.aiCaseChat,
      arguments: AiCaseChatArgs(
        module: 'machinery',
        title: tr('recommendation', 'Recommendation'),
        imagePath: _repairImage?.path,
        context: contextData,
      ),
    );
  }

  void _openRepairAssist() {
    if (_repairImage == null) {
      H.snack(
        context,
        tr('machineryRepairNeedsPhoto',
            'Capture a machine-part photo before opening repair assist.'),
        error: true,
      );
      return;
    }

    Navigator.pushNamed(
      context,
      Routes.machArGuide,
      arguments: {
        'machine': _repairMachine,
        'issue': _repairIssue,
        'imageFile': _repairImage!,
      },
    );
  }

  Widget _recommendationCard() => ACard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(tr('recommendation', 'Recommendation'), Icons.agriculture_rounded),
            const SizedBox(height: 12),
            _field(_cropCtrl, tr('cropLabel', 'Crop'), hint: tr('machineryCropHint', 'Rice, wheat, maize, vegetables')),
            const SizedBox(height: 10),
            _field(_landCtrl, tr('landSize', 'Land Size'), hint: tr('machineryLandHint', 'Area in acres'), keyboard: TextInputType.number),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _voiceNoteCtrl,
                    tr('voiceNotes', 'Voice notes'),
                    hint: tr('voiceNotesHintMachinery', 'e.g. Tractor engine making noise near fuel filter'),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleVoice,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: _listening ? AppColors.danger : AppColors.orangeFaint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _listening ? Colors.white : AppColors.orangeDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleAiVoice,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: _backendRecording ? AppColors.warning : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _backendRecording ? AppColors.warning : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      _backendRecording ? Icons.stop_circle_outlined : Icons.cloud_rounded,
                      color: _backendRecording ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (_machineryAdvisory != null && _machineryAdvisory!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _machineryAdvisory!,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Btn(
              label: tr('suggestMachine', 'Suggest Machine'),
              icon: Icons.auto_awesome_rounded,
              bg: AppColors.orangeDark,
              onTap: _suggestMachine,
            ),
            if (_recommendation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.orangeFaint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _machineLabel(_recommendation!['machine'] as String),
                      style: GoogleFonts.dmSans(
                        color: AppColors.orangeDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _recommendation!['reason'] as String,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_recommendation!['tasks'] as List<dynamic>)
                          .map((task) => _pill(task.toString(), AppColors.orangeDark, AppColors.surface))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Btn.outline(
                label: tr('betterSuggestion', 'Ask AI for Better Suggestion'),
                icon: Icons.chat_bubble_rounded,
                fg: AppColors.orangeDark,
                onTap: _openAiChat,
              ),
            ],
          ],
        ),
      );

  Widget _maintenanceCard() => ACard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(tr('maintenance', 'Maintenance'), Icons.build_circle_rounded),
            const SizedBox(height: 12),
            _dropdown(tr('machine', 'Machine'), _maintenanceMachine, (value) {
              setState(() => _maintenanceMachine = value!);
            }),
            const SizedBox(height: 10),
            TextField(
              controller: _lastServiceCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: tr('lastService', 'Last Service'),
                hintText: tr('dateFormatHint', 'YYYY-MM-DD'),
                suffixIcon: const Icon(Icons.calendar_month_rounded),
              ),
            ),
            const SizedBox(height: 10),
            _field(_usageCtrl, tr('usage', 'Usage'), hint: tr('machineryUsageHint', 'Hours since last service'), keyboard: TextInputType.number),
            const SizedBox(height: 12),
            Btn(
              label: tr('checkStatus', 'Check Status'),
              icon: Icons.health_and_safety_rounded,
              bg: AppColors.primaryDark,
              onTap: _checkStatus,
            ),
            if (_maintenance != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_maintenance!['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: (_maintenance!['color'] as Color).withValues(alpha: 0.28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: _maintenance!['color'] as Color),
                        const SizedBox(width: 8),
                        Text(
                          _maintenance!['status'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _maintenance!['note'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _costCard() => ACard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(tr('costCalculator', 'Cost Calculator'), Icons.currency_rupee_rounded),
            const SizedBox(height: 12),
            _dropdown(tr('machine', 'Machine'), _costMachine, (value) {
              setState(() => _costMachine = value!);
            }),
            const SizedBox(height: 10),
            _field(_hoursCtrl, tr('hours', 'Hours'), hint: tr('machineryHoursHint', 'Enter operating hours'), keyboard: TextInputType.number),
            const SizedBox(height: 12),
            Btn(
              label: tr('calculate', 'Calculate'),
              icon: Icons.calculate_rounded,
              bg: AppColors.indigoDark,
              onTap: _calculateCost,
            ),
            if (_costEstimate != null) ...[
              const SizedBox(height: 12),
              ACard(
                color: AppColors.indigoFaint,
                borderColor: AppColors.indigoFaint,
                child: Column(
                  children: [
                    KVRow(tr('ratePerHour', 'Rate/hr'), H.rupees((_costEstimate!['rate'] as num).toDouble())),
                    KVRow(tr('fuelEstimate', 'Fuel estimate'), H.rupees((_costEstimate!['fuel'] as num).toDouble())),
                    KVRow(tr('operatorEstimate', 'Operator estimate'), H.rupees((_costEstimate!['operator'] as num).toDouble())),
                    const Divider(height: 18),
                    KVRow(
                      tr('total', 'Total'),
                      H.rupees((_costEstimate!['total'] as num).toDouble()),
                      valueColor: AppColors.indigoDark,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _repairAssistCard() => ACard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              tr('arRepairAssist', 'AR Repair Assist'),
              Icons.view_in_ar_rounded,
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                'machineryRepairSub',
                'Capture the faulty part and open a guided overlay with tools and step-by-step repair help.',
              ),
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _dropdown(tr('machine', 'Machine'), _repairMachine, (value) {
              setState(() => _repairMachine = value!);
            }),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _repairIssue,
              decoration:
                  InputDecoration(labelText: tr('issueType', 'Issue Type')),
              items: _repairIssues
                  .map(
                    (issue) => DropdownMenuItem<String>(
                      value: issue,
                      child: Text(_issueLabel(issue)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _repairIssue = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Btn.outline(
                    label: tr('camera', 'Camera'),
                    fg: AppColors.primaryDark,
                    onTap: () => _pickRepairImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Btn.outline(
                    label: tr('gallery', 'Gallery'),
                    fg: AppColors.primaryDark,
                    onTap: () => _pickRepairImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (_repairImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  _repairImage!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Btn(
              label: tr('openArGuide', 'Open AR Guide'),
              icon: Icons.auto_awesome_motion_rounded,
              bg: AppColors.orangeDark,
              onTap: _openRepairAssist,
            ),
          ],
        ),
      );

  Widget _rentalsCard() => ACard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(tr('nearbyRentals', 'Nearby Rentals'), Icons.location_on_rounded),
            const SizedBox(height: 12),
            _field(
              _locationCtrl,
              tr('locationAutoInput', 'Location (Auto / Input)'),
              hint: tr('machineryLocationHint', 'Use current location or type city'),
              onChanged: (_) => _applyManualLocation(silent: true),
            ),
            const SizedBox(height: 10),
            Btn.outline(
              label: _findingLocation ? tr('locating', 'Locating...') : tr('useMyLocation', 'Use My Location'),
              fg: AppColors.primaryDark,
              onTap: _findingLocation ? null : _detectLocation,
            ),
            const SizedBox(height: 10),
            _dropdown(tr('machineType', 'Machine Type'), _rentalMachine, (value) {
              setState(() => _rentalMachine = value!);
              _refreshRentals();
            }),
            const SizedBox(height: 12),
            Btn(
              label: tr('findRentals', 'Find Rentals'),
              icon: Icons.travel_explore_rounded,
              bg: AppColors.primary,
              onTap: () {
                _applyManualLocation();
                _refreshRentals();
              },
            ),
            const SizedBox(height: 12),
            if (_rentals.isEmpty)
              Text(
                tr('noRentalsFound', 'No rentals found for the selected machine.'),
                style: GoogleFonts.dmSans(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              )
            else
              Column(
                children: _rentals.map(_rentalTile).toList(),
              ),
          ],
        ),
      );

  Widget _rentalTile(Map<String, dynamic> rental) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rental['ownerName'] as String,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              KVRow(tr('ownerName', 'Owner Name'), rental['ownerName'] as String),
              KVRow(tr('pricePerHour', 'Price/hr'), H.rupees((rental['pricePerHour'] as num).toDouble())),
              KVRow(
                tr('distance', 'Distance'),
                rental['distance'] == null ? rental['place'] as String : H.dist((rental['distance'] as num).toDouble()),
              ),
              const SizedBox(height: 10),
              Btn(
                label: tr('contactButton', 'Contact Button'),
                icon: Icons.call_rounded,
                bg: AppColors.primaryDark,
                onTap: () => _contactOwner(rental['phone'] as String),
              ),
            ],
          ),
        ),
      );

  Widget _sectionHeader(String title, IconData icon) => Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboard,
    ValueChanged<String>? onChanged,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      );

  Widget _dropdown(String label, String value, ValueChanged<String?> onChanged) => DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: _machines
            .map(
              (machine) => DropdownMenuItem<String>(
                value: machine,
                child: Text(_machineLabel(machine)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      );

  Widget _pill(String text, Color color, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
