import 'package:flutter/material.dart';
import '../db_helper.dart';
import 'add_member_screen.dart';

class CreateTripScreen extends StatefulWidget {
  @override
  _CreateTripScreenState createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController descCtrl = TextEditingController();
  TextEditingController locationCtrl = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  final DBHelper dbHelper = DBHelper.instance; // ✅ Use singleton instance

  Future<void> _createTrip() async {
    if (nameCtrl.text.isEmpty) return;

    int id = await dbHelper.insert('trips', {
      'name': nameCtrl.text,
      'description': descCtrl.text,
      'location': locationCtrl.text,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddMemberScreen(
          tripId: id,
          tripName: nameCtrl.text,
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Trip")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: "Trip Name"),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(labelText: "Description"),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(labelText: "Location"),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        child: Text(
                          startDate == null
                              ? "Start Date"
                              : startDate!.toLocal().toString().split(' ')[0],style: TextStyle(
                 color: Colors.teal
              ),
                     ),
                        onPressed: () => _pickDate(isStart: true),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        child: Text(
                          endDate == null
                              ? "End Date"
                              : endDate!.toLocal().toString().split(' ')[0],style: TextStyle(
                 color: Colors.teal
              ),
                        ),
                        onPressed: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text("Create Trip"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: _createTrip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
