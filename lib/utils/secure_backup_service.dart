import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../db_helper.dart';

class SecureBackupService {

  static String _encrypt(String data) {
    return base64Encode(utf8.encode(data));
  }

  static String _decrypt(String data) {
    return utf8.decode(base64Decode(data));
  }

  /// EXPORT ENCRYPTED BACKUP
  static Future<void> exportBackup() async {

    final db = DBHelper.instance;

    Map<String,dynamic> backup = {

      "trips": await db.getAll("trips"),
      "members": await db.getAll("members"),
      "expenses": await db.getAll("expenses"),
      "member_transactions": await db.getAll("member_transactions"),
      "categories": await db.getAll("categories"),

    };

    String encrypted = _encrypt(jsonEncode(backup));

    final dir = await getApplicationDocumentsDirectory();

    File file = File("${dir.path}/tour_khata_backup.tkh");

    await file.writeAsString(encrypted);

    await Share.shareXFiles([XFile(file.path)], text: "Tour Khata Backup");
  }

  /// IMPORT ENCRYPTED BACKUP
  static Future<void> importBackup() async {

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ["tkh"],
      type: FileType.custom,
    );

    if(result == null) return;

    File file = File(result.files.single.path!);

    String encrypted = await file.readAsString();

    String decrypted = _decrypt(encrypted);

    Map<String,dynamic> backup = jsonDecode(decrypted);

    final db = await DBHelper.instance.database;

    await db.delete("trips");
    await db.delete("members");
    await db.delete("expenses");
    await db.delete("member_transactions");
    await db.delete("categories");

    for(var t in backup["trips"]) {
      await db.insert("trips", Map<String,dynamic>.from(t));
    }

    for(var m in backup["members"]) {
      await db.insert("members", Map<String,dynamic>.from(m));
    }

    for(var e in backup["expenses"]) {
      await db.insert("expenses", Map<String,dynamic>.from(e));
    }

    for(var l in backup["member_transactions"]) {
      await db.insert("member_transactions", Map<String,dynamic>.from(l));
    }

    for(var c in backup["categories"]) {
      await db.insert("categories", Map<String,dynamic>.from(c));
    }
  }
}