import 'package:flutter/widgets.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const demoMode = bool.fromEnvironment('LIBRERING_DEMO');
  runApp(const LibreRingApp(demoMode: demoMode));
}
