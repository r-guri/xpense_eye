import 'package:flutter/material.dart';
import '../db_helper.dart';

class SettlementScreen extends StatefulWidget {

  final int tripId;
  final String tripName;

  const SettlementScreen({
    required this.tripId,
    required this.tripName
  });

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {

  List<Map<String,dynamic>> members = [];

  Map<int,double> memberShares = {};
  Map<int,double> memberDeposits = {};

  List<String> settlements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

Future<void> _loadData() async {

  members = await DBHelper.instance.getAll(
    'members',
    where: 'tripId = ?',
    whereArgs: [widget.tripId],
  );

  var expenses = await DBHelper.instance.getAll(
    'expenses',
    where: 'tripId = ?',
    whereArgs: [widget.tripId],
  );

  memberShares.clear();
  memberDeposits.clear();

  /// MEMBER DEPOSIT (payAmount + ledger)
  for (var m in members) {

    int id = m['id'];

    memberShares[id] = 0;

    double payAmount = (m['payAmount'] ?? 0).toDouble();

    double ledgerDeposit =
        await DBHelper.instance.getMemberDeposit(widget.tripId, id);

    double ledgerWithdraw =
        await DBHelper.instance.getMemberWithdraw(widget.tripId, id);

    memberDeposits[id] =
        payAmount + ledgerDeposit - ledgerWithdraw;

  }

  /// SHARE CALCULATION
  for (var e in expenses) {

    if (e['members'] == null || e['members'].toString().isEmpty) continue;

    List<int> ids = e['members']
        .toString()
        .split(',')
        .map((s) => int.parse(s))
        .toList();

  double amount = (e['amount'] ?? 0).toDouble();

double perPerson = (amount / ids.length).ceilToDouble();

for (var id in ids) {

  memberShares[id] =
      (memberShares[id] ?? 0) + perPerson;

}

  }

  _calculateSettlement();

  setState(() {});
}
void _calculateSettlement(){

  settlements.clear();

  // var admin =
  //     members.firstWhere((m) => m['isAdmin'] == 1);

  // String adminName = admin['name'];

  for(var m in members){

    if(m['isAdmin'] == 1) continue;

    int id = m['id'];

    double deposit = memberDeposits[id] ?? 0;
    double share = memberShares[id] ?? 0;

    double balance = deposit - share;

    if(balance > 0){

      settlements.add(
        "Admin pays ₹${balance.toStringAsFixed(0)} to ${m['name']}"
      );

    }

    if(balance < 0){

      settlements.add(
        "${m['name']} pays ₹${balance.abs().toStringAsFixed(0)} to Admin"
      );

    }

  }

}
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Settlement - ${widget.tripName}"),
        backgroundColor: Colors.teal,
      ),

      body: settlements.isEmpty

          ? Center(child: Text("No settlement required"))

          : ListView.builder(

        padding: EdgeInsets.all(16),

        itemCount: settlements.length,

        itemBuilder: (context,index){

          return Card(

            child: ListTile(

              leading: Icon(
                Icons.account_balance_wallet,
                color: Colors.teal,
              ),

              title: Text(settlements[index]),

            ),

          );

        },

      ),

    );

  }

}