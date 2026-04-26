import 'package:flutter/material.dart';
import '../utils/app_info.dart';

class PrivacyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy Policy"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
             colors: Theme.of(context).brightness == Brightness.dark
    ? [Colors.grey.shade900, Colors.grey.shade900]
    : [Colors.teal, Colors.teal],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            /// TITLE
            Text(
              "${AppInfo.appName} Privacy Policy",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Text("Last updated: March 2026"),

            SizedBox(height: 20),

            Text(
              "Thank you for using ${AppInfo.appName}. "
              "${AppInfo.appName} helps you manage expenses across trips, friends, groups, shared living, and daily activities.",
            ),

            SizedBox(height: 20),

            /// 1
            Text(
              "1. Information We Collect",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              "${AppInfo.appName} does not collect or store any personal data on external servers by default.\n\n"
              "All information such as:\n"
              "• Expenses\n"
              "• Groups & Members\n"
              "• Payments & Ledger data\n\n"
              "is stored locally on your device only.\n\n"
              "We do not collect:\n"
              "• Personal identity information\n"
              "• Location data\n"
              "• Contacts\n"
              "• Bank or financial account details",
            ),

            SizedBox(height: 20),

            /// 2
            Text(
              "2. How Your Data is Used",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              "Your data is used only within the app to:\n"
              "• Track expenses\n"
              "• Manage group balances\n"
              "• Calculate settlements\n\n"
              "Your data never leaves your device unless you choose to export it.",
            ),

            SizedBox(height: 20),

            /// 3
            Text(
              "3. Local Storage",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              "All data is stored securely in your device.\n\n"
              "You have full control:\n"
              "• Edit or delete anytime\n"
              "• Clear app data anytime",
            ),

            SizedBox(height: 20),

            /// 4
            Text(
              "4. Backup & Sharing",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              "You can:\n"
              "• Export backup manually\n"
              "• Share your data files\n\n"
              "No automatic data upload is performed.",
            ),

            SizedBox(height: 20),

            /// 5
            Text(
              "5. Data Security",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              "We ensure:\n"
              "• No tracking\n"
              "• No selling of data\n"
              "• No background data collection",
            ),

            SizedBox(height: 20),

            /// 6
            Text(
              "6. Children’s Privacy",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text("This app is not intended for children under the age of 13."),

            SizedBox(height: 20),

            /// 7
            Text(
              "7. Changes to This Policy",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text("This policy may be updated anytime."),

            SizedBox(height: 25),
            Text(
              "8. Google Sign-In",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              "${AppInfo.appName} allows users to sign in using their Google account.\n\n"
              "When you sign in with Google, the app may access basic profile information such as:\n"
              "• Name\n"
              "• Email address\n"
              "• Profile picture\n\n"
              "This information is used only for authentication purposes to securely log you into the app.\n\n"
              "We do not store this information on our servers, nor do we share it with any third parties.",
            ),
            Divider(),

            SizedBox(height: 10),

            /// CONTACT
            Text(
              "Contact Us",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text("Developer: ${AppInfo.developerName}"),
            Text("Email: ${AppInfo.developerEmail}"),

            SizedBox(height: 20),

            Text(
              "By using ${AppInfo.appName}, you agree to this Privacy Policy.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
