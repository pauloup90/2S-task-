class AppConfig {
  AppConfig._();

  static const defaultServerUrl = String.fromEnvironment('ODOO_URL', defaultValue: 'https://2stask.odoo.com');
  static const defaultDatabase = String.fromEnvironment('ODOO_DB', defaultValue: '2stask');
}
