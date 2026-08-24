class BigDataAssemblyException implements Exception {
  const BigDataAssemblyException(this.message);

  final String message;

  @override
  String toString() => 'BigDataAssemblyException: $message';
}

class BigDataFragment {
  const BigDataFragment({
    required this.sequence,
    required this.payload,
    required this.isLast,
  });

  final int sequence;
  final List<int> payload;
  final bool isLast;
}

class BigDataAssembler {
  factory BigDataAssembler({int maximumBytes = 64 * 1024}) {
    if (maximumBytes < 1) {
      throw ArgumentError.value(maximumBytes, 'maximumBytes');
    }
    return BigDataAssembler._(maximumBytes);
  }

  BigDataAssembler._(this.maximumBytes);

  final int maximumBytes;
  final List<int> _bytes = <int>[];
  final Map<int, BigDataFragment> _accepted = <int, BigDataFragment>{};
  int _nextSequence = 0;
  bool _complete = false;

  bool get isComplete => _complete;
  List<int> get bytes => List<int>.unmodifiable(_bytes);

  void add(BigDataFragment fragment) {
    if (fragment.sequence < 0) {
      throw const BigDataAssemblyException('Sequence cannot be negative.');
    }
    for (final value in fragment.payload) {
      if (value < 0 || value > 255) {
        throw const BigDataAssemblyException(
          'Payload contains a non-byte value.',
        );
      }
    }
    if (fragment.sequence < _nextSequence) {
      final accepted = _accepted[fragment.sequence];
      if (accepted != null &&
          accepted.isLast == fragment.isLast &&
          _sameBytes(accepted.payload, fragment.payload)) {
        return;
      }
      throw BigDataAssemblyException(
        'Conflicting duplicate for sequence ${fragment.sequence}.',
      );
    }
    if (_complete) {
      throw const BigDataAssemblyException('Stream is already complete.');
    }
    if (fragment.sequence != _nextSequence) {
      throw BigDataAssemblyException(
        'Expected sequence $_nextSequence, received ${fragment.sequence}.',
      );
    }
    if (_bytes.length + fragment.payload.length > maximumBytes) {
      throw const BigDataAssemblyException('Stream exceeded its bounded size.');
    }
    _bytes.addAll(fragment.payload);
    _accepted[fragment.sequence] = BigDataFragment(
      sequence: fragment.sequence,
      payload: List<int>.unmodifiable(fragment.payload),
      isLast: fragment.isLast,
    );
    _nextSequence++;
    _complete = fragment.isLast;
  }

  static bool _sameBytes(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
