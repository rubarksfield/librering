import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'src/ble/flutter_reactive_ble_transport.dart';
import 'src/ble/r12_pairing_client.dart';
import 'src/storage/ring_data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const demoMode = bool.fromEnvironment('LIBRERING_DEMO');
  const captureMode = bool.fromEnvironment('LIBRERING_CAPTURE');
  final captureFile = File(
    '${Directory.systemTemp.path}/librering-r12-capture.json',
  );
  if (await captureFile.exists()) await captureFile.delete();
  final pairingClient = demoMode
      ? null
      : PhysicalR12PairingClient(
          FlutterReactiveBleTransport(),
          captureSink: captureMode
              ? (capture) async {
                  await captureFile.writeAsString('$capture\n', flush: true);
                }
              : null,
        );
  final ringDataRepository = demoMode
      ? null
      : FileRingDataRepository(await getApplicationSupportDirectory());
  runApp(
    LibreRingApp(
      demoMode: demoMode,
      captureMode: captureMode,
      initialLocation: captureMode ? '/pairing/scan' : '/welcome',
      pairingClient: pairingClient,
      ringDataRepository: ringDataRepository,
    ),
  );
}
