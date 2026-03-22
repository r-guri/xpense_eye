import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../db_helper.dart';

class BackupService {

  /// EXPORT BACKUP
  static Future<void> exportBackup() async {

    final db = DBHelper.instance;

    Map<String,dynamic> backup = {

      "trips": await db.getAll("trips"),
      "members": await db.getAll("members"),
      "expenses": await db.getAll("expenses"),
      "member_transactions": await db.getAll("member_transactions"),
      "categories": await db.getAll("categories"),

    };

    final dir = await getApplicationDocumentsDirectory();

    File file = File("${dir.path}/xpense_eye_backup.json");

    await file.writeAsString(jsonEncode(backup));

    await Share.shareXFiles([XFile(file.path)],
        text: "Xpense Eye Backup");

  }
// static Future<bool> importBackup(int currentUserId) async {
//   FilePickerResult? result = await FilePicker.platform.pickFiles(
//     type: FileType.custom,
//     allowedExtensions: ["json"],
//   );

//   if (result == null) return false;

//   File file = File(result.files.single.path!);

//   String data = await file.readAsString();

//   Map<String, dynamic> backup = jsonDecode(data);

//   final db = await DBHelper.instance.database;

//   // CLEAR OLD DATA
//   await db.delete("trips");
//   await db.delete("members");
//   await db.delete("expenses");
//   await db.delete("member_transactions");
//   await db.delete("categories");

//   Map<int,int> tripIdMap = {}; // oldTripId -> newTripId mapping

//   // RESTORE TRIPS
//   for (var t in backup["trips"]) {
//     var trip = Map<String,dynamic>.from(t);
//     trip['userId'] = currentUserId; // replace with current userId
//     trip.remove('id'); // remove old ID to generate new one
//     int newTripId = await db.insert("trips", trip);
//     tripIdMap[t['id']] = newTripId;
//   }

//   // RESTORE MEMBERS
//   for (var m in backup["members"]) {
//     var member = Map<String,dynamic>.from(m);
//     member['tripId'] = tripIdMap[m['tripId']]!;
//     member.remove('id');
//     await db.insert("members", member);
//   }

//   // RESTORE EXPENSES
//   for (var e in backup["expenses"]) {
//     var expense = Map<String,dynamic>.from(e);
//     expense['tripId'] = tripIdMap[e['tripId']]!;
//     expense.remove('id');
//     await db.insert("expenses", expense);
//   }

//   // RESTORE TRANSACTIONS
//   for (var l in backup["member_transactions"]) {
//     var transaction = Map<String,dynamic>.from(l);
//     transaction['tripId'] = tripIdMap[l['tripId']]!;
//     transaction.remove('id');
//     await db.insert("member_transactions", transaction);
//   }

//   // RESTORE CATEGORIES
//   for (var c in backup["categories"]) {
//     var category = Map<String,dynamic>.from(c);
//     category['tripId'] = tripIdMap[c['tripId']]!;
//     category.remove('id');
//     await db.insert("categories", category);
//   }

//   return true;
// }
  /// IMPORT BACKUP
static Future<bool> importBackup() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ["json"],
  );

  if (result == null) return false;

  File file = File(result.files.single.path!);

  String data = await file.readAsString();

  Map<String, dynamic> backup = jsonDecode(data);

  final db = await DBHelper.instance.database;

  await db.delete("trips");
  await db.delete("members");
  await db.delete("expenses");
  await db.delete("member_transactions");
  await db.delete("categories");

  for (var t in backup["trips"]) {
    await db.insert("trips", Map<String, dynamic>.from(t));
  }

  for (var m in backup["members"]) {
    await db.insert("members", Map<String, dynamic>.from(m));
  }

  for (var e in backup["expenses"]) {
    await db.insert("expenses", Map<String, dynamic>.from(e));
  }

  for (var l in backup["member_transactions"]) {
    await db.insert("member_transactions", Map<String, dynamic>.from(l));
  }

  for (var c in backup["categories"]) {
    await db.insert("categories", Map<String, dynamic>.from(c));
  }

  return true; // 👈 IMPORTANT
}
  // static Future<void> importBackup() async {

  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ["json"],
  //   );

  //   if(result == null) return;

  //   File file = File(result.files.single.path!);

  //   String data = await file.readAsString();

  //   Map<String,dynamic> backup = jsonDecode(data);

  //   final db = await DBHelper.instance.database;

  //   /// CLEAR OLD DATA

  //   await db.delete("trips");
  //   await db.delete("members");
  //   await db.delete("expenses");
  //   await db.delete("member_transactions");
  //   await db.delete("categories");

  //   /// RESTORE DATA

  //   for(var t in backup["trips"]) {
  //     await db.insert("trips", Map<String,dynamic>.from(t));
  //   }

  //   for(var m in backup["members"]) {
  //     await db.insert("members", Map<String,dynamic>.from(m));
  //   }

  //   for(var e in backup["expenses"]) {
  //     await db.insert("expenses", Map<String,dynamic>.from(e));
  //   }

  //   for(var l in backup["member_transactions"]) {
  //     await db.insert("member_transactions", Map<String,dynamic>.from(l));
  //   }

  //   for(var c in backup["categories"]) {
  //     await db.insert("categories", Map<String,dynamic>.from(c));
  //   }

  // }

}