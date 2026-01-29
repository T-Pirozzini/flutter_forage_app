import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service to create map markers from emojis
class EmojiMarkerService {
  EmojiMarkerService._();

  // Cache for emoji markers
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Get or create a BitmapDescriptor for an emoji
  static Future<BitmapDescriptor> getEmojiMarker(String emoji) async {
    if (_cache.containsKey(emoji)) {
      return _cache[emoji]!;
    }

    final icon = await _createEmojiMarker(emoji);
    _cache[emoji] = icon;
    return icon;
  }

  /// Create a BitmapDescriptor from an emoji using Canvas
  static Future<BitmapDescriptor> _createEmojiMarker(String emoji) async {
    const double size = 56; // Smaller size for better zoom-out visibility
    const double padding = 4;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Draw white circular background with shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 1),
      size / 2 - padding,
      shadowPaint,
    );

    // Draw white background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - padding,
      bgPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - padding,
      borderPaint,
    );

    // Draw emoji text
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 28), // Smaller font for smaller marker
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Center the emoji
    final offsetX = (size - textPainter.width) / 2;
    final offsetY = (size - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(offsetX, offsetY));

    // Convert to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes == null) {
      // Fallback to default marker
      return BitmapDescriptor.defaultMarker;
    }

    return BitmapDescriptor.bytes(bytes.buffer.asUint8List());
  }

  /// Clear the emoji marker cache
  static void clearCache() {
    _cache.clear();
  }

  /// Check if an emoji is cached
  static bool isCached(String emoji) => _cache.containsKey(emoji);
}
