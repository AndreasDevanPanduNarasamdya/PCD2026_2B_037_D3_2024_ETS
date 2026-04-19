import 'package:flutter/material.dart';
import 'vision_controller.dart';

/// DamagePainter draws bounding boxes and labels for detection results.
/// Uses normalized coordinates (0.0–1.0) scaled to canvas size.
class DamagePainter extends CustomPainter {
  final List<DetectionResult> detections;

  DamagePainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final bgPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.75)
      ..style = PaintingStyle.fill;

    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    for (final detection in detections) {
      // Scale normalized coords to canvas
      final rect = Rect.fromLTRB(
        detection.box.left * size.width,
        detection.box.top * size.height,
        detection.box.right * size.width,
        detection.box.bottom * size.height,
      );

      // Draw bounding box
      canvas.drawRect(rect, boxPaint);

      // Label text
      final label =
          '${detection.label} ${(detection.score * 100).toStringAsFixed(0)}%';
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);

      // Label background
      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
        bgPaint,
      );

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
