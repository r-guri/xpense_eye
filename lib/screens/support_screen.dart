import 'package:flutter/material.dart';
import '../utils/app_info.dart';
class SupportScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Support"),
        backgroundColor: Colors.teal,
      ),

      body: Padding(
        padding: EdgeInsets.all(16),

        child: ListView(

          children: [

            Text(
              "Need Help?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "If you face any issue while using "+AppInfo.appName+" or have suggestions to improve the app, feel free to contact us."
            ),

            SizedBox(height: 20),

            Text(
              "Support Email",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 6),

            Container(
              padding: EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),

              child: Row(
                children: [

                  Icon(Icons.email, color: Colors.teal),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      AppInfo.developerEmail,
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                ],
              ),
            ),

            SizedBox(height: 20),

            Text(
              "Response Time",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 6),

            Text(
              "We usually respond within 24-48 hours."
            ),

            SizedBox(height: 25),

            Divider(),

            SizedBox(height: 10),

            Text(
              "Developer",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 6),

            Text(AppInfo.developerName),

            SizedBox(height: 6),

            Text(
              AppInfo.appName+" is designed to help users easily manage trip expenses and track deposits during tours."
            ),

          ],

        ),
      ),

    );

  }

}