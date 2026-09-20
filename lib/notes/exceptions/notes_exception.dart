/// Exception thrown during validation or operations in Notes V3.
class NotesException implements Exception {
  final String message;

  const NotesException(this.message);

  @override
  String toString() => 'NotesException: $message';
}
