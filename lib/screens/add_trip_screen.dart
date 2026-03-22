import 'package:flutter/material.dart';
import '../db_helper.dart';
import '../utils/app_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTripScreen extends StatefulWidget {
  final int userId;
  AddTripScreen({required this.userId});

  @override
  _AddTripScreenState createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController destCtrl = TextEditingController();

  DateTime? startDate, endDate;

  bool _isLoading = false;

  Future<void> _pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart)
          startDate = picked;
        else
          endDate = picked;
      });
    }
  }

  Future<void> _saveTrip() async {
    if (nameCtrl.text.isEmpty ||
        destCtrl.text.isEmpty ||
        startDate == null ||
        endDate == null) {
      AppToast.error(context, "Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DBHelper.instance.insert('trips', {
        'userId': widget.userId,
        'name': nameCtrl.text,
        'destination': destCtrl.text,
        'startDate': startDate!.toIso8601String(),
        'endDate': endDate!.toIso8601String(),
      });

      /// 2️⃣ Supabase insert (backup only)
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('trips').insert({
          'name': nameCtrl.text,
          'destination': destCtrl.text,
          'start_date': startDate!.toIso8601String(),
          'end_date': endDate!.toIso8601String(),
          'user_id': widget.userId,
        });
      } catch (e) {}
      AppToast.success(context, "Trip added successfully!");
      await Future.delayed(Duration(seconds: 2));

      Navigator.pop(context, true);
    } catch (e) {
      AppToast.error(context, "Error adding trip: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(icon, color: Colors.teal),

      filled: true,

      // fillColor: Colors.white,
      fillColor: Theme.of(context).cardColor,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
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
        title: Text("Create Expense"),

        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent.shade400],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),

        child: Column(
          children: [
            /// FORM CARD
            Container(
              padding: EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,

                borderRadius: BorderRadius.circular(16),

                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  Text(
                    "Expense Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),

                  SizedBox(height: 20),

                  /// NAME / TITLE
                  TextField(
                    controller: nameCtrl,
                    decoration: _inputStyle(
                      "Name / Title", // Replace "Trip Name" style with generic
                      Icons
                          .drive_file_rename_outline, // Icon for generic name/title
                    ),
                  ),

                  SizedBox(height: 16),

                  /// DESCRIPTION
                  TextField(
                    controller: destCtrl,
                    decoration: _inputStyle(
                      "Description", // Spelling fix + generic text
                      Icons.note_alt_outlined, // Icon for description/note
                    ),
                  ),
                  SizedBox(height: 18),

                  /// DATE BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(true),

                          icon: Icon(Icons.date_range, color: Colors.teal),

                          label: Text(
                            startDate == null
                                ? "Start Date"
                                : startDate!.toLocal().toString().split(' ')[0],
                            style: TextStyle(color: Colors.teal),
                          ),

                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.teal),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDate(false),

                          icon: Icon(Icons.date_range, color: Colors.teal),

                          label: Text(
                            endDate == null
                                ? "End Date"
                                : endDate!.toLocal().toString().split(' ')[0],
                            style: TextStyle(color: Colors.teal),
                          ),

                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.teal),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  /// SAVE BUTTON
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveTrip,

                    icon: _isLoading
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.save),

                    label: Text(_isLoading ? "Saving..." : "Save"),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,

                      foregroundColor: Colors.white,

                      padding: EdgeInsets.symmetric(vertical: 16),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),

                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
