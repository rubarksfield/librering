import 'package:flutter/material.dart';

import 'tokens.dart';

class LibreRingWordmark extends StatelessWidget {
  const LibreRingWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'LibreRing',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CustomPaint(size: const Size(20, 20), painter: _MarkPainter()),
                const SizedBox(width: 8),
                const Text(
                  'LibreRing',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LibreRingPrimaryButton extends StatelessWidget {
  const LibreRingPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: LibreRingTokens.foreground,
          foregroundColor: LibreRingTokens.onForeground,
          disabledBackgroundColor: LibreRingTokens.border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LibreRingTokens.controlRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20),
          ],
        ),
      ),
    );
  }
}

class LibreRingCard extends StatelessWidget {
  const LibreRingCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LibreRingTokens.surface,
        borderRadius: BorderRadius.circular(LibreRingTokens.cardRadius),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class LibreRingEyebrow extends StatelessWidget {
  const LibreRingEyebrow(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
    ),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LibreRingTokens.foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(size.center(Offset.zero), 8, paint);
    canvas.drawLine(
      Offset(size.width * .7, size.height * .62),
      Offset(size.width, size.height * .48),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
