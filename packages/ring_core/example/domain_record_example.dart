import 'package:ring_core/ring_core.dart';

void main() {
  const entry = SwimEntry(
    durationMinutes: 42,
    poolLength: '25 metres',
    effort: 'steady',
    origin: DataOrigin.manual,
  );
  print('Manual swim: ${entry.durationMinutes} minutes');
}
