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

            /// TITLE
            Text(
              "Need Help?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "If you face any issue while using ${AppInfo.appName} or have suggestions to improve the app, feel free to contact us.",
            ),

            SizedBox(height: 20),

            /// EMAIL CARD
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Row(
                children: [

                  Icon(Icons.email, color: Colors.teal),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      AppInfo.developerEmail,
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  /// COPY BUTTON
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.teal),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Email copied")),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            /// RESPONSE TIME
            Text(
              "Response Time",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 6),

            Text("We usually respond within 24–48 hours."),

            SizedBox(height: 25),

            Divider(),

            SizedBox(height: 10),

            /// DEVELOPER INFO
            Text(
              "Developer",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 6),

            Text(AppInfo.developerName),

            SizedBox(height: 10),

            /// APP DESCRIPTION FIXED
            Text(
              "${AppInfo.appName} helps you manage expenses across trips, friends, groups, shared living, and daily activities. "
              "Track expenses, manage balances, and settle payments easily.",
              style: TextStyle(color: Colors.grey[700]),
            ),

            SizedBox(height: 30),

            /// FOOTER
            Center(
              child: Text(
                "Thank you for using ${AppInfo.appName}",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}