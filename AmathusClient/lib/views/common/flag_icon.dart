import 'package:flutter/material.dart';

class FlagIcon extends StatelessWidget {
  final String languageCode;
  final double width;
  final double height;

  const FlagIcon({
    super.key,
    required this.languageCode,
    this.width = 20,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        size: Size(width, height),
        painter: _FlagPainter(languageCode),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final String languageCode;

  _FlagPainter(this.languageCode);

  @override
  void paint(Canvas canvas, Size size) {
    switch (languageCode) {
      case 'tr':
        _paintTurkishFlag(canvas, size);
        break;
      case 'el':
        _paintGreekFlag(canvas, size);
        break;
      case 'en':
        _paintBritishFlag(canvas, size);
        break;
    }
  }

  void _paintTurkishFlag(Canvas canvas, Size size) {
    final redPaint = Paint()..color = const Color(0xFFE30A17);
    final whitePaint = Paint()..color = Colors.white;

    canvas.drawRect(Offset.zero & size, redPaint);

    final h = size.height;
    final outerCenter = Offset(size.width * 0.38, h * 0.5);
    final outerRadius = h * 0.25;
    final innerCenter = Offset(size.width * 0.435, h * 0.5);
    final innerRadius = h * 0.20;

    canvas.drawCircle(outerCenter, outerRadius, whitePaint);
    canvas.drawCircle(innerCenter, innerRadius, redPaint);

    // Small white circle/diamond for the star
    final starCenter = Offset(size.width * 0.62, h * 0.5);
    canvas.drawCircle(starCenter, h * 0.085, whitePaint);
  }

  void _paintGreekFlag(Canvas canvas, Size size) {
    final bluePaint = Paint()..color = const Color(0xFF0D5EAF);
    final whitePaint = Paint()..color = Colors.white;

    canvas.drawRect(Offset.zero & size, whitePaint);

    final stripeH = size.height / 9.0;
    for (var i = 0; i < 9; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, size.width, stripeH),
        bluePaint,
      );
    }

    final cantonSize = stripeH * 5.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cantonSize, cantonSize),
      bluePaint,
    );

    // White cross inside canton
    canvas.drawRect(
      Rect.fromLTWH(cantonSize * 0.4, 0, cantonSize * 0.2, cantonSize),
      whitePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, cantonSize * 0.4, cantonSize, cantonSize * 0.2),
      whitePaint,
    );
  }

  void _paintBritishFlag(Canvas canvas, Size size) {
    final bluePaint = Paint()..color = const Color(0xFF012169);
    final whitePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.height * 0.22
      ..style = PaintingStyle.stroke;
    final redDiagPaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = size.height * 0.10
      ..style = PaintingStyle.stroke;
    final whiteCrossPaint = Paint()..color = Colors.white;
    final redCrossPaint = Paint()..color = const Color(0xFFC8102E);

    canvas.drawRect(Offset.zero & size, bluePaint);

    // Diagonals
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), whitePaint);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      whitePaint,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      redDiagPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      redDiagPaint,
    );

    // Central white cross
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.38, 0, size.width * 0.24, size.height),
      whiteCrossPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.34, size.width, size.height * 0.32),
      whiteCrossPaint,
    );

    // Central red cross
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.43, 0, size.width * 0.14, size.height),
      redCrossPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.40, size.width, size.height * 0.20),
      redCrossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) =>
      oldDelegate.languageCode != languageCode;
}
