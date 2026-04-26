import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
import '../db_helper.dart';
import 'add_trip_screen.dart';
import 'add_member_screen.dart';
import 'add_expense_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';
import 'support_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/backup_service.dart';
import '../utils/app_info.dart';
import '../utils/app_toast.dart';
import '../utils/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/purchase_service.dart';
import 'services/rating_service.dart';
import 'services/review_service.dart';
import 'settings_screen.dart';
// import 'ads/banner_ad_widget.dart';
import 'ads/ad_helper.dart';
import '../utils/app_strings.dart';
import 'analytics_screen.dart';

// import '../utils/google_drive_backup.dart';
class DashboardScreen extends StatefulWidget {
  final int userId;
  final String userName;
  DashboardScreen({required this.userId, required this.userName});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class LanguageDropdown extends StatefulWidget {
  final VoidCallback onChanged;

  const LanguageDropdown({super.key, required this.onChanged});

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  void _showLangMenu() async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(1000, 80, 10, 0),
      items: [
        PopupMenuItem(value: 'en', child: Text("English")),
        PopupMenuItem(value: 'hi', child: Text("हिन्दी")),
        PopupMenuItem(value: 'pa', child: Text("ਪੰਜਾਬੀ")),
      ],
    );

    if (selected != null) {
      await AppStrings.setLang(selected); // 🔥 IMPORTANT
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Image.asset('assets/language.png', height: 22, color: Colors.white),
      onPressed: _showLangMenu,
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> trips = [];
  Map<int, double> tripDeposits = {};
  Map<int, double> tripExpenses = {};
  Map<int, int> tripMembersCount = {};
  int totalMembers = 0;
  int currentIndex = 0;
  double totalExpense = 0;
  double totalDeposit = 0;
  int _selectedIndex = 0;
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void showRateAppDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ⭐ ICON
                Icon(Icons.star, color: Colors.orange, size: 60),

                SizedBox(height: 10),

                /// TITLE
                Text(
                  "Enjoying Xpense Eye?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 10),

                /// MESSAGE
                Text(
                  "A 5-star rating takes just a few seconds,\n"
                  "but helps us a lot to improve the app 🚀",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),

                SizedBox(height: 20),

                /// BUTTONS
                Row(
                  children: [
                    /// LATER BUTTON
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Later"),
                      ),
                    ),

                    SizedBox(width: 10),

                    /// RATE NOW BUTTON
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ReviewService.openReview();
                        },
                        child: Text("Rate Now ⭐"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String isoDate) {
    DateTime date = DateTime.parse(isoDate);

    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();

    return "$day-$month-$year";
  }

  Future<void> _loadTrips() async {
    var tripData = await DBHelper.instance.getAll(
      'trips',
      where: 'userId = ?',
      whereArgs: [widget.userId],
      orderBy: 'id DESC',
    );

    var members = await DBHelper.instance.getAll(
      'members',
      where: 'tripId IN (SELECT id FROM trips WHERE userId = ?)',
      whereArgs: [widget.userId],
    );

    var expenses = await DBHelper.instance.getAll(
      'expenses',
      where: 'tripId IN (SELECT id FROM trips WHERE userId = ?)',
      whereArgs: [widget.userId],
    );
    double sumDeposit = 0;
    tripDeposits.clear();

    for (var m in members) {
      int tripId = m['tripId'];

      double payAmount = (m['payAmount'] ?? 0).toDouble();

      double ledgerDeposit = await DBHelper.instance.getMemberDeposit(
        tripId,
        m['id'],
      );

      double ledgerWithdraw = await DBHelper.instance.getMemberWithdraw(
        tripId,
        m['id'],
      );

      double memberDeposit = payAmount + ledgerDeposit - ledgerWithdraw;

      sumDeposit += memberDeposit;

      tripDeposits[tripId] = (tripDeposits[tripId] ?? 0) + memberDeposit;
    }
    double sumExpense = 0;

    tripExpenses.clear();
    tripMembersCount.clear();

    for (var e in expenses) {
      int tripId = e['tripId'];
      double amt = (e['amount'] ?? 0).toDouble();

      sumExpense += amt;
      tripExpenses[tripId] = (tripExpenses[tripId] ?? 0) + amt;
    }

    for (var m in members) {
      int tripId = m['tripId'];
      tripMembersCount[tripId] = (tripMembersCount[tripId] ?? 0) + 1;
    }

    setState(() {
      trips = tripData;
      totalMembers = members.length;
      totalExpense = sumExpense;
      totalDeposit = sumDeposit;
    });
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      // Firebase logout
      await FirebaseAuth.instance.signOut();

      // Google logout
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect(); // safe now
      }
    } catch (e) {
      print("Logout error: $e");
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case "food":
        return Icons.fastfood;

      case "travel":
        return Icons.directions_car;

      case "hotel":
        return Icons.hotel;

      case "shopping":
        return Icons.shopping_bag;

      default:
        return Icons.currency_rupee;
    }
  }

  Widget _getBody() {
    if (_selectedIndex == 1) {
      return AnalyticsScreen(tripId: 0); // 🔥 NEW
    }

    if (_selectedIndex == 2) {
      return ProfileScreen(
        userId: widget.userId,
        userName: widget.userName,
        onLogout: _logout,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [_buildStats(), _recentExpenses(), _buildTripList()],
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.teal.withOpacity(0.2),
        highlightColor: Colors.transparent,
        onTap: () {
          if (_selectedIndex != index) {
            setState(() => _selectedIndex = index);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: isSelected ? Colors.teal : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.teal : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal),

            const SizedBox(height: 6),

            /// VALUE (Auto resize)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _statCard(
            AppStrings.get("total"),
            trips.length.toString(),
            Icons.card_travel,
          ),

          const SizedBox(width: 10),

          _statCard(
            AppStrings.get("members"),
            totalMembers.toString(),
            Icons.group,
          ),

          const SizedBox(width: 10),

          _statCard(
            AppStrings.get("expense"),
            "₹${totalExpense.toStringAsFixed(0)}",
            Icons.currency_rupee,
          ),

          const SizedBox(width: 10),

          _statCard(
            AppStrings.get("deposit"),
            "₹${totalDeposit.toStringAsFixed(0)}",
            Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }

  Widget _recentExpenses() {
    return FutureBuilder(
      future: DBHelper.instance.getAll(
        'expenses',
        where: 'tripId IN (SELECT id FROM trips WHERE userId = ?)',
        whereArgs: [widget.userId],
        orderBy: 'id DESC',
      ),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snap) {
        if (!snap.hasData || snap.data!.isEmpty) return SizedBox();

        var data = snap.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.get("recent_expenses"),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),

            SizedBox(height: 5),

            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.length > 5 ? 5 : data.length,
                itemBuilder: (context, index) {
                  var e = data[index];

                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(right: 10),

                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),

                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.teal.shade100,
                              child: Icon(
                                _categoryIcon(e['category']),
                                size: 14,
                                color: Colors.teal,
                              ),
                            ),

                            Spacer(),

                            Text(
                              "₹${e['amount']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 5),

                        Text(
                          e['description'] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                        ),

                        Text(
                          e['category'] ?? "",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // SizedBox(height: 2),
          ],
        );
      },
    );
  }

  Widget _buildTripList() {
    if (trips.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),

        child: Center(
          child: Text(
            "No group/trip added yet.\nClick + to add your first group/trip!",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      padding: const EdgeInsets.all(16),

      itemCount: trips.length,

      itemBuilder: (context, index) {
        var t = trips[index];

        return _buildTripCard(t);
      },
    );
  }

  Widget _buildTripCard(Map<String, dynamic> t) {
    double totalExpense = tripExpenses[t['id']] ?? 0;
    double totalDeposit = tripDeposits[t['id']] ?? 0;
    int memberCount = tripMembersCount[t['id']] ?? 0;

    double perPerson = memberCount == 0 ? 0 : totalExpense / memberCount;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportScreen(tripId: t['id'], tripName: t['name']),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// NAME + AMOUNT
                Row(
                  children: [
                    const Icon(Icons.card_travel, color: Colors.teal),
                    const SizedBox(width: 6),

                    /// 🔥 NAME
                    Expanded(
                      child: Text(
                        t['name'] ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),

                    /// 🔥 GAP PUSHER (IMPORTANT)
                    const SizedBox(width: 10),

                    /// 🔥 AMOUNTS WITH SAFE SPACE FOR 3 DOT
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 30,
                      ), // space for menu
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "₹${totalExpense.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "₹${totalDeposit.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                /// DESTINATION
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      t['destination'] ?? "",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                /// DATE
                Text(
                  "${_formatDate(t['startDate'])} → ${_formatDate(t['endDate'])}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),

                const SizedBox(height: 5),

                /// MEMBERS
                Row(
                  children: [
                    Icon(Icons.group, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text("$memberCount ${AppStrings.get('members')}"),
                  ],
                ),

                const SizedBox(height: 12),

                /// BUTTONS
                Row(
                  children: [
                    _actionBtn(
                      Icons.group,
                      AppStrings.get("members"),
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddMemberScreen(
                              tripId: t['id'],
                              tripName: t['name'],
                            ),
                          ),
                        );
                        if (result == true) {
                          Future.delayed(
                            const Duration(milliseconds: 100),
                            () => _loadTrips(),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _actionBtn(
                      Icons.currency_rupee,
                      AppStrings.get("expense"),
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddExpenseScreen(
                              tripId: t['id'],
                              tripName: t['name'],
                            ),
                          ),
                        );
                        if (result == true) {
                          Future.delayed(
                            const Duration(milliseconds: 100),
                            () => _loadTrips(),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 40),

          /// THREE DOT MENU
          Positioned(
            top: 8,
            right: 8,

            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == "view") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReportScreen(tripId: t['id'], tripName: t['name']),
                    ),
                  );
                }

                if (value == "delete") {
                  bool confirm = await showDialog(
                    context: context,

                    builder: (context) => AlertDialog(
                      title: const Text("Delete"),

                      content: const Text(
                        "Are you sure you want to delete this expense?\nAll members and expenses will also be deleted.",
                      ),

                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),

                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm) {
                    await DBHelper.instance.delete('members', 'tripId = ?', [
                      t['id'],
                    ]);

                    await DBHelper.instance.delete('expenses', 'tripId = ?', [
                      t['id'],
                    ]);

                    await DBHelper.instance.delete('categories', 'tripId = ?', [
                      t['id'],
                    ]);

                    await DBHelper.instance.delete('trips', 'id = ?', [
                      t['id'],
                    ]);

                    _loadTrips();
                  }
                }
                if (value == "edit") {
                  TextEditingController nameCtrl = TextEditingController(
                    text: t['name'],
                  );

                  TextEditingController destCtrl = TextEditingController(
                    text: t['destination'],
                  );

                  await showDialog(
                    context: context,

                    builder: (context) {
                      return AlertDialog(
                        title: Text("Edit"),

                        content: Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(labelText: "Name"),
                            ),

                            SizedBox(height: 10),

                            TextField(
                              controller: destCtrl,
                              decoration: InputDecoration(
                                labelText: "Destination",
                              ),
                            ),
                          ],
                        ),

                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel"),
                          ),

                          ElevatedButton(
                            onPressed: () async {
                              await DBHelper.instance.update(
                                'trips',

                                {
                                  'name': nameCtrl.text,
                                  'destination': destCtrl.text,
                                },

                                'id = ?',
                                [t['id']],
                              );

                              Navigator.pop(context);

                              _loadTrips();
                            },

                            child: Text("Update"),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "view",
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(AppStrings.get('view_report')),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: "edit",
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(AppStrings.get("edit")),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text(AppStrings.get("delete")),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,

        icon: Icon(icon, size: 20), // 🔥 thoda bigger

        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600, // 🔥 bold feel
            fontSize: 14,
          ),
        ),

        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.teal,

          side: BorderSide(
            color: Colors.teal.withOpacity(0.6), // 🔥 soft border
          ),

          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.circular(12), // 🔥 more smooth
          // ),
          padding: const EdgeInsets.symmetric(vertical: 10),

          elevation: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text("Welcome, ${widget.userName}"),
        actions: [
          LanguageDropdown(
            onChanged: () {
              setState(() {});
            },
          ),
        ],

        /// 🔥 DARK MODE CHECK
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
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.userName),
              accountEmail: Text(""),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,

                child: Icon(Icons.person, size: 40, color: Colors.teal),
              ),

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [Colors.grey.shade900, Colors.grey.shade900] // 🌙 dark
                      : [Colors.teal, Colors.teal], // ☀️ light
                ),
              ),
            ),

            ListTile(
              leading: Icon(Icons.person, color: Colors.teal),

              title: Text(AppStrings.get('profile')),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      userId: widget.userId,
                      userName: widget.userName,
                      onLogout: _logout,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: Colors.teal),
              title: Text(AppStrings.get('export_backup')),
              onTap: () async {
                Navigator.pop(context);

                if (!AppConfig.enableAds || PurchaseService.isAdsRemoved) {
                  /// 👑 Premium user → direct export
                  await BackupService.exportBackup(widget.userId);

                  AppToast.success(context, AppStrings.get("backup_exported"));
                } else {
                  /// 💰 Free user → ad + export
                  AdHelper.showInterstitialAd(
                    onAdClosed: () async {
                      await BackupService.exportBackup(widget.userId);

                      AppToast.success(
                        context,
                        AppStrings.get("backup_exported"),
                      );
                    },
                  );
                }
              },
            ),
            // ListTile(
            //   leading: Icon(Icons.download, color: Colors.teal),
            //   title: Text("Export Backup"),
            //   onTap: () async {
            //     Navigator.pop(context);

            //     await BackupService.exportBackup(widget.userId);
            //     AppToast.success(context, "Backup exported successfully");
            //   },
            // ),
            ListTile(
              leading: Icon(Icons.upload, color: Colors.teal),
              title: Text(AppStrings.get('import_backup')),
              onTap: () async {
                Navigator.pop(context);

                if (!AppConfig.enableAds || PurchaseService.isAdsRemoved) {
                  bool success = await BackupService.importBackup(
                    widget.userId,
                  );

                  if (success) {
                    _refreshKey.currentState?.show();
                    AppToast.success(
                      context,
                      AppStrings.get("backup_restored"),
                    );
                  }
                } else {
                  AdHelper.showInterstitialAd(
                    onAdClosed: () async {
                      bool success = await BackupService.importBackup(
                        widget.userId,
                      );

                      if (success) {
                        _refreshKey.currentState?.show();
                        AppToast.success(
                          context,
                          AppStrings.get("backup_restored"),
                        );
                        RatingService.trigger(context);
                      }
                    },
                  );
                }
              },
            ),
            // ListTile(
            //   leading: Icon(Icons.upload, color: Colors.teal),
            //   title: Text("Import Backup"),
            //   onTap: () async {
            //     Navigator.pop(context);

            //     bool success = await BackupService.importBackup(widget.userId);
            //     if (success) {
            //       _refreshKey.currentState?.show();

            //       AppToast.success(context, "Backup restored. Refreshing...");
            //     }
            //   },
            // ),
            //             ListTile(
            //               leading: Icon(Icons.cloud_upload, color: Colors.teal),
            //               title: Text("Backup to Google Drive"),

            //           onTap: () async {

            //   File file = await BackupService.getBackupFile();

            //   await GoogleDriveBackup.uploadBackup(file);

            //   AppToast.error(context, "Backup uploaded to Google Drive");

            // }
            //             ),
            ListTile(
              leading: Icon(Icons.privacy_tip, color: Colors.teal),
              title: Text(AppStrings.get('privacy')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PrivacyScreen()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.support_agent, color: Colors.teal),
              title: Text(AppStrings.get('support')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SupportScreen()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.teal),
              title: Text(AppStrings.get('about')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AboutScreen()),
                );
              },
            ),

            //             ListTile(
            //   leading: Icon(Icons.star, color: Colors.orange),
            //   title: Text("Remove Ads ₹99"),
            //   onTap: () {
            //     Navigator.pop(context);

            //     showDialog(
            //       context: context,
            //       builder: (_) => AlertDialog(
            //         title: Text("Go Premium 👑"),
            //         content: Text(
            //             "Remove all ads & enjoy smooth experience.\n\nOne-time payment Price: ₹99 (may vary slightly due to taxes)"),
            //         actions: [
            //           TextButton(
            //             onPressed: () => Navigator.pop(context),
            //             child: Text("Cancel"),
            //           ),
            //           ElevatedButton(
            //             onPressed: () async {
            //               Navigator.pop(context);

            //               /// 🔥 MAIN FIX
            //               await PurchaseService.buyRemoveAds();
            //             },
            //             child: Text("Buy ₹99"),
            //           ),
            //         ],
            //       ),
            //     );
            //   },
            // ),
            /// 🔁 Restore Purchase
            // ListTile(
            //   leading: Icon(Icons.restore, color: Colors.teal),
            //   title: Text("Restore Purchase"),
            //   onTap: () async {
            //     Navigator.pop(context);

            //     await PurchaseService.restore();

            //     ScaffoldMessenger.of(context).showSnackBar(
            //       SnackBar(content: Text("Restoring purchase...")),
            //     );
            //   },
            // ),
            ListTile(
              leading: Icon(Icons.star, color: Colors.orange),
              title: Text(AppStrings.get('rate_app')),
              onTap: () {
                Navigator.pop(context);
                showRateAppDialog(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.teal),
              title: Text("Settings"),
              onTap: () {
                Navigator.pop(context); // drawer close
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),

              title: Text(AppStrings.get('logout')),

              onTap: _logout,
            ),

            const Spacer(),

            const Divider(),

            Padding(
              padding: EdgeInsets.only(bottom: 20),

              child: Column(
                children: [
                  Text(
                    "Designed & Developed by",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  Text(
                    AppInfo.developerName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // InkWell(
                  //   onTap: () async {
                  //     final Uri emailLaunchUri = Uri(
                  //       scheme: 'mailto',

                  //       path: AppInfo.developerEmail,

                  //       query: Uri.encodeFull(
                  //         'subject=App Support / Suggestion',
                  //       ),
                  //     );

                  //     await launchUrl(emailLaunchUri);
                  //   },

                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,

                  //     children: [
                  //       Icon(
                  //         Icons.email_outlined,
                  //         size: 16,
                  //         color: Colors.teal,
                  //       ),

                  //       SizedBox(width: 5),

                  //       Text(
                  //         AppInfo.developerEmail,
                  //         style: TextStyle(color: Colors.teal, fontSize: 13),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      // body: RefreshIndicator(onRefresh: _loadTrips, child: _getBody()),
      body: _selectedIndex == 0
          ? RefreshIndicator(
              key: _refreshKey,
              onRefresh: _loadTrips,
              child: _getBody(),
            )
          : _getBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTripScreen(userId: widget.userId),
            ),
          );

          if (result == true) {
            _loadTrips();
          }
        },

        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 30),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        color: Theme.of(context).cardColor,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.home_rounded, label: "Home", index: 0),

              const SizedBox(width: 40), // FAB space

              _navItem(
                icon: Icons.analytics_rounded,
                label: "Analytics",
                index: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
