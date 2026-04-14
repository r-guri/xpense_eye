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

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 30,
              ),

              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Center(
                      child: Text(
                        AppStrings.get("edit_expense"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// CATEGORY
                    DropdownButtonFormField<String>(
                      value: category,

                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// AMOUNT
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.get("amount"),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// DATE
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            travelDate == null
                                ? "Select Date"
                                : DateFormat("dd-MM-yyyy").format(travelDate!),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.date_range),

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
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// SHOW ONLY IF TRAVEL CATEGORY
                    if (category.toLowerCase() == "travel") ...[
                      TextField(
                        controller: fromCtrl,
                        decoration: const InputDecoration(
                          labelText: "From Location",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: toCtrl,
                        decoration: const InputDecoration(
                          labelText: "To Location",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),
                    ],

                    /// MEMBERS
                    const Text(
                      "Members",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    ...members.map((m) {
                      bool checked = selectedMembers.contains(m['id']);

                      return CheckboxListTile(
                        value: checked,

                        title: Text(m['name']),

                        onChanged: (val) {
                          setModal(() {
                            if (val == true) {
                              selectedMembers.add(m['id']);
                            } else {
                              selectedMembers.remove(m['id']);
                            }
                          });
                        },
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    /// UPDATE BUTTON
                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                          style: TextStyle(color: Colors.white),
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

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Text(
                    AppStrings.get("select_members"),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

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

                  SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(AppStrings.get("ok")),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal, Colors.teal]),
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

                const SizedBox(height: 16),

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

                const SizedBox(height: 20),

                Text(
                  AppStrings.get("member_expense_details"),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(height: 10),

                _memberTable(),

                const SizedBox(height: 20),

                Text(
                  AppStrings.get("expense_list"),
                  style: TextStyle(
                    fontSize: 18,
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
                                fontSize: 16,
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
            duration: Duration(milliseconds: 250), // 🔥 smooth fade

            child: IgnorePointer(
              ignoring: !isLoading, // 👈 clicks disable only when loading

              child: Container(
                color: Colors.black.withOpacity(0.1), // 🔥 softer

                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.teal),
                        SizedBox(height: 10),
                        Text(
                          "Loading...",
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.black,
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
