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
            child: const Text(
              'LibreRing',
              maxLines: 1,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: LibreRingTokens.foreground,
            foregroundColor: LibreRingTokens.onForeground,
            disabledBackgroundColor: LibreRingTokens.border,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                LibreRingTokens.controlRadius,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class LibreRingCard extends StatelessWidget {
  const LibreRingCard({
    required this.child,
    this.padding,
    this.backgroundColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? LibreRingTokens.surface,
        borderRadius: BorderRadius.circular(LibreRingTokens.cardRadius),
        border: Border.all(
          color: LibreRingTokens.border.withValues(alpha: .75),
        ),
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
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
    ),
  );
}
