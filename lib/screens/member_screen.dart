import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'category_screen.dart';

class MemberScreen extends StatefulWidget {
  final int tripId;
  final String tripName;

  MemberScreen({required this.tripId, required this.tripName});

  @override
  _MemberScreenState createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final _formKey = GlobalKey<FormState>();
  String memberName = "";

  @override
  Widget build(BuildContext context) {
    var memberBox = Hive.box('members');
    var members = memberBox.values.where((m) => m['tripId'] == widget.tripId).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Add Members")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: "Member Name"),
                      validator: (value) => value!.isEmpty ? "Enter name" : null,
                      onSaved: (value) => memberName = value!,
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    child: Text("Add"),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        memberBox.add({
                          'name': memberName,
                          'tripId': widget.tripId,
                          'tripName': widget.tripName,
                        });
                        setState(() {});
                        _formKey.currentState!.reset();
                      }
                    },
                  )
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (ctx, index) {
                  var member = members[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.teal),
                      title: Text(member['name']),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          memberBox.deleteAt(index);
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              child: Text("Continue to Categories"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => CategoryScreen(
                      tripId: widget.tripId,
                      tripName: widget.tripName,
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
