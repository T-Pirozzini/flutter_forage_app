import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// A real-to-size ruler overlay for measuring shellfish
/// Calibrated to display actual size based on device screen DPI
class RulerOverlay extends StatefulWidget {
  const RulerOverlay({super.key});

  @override
  State<RulerOverlay> createState() => _RulerOverlayState();
}

class _RulerOverlayState extends State<RulerOverlay> {
  bool _showMetric = true;

  void _showInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.accent, size: 22),
                const SizedBox(width: 10),
                Text(
                  'How to use',
                  style: AppTheme.title(
                    size: 16,
                    weight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '1. Place your shellfish next to the screen\n'
              '2. Align the shell edge with the 0 mark\n'
              '3. Read measurement at the opposite edge',
              style: AppTheme.body(size: 14, color: AppTheme.textWhite),
            ),
            const SizedBox(height: 16),
            Text(
              'Note: Ruler is calibrated for standard screen DPI. '
              'For precise measurements, use an official measuring tool.',
              style: AppTheme.caption(
                size: 12,
                color: AppTheme.textWhite.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Column(
          children: [
            // Compact header: close, title, unit toggle, info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Shellfish Ruler',
                    style: AppTheme.heading(size: 18, color: AppTheme.textWhite),
                  ),
                  const Spacer(),
                  // Unit toggle chips
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUnitChip('cm', true),
                        _buildUnitChip('in', false),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.help_outline, color: AppTheme.textWhite, size: 22),
                    onPressed: _showInfo,
                  ),
                ],
              ),
            ),

            // Ruler fills remaining space
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: _showMetric
                        ? MetricRuler(availableHeight: constraints.maxHeight)
                        : ImperialRuler(availableHeight: constraints.maxHeight),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitChip(String label, bool isMetric) {
    final isSelected = _showMetric == isMetric;
    return GestureDetector(
      onTap: () => setState(() => _showMetric = isMetric),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.textWhite : AppTheme.textMedium,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Vertical ruler showing centimeters — dynamically sized to fit screen
class MetricRuler extends StatelessWidget {
  final double availableHeight;

  const MetricRuler({super.key, required this.availableHeight});

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final pixelsPerCm = 63.0 / devicePixelRatio;

    // Calculate how many whole cm fit in the available height (with some padding)
    final usableHeight = availableHeight - 32; // 16px padding top+bottom
    final maxCm = (usableHeight / pixelsPerCm).floor();
    final rulerCm = maxCm.clamp(1, 30); // Cap at 30cm max

    return RotatedBox(
      quarterTurns: 3,
      child: Container(
        width: pixelsPerCm * rulerCm,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.textWhite,
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomPaint(
          painter: MetricRulerPainter(pixelsPerCm: pixelsPerCm, totalCm: rulerCm),
        ),
      ),
    );
  }
}

/// Vertical ruler showing inches — dynamically sized to fit screen
class ImperialRuler extends StatelessWidget {
  final double availableHeight;

  const ImperialRuler({super.key, required this.availableHeight});

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final pixelsPerInch = 160.0 / devicePixelRatio;

    // Calculate how many whole inches fit in the available height
    final usableHeight = availableHeight - 32;
    final maxInches = (usableHeight / pixelsPerInch).floor();
    final rulerInches = maxInches.clamp(1, 12); // Cap at 12 inches max

    return RotatedBox(
      quarterTurns: 3,
      child: Container(
        width: pixelsPerInch * rulerInches,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.textWhite,
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomPaint(
          painter: ImperialRulerPainter(pixelsPerInch: pixelsPerInch, totalInches: rulerInches),
        ),
      ),
    );
  }
}

/// Custom painter for metric ruler
class MetricRulerPainter extends CustomPainter {
  final double pixelsPerCm;
  final int totalCm;

  MetricRulerPainter({required this.pixelsPerCm, required this.totalCm});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textDark
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int cm = 0; cm <= totalCm; cm++) {
      final x = cm * pixelsPerCm;

      // Major tick (cm)
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, cm % 5 == 0 ? size.height * 0.45 : size.height * 0.3),
        paint..strokeWidth = cm % 5 == 0 ? 2 : 1,
      );

      // Label every 5 cm
      if (cm % 5 == 0) {
        textPainter.text = TextSpan(
          text: '$cm',
          style: AppTheme.caption(size: 12, color: AppTheme.textDark, weight: FontWeight.w600),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height * 0.50),
        );
      }

      // Minor ticks (mm)
      if (cm < totalCm) {
        for (int mm = 1; mm < 10; mm++) {
          final mmX = x + (mm * pixelsPerCm / 10);
          canvas.drawLine(
            Offset(mmX, 0),
            Offset(mmX, mm == 5 ? size.height * 0.22 : size.height * 0.12),
            Paint()
              ..color = AppTheme.textMedium
              ..strokeWidth = 0.5,
          );
        }
      }
    }

    // "CM" label at bottom-right
    textPainter.text = TextSpan(
      text: 'CM',
      style: AppTheme.title(size: 12, color: AppTheme.textDark),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 10, size.height * 0.70),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for imperial ruler
class ImperialRulerPainter extends CustomPainter {
  final double pixelsPerInch;
  final int totalInches;

  ImperialRulerPainter({required this.pixelsPerInch, required this.totalInches});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textDark
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int inch = 0; inch <= totalInches; inch++) {
      final x = inch * pixelsPerInch;

      // Major tick (inch)
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * 0.45),
        paint..strokeWidth = 2,
      );

      // Label every inch
      textPainter.text = TextSpan(
        text: '$inch',
        style: AppTheme.caption(size: 12, color: AppTheme.textDark, weight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height * 0.50),
      );

      // Minor ticks (1/8 inch)
      if (inch < totalInches) {
        for (int frac = 1; frac < 8; frac++) {
          final fracX = x + (frac * pixelsPerInch / 8);
          double tickHeight;

          if (frac == 4) {
            tickHeight = size.height * 0.32; // 1/2 inch
          } else if (frac % 2 == 0) {
            tickHeight = size.height * 0.22; // 1/4 inch
          } else {
            tickHeight = size.height * 0.12; // 1/8 inch
          }

          canvas.drawLine(
            Offset(fracX, 0),
            Offset(fracX, tickHeight),
            Paint()
              ..color = AppTheme.textMedium
              ..strokeWidth = 0.5,
          );
        }
      }
    }

    // "IN" label at bottom-right
    textPainter.text = TextSpan(
      text: 'IN',
      style: AppTheme.title(size: 12, color: AppTheme.textDark),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 10, size.height * 0.70),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
