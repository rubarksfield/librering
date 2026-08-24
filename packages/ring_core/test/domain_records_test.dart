import 'package:ring_core/ring_core.dart';
import 'package:test/test.dart';

void main() {
  test('manual records retain their provenance', () {
    const entry = SwimEntry(
      durationMinutes: 42,
      poolLength: '25 metres',
      effort: 'steady',
      origin: DataOrigin.manual,
    );

    expect(entry.origin, DataOrigin.manual);
    expect(entry.durationMinutes, 42);
  });
}
