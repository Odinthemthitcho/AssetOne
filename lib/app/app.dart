import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import 'di/app_dependencies.dart';
import 'shell/asset_one_root.dart';

class AssetOneApp extends StatelessWidget {
  const AssetOneApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AssetOne',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: AssetOneRoot(dependencies: dependencies),
  );
}
