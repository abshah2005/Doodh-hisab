import 'package:sqflite/sqflite.dart';

import '../app_database.dart';

/// Keys used in the `setting` table.
class SettingKeys {
  static const lang = 'lang'; // 'roman_urdu' | 'english'
  static const twoRounds = 'two_rounds'; // '1' | '0'
  static const businessName = 'business_name';
  static const combinedUnit = 'combined_unit'; // '1' | '0'
}

/// Thin key/value access over the `setting` table.
class SettingsRepository {
  Future<Map<String, String>> all() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('setting');
    return {
      for (final r in rows)
        (r['key'] as String): (r['value'] as String? ?? ''),
    };
  }

  Future<void> put(String key, String value) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'setting',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
