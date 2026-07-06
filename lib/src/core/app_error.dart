class OceanMatchException implements Exception {
  const OceanMatchException(this.message);

  final String message;

  @override
  String toString() => message;
}

String userFacingError(Object error) {
  if (error is OceanMatchException) {
    return error.message;
  }
  final message = error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Exception: ', '')
      .trim();
  if (message.isEmpty) {
    return 'Une erreur est survenue. Reessayez dans un instant.';
  }
  return message;
}
