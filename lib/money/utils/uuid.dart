import 'dart:math';

/// Utility class for generating RFC 4122 compliant version 4 UUIDs.
class Uuid {
  static final Random _secureRandom = Random.secure();

  /// Generates a random RFC 4122 version 4 UUID string.
  /// Format: `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`
  static String v4() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));

    // Set version to 4 -> 0100 in bits 48-51 (byte 6)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    // Set variant to 10xx in bits 64-65 (byte 8)
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String byteToHex(int byte) => byte.toRadixString(16).padLeft(2, '0');

    return '${byteToHex(bytes[0])}${byteToHex(bytes[1])}${byteToHex(bytes[2])}${byteToHex(bytes[3])}-'
        '${byteToHex(bytes[4])}${byteToHex(bytes[5])}-'
        '${byteToHex(bytes[6])}${byteToHex(bytes[7])}-'
        '${byteToHex(bytes[8])}${byteToHex(bytes[9])}-'
        '${byteToHex(bytes[10])}${byteToHex(bytes[11])}${byteToHex(bytes[12])}${byteToHex(bytes[13])}${byteToHex(bytes[14])}${byteToHex(bytes[15])}';
  }

  /// Checks if a given string matches the standard UUID pattern.
  static bool isValid(String uuid) {
    final regex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return regex.hasMatch(uuid);
  }
}
