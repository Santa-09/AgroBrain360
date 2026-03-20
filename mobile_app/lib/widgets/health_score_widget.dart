import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/helpers.dart';

class FHIGauge extends StatelessWidget {
  final int score;
  final double size;
  const FHIGauge({super.key, required this.score, this.size = 140});

  @override
  Widget build(BuildContext context) {
    final c = H.fhiColor(score);
    return CircularPercentIndicator(
      radius: size / 2,
      lineWidth: 12,
      percent: (score / 100).clamp(0.0, 1.0),
      center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('$score',
            style: GoogleFonts.dmSans(
                fontSize: size * 0.24,
                fontWeight: FontWeight.w800,
                color: c,
                height: 1)),
        Text(H.fhiLabel(score),
            style: GoogleFonts.dmSans(
                fontSize: size * 0.085,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500)),
      ]),
      progressColor: c,
      backgroundColor: c.withValues(alpha: 0.12),
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 1100,
    );
  }
}

class ScoreStrip extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const ScoreStrip(
      {super.key,
      required this.label,
      required this.score,
      required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500))),
            Text('$score',
                style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
          const SizedBox(height: 5),
          LinearPercentIndicator(
            percent: (score / 100).clamp(0.0, 1.0),
            lineHeight: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            progressColor: color,
            barRadius: const Radius.circular(3),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 900,
          ),
        ]),
      );
}
