import 'package:flutter/material.dart';
import 'expense_form_screen.dart';

class CategoryScreen extends StatelessWidget {
  final int tripId;
  final String tripName;

  CategoryScreen({required this.tripId, required this.tripName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Category")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CategoryCard(
              title: "Travel",
              icon: Icons.directions_bus,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ExpenseFormScreen(
                      category: "Travel",
                      tripId: tripId,
                      tripName: tripName,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            CategoryCard(
              title: "Food",
              icon: Icons.fastfood,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ExpenseFormScreen(
                      category: "Food",
                      tripId: tripId,
                      tripName: tripName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  CategoryCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal, size: 30),
        title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
