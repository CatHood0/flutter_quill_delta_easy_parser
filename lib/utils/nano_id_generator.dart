import 'dart:math';

const String _hexDigits = '0123456789ABCDEF';

String nanoid(int length) {
  if (length <= 0 || length > 35) {
    throw Exception(
        "The length provided: $length, cannot be used to generate an id");
  }
  final Random random = Random.secure();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < length; i++) {
    buffer.write(_hexDigits[random.nextInt(_hexDigits.length)]);
  }

  return buffer.toString();
}
