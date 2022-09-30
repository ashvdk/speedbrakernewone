import 'package:flutter/material.dart';
import 'dart:ui';

class CirclePainte extends CustomPainter {
  final int precision;
  final double x,y;
  CirclePainte({required this.precision, required this.x, required this.y});

  final _paint = Paint()
    ..color = Colors.red
    ..strokeWidth =  5
  // Use [PaintingStyle.fill] if you want the circle to be filled.
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(center:  this.precision == 9 ? Offset(this.x, this.y) : Offset(this.x, this.y),
          width: this.precision == 9 ? 68 : 20, height: this.precision == 9 ? 68 : 20),
      _paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}