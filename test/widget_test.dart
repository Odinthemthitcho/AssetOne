
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assetone/app/app.dart';
import 'package:assetone/app/di/app_dependencies.dart';
import 'package:assetone/app/shell/asset_one_root.dart';
import 'package:assetone/core/config/app_config.dart';
import 'package:assetone/core/storage/local_storage.dart';

void main() {
  testWidgets('AssetOne app boots successfully', (tester) async {
    final dependencies = AppDependencies(
      const AppConfig(
        environment: 'test',
        useDemoData: true,
      ),
      storage: MemoryStorage(),
    );

    addTearDown(dependencies.dispose);

    await tester.pumpWidget(
      AssetOneApp(dependencies: dependencies),
    );

    await tester.pump();

    // Verify the application is initialized.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify the correct application root is loaded.
    expect(find.byType(AssetOneRoot), findsOneWidget);

    // Verify application title.
    final app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );

    expect(app.title, 'AssetOne');
  });
}
