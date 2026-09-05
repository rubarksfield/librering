import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/ui/sleep_palette.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

void main() {
  test('shared sleep palette preserves the Today sage colours', () {
    expect(sleepStageColor(RingSleepStage.deep), LibreRingTokens.sage);
    expect(sleepStageColor(RingSleepStage.light), const Color(0xFFA0B69C));
    expect(sleepStageColor(RingSleepStage.rem), const Color(0xFFCDD8C5));
    expect(sleepStageColor(RingSleepStage.awake), LibreRingTokens.accent);
  });

  test('sleep stages remain distinct, with deepest sleep darkest', () {
    final colours = RingSleepStage.values.map(sleepStageColor).toSet();
    expect(colours.length, RingSleepStage.values.length);
    expect(
      sleepStageColor(RingSleepStage.deep).computeLuminance(),
      lessThan(sleepStageColor(RingSleepStage.light).computeLuminance()),
    );
    expect(
      sleepStageColor(RingSleepStage.light).computeLuminance(),
      lessThan(sleepStageColor(RingSleepStage.rem).computeLuminance()),
    );
  });
}
