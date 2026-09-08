import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../localized_copy.dart';
import 'haptics.dart';

/// Refresh only the phone's saved history. Bluetooth remains an explicit Sync
/// action. The controller serializes this read with pending saves/deletions.
Future<void> refreshSavedRingReadings(
  BuildContext context,
  WidgetRef ref,
) async {
  if (ref.read(isDemoModeProvider)) return;
  try {
    await ref.read(ringDataProvider.notifier).refresh();
    if (!context.mounted) return;
    RingHaptics.success();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            copyFor(
              context,
              'Saved readings refreshed. Use Sync to get new data from your ring.',
              'Leituras guardadas atualizadas. Use Sincronizar para obter novos dados do anel.',
            ),
          ),
        ),
      );
  } catch (_) {
    if (!context.mounted) return;
    RingHaptics.error();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            copyFor(
              context,
              'Could not refresh saved readings. Your data has not been changed. Please try again.',
              'Não foi possível atualizar as leituras guardadas. Os seus dados não foram alterados. Tente novamente.',
            ),
          ),
        ),
      );
  }
}
