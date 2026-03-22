import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'report_screen.dart';

class SummaryScreen extends StatefulWidget {
  final int tripId;
  final String tripName;

  SummaryScreen({required this.tripId, required this.tripName});

  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String selectedFilter = "All";

  void _deleteExpense(int index) {
    var box = Hive.box('expenses');
    box.deleteAt(index);
    setState(() {});
  }

  void _editExpense(int index, Map expense) {
    TextEditingController descCtrl =
        TextEditingController(text: expense['description']);
    TextEditingController amountCtrl =
        TextEditingController(text: expense['amount'].toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Edit Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              child: Text("Save"),
              onPressed: () {
                var box = Hive.box('expenses');
                box.putAt(index, {
                  'category': expense['category'],
                  'description': descCtrl.text,
                  'amount': double.tryParse(amountCtrl.text) ?? expense['amount'],
                  'tripId': expense['tripId'],
                  'tripName': expense['tripName'],
                  'members': expense['members'],
                });
                setState(() {});
                Navigator.pop(ctx);
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('expenses');
    var expenses = box.values.where((e) => e['tripId'] == widget.tripId).toList();

    // Apply filter
    var filteredExpenses = selectedFilter == "All"
        ? expenses
        : expenses.where((e) => e['category'] == selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Expense Summary")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Filter:", style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: selectedFilter,
                  items: ["All", "Travel", "Food"]
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedFilter = val!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),

            // Expense List
            Expanded(
              child: filteredExpenses.isEmpty
                  ? Center(child: Text("No expenses found"))
                  : ListView.builder(
                      itemCount: filteredExpenses.length,
                      itemBuilder: (ctx, index) {
                        var e = filteredExpenses[index];
                        int realIndex = box.values.toList().indexOf(e);

                        return Card(
                          child: ListTile(
                            leading: Icon(Icons.receipt_long),
                            title: Text(e['description']),
                            subtitle: Text(
                                "Category: ${e['category']} | Amount: \$${e['amount']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editExpense(realIndex, e),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteExpense(realIndex),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Generate Report Button
              ElevatedButton.icon(
                icon: Icon(Icons.picture_as_pdf),
                label: Text("Generate Report"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () {
                Navigator.push(
  context,
  MaterialPageRoute(
    builder: (ctx) => ReportScreen(
      tripId: widget.tripId,    // Pass the tripId
      tripName: widget.tripName, // Pass the tripName
    ),
  ),
);

                },
              )
          ],
        ),
      ),
    );
  }
}
