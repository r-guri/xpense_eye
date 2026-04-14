import 'package:flutter/material.dart';
import 'package:my_app/utils/app_strings.dart';
import '../db_helper.dart';
import 'package:intl/intl.dart';
import 'ads/banner_ad_widget.dart';
import 'services/purchase_service.dart';
import '../utils/app_config.dart';
import '../utils/app_toast.dart';
class MemberLedgerScreen extends StatefulWidget {
  final int memberId;
  final String memberName;
  final int tripId;

  MemberLedgerScreen({
    required this.memberId,
    required this.memberName,
    required this.tripId,
  });

  @override
  _MemberLedgerScreenState createState() => _MemberLedgerScreenState();
}

class _MemberLedgerScreenState extends State<MemberLedgerScreen> {
  List<Map<String, dynamic>> transactions = [];

  double balance = 0;

  TextEditingController amountCtrl = TextEditingController();
  TextEditingController noteCtrl = TextEditingController();

  String type = "deposit";

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  String formatDate(String? date) {
    if (date == null) return "";

    DateTime d = DateTime.parse(date);

    return DateFormat("dd-MM-yyyy").format(d);
  }

  Future<void> _loadLedger() async {
    var data = await DBHelper.instance.getMemberTransactions(
      widget.tripId,
      widget.memberId,
    );

    double bal = await DBHelper.instance.getMemberBalance(
      widget.tripId,
      widget.memberId,
    );

    setState(() {
      transactions = data;
      balance = bal;
    });
  }

  Future<void> _addTransaction() async {
    double amount = double.tryParse(amountCtrl.text) ?? 0;
 if (amount <= 0) {
    AppToast.error(context, AppStrings.get('amount_positive'));
    return;
  }
    await DBHelper.instance.insert('member_transactions', {
      'tripId': widget.tripId,
      'memberId': widget.memberId,
      'type': type,
      'amount': amount,
      'note': noteCtrl.text,
      'createdAt': DateTime.now().toIso8601String(),
    });

    amountCtrl.clear();
    noteCtrl.clear();
  AppToast.success(context, AppStrings.get('entry_added'));

    _loadLedger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text("${widget.memberName} ${AppStrings.get("ledger")}"),
        backgroundColor: Colors.teal,
      ),

      body: RefreshIndicator(
        onRefresh: _loadLedger,

        child: ListView(
          children: [
            /// BALANCE CARD
            Container(
              margin: EdgeInsets.all(16),

              padding: EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Text(
                    AppStrings.get("current_balance"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),

                  Text(
                    "₹${balance.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            /// ADD TRANSACTION
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),

              padding: EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),

              child: Column(
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppStrings.get("amount"),
                      prefixIcon: Icon(
                        Icons.currency_rupee,
                        color: Colors.teal,
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  TextField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: AppStrings.get("note"),
                      prefixIcon: Icon(Icons.note, color: Colors.teal),
                    ),
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Radio(
                        value: "deposit",
                        groupValue: type,

                        onChanged: (v) => setState(() => type = v.toString()),
                      ),

                      Text(AppStrings.get("deposit")),

                      Radio(
                        value: "withdraw",
                        groupValue: type,
                        onChanged: (v) => setState(() => type = v.toString()),
                      ),

                      Text(AppStrings.get("withdraw")),
                    ],
                  ),

                  SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      onPressed: _addTransaction,

                      icon: Icon(Icons.add),

                      label: Text(AppStrings.get("add_entry")),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            /// TRANSACTIONS TITLE
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),

              child: Text(
                AppStrings.get("transactions"),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),

            SizedBox(height: 10),

            /// TRANSACTION LIST
            ...transactions.map((t) {
              bool deposit = t['type'] == "deposit";

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),

                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),

                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: deposit
                        ? Colors.green.shade100
                        : Colors.red.shade100,

                    child: Icon(
                      deposit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: deposit ? Colors.green : Colors.red,
                    ),
                  ),

                  title: Text(
                    "₹${t['amount']}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      if (t['note'] != null && t['note'] != "") Text(t['note']),

                      SizedBox(height: 2),

                      Text(
                        formatDate(t['createdAt']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),

                  trailing: Text(
                    deposit ? "Deposit" : "Withdraw",
                    style: TextStyle(
                      color: deposit ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),

            // SizedBox(height: 20),
               SizedBox(height: 20),
          if (AppConfig.enableAds && !PurchaseService.isAdsRemoved)
  const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}
