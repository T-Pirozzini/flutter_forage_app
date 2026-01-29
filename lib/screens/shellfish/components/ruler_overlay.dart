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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shellfish Ruler',
                    style: AppTheme.heading(size: 20, color: AppTheme.textWhite),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.2),
                borderRadius: AppTheme.borderRadiusSmall,
                border: Border.all(color: AppTheme.accent, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.accent, size: 20),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        'How to use:',
                        style: AppTheme.title(
                            size: 14,
                            weight: FontWeight.bold,
                            color: AppTheme.textWhite),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    '• Place your shellfish next to the ruler\n'
                    '• Align the shell edge with the 0 mark\n'
                    '• Read measurement at the opposite edge',
                    style:
                        AppTheme.caption(size: 12, color: AppTheme.textWhite),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space24),

            // Unit toggle
            SegmentedButton<bool>(
              selected: {_showMetric},
              onSelectionChanged: (Set<bool> selection) {
                setState(() => _showMetric = selection.first);
              },
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text('Centimeters'),
                  icon: Icon(Icons.straighten),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Inches'),
                  icon: Icon(Icons.straighten),
                ),
              ],
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.secondary;
                  }
                  return AppTheme.backgroundDark;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.textWhite;
                  }
                  return AppTheme.textMedium;
                }),
              ),
            ),

            const SizedBox(height: AppTheme.space32),

            // Ruler
            Expanded(
              child: Center(
                child: _showMetric
                    ? const MetricRuler()
                    : const ImperialRuler(),
              ),
            ),

            // Calibration note
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Text(
                'Note: Ruler is calibrated for standard screen DPI.\n'
                'For precise measurements, use an official measuring tool.',
                textAlign: TextAlign.center,
                style: AppTheme.caption(
                    size: 11, color: AppTheme.textWhite.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical ruler showing centimeters
class MetricRuler extends StatelessWidget {
  const MetricRuler({super.key});

  @override
  Widget build(BuildContext context) {
    // Get physical pixel ratio to approximate real size
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Standard Android/iOS DPI is ~160 (mdpi), which is ~63 pixels per cm
    // Adjust based on device pixel ratio
    final pixelsPerCm = 63.0 / devicePixelRatio;

    return RotatedBox(
      quarterTurns: 3,
      child: Container(
        width: pixelsPerCm * 25, // 25cm ruler
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.textWhite,
          borderRadius: BorderRadius.circular(4),
          // boxShadow: AppTheme.shadowLarge,
        ),
        child: CustomPaint(
          painter: MetricRulerPainter(pixelsPerCm: pixelsPerCm),
        ),
      ),
    );
  }
}

/// Vertical ruler showing inches
class ImperialRuler extends StatelessWidget {
  const ImperialRuler({super.key});

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // ~160 DPI = ~160 pixels per inch at 1x scale
    final pixelsPerInch = 160.0 / devicePixelRatio;

    return RotatedBox(
      quarterTurns: 3,
      child: Container(
        width: pixelsPerInch * 10, // 10 inch ruler
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.textWhite,
          borderRadius: BorderRadius.circular(4),
          // boxShadow: AppTheme.shadowLarge,
        ),
        child: CustomPaint(
          painter: ImperialRulerPainter(pixelsPerInch: pixelsPerInch),
        ),
      ),
    );
  }
}

/// Custom painter for metric ruler
class MetricRulerPainter extends CustomPainter {
  final double pixelsPerCm;

  MetricRulerPainter({required this.pixelsPerCm});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textDark
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw 25 cm
    for (int cm = 0; cm <= 25; cm++) {
      final x = cm * pixelsPerCm;

      // Major tick (cm)
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, cm % 5 == 0 ? size.height * 0.5 : size.height * 0.35),
        paint..strokeWidth = cm % 5 == 0 ? 2 : 1,
      );

      // Label every 5 cm
      if (cm % 5 == 0) {
        textPainter.text = TextSpan(
          text: '$cm',
          style: AppTheme.caption(size: 10, color: AppTheme.textDark),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height * 0.55),
        );
      }

      // Minor ticks (mm)
      if (cm < 25) {
        for (int mm = 1; mm < 10; mm++) {
          final mmX = x + (mm * pixelsPerCm / 10);
          canvas.drawLine(
            Offset(mmX, 0),
            Offset(mmX, mm == 5 ? size.height * 0.25 : size.height * 0.15),
            Paint()
              ..color = AppTheme.textMedium
              ..strokeWidth = 0.5,
          );
        }
      }
    }

    // Label
    textPainter.text = TextSpan(
      text: 'CM',
      style: AppTheme.title(size: 11, color: AppTheme.textDark),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 10, size.height * 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for imperial ruler
class ImperialRulerPainter extends CustomPainter {
  final double pixelsPerInch;

  ImperialRulerPainter({required this.pixelsPerInch});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textDark
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Draw 10 inches
    for (int inch = 0; inch <= 10; inch++) {
      final x = inch * pixelsPerInch;

      // Major tick (inch)
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * 0.5),
        paint..strokeWidth = 2,
      );

      // Label
      textPainter.text = TextSpan(
        text: '$inch',
        style: AppTheme.caption(size: 10, color: AppTheme.textDark),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height * 0.55),
      );

      // Minor ticks (1/8 inch)
      if (inch < 10) {
        for (int frac = 1; frac < 8; frac++) {
          final fracX = x + (frac * pixelsPerInch / 8);
          double tickHeight;

          if (frac == 4) {
            tickHeight = size.height * 0.35; // 1/2 inch
          } else if (frac % 2 == 0) {
            tickHeight = size.height * 0.25; // 1/4 inch
          } else {
            tickHeight = size.height * 0.15; // 1/8 inch
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

    // Label
    textPainter.text = TextSpan(
      text: 'IN',
      style: AppTheme.title(size: 11, color: AppTheme.textDark),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 10, size.height * 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
