import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/di/app_dependencies.dart';
import 'core/config/app_config.dart';

void bootstrap({AppConfig? config}) {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies(config ?? AppConfig.fromEnvironment());
  runApp(AssetOneApp(dependencies: dependencies));
}
