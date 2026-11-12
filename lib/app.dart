import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chola/app_info.dart';
import 'package:chola/localization/localization.dart';
import 'package:chola/practice/practice_config.dart';
import 'package:chola/practice/stats_store.dart';
import 'package:chola/settings/app_settings.dart';
import 'package:chola/theme/app_theme.dart';
import 'package:chola/ui/app_shell.dart';

class CholaApp extends StatelessWidget {
  const CholaApp({
    required this.settings,
    required this.config,
    required this.stats,
    super.key,
  });

  final AppSettings settings;
  final PracticeConfig config;
  final StatsStore stats;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (_) => AppInfo.name.tr,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(settings.accent),
          darkTheme: AppTheme.dark(settings.accent),
          themeMode: settings.themeMode,
          scrollBehavior: const _NoScrollbarBehavior(),
          locale: L10n.locale,
          supportedLocales: [
            for (final language in L10n.languages) Locale(language.code),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final phone = media.size.shortestSide < 600;
            final user = media.textScaler.scale(1).clamp(0.85, 1.15);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(user * (phone ? 0.86 : 1.0)),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: KeyedSubtree(
            key: ValueKey(L10n.code),
            child: AppShell(settings: settings, config: config, stats: stats),
          ),
        );
      },
    );
  }
}

class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
