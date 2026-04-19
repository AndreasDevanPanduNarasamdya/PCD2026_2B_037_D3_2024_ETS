import 'package:flutter/material.dart';
import 'vision_controller.dart';

/// DamagePainter implements custom painting for road damage detection
///
/// This follows Single Responsibility Principle:
/// - Only handles drawing logic
/// - Receives detection results from VisionController
/// - Doesn't manage camera or state
class DamagePainter extends CustomPainter {
  final List<DetectionResult> detections;

  DamagePainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final labelBgPaint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    const labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    for (final detection in detections) {
      // Coordinates are normalized (0.0 - 1.0), scale to canvas size
      final rect = Rect.fromLTWH(
        detection.box.left * size.width,
        detection.box.top * size.height,
        detection.box.width * size.width,
        detection.box.height * size.height,
      );

      // Draw bounding box
      canvas.drawRect(rect, boxPaint);

      // Draw label background
      final labelText =
          '${detection.label} ${(detection.score * 100).toStringAsFixed(0)}%';
      final textSpan = TextSpan(text: labelText, style: labelStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRect(labelRect, labelBgPaint);

      // Draw label text
      textPainter.paint(
        canvas,
        Offset(rect.left + 4, rect.top - textPainter.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(DamagePainter oldDelegate) =>
      oldDelegate.detections != detections;
}
