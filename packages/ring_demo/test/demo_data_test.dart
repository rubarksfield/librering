import 'package:ring_core/ring_core.dart';
import 'package:ring_demo/ring_demo.dart';
import 'package:test/test.dart';

void main() {
  test('every bundled metric is explicitly demo-origin data', () {
    expect(demoDailySnapshot.origin, DataOrigin.demo);
    expect(
      demoDailySnapshot.metrics.every(
        (metric) => metric.origin == DataOrigin.demo,
      ),
      isTrue,
    );
  });
}
