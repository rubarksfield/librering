import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:librering_mobile/src/storage/preferences_repository.dart';

void main() {
  late Directory temporary;
  late FilePreferencesRepository repository;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp(
      'librering-preferences-test-',
    );
    repository = FilePreferencesRepository(temporary);
  });
  tearDown(() => temporary.delete(recursive: true));

  test('preferences survive reopening and apply distance units', () async {
    final defaults = await repository.read();
    expect(defaults.dailyStepGoal, 5000);
    expect(defaults.sleepTargetMinutes, 480);
    await repository.save(
      const AppPreferences(
        displayName: '  Alex  ',
        unitSystem: UnitSystem.imperial,
        dailyStepGoal: 8000,
        sleepTargetMinutes: 450,
      ),
    );
    final reopened = await FilePreferencesRepository(temporary).read();
    expect(reopened.displayName, 'Alex');
    expect(reopened.dailyStepGoal, 8000);
    expect(reopened.sleepTargetMinutes, 450);
    expect(reopened.formatDistance(1609.344), '1.00 mi');
    expect(defaults.formatDistance(1609.344), '1.61 km');
  });

  test(
    'invalid targets cannot overwrite previously saved preferences',
    () async {
      await repository.save(const AppPreferences(displayName: 'Alex'));
      await expectLater(
        repository.save(const AppPreferences(dailyStepGoal: -1)),
        throwsFormatException,
      );
      expect((await repository.read()).displayName, 'Alex');
    },
  );

  test('corrupt preferences are reported and preserved', () async {
    final file = File('${temporary.path}/librering/preferences-v1.json');
    await file.parent.create(recursive: true);
    await file.writeAsString('{broken');
    await expectLater(repository.read(), throwsFormatException);
    expect(await file.readAsString(), '{broken');
  });
}
