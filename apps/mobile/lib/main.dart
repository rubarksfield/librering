import 'package:flutter/widgets.dart';

import 'app.dart';
import 'src/ble/flutter_reactive_ble_transport.dart';
import 'src/ble/r12_pairing_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const demoMode = bool.fromEnvironment('LIBRERING_DEMO');
  final pairingClient = demoMode
      ? null
      : PhysicalR12PairingClient(FlutterReactiveBleTransport());
  runApp(LibreRingApp(demoMode: demoMode, pairingClient: pairingClient));
}
