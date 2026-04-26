import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../utils/app_toast.dart';
import 'member_ledger_screen.dart';
import '../utils/app_strings.dart';

class AddMemberScreen extends StatefulWidget {
  final int tripId;
  final String tripName;

  AddMemberScreen({required this.tripId, required this.tripName});

  @override
  _AddMemberScreenState createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController mobileCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController payCtrl = TextEditingController();

  bool isAdmin = false;
  int? editingMemberId;
  bool adminExists = false;
  bool isChanged = false;
  List<Map<String, dynamic>> members = [];
  bool get isEditingAdmin {
    if (editingMemberId == null) return false;

    return members.any((m) => m['id'] == editingMemberId && m['isAdmin'] == 1);
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    var data = await DBHelper.instance.getAll(
      'members',
      where: 'tripId = ?',
      whereArgs: [widget.tripId],
    );

    setState(() {
      members = data;
      adminExists = members.any((m) => m['isAdmin'] == 1);
    });
  }

  Future<void> _saveMember() async {
    if (nameCtrl.text.trim().isEmpty) {
      AppToast.error(context, AppStrings.get("name_required"));
      return;
    }

    // if (mobileCtrl.text.trim().isEmpty) {
    //   AppToast.error(context, "Mobile No is required!");
    //   return;
    // }

    if (payCtrl.text.trim().isEmpty) {
      AppToast.error(context, AppStrings.get("pay_amount_required"));
      return;
    }

    double payAmount = double.tryParse(payCtrl.text) ?? -1;

    if (payAmount < 0) {
      AppToast.error(context, AppStrings.get("valid_pay_amount"));
      return;
    }
    FocusScope.of(context).requestFocus(FocusNode());
    int adminValue = 0;

    if (isAdmin && !adminExists) {
      adminValue = 1;
    }

    if (editingMemberId == null) {
      await DBHelper.instance.insert('members', {
        'tripId': widget.tripId,
        'name': nameCtrl.text.trim(),
        'mobile': mobileCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'payAmount': payAmount,
        'isAdmin': adminValue,
      });
    } else {
      await DBHelper.instance.update(
        'members',
        {
          'name': nameCtrl.text.trim(),
          'mobile': mobileCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'payAmount': payAmount,
          'isAdmin': isAdmin ? 1 : 0,
        },
        'id = ?',
        [editingMemberId],
      );
    }

    nameCtrl.clear();
    mobileCtrl.clear();
    emailCtrl.clear();
    payCtrl.clear();
    editingMemberId = null;
    isAdmin = false;
    isChanged = true;
    await _loadMembers();
    AppToast.success(context, AppStrings.get("member_saved"));
  }

  int? get adminExistsId {
    var admin = members.firstWhere((m) => m['isAdmin'] == 1, orElse: () => {});

    if (admin.isNotEmpty) return admin['id'];

    return null;
  }

  Future<void> _deleteMember(int id) async {
    await DBHelper.instance.delete('members', 'id = ?', [id]);
    isChanged = true; // 🔥 ADD THIS
    await _loadMembers();
  }

  void _editMember(Map<String, dynamic> member) {
    nameCtrl.text = member['name'];
    mobileCtrl.text = member['mobile'];
    emailCtrl.text = member['email'];
    payCtrl.text = member['payAmount'].toString();

    editingMemberId = member['id'];
    isAdmin = member['isAdmin'] == 1;

    setState(() {});
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(icon, color: Colors.teal),
      fillColor: Theme.of(context).cardColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
  onWillPop: () async {
    Navigator.pop(context, isChanged); // 🔥 send result
    return false;
  },
  child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("${AppStrings.get("members")} - ${widget.tripName}"),
        leading: BackButton(
    onPressed: () {
      Navigator.pop(context, isChanged);
    },
  ),
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
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: ListView(
          padding: EdgeInsets.all(16),

          children: [
            /// FORM
            ///
            Container(
              padding: EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),

              child: Column(
                children: [
                  Text(
                    AppStrings.get("add_member_details"),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: _inputStyle(
                      "${AppStrings.get("name")} *",
                      Icons.person,
                    ),
                  ),

                  SizedBox(height: 12),

                  TextField(
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputStyle(
                      AppStrings.get("mobile"),
                      Icons.phone,
                    ),
                  ),

                  SizedBox(height: 12),

                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputStyle(
                      AppStrings.get("email"),
                      Icons.email,
                    ),
                  ),

                  SizedBox(height: 12),

                  TextField(
                    controller: payCtrl,
                    enabled: editingMemberId == null, // edit time disable
                    keyboardType: TextInputType.number,
                    decoration: _inputStyle(
                      "${AppStrings.get("pay_amount")} *",
                      Icons.currency_rupee,
                    ),
                  ),

                  Row(
                    children: [
                      Checkbox(
                        value: isAdmin,
                        onChanged: adminExists
                            ? null
                            : (val) {
                                setState(() {
                                  isAdmin = val!;
                                });
                              },
                      ),

                      Text(
                        adminExists && !isEditingAdmin
                            ? AppStrings.get("admin_marked")
                            : AppStrings.get("admin"), // 🔥 FIX
                        style: TextStyle(
                          color: adminExists && !isEditingAdmin
                              ? Colors.red
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      onPressed: _saveMember,

                      icon: Icon(Icons.save),

                      label: Text(
                        editingMemberId == null
                            ? AppStrings.get("add_member")
                            : "Save Changes",
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            Text(
              AppStrings.get("all_members"),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),

            SizedBox(height: 12),

            ...members.map(
              (m) => Container(
                margin: EdgeInsets.symmetric(vertical: 6),

                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),

                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(Icons.person, color: Colors.teal),
                  ),

                  title: Row(
                    children: [
                      Expanded(child: Text(m['name'])),

                      if (m['isAdmin'] == 1)
                        Icon(Icons.star, color: Colors.orange, size: 18),
                    ],
                  ),

                  subtitle: Text(
                    "${AppStrings.get("mobile")}: ${m['mobile']} | ${AppStrings.get("pay")} ₹${m['payAmount']}",
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "ledger",
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(AppStrings.get("ledger")),
                          ],
                        ),
                      ),

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
                      if (value == "ledger") {
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
                      }

                      if (value == "edit") {
                        _editMember(m);
                      }

                      if (value == "delete") {
                        _deleteMember(m['id']);
                      }
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    ),
    );
  }
}
