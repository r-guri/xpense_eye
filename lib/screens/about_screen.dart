import 'package:flutter/material.dart';
import '../utils/app_info.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About App"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [

            /// TOP SECTION
            Center(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Image.asset('assets/logo.png', height: 100),

                  ),

                  SizedBox(height: 12),

                  Text(
                    AppInfo.appName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    "Version ${AppInfo.version}",
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 25),

            /// ABOUT TEXT
            Text(
              "About ${AppInfo.appName}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              "${AppInfo.appName} is a simple and powerful app designed to help you manage expenses across trips, friends, groups, shared living, and daily activities. "
              "Track expenses, manage deposits, and calculate balances easily in one place.",
            ),

            SizedBox(height: 20),

            /// FEATURES
            Text(
              "Key Features",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            _feature("Create and manage multiple groups or trips"),
            _feature("Add members and track deposits"),
            _feature("Record shared expenses easily"),
            _feature("Automatic balance & settlement calculation"),
            _feature("Member ledger (deposit & withdraw tracking)"),
            _feature("Download PDF reports"),
            _feature("Works offline – no internet required"),

            SizedBox(height: 25),

            Divider(),

            SizedBox(height: 15),

            /// DEVELOPER
            Text(
              "Developer",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 6),

            Text(AppInfo.developerName),

            SizedBox(height: 6),

            Text(
              "Designed and developed to make group expense management simple, transparent, and stress-free.",
              style: TextStyle(color: Colors.grey[700]),
            ),

            SizedBox(height: 25),

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

  Widget _feature(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.teal, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}