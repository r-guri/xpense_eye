import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> generateTripReportPDF({
  required String tripName,
  required List<Map<String, dynamic>> members,
  required List<Map<String, dynamic>> expenses,
  required double totalExpense,
  int? selectedMemberId, // Pass memberId if only one member PDF required
}) async {
  final pdf = pw.Document();

  // Calculate member-wise share per expense
  Map<int, double> memberShares = {};
  for (var m in members) memberShares[m['id']] = 0.0;

  for (var e in expenses) {
    if (e['members'] != null && e['members'].toString().isNotEmpty) {
      List<int> participantIds = e['members']
          .toString()
          .split(',')
          .map((s) => int.tryParse(s) ?? 0)
          .toList();
      double perPerson = (e['amount'] ?? 0).toDouble() / participantIds.length;
      for (var id in participantIds) {
        memberShares[id] = (memberShares[id] ?? 0) + perPerson;
      }
    }
  }

  // Filter for single member report
  List<Map<String, dynamic>> reportMembers = selectedMemberId != null
      ? members.where((m) => m['id'] == selectedMemberId).toList()
      : members;

  // Add logo & header
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // 🔹 Logo
              pw.Image(
                pw.MemoryImage(
                  File('assets/logo.png')
                      .readAsBytesSync(), // Place logo in assets folder
                ),
                height: 60,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Tour Khata',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Trip Expense Report',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Divider(),
            ],
          ),
        ),

        pw.SizedBox(height: 10),
        pw.Text('Trip Name: $tripName',
            style:
                pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text(
          'Total Expense: ₹${totalExpense.toStringAsFixed(2)}',
          style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.blue,
              fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),

        pw.Container(
          color: PdfColors.grey300,
          padding: pw.EdgeInsets.all(6),
          child: pw.Text('Member-wise Summary',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 6),

        pw.Table.fromTextArray(
          headerDecoration:
              pw.BoxDecoration(color: PdfColors.teal400),
          headerStyle: pw.TextStyle(
              color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          headers: ['Member', 'Deposit', 'Share', 'Balance'],
          data: reportMembers.map((m) {
            double deposit =
                m['isAdmin'] == 1 ? 0.0 : (m['payAmount'] ?? 0.0);
            double share = memberShares[m['id']] ?? 0.0;
            double balance = m['isAdmin'] == 1
                ? totalExpense -
                    members
                        .where((x) => x['isAdmin'] == 0)
                        .fold(0.0,
                            (sum, nm) => sum + (nm['payAmount'] ?? 0))
                : deposit - share;
            return [
              m['name'],
              deposit.toStringAsFixed(2),
              share.toStringAsFixed(2),
              balance.toStringAsFixed(2),
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 20),
        pw.Container(
          color: PdfColors.grey300,
          padding: pw.EdgeInsets.all(6),
          child: pw.Text('Expenses List',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 6),

        pw.Table.fromTextArray(
          headerDecoration:
              pw.BoxDecoration(color: PdfColors.blueGrey700),
          headerStyle: pw.TextStyle(
              color: PdfColors.white, fontWeight: pw.FontWeight.bold),
          headers: ['Category', 'Description', 'Amount', 'Members'],
          data: expenses.map((e) {
            String memberNames = '';
            if (e['members'] != null && e['members'].toString().isNotEmpty) {
              var ids = e['members']
                  .toString()
                  .split(',')
                  .map((id) => int.tryParse(id))
                  .whereType<int>()
                  .toList();
              // If single member report, filter only that member
              var filteredNames = ids
                  .where((id) =>
                      selectedMemberId == null || id == selectedMemberId)
                  .map((id) {
                return members
                        .firstWhere(
                          (m) => m['id'] == id,
                          orElse: () => {'name': ''},
                        )['name']
                        ?.toString() ??
                    '';
              }).where((name) => name.isNotEmpty).join(', ');
              memberNames = filteredNames.isEmpty
                  ? (selectedMemberId != null
                      ? members
                          .firstWhere(
                              (m) => m['id'] == selectedMemberId,
                              orElse: () => {'name': ''})['name']
                          .toString()
                      : '')
                  : filteredNames;
            }
            return [
              e['category'] ?? '',
              e['description'] ?? '',
              (e['amount'] ?? 0).toStringAsFixed(2),
              memberNames,
            ];
          }).toList(),
        ),

        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.Center(
          child: pw.Text(
            'Generated by Tour Khata',
            style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic),
          ),
        ),
      ],
    ),
  );

  final output = await getTemporaryDirectory();
  final fileName = selectedMemberId != null
      ? "$tripName-${reportMembers.first['name']}.pdf"
      : "$tripName-report.pdf";
  final file = File("${output.path}/$fileName");
  await file.writeAsBytes(await pdf.save());
  await OpenFile.open(file.path);
}
