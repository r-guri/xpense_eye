import 'package:shared_preferences/shared_preferences.dart';

class AutoBackupService {

  static Future<bool> shouldBackup() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    int? lastBackup = prefs.getInt("lastBackup");

    int now = DateTime.now().millisecondsSinceEpoch;

    if(lastBackup == null) return true;

    int diff = now - lastBackup;

    return diff > 7 * 24 * 60 * 60 * 1000;
  }

  static Future<void> markBackupDone() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setInt(
      "lastBackup",
      DateTime.now().millisecondsSinceEpoch
    );

  }
}