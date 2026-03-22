import 'package:flutter/material.dart';
import '../db_helper.dart';
import 'add_member_screen.dart';

class TripScreen extends StatefulWidget {
  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final _formKey = GlobalKey<FormState>();
  String tripName = '';
  String destination = '';

  Future<void> _saveTrip() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      int id = await DBHelper.instance.insert('trips', {
        'name': tripName,
        'destination': destination,
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddMemberScreen(tripId: id, tripName: tripName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Trip')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Trip Name'),
                validator: (v) => v!.isEmpty ? 'Enter trip name' : null,
                onSaved: (v) => tripName = v!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Destination'),
                validator: (v) => v!.isEmpty ? 'Enter destination' : null,
                onSaved: (v) => destination = v!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Save & Continue'),
                onPressed: _saveTrip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
