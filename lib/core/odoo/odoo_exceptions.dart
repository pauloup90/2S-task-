sealed class OdooException implements Exception {
  final String message;
  const OdooException(this.message);

  @override
  String toString() => message;
}

class OdooNetworkException extends OdooException {
  const OdooNetworkException([super.message = 'No connection to the Odoo server.']);
}

class OdooAuthException extends OdooException {
  const OdooAuthException(super.message);
}

class OdooSessionExpiredException extends OdooException {
  const OdooSessionExpiredException([super.message = 'Your session has expired. Please log in again.']);
}

class OdooAccessException extends OdooException {
  const OdooAccessException(super.message);
}

class OdooValidationException extends OdooException {
  const OdooValidationException(super.message);
}

class OdooServerException extends OdooException {
  const OdooServerException(super.message);
}
