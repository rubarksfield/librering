import 'package:flutter/material.dart';
import 'package:ring_core/ring_core.dart';
import 'package:ring_design_system/ring_design_system.dart';

/// Shared by the Today ribbon, sleep timeline and stage breakdown.
/// Deeper sleep uses deeper sage; awake keeps the brand's warm contrast.
Color sleepStageColor(RingSleepStage stage) => switch (stage) {
  RingSleepStage.deep => LibreRingTokens.sage,
  RingSleepStage.light => const Color(0xFFA0B69C),
  RingSleepStage.rem => const Color(0xFFCDD8C5),
  RingSleepStage.awake => LibreRingTokens.accent,
};
