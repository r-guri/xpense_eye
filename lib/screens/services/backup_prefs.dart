import 'package:shared_preferences/shared_preferences.dart';

enum BackupFrequency { daily, weekly, monthly }

class BackupPrefs {
  static const _kAuto = 'auto_backup';
  static const _kLast = 'last_backup';
  static const _kFreq = 'backup_freq';

  /// ON/OFF
  static Future<void> setAutoBackup(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAuto, v);
  }

  static Future<bool> getAutoBackup() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kAuto) ?? false;
  }

  /// last backup (epoch ms)
  static Future<void> setLastBackup(int t) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLast, t);
  }

  static Future<int> getLastBackup() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kLast) ?? 0;
  }

  /// frequency
  static Future<void> setFrequency(BackupFrequency f) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kFreq, f.name);
  }

  static Future<BackupFrequency> getFrequency() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kFreq) ?? BackupFrequency.daily.name;
    return BackupFrequency.values.firstWhere((e) => e.name == s);
  }

  /// helper: due?
  static Future<bool> isBackupDue() async {
    final enabled = await getAutoBackup();
    if (!enabled) return false;

    final last = await getLastBackup();
    final now = DateTime.now().millisecondsSinceEpoch;
    final freq = await getFrequency();

    int interval;
    switch (freq) {
      case BackupFrequency.daily:
        interval = 24 * 60 * 60 * 1000;
        break;
      case BackupFrequency.weekly:
        interval = 7 * 24 * 60 * 60 * 1000;
        break;
      case BackupFrequency.monthly:
        interval = 30 * 24 * 60 * 60 * 1000;
        break;
    }
    return (now - last) >= interval;
  }

  static Future<void> setBackupSize(int size) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('backup_size', size);
}

static Future<int> getBackupSize() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('backup_size') ?? 0;
}
}