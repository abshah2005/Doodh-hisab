import 'package:flutter/foundation.dart';

import '../data/repositories/settings_repository.dart';
import '../l10n/strings.dart';

/// App-wide settings, backed by the `setting` table. Screens read [strings],
/// [twoRounds] etc. and listen for changes.
class SettingsController extends ChangeNotifier {
  final SettingsRepository _repo = SettingsRepository();

  AppLang _lang = AppLang.romanUrdu;
  bool _twoRounds = false;
  bool _combinedUnit = false;
  String _businessName = '';
  bool _loaded = false;

  AppLang get lang => _lang;
  bool get twoRounds => _twoRounds;
  bool get combinedUnit => _combinedUnit;
  String get businessName => _businessName;
  bool get loaded => _loaded;

  Strings get strings => Strings(_lang);

  Future<void> load() async {
    final map = await _repo.all();
    _lang = (map[SettingKeys.lang] == 'english')
        ? AppLang.english
        : AppLang.romanUrdu;
    _twoRounds = map[SettingKeys.twoRounds] == '1';
    _combinedUnit = map[SettingKeys.combinedUnit] == '1';
    _businessName = map[SettingKeys.businessName] ?? '';
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLang(AppLang lang) async {
    _lang = lang;
    await _repo.put(
        SettingKeys.lang, lang == AppLang.english ? 'english' : 'roman_urdu');
    notifyListeners();
  }

  Future<void> setTwoRounds(bool value) async {
    _twoRounds = value;
    await _repo.put(SettingKeys.twoRounds, value ? '1' : '0');
    notifyListeners();
  }

  Future<void> setCombinedUnit(bool value) async {
    _combinedUnit = value;
    await _repo.put(SettingKeys.combinedUnit, value ? '1' : '0');
    notifyListeners();
  }

  Future<void> setBusinessName(String value) async {
    _businessName = value;
    await _repo.put(SettingKeys.businessName, value);
    notifyListeners();
  }
}
