import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

enum LibreRingArtworkKind { ring, privacy, scan, unsupported }

class LibreRingArtwork extends StatelessWidget {
  const LibreRingArtwork({
    required this.kind,
    this.size = 260,
    this.semanticLabel,
    super.key,
  });

  final LibreRingArtworkKind kind;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final art = CustomPaint(
      size: Size.square(size),
      painter: _ArtworkPainter(kind),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: art)
        : Semantics(label: semanticLabel, image: true, child: art);
  }
}

class _ArtworkPainter extends CustomPainter {
  _ArtworkPainter(this.kind);

  final LibreRingArtworkKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case LibreRingArtworkKind.ring:
        _ring(canvas, size);
        return;
      case LibreRingArtworkKind.privacy:
        _privacy(canvas, size);
        return;
      case LibreRingArtworkKind.scan:
        _scan(canvas, size);
        return;
      case LibreRingArtworkKind.unsupported:
        _unsupported(canvas, size);
        return;
    }
  }

  void _ring(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-18 * math.pi / 180);
    final oval = Rect.fromCenter(
      center: Offset.zero,
      width: size.width * .48,
      height: size.height * .68,
    );
    canvas.drawOval(
      oval,
      Paint()
        ..color = const Color(0xFFB6B3AD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .18,
    );
    canvas.drawOval(
      oval,
      Paint()
        ..color = const Color(0xFFE5E2DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .15,
    );
    canvas.drawOval(
      oval.deflate(size.width * .075),
      Paint()
        ..color = const Color(0xFFBDB9B2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(
      Offset(0, size.height * .32),
      size.width * .018,
      Paint()..color = LibreRingTokens.accent,
    );
    canvas.restore();
  }

  void _privacy(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      size.width * .47,
      Paint()
        ..color = LibreRingTokens.border
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center,
      size.width * .25,
      Paint()
        ..color = LibreRingTokens.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .11,
    );
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(0, 18), width: 68, height: 76),
      const Radius.circular(18),
    );
    canvas.drawRRect(body, Paint()..color = LibreRingTokens.background);
    canvas.drawRRect(
      body,
      Paint()
        ..color = LibreRingTokens.foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final shackle = Rect.fromCenter(
      center: center.translate(0, -30),
      width: 34,
      height: 44,
    );
    canvas.drawArc(
      shackle,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = LibreRingTokens.foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _scan(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (final scale in <double>[.98, .72, .46]) {
      canvas.drawCircle(
        center,
        size.width * scale / 2,
        Paint()
          ..color = LibreRingTokens.border
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-22 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 62, height: 84),
      Paint()
        ..color = LibreRingTokens.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16,
    );
    canvas.restore();
  }

  void _unsupported(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      size.width * .46,
      Paint()
        ..color = LibreRingTokens.border
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center,
      size.width * .25,
      Paint()
        ..color = LibreRingTokens.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .09,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-38 * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * .62,
          height: 5,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = LibreRingTokens.accent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtworkPainter oldDelegate) => oldDelegate.kind != kind;
}
