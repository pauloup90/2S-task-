// ignore_for_file: avoid_print
import 'dart:io';

import 'package:two_s_task/core/odoo/odoo_client.dart';
import 'package:two_s_task/core/odoo/odoo_seed.dart';
import 'package:two_s_task/core/odoo/odoo_smoke_test.dart';

import 'env.dart';

Future<void> main(List<String> args) async {
  final env = loadEnv();
  final portal = args.contains('--portal');
  final client = OdooClient(baseUrl: requireEnv(env, 'ODOO_URL'), database: requireEnv(env, 'ODOO_DB'));

  final demo = args.contains('--demo');
  final (login, password) = portal
      ? (OdooSeed.portalUserLogin, requireEnv(env, 'SEED_PORTAL_PASSWORD'))
      : demo
      ? (OdooSeed.demoUserLogin, requireEnv(env, 'SEED_DEMO_PASSWORD'))
      : (requireEnv(env, 'ODOO_LOGIN'), requireEnv(env, 'ODOO_PASSWORD'));
  final checks = await OdooSmokeTest(client).run(login: login, password: password);
  checks.forEach(print);
  exit(checks.every((c) => c.passed) ? 0 : 1);
}
