import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../db_helper.dart';
import '../utils/app_info.dart';

Future<void> generateTripReportPDF({
  required String tripName,
  required List<Map<String, dynamic>> members,
  required List<Map<String, dynamic>> expenses,
  required double totalExpense,
  required List<Map<String, dynamic>> allMembers,
}) async {
  final pdf = pw.Document();

  Map<int, double> memberShares = {};
  Map<int, double> memberDeposits = {};
  Map<int, double> memberSpent = {};

  /// ================= SHARE CALCULATION =================

  for (var m in members) {
    memberShares[m['id']] = 0;
  }

  for (var e in expenses) {
    if (e['members'] != null && e['members'].toString().isNotEmpty) {
      List<int> ids = e['members']
          .toString()
          .split(',')
          .map((s) => int.tryParse(s) ?? 0)
          .toList();

      double perPerson = ((e['amount'] ?? 0).toDouble() / ids.length)
          .ceilToDouble();

      for (var id in ids) {
        if (memberShares.containsKey(id)) {
          memberShares[id] = (memberShares[id] ?? 0) + perPerson;
        }
      }
    }
  }

  /// ================= DEPOSIT FROM LEDGER =================

  for (var m in members) {
    int memberId = m['id'];

    double payAmount = (m['payAmount'] ?? 0).toDouble();

    double ledgerDeposit = await DBHelper.instance.getMemberDeposit(
      m['tripId'],
      memberId,
    );

    double ledgerWithdraw = await DBHelper.instance.getMemberWithdraw(
      m['tripId'],
      memberId,
    );

    memberDeposits[memberId] = payAmount + ledgerDeposit - ledgerWithdraw;
  }

  /// ================= ADMIN EXPENSE = ADMIN DEPOSIT =================
  /// ================= SPENT CALCULATION =================

  for (var m in members) {
    memberSpent[m['id']] = 0;
  }

  for (var e in expenses) {
    int? paidBy = e['addedBy'];
    double amount = (e['amount'] ?? 0).toDouble();

    if (paidBy != null && memberSpent.containsKey(paidBy)) {
      memberSpent[paidBy] = (memberSpent[paidBy] ?? 0) + amount;
    }
  }
  // for (var e in expenses) {

  //   int? paidBy = e['addedBy'];

  //   double amount = (e['amount'] ?? 0).toDouble();

  //   if (paidBy != null && memberDeposits.containsKey(paidBy)) {

  //     memberDeposits[paidBy] =
  //         (memberDeposits[paidBy] ?? 0) + amount;

  //   }

  // }
  /// ================= FILTER EXPENSES (CUSTOM MEMBERS) =================

  List<Map<String, dynamic>> filteredExpenses = expenses.where((e) {
    if (e['members'] == null) return false;

    List<int> ids = e['members']
        .toString()
        .split(',')
        .map((s) => int.tryParse(s) ?? 0)
        .toList();

    for (var m in members) {
      if (ids.contains(m['id'])) return true;
    }

    return false;
  }).toList();

  double filteredTotalExpense = filteredExpenses.fold(
    0.0,
    (sum, e) => sum + ((e['amount'] ?? 0).toDouble()),
  );

  /// ================= DATE FORMAT =================

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "";

    DateTime d = DateTime.parse(date);

    return DateFormat("dd-MM-yyyy").format(d);
  }

  double roundFigure(double value) {
    if (value % 1 == 0) {
      return value;
    } else {
      return value.ceilToDouble();
    }
  }

  /// ================= LOAD LOGO =================

  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/logo_header.png')).buffer.asUint8List(),
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(24),

      build: (context) => [
        /// HEADER
        pw.Container(
          padding: pw.EdgeInsets.all(12),

          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex("#ffffff"),
            borderRadius: pw.BorderRadius.circular(8),
          ),

          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,

                children: [
                  pw.Text(
                    AppInfo.appName,
                    style: pw.TextStyle(
                      color: PdfColor.fromHex("#00796B"),
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.Text(
                    "Smart Expense Manager",
                    style: pw.TextStyle(color: PdfColors.black, fontSize: 12),
                  ),
                ],
              ),

              pw.Container(height: 60, width: 60, child: pw.Image(logo)),
            ],
          ),
        ),

        // pw.SizedBox(height: 20),
 pw.Divider(),
        /// TITLE
        pw.Center(
          child: pw.Text(
            "Expense Report - "+tripName,

            style: pw.TextStyle(
              fontSize: 17,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex("#00796B"),
            ),
          ),
        ),

        pw.Divider(),

        pw.Text(
          "Total Expense: Rs. ${filteredTotalExpense.toStringAsFixed(2)}",
          style: pw.TextStyle(fontSize: 16,color:PdfColor.fromHex('#00796B'), fontWeight: pw.FontWeight.bold),
        ),

        pw.SizedBox(height: 20),

        /// MEMBER TABLE
        pw.Text(
          "Member Expense Details",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),

        pw.SizedBox(height: 10),

        pw.Table.fromTextArray(
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromHex("#00796B"),
          ),

          headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),

          headers: ["Member", "Deposit", "Spent", "Share", "Balance"],
          data: members.map((m) {
            double share = memberShares[m['id']] ?? 0;

            double deposit = memberDeposits[m['id']] ?? 0;

            double spent = memberSpent[m['id']] ?? 0;

            double balance;

            if (m['isAdmin'] == 1) {
              deposit = 0;

              double totalDeposits = 0;

              for (var member in members) {
                if (member['isAdmin'] != 1) {
                  totalDeposits += memberDeposits[member['id']] ?? 0;
                }
              }

              balance = spent - share - totalDeposits;
              // print(totalDeposits);
            } else {
              balance = deposit + spent - share;
            }

            return [
              m['isAdmin'] == 1 ? "${m['name']} (Admin)" : m['name'],

              "Rs ${roundFigure(deposit).toStringAsFixed(0)}",
              "Rs ${roundFigure(spent).toStringAsFixed(0)}",
              "Rs ${share.toStringAsFixed(0)}",
              "Rs ${roundFigure(balance).toStringAsFixed(0)}",
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 25),

        /// EXPENSE TABLE
        pw.Text(
          "Expenses List",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),

        pw.SizedBox(height: 10),

        pw.Table.fromTextArray(
          headerDecoration: pw.BoxDecoration(
            color: PdfColor.fromHex("#00796B"),
          ),

          headerStyle: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),

          headers: ["Date", "Category", "Description", "Amount", "Members"],

          data: filteredExpenses.map((e) {
            String memberNames = "";

            if (e['members'] != null) {
              memberNames = e['members']
                  .toString()
                  .split(',')
                  .map((id) {
                    var name = allMembers.firstWhere(
                      (m) => m['id'] == int.tryParse(id),
                      orElse: () => {'name': 'Unknown'},
                    )['name'];

                    return name;
                  })
                  .join(", ");
            }

            return [
              formatDate(e['travelDate']),

              e['category'] ?? "",

              e['description'] ?? "",

              "Rs ${roundFigure((e['amount'] ?? 0).toDouble()).toStringAsFixed(0)}",

              memberNames,
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 20),

        /// FOOTER
        pw.Align(
          alignment: pw.Alignment.centerRight,

          child: pw.Text(
            "Generated by " + AppInfo.appName,

            style: pw.TextStyle(
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ],
    ),
  );

  /// SAVE FILE

  final output = await getTemporaryDirectory();

final safeTripName = tripName
    .trim()
    .replaceAll(' ', '_')
    .replaceAll(RegExp(r'[^\w\-]'), '');

final file = File("${output.path}/${safeTripName}_report.pdf");

  await file.writeAsBytes(await pdf.save());

  await OpenFile.open(file.path);
}
