import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/language_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class ServiceContactScreen extends StatelessWidget {
  final Map<String, dynamic> svc;
  const ServiceContactScreen({super.key, required this.svc});

  String tr(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    final phone = svc['phone'] as String? ?? '';
    final open = svc['open'] as bool? ?? false;
    final dist = (svc['distance'] as num? ?? 0).toDouble();
    final rating = (svc['rating'] as num? ?? 0).toDouble();
    final lat = (svc['lat'] as num?)?.toDouble();
    final lng = (svc['lng'] as num?)?.toDouble();
    final directionsUri = lat == null || lng == null
        ? Uri.parse(
            'https://www.google.com/maps/search/${Uri.encodeComponent(svc['name'] as String? ?? '')}',
          )
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppColors.indigoDark,
          leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white))),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF283593)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)),
              child: SafeArea(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const SizedBox(height: 36),
                    Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.storefront_rounded,
                            color: Colors.white, size: 28)),
                    const SizedBox(height: 8),
                    Text(svc['name'] as String? ?? '',
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center),
                    Text(svc['category'] as String? ?? '',
                        style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11)),
                  ])),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            Row(children: [
              _pill(
                  Icons.circle,
                  open ? tr('openNow', 'Open Now') : tr('closedLabel', 'Closed'),
                  open ? AppColors.success : AppColors.danger,
                  open ? AppColors.successFaint : AppColors.dangerFaint),
              const SizedBox(width: 8),
              _pill(Icons.near_me_rounded, H.dist(dist * 1000),
                  AppColors.indigoDark, AppColors.indigoFaint),
              const SizedBox(width: 8),
              _pill(Icons.star_rounded, rating.toStringAsFixed(1),
                  AppColors.amber, AppColors.amberLight),
            ]),
            const SizedBox(height: 16),
            ACard(
                child: Column(children: [
              KVRow(
                tr('specialty', 'Specialty'),
                H.displayText(svc['specialty'] as String? ?? ''),
              ),
              const Divider(height: 16),
              KVRow(tr('address', 'Address'), svc['address'] as String? ?? ''),
              const Divider(height: 16),
              KVRow(tr('phone', 'Phone'), phone),
            ])),
            const SizedBox(height: 16),
            Btn(
                label: tr('callNow', 'Call Now'),
                icon: Icons.phone_rounded,
                bg: AppColors.indigoDark,
                onTap: () => launchUrl(Uri.parse('tel:$phone'))),
            const SizedBox(height: 10),
            Btn(
                label: tr('chatOnWhatsApp', 'Chat on WhatsApp'),
                icon: Icons.chat_rounded,
                bg: const Color(0xFF25D366),
                onTap: () => launchUrl(Uri.parse(
                    'https://wa.me/91${phone.replaceAll(RegExp(r'\D'), '')}?text=Hello,+I+need+agricultural+services.'))),
            const SizedBox(height: 10),
            Btn.outline(
                label: tr('getDirections', 'Get Directions'),
                icon: Icons.directions_rounded,
                fg: AppColors.indigoDark,
                onTap: () => launchUrl(directionsUri)),
            const SizedBox(height: 30),
          ])),
        ),
      ]),
    );
  }

  Widget _pill(IconData icon, String label, Color color, Color bg) => Expanded(
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ])));
}
