
import 'package:flutter/material.dart';

class HighlightPainter extends CustomPainter {
  final Rect rect;
  HighlightPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(rect, paint);

    paint.style = PaintingStyle.fill;
    canvas.drawCircle(rect.topLeft, 4, paint);
    canvas.drawCircle(rect.topRight, 4, paint);
    canvas.drawCircle(rect.bottomLeft, 4, paint);
    canvas.drawCircle(rect.bottomRight, 4, paint);
  }

  @override
  bool shouldRepaint(covariant HighlightPainter oldDelegate) =>
      rect != oldDelegate.rect;
}
