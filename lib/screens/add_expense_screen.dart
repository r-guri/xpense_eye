import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../utils/app_toast.dart';
import 'add_member_screen.dart';
class AddExpenseScreen extends StatefulWidget {
  final int tripId;
  final String tripName;

  AddExpenseScreen({required this.tripId, required this.tripName});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController fromCtrl = TextEditingController();
  final TextEditingController toCtrl = TextEditingController();

  DateTime? travelDate;

  String? selectedCategory;

  List<String> categories = [];
  List<Map<String, dynamic>> members = [];

  List<int> selectedMembers = [];

  bool selectAll = false;

  int? adminId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadMembers();
    await _loadCategories();
  }

  Future<void> _loadMembers() async {
    var data = await DBHelper.instance.getAll(
      'members',
      where: 'tripId = ?',
      whereArgs: [widget.tripId],
    );

    setState(() {
      members = data;

      var admin = members.firstWhere(
        (m) => m['isAdmin'] == 1,
        orElse: () => {},
      );

      adminId = admin['id'];
    });
  }

  Future<void> _loadCategories() async {
    await DBHelper.instance.createCategoryTable();

    var data = await DBHelper.instance.getCategories(widget.tripId);

    if (data.isEmpty) {
      await DBHelper.instance.addDefaultCategories(widget.tripId);
      data = await DBHelper.instance.getCategories(widget.tripId);
    }

    setState(() {
      categories = data.map((c) => c['name'] as String).toList();

      if (categories.isNotEmpty) {
        selectedCategory ??= categories.first;
      }
    });
  }

  Future<void> _addExpense() async {

var members = await DBHelper.instance.getAll(
  'members',
  where: 'tripId = ?',
  whereArgs: [widget.tripId],
);

bool hasAdmin = members.any((m) => m['isAdmin'] == 1);

if (!hasAdmin) {

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Admin Required"),
      content: Text(
          "Please mark one member as Admin before adding expense."),
      actions: [

        TextButton(
          onPressed: () {

            Navigator.pop(context);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddMemberScreen(
                  tripId: widget.tripId,
                  tripName: widget.tripName,
                ),
              ),
            );

          },
          child: Text("OK"),
        ),

      ],
    ),
  );

  return;
}

    if (descCtrl.text.isEmpty ||
        amountCtrl.text.isEmpty ||
        selectedCategory == null) {
      AppToast.error(context, "Please fill all required fields");
      return;
    }

    if (travelDate == null) {
      AppToast.error(context, "Please select expense date");
      return;
    }

    if ((double.tryParse(amountCtrl.text) ?? 0) <= 0) {
      AppToast.error(context, "Amount must be greater than 0");
      return;
    }

    if (selectedMembers.isEmpty) {
      AppToast.error(context, "Please select members");
      return;
    }

    await DBHelper.instance.insert('expenses', {
      'tripId': widget.tripId,
      'description': descCtrl.text,
      'amount': double.tryParse(amountCtrl.text),
      'category': selectedCategory,
      'members': selectedMembers.join(','),
      'startLocation': fromCtrl.text,
      'endLocation': toCtrl.text,
      'travelDate': travelDate?.toIso8601String(),
      'addedBy': adminId,
    });

    descCtrl.clear();
    amountCtrl.clear();
    fromCtrl.clear();
    toCtrl.clear();
    selectedMembers.clear();
    travelDate = null;

    AppToast.success(context, "Expense added successfully!");

    setState(() {});
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => travelDate = picked);
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      prefixIcon: Icon(icon, color: Colors.teal),
fillColor: Theme.of(context).cardColor,

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Expense - ${widget.tripName}"),
        flexibleSpace: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.teal, Colors.tealAccent],
    ),
  ),
),
      ),

      body: ListView(
        padding: EdgeInsets.all(16),

        children: [
          /// FORM
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
                    "Add Expense Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,

                        decoration: _inputStyle("Category", Icons.category),
                      
                        items: categories
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),

                        onChanged: (val) =>
                            setState(() => selectedCategory = val),
                      ),
                    ),

                    SizedBox(width: 10),

                    IconButton(
                      icon: Icon(
                        Icons.add_circle,
                       color: Colors.teal,
                        size: 30,
                      ),

                      onPressed: () async {
                        TextEditingController catCtrl = TextEditingController();

                        await showDialog(
                          context: context,

                          builder: (context) {
                            return AlertDialog(
                              title: Text("Add Category"),

                              content: TextField(
                                controller: catCtrl,
                                decoration: InputDecoration(
                                  hintText: "Enter category name",
                                ),
                              ),

                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Cancel"),
                                ),

                                ElevatedButton(
                                  onPressed: () async {
                                    if (catCtrl.text.isNotEmpty) {
                                      await DBHelper.instance.addCategory(
                                        widget.tripId,
                                        catCtrl.text,
                                      );

                                      Navigator.pop(context);

                                      _loadCategories();
                                    }
                                  },

                                  child: Text("Add"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 12),

                TextField(
                  controller: descCtrl,
                  decoration: _inputStyle("Description", Icons.description),
                ),

                SizedBox(height: 12),

                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputStyle("Amount", Icons.currency_rupee),
                ),

                SizedBox(height: 12),

                /// EXPENSE DATE (FOR ALL CATEGORIES)
                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton.icon(
                    icon: Icon(Icons.date_range, color: Colors.teal),

                    label: Text(
                      travelDate == null
                          ? "Expense Date"
                          : travelDate!.toLocal().toString().split(' ')[0],  style: TextStyle(
                 color: Colors.teal
              ),
                    ),

                    onPressed: _pickDate,

                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.teal),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                /// TRAVEL EXTRA FIELDS
                if (selectedCategory == "Travel") ...[
                  SizedBox(height: 12),

                  TextField(
                    controller: fromCtrl,
                    decoration: _inputStyle("From", Icons.location_on),
                  ),

                  SizedBox(height: 12),

                  TextField(
                    controller: toCtrl,
                    decoration: _inputStyle("To", Icons.location_on),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 24),

          /// MEMBERS TITLE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                "Select Members",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),

              Text(
                "${selectedMembers.length}/${members.length}",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),

          Row(
            children: [
              Checkbox(
                value: selectAll,
                onChanged: (val) {
                  setState(() {
                    selectAll = val ?? false;

                    selectedMembers = selectAll
                        ? members.map((m) => m['id'] as int).toList()
                        : [];
                  });
                },
              ),

              Text("Select All"),
            ],
          ),

          SizedBox(height: 6),

          ...members.map((m) {
            bool selected = selectedMembers.contains(m['id']);

            return Container(
              margin: EdgeInsets.symmetric(vertical: 6),

              decoration: BoxDecoration(
               color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),

              child: CheckboxListTile(
                value: selected,

                secondary: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal),
                ),

                title: Text(
                  m['name'],
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                subtitle: Text(
                  "Mobile: ${m['mobile']} | Pay ₹${m['payAmount']}",
                ),

                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      selectedMembers.add(m['id']);
                    } else {
                      selectedMembers.remove(m['id']);
                    }

                    selectAll = selectedMembers.length == members.length;
                  });
                },
              ),
            );
          }),

          SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _addExpense,

            icon: Icon(Icons.add),

            label: Text("Add Expense"),

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
           SizedBox(height: 40),
        ],
      ),
    );
  }
}
