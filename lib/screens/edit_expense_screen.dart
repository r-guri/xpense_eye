import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../utils/app_toast.dart';

class EditExpenseScreen extends StatefulWidget {

  final Map expense;

  EditExpenseScreen({required this.expense});

  @override
  _EditExpenseScreenState createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {

  TextEditingController descCtrl = TextEditingController();
  TextEditingController amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    descCtrl.text = widget.expense['description'];
    amountCtrl.text = widget.expense['amount'].toString();
  }

  Future<void> _updateExpense() async {

    await DBHelper.instance.update(
      'expenses',
      {
        'description': descCtrl.text,
        'amount': double.parse(amountCtrl.text),
      },
      'id = ?',
      [widget.expense['id']],
    );

    AppToast.success(context, "Expense updated");

    Navigator.pop(context,true);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Edit Expense"),
        backgroundColor: Colors.teal,
      ),

      body: Padding(

        padding: EdgeInsets.all(20),

        child: Column(

          children: [

            TextField(
              controller: descCtrl,
              decoration: InputDecoration(labelText: "Description"),
            ),

            SizedBox(height:10),

            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Amount"),
            ),

            SizedBox(height:20),

            ElevatedButton(

              onPressed: _updateExpense,

              child: Text("Update"),

            )

          ],

        ),

      ),

    );

  }
}