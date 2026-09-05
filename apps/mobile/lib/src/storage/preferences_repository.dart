import 'dart:convert';
import 'dart:io';

enum UnitSystem { metric, imperial }

class AppPreferences {
  const AppPreferences({
    this.displayName = '',
    this.unitSystem = UnitSystem.metric,
    this.dailyStepGoal = 5000,
    this.sleepTargetMinutes = 480,
  });

  final String displayName;
  final UnitSystem unitSystem;
  final int dailyStepGoal;
  final int sleepTargetMinutes;

  AppPreferences copyWith({
    String? displayName,
    UnitSystem? unitSystem,
    int? dailyStepGoal,
    int? sleepTargetMinutes,
  }) => AppPreferences(
    displayName: displayName ?? this.displayName,
    unitSystem: unitSystem ?? this.unitSystem,
    dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
    sleepTargetMinutes: sleepTargetMinutes ?? this.sleepTargetMinutes,
  );

  String formatDistance(num meters) => unitSystem == UnitSystem.imperial
      ? '${(meters / 1609.344).toStringAsFixed(2)} mi'
      : '${(meters / 1000).toStringAsFixed(2)} km';

  void validate() {
    if (displayName.trim().length > 40 ||
        dailyStepGoal < 500 ||
        dailyStepGoal > 50000 ||
        sleepTargetMinutes < 240 ||
        sleepTargetMinutes > 720) {
      throw const FormatException('Preferences are outside supported limits.');
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'displayName': displayName.trim(),
    'unitSystem': unitSystem.name,
    'dailyStepGoal': dailyStepGoal,
    'sleepTargetMinutes': sleepTargetMinutes,
  };

  factory AppPreferences.fromJson(Map<String, Object?> json) {
    final name = json['displayName'];
    final units = json['unitSystem'];
    final steps = json['dailyStepGoal'];
    final sleep = json['sleepTargetMinutes'];
    if (name is! String || units is! String || steps is! int || sleep is! int) {
      throw const FormatException('Invalid preferences.');
    }
    final result = AppPreferences(
      displayName: name.trim(),
      unitSystem: UnitSystem.values.firstWhere(
        (value) => value.name == units,
        orElse: () => throw const FormatException('Unknown unit system.'),
      ),
      dailyStepGoal: steps,
      sleepTargetMinutes: sleep,
    );
    result.validate();
    return result;
  }
}

abstract interface class PreferencesRepository {
  Future<AppPreferences> read();
  Future<void> save(AppPreferences preferences);
}

class FilePreferencesRepository implements PreferencesRepository {
  FilePreferencesRepository(Directory applicationSupportDirectory)
    : _file = File(
        '${applicationSupportDirectory.path}/librering/preferences-v1.json',
      );

  final File _file;

  @override
  Future<AppPreferences> read() async {
    if (!await _file.exists()) return const AppPreferences();
    final root = jsonDecode(await _file.readAsString());
    if (root is! Map<String, Object?> || root['schemaVersion'] != 1) {
      throw const FormatException('Stored preferences could not be read.');
    }
    return AppPreferences.fromJson(root);
  }

  @override
  Future<void> save(AppPreferences preferences) async {
    preferences.validate();
    await _file.parent.create(recursive: true);
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        ...preferences.toJson(),
      }),
      flush: true,
    );
    await temporary.rename(_file.path);
  }
}
