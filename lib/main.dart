import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open (and on first run, create + seed) the local database up front so the
  // first screen has data immediately.
  await AppDatabase.instance.database;

  final settings = SettingsController();
  await settings.load();

  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: const DoodhHisaabApp(),
    ),
  );
}
