import 'dart:io';

Map<String, String> loadEnv([String path = '.env']) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path. Copy .env.example to .env and fill it in.');
    exit(64);
  }
  final env = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq <= 0) continue;
    env[trimmed.substring(0, eq).trim()] = trimmed.substring(eq + 1);
  }
  return env;
}

String requireEnv(Map<String, String> env, String key) {
  final value = env[key];
  if (value == null || value.isEmpty) {
    stderr.writeln('$key is not set in .env');
    exit(64);
  }
  return value;
}
