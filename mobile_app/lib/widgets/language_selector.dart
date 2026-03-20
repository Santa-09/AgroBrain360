import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../services/language_service.dart';

// Compact dropdown used in dashboard AppBar (on dark background)
class LangPicker extends StatefulWidget {
  final void Function(String) onChange;
  const LangPicker({super.key, required this.onChange});
  @override
  State<LangPicker> createState() => _LangPickerState();
}

class _LangPickerState extends State<LangPicker> {
  String _val = LangSvc().lang.isEmpty ? 'en' : LangSvc().lang;

  @override
  void initState() {
    super.initState();
    LangSvc().addListener(_syncWithService);
  }

  @override
  void dispose() {
    LangSvc().removeListener(_syncWithService);
    super.dispose();
  }

  void _syncWithService() {
    final next = LangSvc().lang.isEmpty ? 'en' : LangSvc().lang;
    if (!mounted || next == _val) return;
    setState(() => _val = next);
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _val,
            isDense: true,
            dropdownColor: AppColors.primaryDark,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 14),
            style: GoogleFonts.dmSans(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            items: LangSvc.supported.entries
                .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) async {
              if (v == null) return;
              setState(() => _val = v);
              widget.onChange(v);
            },
          ),
        ),
      );
}
