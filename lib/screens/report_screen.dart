import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../utils/pdf_generator.dart';
import '../utils/app_toast.dart';
import '../utils/app_config.dart';
import 'package:intl/intl.dart';
import 'settlement_screen.dart';
import 'member_ledger_screen.dart';
import 'ads/banner_ad_widget.dart';
import 'ads/ad_helper.dart';
import 'services/purchase_service.dart';
// import 'services/rating_service.dart';
import '../utils/app_strings.dart';

class ReportScreen extends StatefulWidget {
  final int tripId;
  final String tripName;

  const ReportScreen({required this.tripId, required this.tripName});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

String formatDate(String? date) {
  if (date == null || date.isEmpty) return "";
  DateTime d = DateTime.parse(date);
  return DateFormat("dd-MM-yyyy").format(d);
}

class _ReportScreenState extends State<ReportScreen> {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> members = [];
  List<String> categories = [];

  Map<int, double> memberShares = {};
  Map<int, double> memberDeposits = {};
  Map<int, double> memberSpent = {};
  List<int> selectedMembers = [];
  bool selectAll = true;

  double totalTripExpense = 0;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  /// LOAD DATA
  Future<void> _loadReport() async {
    setState(() => isLoading = true); // 🔥 START LOADER
    final results = await Future.wait([
      DBHelper.instance.getAll(
        'expenses',
        where: 'tripId = ?',
        whereArgs: [widget.tripId],
        orderBy: 'id DESC',
      ),

      DBHelper.instance.getAll(
        'members',
        where: 'tripId = ?',
        whereArgs: [widget.tripId],
      ),

      DBHelper.instance.getCategories(widget.tripId),
    ]);

    expenses = List<Map<String, dynamic>>.from(results[0]);
    members = List<Map<String, dynamic>>.from(results[1]);
    var cats = results[2];

    categories = cats.map((c) => c['name'] as String).toList();

    memberDeposits.clear();

    /// MEMBER INITIAL + LEDGER

    for (var m in members) {
      double initialPay = (m['payAmount'] ?? 0).toDouble();

      double ledgerDeposit = await DBHelper.instance.getMemberDeposit(
        widget.tripId,
        m['id'],
      );

      double ledgerWithdraw = await DBHelper.instance.getMemberWithdraw(
        widget.tripId,
        m['id'],
      );

      memberDeposits[m['id']] = initialPay + ledgerDeposit - ledgerWithdraw;
    }

    /// ADMIN EXPENSE = ADMIN DEPOSIT

    for (var e in expenses) {
      int? paidBy = e['addedBy'];

      double amount = (e['amount'] ?? 0).toDouble();

      if (paidBy != null) {
        memberDeposits[paidBy] = (memberDeposits[paidBy] ?? 0) + amount;
      }
    }

    totalTripExpense = expenses.fold(
      0.0,
      (sum, e) => sum + ((e['amount'] ?? 0).toDouble()),
    );

    _calculateShares();

    if (selectAll) {
      selectedMembers = members.map((m) => m['id'] as int).toList();
    }
    setState(() => isLoading = false); // 🔥 END LOADER
  }
  // Future<void> _loadReport() async {

  //   expenses = await DBHelper.instance.getAll(
  //     'expenses',
  //     where:'tripId = ?',
  //     whereArgs:[widget.tripId],
  //     orderBy:'COALESCE(travelDate, createdAt) DESC',
  //   );

  //   members = await DBHelper.instance.getAll(
  //     'members',
  //     where:'tripId = ?',
  //     whereArgs:[widget.tripId],
  //   );

  //   var cats = await DBHelper.instance.getCategories(widget.tripId);
  //   categories = cats.map((c)=>c['name'] as String).toList();

  //   memberDeposits.clear();

  //   for(var m in members){

  //     double initialPay = (m['payAmount'] ?? 0).toDouble();

  //     double ledgerDeposit =
  //     await DBHelper.instance.getMemberDeposit(widget.tripId, m['id']);

  //     double ledgerWithdraw =
  //     await DBHelper.instance.getMemberWithdraw(widget.tripId, m['id']);

  //     memberDeposits[m['id']] =
  //         initialPay + ledgerDeposit - ledgerWithdraw;

  //   }

  //   totalTripExpense = expenses.fold(
  //       0.0,
  //           (sum,e)=>sum + ((e['amount'] ?? 0).toDouble())
  //   );

  //   _calculateShares();

  //   if(selectAll){
  //     selectedMembers = members.map((m)=>m['id'] as int).toList();
  //   }

  //   setState((){});

  // }

  /// SHARE CALCULATION

  void _calculateShares() {
    memberSpent.clear();

    for (var m in members) {
      memberSpent[m['id']] = 0;
    }
    memberShares.clear();

    for (var m in members) {
      memberShares[m['id']] = 0;
    }
    for (var e in expenses) {
      int? paidBy = e['addedBy'];
      double amount = (e['amount'] ?? 0).toDouble();

      if (paidBy != null) {
        memberSpent[paidBy] = (memberSpent[paidBy] ?? 0) + amount;
      }
    }
    for (var e in expenses) {
      if (e['members'] == null || e['members'].toString().isEmpty) continue;

      List<int> ids = e['members']
          .toString()
          .split(',')
          .map((s) => int.tryParse(s) ?? 0)
          .toList();

      double amount = (e['amount'] ?? 0).toDouble();

      double perPerson = (amount / ids.length).ceilToDouble();

      for (var id in ids) {
        memberShares[id] = (memberShares[id] ?? 0) + perPerson;
      }
    }
  }

  /// DELETE EXPENSE

  Future<void> _deleteExpense(int id) async {
    bool? confirm = await showDialog(
      context: context,

      builder: (context) => AlertDialog(
        title: const Text("Delete Expense"),

        content: const Text("Are you sure you want to delete this expense?"),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DBHelper.instance.delete('expenses', 'id = ?', [id]);

      AppToast.success(context, AppStrings.get("expense_deleted"));

      _loadReport();
    }
  }

  /// EDIT EXPENSE

  Future<void> _editExpense(Map expense) async {
    TextEditingController descCtrl = TextEditingController(
      text: expense['description'],
    );

    TextEditingController amountCtrl = TextEditingController(
      text: expense['amount'].toString(),
    );

    TextEditingController fromCtrl = TextEditingController(
      text: expense['startLocation'],
    );

    TextEditingController toCtrl = TextEditingController(
      text: expense['endLocation'],
    );

    DateTime? travelDate;

    if (expense['travelDate'] != null) {
      travelDate = DateTime.tryParse(expense['travelDate']);
    }

    String category = expense['category'] ?? categories.first;

    List<int> selectedMembers = [];

    if (expense['members'] != null &&
        expense['members'].toString().isNotEmpty) {
      selectedMembers = expense['members']
          .toString()
          .split(',')
          .map((e) => int.parse(e))
          .toList();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔥 TOP HANDLE
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// 🔥 TITLE
                    Center(
                      child: Text(
                        AppStrings.get("edit_expense"),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// CATEGORY
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: InputDecoration(
                        labelText: AppStrings.get("category"),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) {
                        setModal(() => category = v!);
                      },
                    ),

                    const SizedBox(height: 12),

                    /// DESCRIPTION
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.get("description"),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// AMOUNT
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: "₹ ",
                        labelText: AppStrings.get("amount"),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// DATE CARD STYLE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              travelDate == null
                                  ? AppStrings.get("select_date")
                                  : DateFormat(
                                      "dd MMM yyyy",
                                    ).format(travelDate!),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: travelDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setModal(() => travelDate = picked);
                              }
                            },
                            child: Text(AppStrings.get("change")),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// TRAVEL EXTRA
                    if (category.toLowerCase() == "travel") ...[
                      TextField(
                        controller: fromCtrl,
                        decoration: InputDecoration(
                          labelText: "From",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: toCtrl,
                        decoration: InputDecoration(
                          labelText: "To",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],

                    /// MEMBERS TITLE
                    const Text(
                      "Members",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// MEMBERS LIST
                    ...members.map((m) {
                      bool checked = selectedMembers.contains(m['id']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.withOpacity(0.05),
                        ),
                        child: CheckboxListTile(
                          value: checked,
                          title: Text(m['name']),
                          activeColor: Colors.teal,
                          onChanged: (val) {
                            setModal(() {
                              if (val == true) {
                                selectedMembers.add(m['id']);
                              } else {
                                selectedMembers.remove(m['id']);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    /// 🔥 UPDATE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          await DBHelper.instance.update(
                            'expenses',
                            {
                              'description': descCtrl.text,
                              'amount': double.tryParse(amountCtrl.text),
                              'category': category,
                              'startLocation': fromCtrl.text,
                              'endLocation': toCtrl.text,
                              'travelDate': travelDate?.toIso8601String(),
                              'members': selectedMembers.join(','),
                            },
                            'id = ?',
                            [expense['id']],
                          );

                          Navigator.pop(context);

                          AppToast.success(
                            context,
                            AppStrings.get("expense_updated"),
                          );

                          _loadReport();
                        },
                        child: Text(
                          AppStrings.get("update_expense"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// MEMBER SELECT

  void _openMemberSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 🔥 IMPORTANT
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    16, // 🔥 FIX
              ),

              child: SingleChildScrollView(
                // 🔥 IMPORTANT
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    /// TITLE
                    Text(
                      AppStrings.get("select_members"),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// SELECT ALL
                    CheckboxListTile(
                      value: selectAll,

                      title: Text(AppStrings.get("all_members")),
                      onChanged: (val) {
                        setModalState(() {
                          selectAll = val!;

                          if (selectAll) {
                            selectedMembers = members
                                .map((m) => m['id'] as int)
                                .toList();
                          } else {
                            selectedMembers.clear();
                          }
                        });

                        setState(() {});
                      },
                    ),

                    const Divider(),

                    /// MEMBERS LIST
                    ...members.map((m) {
                      bool selected = selectedMembers.contains(m['id']);

                      return CheckboxListTile(
                        value: selected,
                        title: Text(m['name']),
                        onChanged: (val) {
                          setModalState(() {
                            selectAll = false;

                            if (val == true) {
                              selectedMembers.add(m['id']);
                            } else {
                              selectedMembers.remove(m['id']);
                            }
                          });

                          setState(() {});
                        },
                      );
                    }).toList(),

                    const SizedBox(height: 10),

                    /// BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(AppStrings.get("ok")),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// PDF
  Future<void> _downloadPDF() async {
    if (AppConfig.enableAds && !PurchaseService.isAdsRemoved) {
      AdHelper.showInterstitialAd(
        onAdClosed: () async {
          await _generatePDF();
        },
      );
    } else {
      await _generatePDF();
    }
  }

  Future<void> _generatePDF() async {
    setState(() => isLoading = true); // 🔥 START LOADER
    List<Map<String, dynamic>> selectedList;

    if (selectAll) {
      selectedList = members;
    } else {
      selectedList = members
          .where((m) => selectedMembers.contains(m['id']))
          .toList();
    }

    if (selectedList.isEmpty) {
      setState(() => isLoading = false); // ❗ important
      AppToast.error(context, AppStrings.get("select_members_first"));
      return;
    }

    await generateTripReportPDF(
      tripName: widget.tripName,
      members: selectedList,
      expenses: expenses,
      totalExpense: totalTripExpense,
      allMembers: members,
    );
    setState(() => isLoading = false); // 🔥 END LOADER
    AppToast.success(context, AppStrings.get("pdf_downloaded"));
  }
  // Future<void> _downloadPDF() async {
  // AdHelper.showInterstitialAd();// 🔥 add this
  //   List<Map<String, dynamic>> selectedList;

  //   if (selectAll) {
  //     selectedList = members;
  //   } else {
  //     selectedList = members
  //         .where((m) => selectedMembers.contains(m['id']))
  //         .toList();
  //   }

  //   if (selectedList.isEmpty) {
  //     AppToast.error(context, "Select members first!");
  //     return;
  //   }

  //   await generateTripReportPDF(
  //     tripName: widget.tripName,

  //     members: selectedList,

  //     expenses: expenses,

  //     totalExpense: totalTripExpense,

  //     allMembers: members,
  //   );

  //   AppToast.success(context, "PDF downloaded successfully!");
  // }

  /// MEMBER TABLE

  Widget _memberTable() {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),

      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          child: DataTable(
            columnSpacing: 20,

            columns: [
              DataColumn(label: Text(AppStrings.get("person"))),
              DataColumn(label: Text(AppStrings.get("deposit"))),
              DataColumn(label: Text(AppStrings.get("spent"))),
              DataColumn(label: Text(AppStrings.get("share"))),
              DataColumn(label: Text(AppStrings.get("balance"))),
            ],

            rows: members.map((m) {
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
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      m['isAdmin'] == 1 ? "${m['name']} ⭐" : m['name'],
                      style: TextStyle(
                        fontWeight: m['isAdmin'] == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemberLedgerScreen(
                            memberId: m['id'],
                            memberName: m['name'],
                            tripId: widget.tripId,
                          ),
                        ),
                      );
                    },
                  ),
                  DataCell(Text("₹${deposit.toStringAsFixed(0)}")),
                  DataCell(Text("₹${spent.toStringAsFixed(0)}")),
                  DataCell(Text("₹${share.toStringAsFixed(0)}")),
                  DataCell(
                    Text(
                      "₹${balance.toStringAsFixed(0)}",

                      style: TextStyle(
                        color: balance >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text("${widget.tripName}"),

        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [Colors.grey.shade900, Colors.grey.shade900]
                  : [Colors.teal, Colors.teal],
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          /// 🔥 MAIN UI (always visible)
          RefreshIndicator(
            onRefresh: _loadReport,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: BouncingScrollPhysics(),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openMemberSelector,
                        icon: const Icon(Icons.people, color: Colors.teal),
                        label: Text(
                          AppStrings.get("members"),
                          style: TextStyle(color: Colors.teal),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadPDF,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(AppStrings.get("pdf")),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// SETTLEMENT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => isLoading = true); // 🔥 start loader

                      await Future.delayed(
                        Duration(milliseconds: 200),
                      ); // 👈 smooth feel

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettlementScreen(
                            tripId: widget.tripId,
                            tripName: widget.tripName,
                          ),
                        ),
                      );

                      setState(
                        () => isLoading = false,
                      ); // 🔥 back aake loader off
                    },
                    icon: const Icon(Icons.account_balance_wallet),
                    label: Text(AppStrings.get("view_settlement")),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  AppStrings.get("member_expense_details"),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(height: 10),

                _memberTable(),

                const SizedBox(height: 10),

                Text(
                  AppStrings.get("expense_list"),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(height: 10),

                ListView.builder(
                  itemCount: expenses.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(), // important

                  itemBuilder: (context, index) {
                    var e = expenses[index];
                    String date = formatDate(e['travelDate']);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(Icons.currency_rupee, color: Colors.teal),
                        ),
                        title: Text(e['description'] ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['category'] ?? ""),
                            if (date.isNotEmpty)
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "₹${(e['amount'] ?? 0).toStringAsFixed(0)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.teal,
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: "edit",
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(AppStrings.get("edit")),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: "delete",
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(AppStrings.get("delete")),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == "edit") _editExpense(e);
                                if (value == "delete") _deleteExpense(e['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                if (AppConfig.enableAds && !PurchaseService.isAdsRemoved)
                  BannerAdWidget(),

                const SizedBox(height: 20),
              ],
            ),
          ),

          /// 🔥 TRANSPARENT LOADER
          AnimatedOpacity(
            opacity: isLoading ? 1 : 0,
            duration: const Duration(milliseconds: 250),

            child: IgnorePointer(
              ignoring: !isLoading,

              child: Container(
                color: Colors.black.withOpacity(0.15),

                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.teal),
                        const SizedBox(height: 10),
                        Text(
                          "Loading...",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
