import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> generateTripReportExcel({
  required String tripName,
  required List<Map<String, dynamic>> members,
  required List<Map<String, dynamic>> expenses,
  required double totalExpense,
}) async {
  var excel = Excel.createExcel();
  Sheet sheet = excel['Trip Report'];

  // Header
  sheet.appendRow(['Member', 'Deposit (₹)', 'Share (₹)', 'Balance (₹)']);

  // Calculate member shares per expense
  Map<int, double> memberShares = {};
  for (var m in members) memberShares[m['id']] = 0.0;
  for (var e in expenses) {
    if (e['members'] != null && e['members'].toString().isNotEmpty) {
      List<int> participantIds =
          e['members'].toString().split(',').map((s) => int.tryParse(s) ?? 0).toList();
      double perPerson = (e['amount'] ?? 0).toDouble() / participantIds.length;
      for (var id in participantIds) {
        memberShares[id] = (memberShares[id] ?? 0) + perPerson;
      }
    }
  }

  // Member data
  for (var m in members) {
    double deposit = m['isAdmin'] == 1 ? 0.0 : (m['payAmount'] ?? 0.0);
    double share = memberShares[m['id']] ?? 0.0;
    double balance = m['isAdmin'] == 1
        ? totalExpense - members.where((x) => x['isAdmin'] == 0)
            .fold(0.0, (sum, nm) => sum + (nm['payAmount'] ?? 0))
        : deposit - share;

    sheet.appendRow([
      m['name'],
      deposit.toStringAsFixed(2),
      share.toStringAsFixed(2),
      balance.toStringAsFixed(2),
    ]);
  }

  // Expenses list
  sheet.appendRow([]);
  sheet.appendRow(['Description', 'Category', 'Amount (₹)', 'Members']);
  for (var e in expenses) {
    String memberNames = '';
    if (e['members'] != null && e['members'].toString().isNotEmpty) {
      memberNames = e['members'].toString().split(',').map((id) {
        var name = members.firstWhere(
          (m) => m['id'] == int.tryParse(id),
          orElse: () => {'name': 'Unknown'},
        )['name'];
        return name;
      }).join(', ');
    }
    sheet.appendRow([
      e['description'] ?? '',
      e['category'] ?? '',
      (e['amount'] ?? 0).toStringAsFixed(2),
      memberNames,
    ]);
  }

  final output = await getTemporaryDirectory();
  final file = File("${output.path}/$tripName-report.xlsx");
  await file.writeAsBytes(excel.encode()!);
  await OpenFile.open(file.path);
}
