import 'package:flutter/material.dart';
import '../utils/app_info.dart';
class PrivacyScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Privacy Policy"),
        backgroundColor: Colors.teal,
      ),

      body: Padding(
        padding: EdgeInsets.all(16),

        child: ListView(

          children: [

            Text(
              AppInfo.appName+" Privacy Policy",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Last Updated: 2026"
            ),

            SizedBox(height: 20),

            Text(
              AppInfo.appName+" is designed to help users manage tour expenses easily. "
              "Your privacy is important to us, and this policy explains how the app handles your data.",
            ),

            SizedBox(height: 20),

            Text(
              "1. Data Collection",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),

            SizedBox(height: 6),

            Text(
              AppInfo.appName+" does not collect any personal data from users. "
              "The app does not track users, does not collect analytics, and does not store information on external servers.",
            ),

            SizedBox(height: 20),

            Text(
              "2. Data Storage",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),

            SizedBox(height: 6),

            Text(
              "All trip information, member details, deposits, and expenses are stored locally on your device using a secure local database. "
              "This information never leaves your device unless you manually export a backup file.",
            ),

            SizedBox(height: 20),

            Text(
              "3. Backup Feature",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),

            SizedBox(height: 6),

            Text(
              AppInfo.appName+" allows users to export and import backup files. "
              "Backup files are saved on your device and are fully controlled by the user.",
            ),

            SizedBox(height: 20),

            Text(
              "4. Internet Usage",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),

            SizedBox(height: 6),

            Text(
              AppInfo.appName+" works completely offline. "
              "The app does not require an internet connection to manage trips or expenses.",
            ),

            SizedBox(height: 20),

            Text(
              "5. Data Security",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),

            SizedBox(height: 6),

            Text(
              "Since all information is stored locally on your device, keeping your device secure is important. "
              "We recommend protecting your device with a password or biometric lock.",
            ),

            SizedBox(height: 20),

            Text(
              "6. Changes to This Policy",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),

            SizedBox(height: 6),

            Text(
              "This privacy policy may be updated from time to time. "
              "Any updates will be reflected with the 'Last Updated' date.",
            ),

            SizedBox(height: 25),

            Divider(),

            SizedBox(height: 10),

            Text(
              "Contact",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),

            SizedBox(height: 6),

            Text("Developer: "+AppInfo.developerName),

            Text("Email: "+AppInfo.developerEmail),

          ],

        ),
      ),

    );

  }

}