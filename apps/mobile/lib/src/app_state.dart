import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ring_core/ring_core.dart';

final isDemoModeProvider = Provider<bool>((Ref ref) => false);
final dailySnapshotProvider = Provider<DailySnapshot?>((Ref ref) => null);

class PrivacySettings {
  const PrivacySettings({
    this.keepLocal = true,
    this.useAsContext = false,
    this.allowExport = false,
  });

  final bool keepLocal;
  final bool useAsContext;
  final bool allowExport;

  PrivacySettings copyWith({
    bool? keepLocal,
    bool? useAsContext,
    bool? allowExport,
  }) => PrivacySettings(
    keepLocal: keepLocal ?? this.keepLocal,
    useAsContext: useAsContext ?? this.useAsContext,
    allowExport: allowExport ?? this.allowExport,
  );
}

class PrivacyController extends Notifier<PrivacySettings> {
  @override
  PrivacySettings build() => const PrivacySettings();

  void setKeepLocal(bool value) => state = state.copyWith(
    keepLocal: value,
    useAsContext: value ? null : false,
    allowExport: value ? null : false,
  );

  void setUseAsContext(bool value) {
    if (state.keepLocal) state = state.copyWith(useAsContext: value);
  }

  void setAllowExport(bool value) {
    if (state.keepLocal) state = state.copyWith(allowExport: value);
  }
}

final privacySettingsProvider =
    NotifierProvider<PrivacyController, PrivacySettings>(PrivacyController.new);

class SwimEntryController extends Notifier<SwimEntry?> {
  @override
  SwimEntry? build() => null;

  void save({
    required int durationMinutes,
    required String poolLength,
    required String effort,
  }) {
    state = SwimEntry(
      durationMinutes: durationMinutes,
      poolLength: poolLength,
      effort: effort,
      origin: DataOrigin.manual,
    );
  }
}

final swimEntryProvider = NotifierProvider<SwimEntryController, SwimEntry?>(
  SwimEntryController.new,
);
