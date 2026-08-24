import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ring_design_system/ring_design_system.dart';

void main() {
  test('frozen V1 tokens match the approved source', () {
    expect(LibreRingTokens.background, const Color(0xFFF4F1EA));
    expect(LibreRingTokens.surface, const Color(0xFFE4E2DE));
    expect(LibreRingTokens.accent, const Color(0xFFC9573E));
    expect(LibreRingTokens.minimumTarget, 48);
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
