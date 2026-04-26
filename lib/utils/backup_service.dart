import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../db_helper.dart';

class BackupService {
  /// 🔐 ENCRYPTION
  static final _key =
      encrypt.Key.fromUtf8('12345678901234567890123456789012');
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  /// ================= 🔥 CORE BACKUP CREATION =================
  static Future<File> _createBackup(int userId) async {
    final db = DBHelper.instance;

    final trips = await db.getAll(
      "trips",
      where: "userId = ?",
      whereArgs: [userId],
    );

    List data = [];

    for (var trip in trips) {
      int tripId = trip['id'];

      var members = await db.getAll(
        "members",
        where: "tripId = ?",
        whereArgs: [tripId],
      );

      var expenses = await db.getAll(
        "expenses",
        where: "tripId = ?",
        whereArgs: [tripId],
      );

      var ledger = await db.getAll(
        "member_transactions",
        where: "tripId = ?",
        whereArgs: [tripId],
      );

      data.add({
        "trip": trip,
        "members": members,
        "expenses": expenses,
        "ledger": ledger,
      });
    }

    final dir = await getApplicationDocumentsDirectory();
    File file = File("${dir.path}/temp_backup.json");

    final jsonString = jsonEncode(data);
    final encrypted = _encrypter.encrypt(jsonString, iv: _iv);

    await file.writeAsString(encrypted.base64);

    return file;
  }

  /// ================= 🔥 MANUAL BACKUP (Download folder) =================
  static Future<File> getPublicBackupFile(int userId) async {
  final file = await _createBackup(userId);
return file;
  }

  /// ================= 🔥 GOOGLE DRIVE BACKUP =================
  static Future<File> getPrivateBackupFile(int userId) async {
    return await _createBackup(userId);
  }

  /// ================= 🔥 EXPORT =================
  static Future<void> exportBackup(int userId) async {
    File file = await getPublicBackupFile(userId);

   await Share.shareXFiles([XFile(file.path)]);
  }

  /// ================= 🔥 RESTORE =================
  static Future<void> restoreBackupFile(File file, int currentUserId) async {
    final db = DBHelper.instance;

    try {
      /// 🔥 DELETE OLD DATA
      final oldTrips = await db.getAll(
        "trips",
        where: "userId = ?",
        whereArgs: [currentUserId],
      );

      for (var t in oldTrips) {
        int tripId = t["id"];

        await db.delete("member_transactions", "tripId = ?", [tripId]);
        await db.delete("expenses", "tripId = ?", [tripId]);
        await db.delete("members", "tripId = ?", [tripId]);
      }

      await db.delete("trips", "userId = ?", [currentUserId]);

      /// 🔐 DECRYPT
      String raw = await file.readAsString();
      String decrypted;

      try {
        decrypted = _encrypter.decrypt64(raw, iv: _iv);
      } catch (e) {
        decrypted = raw;
      }

      List backup = jsonDecode(decrypted);

      /// 🔥 RESTORE
      for (var item in backup) {
        var trip = item["trip"];

        int newTripId = await db.insert("trips", {
          "userId": currentUserId,
          "name": trip["name"],
          "destination": trip["destination"],
          "startDate": trip["startDate"],
          "endDate": trip["endDate"],
        });

        Map<int, int> memberMap = {};

        /// MEMBERS
        for (var m in item["members"]) {
          int oldId = m["id"];

          int newId = await db.insert("members", {
            "tripId": newTripId,
            "name": m["name"],
            "mobile": m["mobile"],
            "email": m["email"],
            "payAmount": m["payAmount"],
            "isAdmin": m["isAdmin"],
          });

          memberMap[oldId] = newId;
        }

        /// EXPENSES (addedBy FIX)
        for (var e in item["expenses"]) {
          List<int> oldIds = e["members"]
              .toString()
              .split(",")
              .map((x) => int.parse(x))
              .toList();

          List<int> newIds = oldIds.map((id) => memberMap[id]!).toList();

          int? newAddedBy;

          if (e["addedBy"] != null &&
              memberMap.containsKey(e["addedBy"])) {
            newAddedBy = memberMap[e["addedBy"]];
          }

          if (newAddedBy == null && newIds.isNotEmpty) {
            newAddedBy = newIds.first;
          }

          await db.insert("expenses", {
            "tripId": newTripId,
            "description": e["description"],
            "amount": e["amount"],
            "category": e["category"],
            "startLocation": e["startLocation"],
            "endLocation": e["endLocation"],
            "travelDate": e["travelDate"],
            "members": newIds.join(","),
            "addedBy": newAddedBy,
          });
        }

        /// LEDGER
        for (var l in item["ledger"]) {
          await db.insert("member_transactions", {
            "tripId": newTripId,
            "memberId": memberMap[l["memberId"]],
            "amount": l["amount"],
            "type": l["type"],
            "note": l["note"],
          });
        }
      }
    } catch (e) {
      print("RESTORE ERROR: $e");
      rethrow;
    }
  }

  /// ================= 🔥 IMPORT =================
  static Future<bool> importBackup(int currentUserId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["json"],
    );

    if (result == null) return false;

    File file = File(result.files.single.path!);

    await restoreBackupFile(file, currentUserId);

    return true;
  }
}