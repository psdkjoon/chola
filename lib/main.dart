import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chola/app.dart';
import 'package:chola/core/diagnostics.dart';
import 'package:chola/core/kv_store.dart';
import 'package:chola/platform/launcher_icon_service.dart';
import 'package:chola/platform/theme_sync_service.dart';
import 'package:chola/practice/practice_config.dart';
import 'package:chola/practice/stats_store.dart';
import 'package:chola/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Diagnostics.init();

  final store = await KvStore.open();
  final settings = AppSettings.load(store);

  await ThemeSyncService.adoptStored(settings);

  runApp(
    CholaApp(
      settings: settings,
      config: PracticeConfig.load(store),
      stats: StatsStore.load(store),
    ),
  );

  unawaited(_initPlatform(settings));
}

Future<void> _initPlatform(AppSettings settings) async {
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } on Object {
    debugPrint('edge-to-edge unavailable');
  }

  LauncherIconService.init(settings);
  await ThemeSyncService.init(settings);
}
