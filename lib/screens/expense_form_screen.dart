import 'package:flutter/material.dart';
import '../db_helper.dart';
import 'summary_screen.dart';

class ExpenseFormScreen extends StatefulWidget {
  final String category;
  final int tripId;
  final String tripName;

  ExpenseFormScreen({
    required this.category,
    required this.tripId,
    required this.tripName,
  });

  @override
  _ExpenseFormScreenState createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String description = "";
  double amount = 0;
  bool splitWithAll = true; // ✅ New checkbox state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.category} Expense"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Category: ${widget.category}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter description" : null,
                onSaved: (value) => description = value!,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "Enter amount" : null,
                onSaved: (value) => amount = double.parse(value!),
              ),
              SizedBox(height: 16),

              // ✅ Checkbox for "Split with all members"
              Row(
                children: [
                  Checkbox(
                    value: splitWithAll,
                    onChanged: (val) => setState(() => splitWithAll = val!),
                  ),
                  Expanded(
                    child: Text(
                      "Split expense with all members",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("Save Expense"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    // If splitWithAll is true, assign all member IDs
                    String assignedMembers = '';
                    if (splitWithAll) {
                      var members = await DBHelper.instance.getAll(
                        'members',
                        where: 'tripId = ?',
                        whereArgs: [widget.tripId],
                      );
                      assignedMembers =
                          members.map((m) => m['id'].toString()).join(',');
                    }

                    // Insert into SQLite
                    await DBHelper.instance.insert('expenses', {
                      'tripId': widget.tripId,
                      'description': description,
                      'amount': amount,
                      'category': widget.category,
                      'members': assignedMembers, // store member IDs
                      'createdAt': DateTime.now().toIso8601String(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Expense added successfully!"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    Future.delayed(Duration(seconds: 1), () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => SummaryScreen(
                            tripId: widget.tripId,
                            tripName: widget.tripName,
                          ),
                        ),
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
