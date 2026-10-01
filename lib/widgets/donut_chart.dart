import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/keuangan_model.dart';
import '../theme/app_theme.dart';

class DonutChart extends StatelessWidget {
  final List<PieSlice> slices;
  final int? selected;
  final String centerLabel;
  final String centerValue;
  final double size;

  const DonutChart({
    super.key,
    required this.slices,
    required this.centerLabel,
    required this.centerValue,
    this.selected,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(slices.map((s) => '${s.label}${s.value}').join()),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _DonutPainter(slices, selected, t),
              ),
              Padding(
                padding: EdgeInsets.all(size * 0.22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      centerLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        centerValue,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<PieSlice> slices;
  final int? selected;
  final double progress;

  _DonutPainter(this.slices, this.selected, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 26.0;
    final rect = Rect.fromLTWH(stroke, stroke, size.width - stroke * 2,
        size.height - stroke * 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.cardAlt;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = slices.fold<double>(0, (a, b) => a + b.value);
    if (total <= 0) return;

    final gap = slices.length > 1 ? 0.04 : 0.0;
    var start = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final sweepFull = (slices[i].value / total) * math.pi * 2;
      final sweep = math.max(0.0, sweepFull - gap) * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = selected == i ? stroke + 8 : stroke
        ..color = selected == null || selected == i
            ? slices[i].color
            : slices[i].color.withOpacity(0.35);
      canvas.drawArc(rect, start + gap / 2, sweep, false, paint);
      start += sweepFull * progress;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.selected != selected || old.slices != slices;
}
