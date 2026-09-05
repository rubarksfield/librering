import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ring_design_system/ring_design_system.dart';

void main() {
  test('refinement palette preserves warm neutrals and terracotta', () {
    expect(LibreRingTokens.background, const Color(0xFFF6F5F2));
    expect(LibreRingTokens.surface, const Color(0xFFFFFFFF));
    expect(LibreRingTokens.accent, const Color(0xFFBF553D));
    expect(LibreRingTokens.minimumTarget, 48);
  });

  test('secondary text remains legible on cards and sage panels', () {
    for (final surface in [
      LibreRingTokens.background,
      LibreRingTokens.surface,
      LibreRingTokens.sageSoft,
    ]) {
      expect(
        (surface.computeLuminance() + .05) /
            (LibreRingTokens.muted.computeLuminance() + .05),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('primary text contrast exceeds WCAG AA', () {
    final light = LibreRingTokens.background.computeLuminance();
    final dark = LibreRingTokens.foreground.computeLuminance();
    final ratio = (light + .05) / (dark + .05);
    expect(ratio, greaterThanOrEqualTo(4.5));
  });

  testWidgets('primary control preserves the 48 dp target minimum', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLibreRingTheme(),
        home: Scaffold(
          body: LibreRingPrimaryButton(label: 'Continue', onPressed: () {}),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
  });
}
