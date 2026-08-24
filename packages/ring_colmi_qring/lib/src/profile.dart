import 'package:ring_ble/ring_ble.dart';
import 'package:ring_core/ring_core.dart';

abstract final class ColmiQringProfile {
  static const commandService = '6e40fff0-b5a3-f393-e0a9-e50e24dcca9e';
  static const commandWrite = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const commandNotify = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
  static const bigDataService = 'de5bf728-d711-4e47-af26-65e3012a5dc7';
  static const bigDataNotify = 'de5bf729-d711-4e47-af26-65e3012a5dc7';
  static const bigDataWrite = 'de5bf72a-d711-4e47-af26-65e3012a5dc7';

  static final _r12Name = RegExp(r'^COLMI R12_.*$', caseSensitive: false);

  static bool isR12Advertisement(RingAdvertisement advertisement) =>
      _r12Name.hasMatch(advertisement.name.trim());

  static bool isInclusiveCandidate(RingAdvertisement advertisement) =>
      isR12Advertisement(advertisement) ||
      advertisement.serviceUuids
          .map((uuid) => uuid.toLowerCase())
          .contains(commandService);

  static ServiceValidation validateServices(Iterable<BleService> services) {
    BleService? command;
    BleService? bigData;
    for (final service in services) {
      switch (service.uuid.toLowerCase()) {
        case commandService:
          command = service;
          break;
        case bigDataService:
          bigData = service;
          break;
      }
    }
    final write = command?.characteristic(commandWrite);
    final notify = command?.characteristic(commandNotify);
    if (command == null ||
        write?.canWrite != true ||
        notify?.canNotify != true) {
      return const ServiceValidation.unsupported(
        'Expected QRing command service/characteristics were not present.',
      );
    }
    final bigWrite = bigData?.characteristic(bigDataWrite);
    final bigNotify = bigData?.characteristic(bigDataNotify);
    final supportsBigData =
        bigData != null &&
        bigWrite?.canWrite == true &&
        bigNotify?.canNotify == true;
    return ServiceValidation.supported(supportsBigData: supportsBigData);
  }
}

class ServiceValidation {
  const ServiceValidation.supported({required this.supportsBigData})
    : isSupported = true,
      reason = null;

  const ServiceValidation.unsupported(this.reason)
    : isSupported = false,
      supportsBigData = false;

  final bool isSupported;
  final bool supportsBigData;
  final String? reason;
}
