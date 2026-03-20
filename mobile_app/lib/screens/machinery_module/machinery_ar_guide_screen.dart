import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../services/language_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class MachineryArGuideScreen extends StatefulWidget {
  final String machine;
  final String issue;
  final File imageFile;

  const MachineryArGuideScreen({
    super.key,
    required this.machine,
    required this.issue,
    required this.imageFile,
  });

  @override
  State<MachineryArGuideScreen> createState() => _MachineryArGuideScreenState();
}

class _MachineryArGuideScreenState extends State<MachineryArGuideScreen> {
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    LangSvc().addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LangSvc().removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

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

  Map<String, dynamic> get _guide {
    switch (widget.issue) {
      case 'Oil Leak':
        return {
          'overlayLabel': tr(
            'overlayOilLeak',
            'Match the highlighted area with hoses, seals, and the lower engine casing.',
          ),
          'tools': [
            tr('toolSpanner', 'Spanner set'),
            tr('toolTorch', 'Torch'),
            tr('toolCleanCloth', 'Clean cloth'),
          ],
          'steps': [
            tr('repairOilLeakStep1',
                'Wipe the suspected area clean so the fresh leak point becomes visible.'),
            tr('repairOilLeakStep2',
                'Check hose joints, filter mount, and drain plug for loose fittings.'),
            tr('repairOilLeakStep3',
                'Tighten the loose connection gently and replace damaged seal or hose before reuse.'),
          ],
        };
      case 'Overheating':
        return {
          'overlayLabel': tr(
            'overlayOverheating',
            'Align this box over the radiator, coolant pipe, or air vents.',
          ),
          'tools': [
            tr('toolGloves', 'Gloves'),
            tr('toolBrush', 'Soft brush'),
            tr('toolCoolant', 'Coolant / water'),
          ],
          'steps': [
            tr('repairOverheatStep1',
                'Let the machine cool fully before touching the radiator area.'),
            tr('repairOverheatStep2',
                'Remove dust from fins or vents and inspect coolant or water level.'),
            tr('repairOverheatStep3',
                'Check belt tension and restart only after airflow and coolant are restored.'),
          ],
        };
      case 'Low Spray Pressure':
        return {
          'overlayLabel': tr(
            'overlaySprayer',
            'Align on the nozzle line, filter cup, or pump head to inspect spray blockage.',
          ),
          'tools': [
            tr('toolNeedle', 'Cleaning pin'),
            tr('toolBucket', 'Water bucket'),
            tr('toolWrench', 'Small wrench'),
          ],
          'steps': [
            tr('repairSprayStep1',
                'Flush the tank line and remove the nozzle cap carefully.'),
            tr('repairSprayStep2',
                'Clean the nozzle and inline filter without widening the nozzle hole.'),
            tr('repairSprayStep3',
                'Prime the pump again and test with clean water before spraying chemical mix.'),
          ],
        };
      case 'Battery Issue':
        return {
          'overlayLabel': tr(
            'overlayBattery',
            'Align on the battery terminals and cable clamps to inspect corrosion or loose contact.',
          ),
          'tools': [
            tr('toolSpanner', 'Spanner set'),
            tr('toolBrush', 'Wire brush'),
            tr('toolTester', 'Voltage tester'),
          ],
          'steps': [
            tr('repairBatteryStep1',
                'Switch the machine off and inspect terminals for white or green corrosion.'),
            tr('repairBatteryStep2',
                'Clean the terminals, tighten cable clamps, and check the fuse link.'),
            tr('repairBatteryStep3',
                'If cranking is still weak, recharge or replace the battery before field use.'),
          ],
        };
      case 'Loose Belt':
        return {
          'overlayLabel': tr(
            'overlayBelt',
            'Align on the pulley-belt path to inspect cracks, slack, or misalignment.',
          ),
          'tools': [
            tr('toolSpanner', 'Spanner set'),
            tr('toolTorch', 'Torch'),
            tr('toolGloves', 'Gloves'),
          ],
          'steps': [
            tr('repairBeltStep1',
                'Inspect the belt for cracks, glazing, or excessive looseness.'),
            tr('repairBeltStep2',
                'Adjust pulley tension gradually until the belt deflects only slightly by hand.'),
            tr('repairBeltStep3',
                'Replace the belt if edges are frayed or if slippage continues after adjustment.'),
          ],
        };
      case 'Engine Noise':
      default:
        return {
          'overlayLabel': tr(
            'overlayEngineNoise',
            'Align this box over the engine bay or drive section where the sound is strongest.',
          ),
          'tools': [
            tr('toolSpanner', 'Spanner set'),
            tr('toolTorch', 'Torch'),
            tr('toolGloves', 'Gloves'),
          ],
          'steps': [
            tr('repairEngineNoiseStep1',
                'Switch off the machine and inspect visible bolts, covers, and mountings in the highlighted zone.'),
            tr('repairEngineNoiseStep2',
                'Check for loose guards, leaking pipes, or belt rubbing near the sound source.'),
            tr('repairEngineNoiseStep3',
                'Tighten loose fittings and avoid heavy use until abnormal noise is resolved.'),
          ],
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = _guide;
    final issue = _issueLabel(widget.issue);
    final machine = _machineLabel(widget.machine);
    final overlayLabel = guide['overlayLabel'] as String? ?? '';
    final tools = (guide['tools'] as List<dynamic>? ?? const []).cast<String>();
    final steps = (guide['steps'] as List<dynamic>? ?? const []).cast<String>();
    if (_stepIndex >= steps.length && steps.isNotEmpty) {
      _stepIndex = steps.length - 1;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(tr('arRepairAssist', 'AR Repair Assist')),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ACard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    machine,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orangeDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _imageOverlay(overlayLabel),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ACard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                    tr('repairToolsChecklist', 'Tools checklist'),
                    Icons.handyman_rounded,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tools
                        .map((tool) => _pill(tool, AppColors.primaryDark))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ACard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                    tr('guidedRepairSteps', 'Guided repair steps'),
                    Icons.view_in_ar_rounded,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFaint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tr('stepLabel', 'Step')} ${_stepIndex + 1}/${steps.length}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          steps.isEmpty ? '' : steps[_stepIndex],
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Btn.outline(
                          label: tr('prevLabel', 'Prev'),
                          fg: AppColors.primaryDark,
                          onTap: _stepIndex == 0
                              ? null
                              : () => setState(() => _stepIndex -= 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Btn(
                          label: steps.isEmpty || _stepIndex == steps.length - 1
                              ? tr('doneLabel', 'Done')
                              : tr('nextStep', 'Next Step'),
                          bg: AppColors.primaryDark,
                          onTap: () {
                            if (steps.isEmpty || _stepIndex == steps.length - 1) {
                              Navigator.pop(context);
                              return;
                            }
                            setState(() => _stepIndex += 1);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ACard(
              color: AppColors.orangeFaint,
              borderColor: AppColors.orangeFaint,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.orangeDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr(
                        'machineryArSafetyNote',
                        'Turn off the engine, remove the key, and let hot parts cool before attempting any repair.',
                      ),
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageOverlay(String overlayLabel) => AspectRatio(
        aspectRatio: 1.12,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(widget.imageFile, fit: BoxFit.cover),
              Container(
                color: Colors.black.withValues(alpha: 0.18),
              ),
              Center(
                child: Container(
                  width: 210,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.amber, width: 3),
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tr('overlayTarget', 'Overlay target'),
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    overlayLabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sectionTitle(String title, IconData icon) => Row(
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
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      );

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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
