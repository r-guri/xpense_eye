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

            Center(
              child: Column(
                children: [

                  Container(
                    padding: EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      Icons.travel_explore,
                      size: 70,
                      color: Colors.teal,
                    ),
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
                    "version "+AppInfo.version,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),

                ],
              ),
            ),

            SizedBox(height: 25),

            Text(
              "About "+AppInfo.appName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              AppInfo.appName+" is a simple and powerful app designed to help you manage trip expenses easily. "
              "You can add trip members, track expenses, manage deposits, and calculate balances during your tours.",
            ),

            SizedBox(height: 20),

            Text(
              "Key Features",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            _feature("Manage multiple trips easily"),
            _feature("Add members and track deposits"),
            _feature("Record trip expenses"),
            _feature("Automatic balance calculation"),
            _feature("Generate PDF reports"),
            _feature("Offline app – no internet required"),

            SizedBox(height: 25),

            Divider(),

            SizedBox(height: 15),

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
              "Designed and developed to make group travel expense management simple and transparent.",
            ),

          ],

        ),
      ),

    );

  }

  Widget _feature(String text){

    return Padding(

      padding: EdgeInsets.symmetric(vertical: 4),

      child: Row(

        children: [

          Icon(Icons.check_circle,
              color: Colors.teal,
              size: 18),

          SizedBox(width: 8),

          Expanded(child: Text(text)),

        ],

      ),

    );

  }

}