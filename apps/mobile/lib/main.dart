import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'src/ble/flutter_reactive_ble_transport.dart';
import 'src/ble/r12_pairing_client.dart';
import 'src/storage/data_export_service.dart';
import 'src/storage/journal_repository.dart';
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
  final supportDirectory = demoMode
      ? null
      : await getApplicationSupportDirectory();
  final ringDataRepository = supportDirectory == null
      ? null
      : FileRingDataRepository(supportDirectory);
  final journalRepository = supportDirectory == null
      ? null
      : FileJournalRepository(supportDirectory);
  final dataExportService = demoMode
      ? null
      : FileDataExportService(await getApplicationDocumentsDirectory());
  final initialLocation = await resolveInitialLocation(
    demoMode: demoMode,
    captureMode: captureMode,
    ringDataRepository: ringDataRepository,
  );
  runApp(
    LibreRingApp(
      demoMode: demoMode,
      captureMode: captureMode,
      initialLocation: initialLocation,
      pairingClient: pairingClient,
      ringDataRepository: ringDataRepository,
      journalRepository: journalRepository,
      dataExportService: dataExportService,
    ),
  );
}
