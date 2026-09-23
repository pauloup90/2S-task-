import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/network/connectivity_service.dart';
import 'core/odoo/odoo_client.dart';
import 'core/odoo/odoo_service.dart';
import 'data/local/local_cache.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/order_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cache = await LocalCache.open();
  final supportDir = await getApplicationSupportDirectory();
  final cookieJar = PersistCookieJar(storage: FileStorage('${supportDir.path}/.cookies/'));

  final saved = cache.session;
  final client = OdooClient(
    baseUrl: saved?.baseUrl ?? AppConfig.defaultServerUrl,
    database: saved?.database ?? AppConfig.defaultDatabase,
    cookieJar: cookieJar,
  );
  final service = OdooService(client);

  runApp(
    App(
      client: client,
      authRepository: AuthRepository(service, cache),
      customerRepository: CustomerRepository(service, cache),
      orderRepository: OrderRepository(service, cache),
      connectivity: ConnectivityService(),
    ),
  );
}
