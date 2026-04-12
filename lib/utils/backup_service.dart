import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../db_helper.dart';

class BackupService {

  /// EXPORT BACKUP
static Future<void> exportBackup(int userId) async {

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
  File file = File("${dir.path}/xpense_backup.json");

  await file.writeAsString(jsonEncode(data));

  await Share.shareXFiles([XFile(file.path),], text: "Backup File");
}
  /// IMPORT BACKUP
static Future<bool> importBackup(int currentUserId) async {

  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ["json"],
  );

  if (result == null) return false;

  File file = File(result.files.single.path!);

  String data = await file.readAsString();
  List backup = jsonDecode(data);

  final db = DBHelper.instance;

  for (var item in backup) {

    /// 🟢 INSERT TRIP
    var trip = item["trip"];

    int newTripId = await db.insert("trips", {
      "userId": currentUserId,
      "name": trip["name"],
      "destination": trip["destination"],
      "startDate": trip["startDate"],
      "endDate": trip["endDate"],
    });

    /// 🟢 MEMBER MAP
    Map<int, int> memberMap = {};

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

    /// 🟢 EXPENSES
    for (var e in item["expenses"]) {

      List<int> oldIds = e["members"]
          .toString()
          .split(",")
          .map((x) => int.parse(x))
          .toList();

      List<int> newIds =
          oldIds.map((id) => memberMap[id]!).toList();

      await db.insert("expenses", {
        "tripId": newTripId,
        "description": e["description"],
        "amount": e["amount"],
        "category": e["category"],
        "startLocation": e["startLocation"],
        "endLocation": e["endLocation"],
        "travelDate": e["travelDate"],
        "members": newIds.join(","),
      });
    }

    /// 🟢 LEDGER
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

  return true;
}
 
}