import 'package:flutter/material.dart';
import '../main.dart';
import '../utils/app_strings.dart';
import 'services/google_drive_service.dart';
import 'services/backup_prefs.dart';
import '../db_helper.dart';
import '../utils/app_toast.dart';

enum AppThemeMode { system, dark, light }

class SettingsScreen extends StatefulWidget {
  final int userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppThemeMode selectedTheme = AppThemeMode.system;
  bool isLoading = false;
  bool autoBackup = false;
  double progress = 0.0;
  String progressText = "";
  int lastBackup = 0;
  int backupSize = 0;
  BackupFrequency frequency = BackupFrequency.daily;
  String? email;
  @override
  void initState() {
    super.initState();
    _loadEmail();
    _loadBackupInfo();

    /// 🔥 Theme sync
    switch (themeNotifier.value) {
      case ThemeMode.dark:
        selectedTheme = AppThemeMode.dark;
        break;
      case ThemeMode.light:
        selectedTheme = AppThemeMode.light;
        break;
      case ThemeMode.system:
        selectedTheme = AppThemeMode.system;
        break;
    }

    _loadPrefs();
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  String formatTime(int millis) {
    if (millis == 0) return "Never";

    final dt = DateTime.fromMillisecondsSinceEpoch(millis);

    int hour = dt.hour;
    String period = "AM";

    if (hour >= 12) {
      period = "PM";
      if (hour > 12) hour -= 12;
    }

    if (hour == 0) hour = 12;

    String minute = dt.minute.toString().padLeft(2, '0');

    return "${dt.day.toString().padLeft(2, '0')}-"
        "${dt.month.toString().padLeft(2, '0')}-"
        "${dt.year} "
        "$hour:$minute $period";
  }

  Future<void> _loadBackupInfo() async {
    lastBackup = await BackupPrefs.getLastBackup();
    backupSize = await BackupPrefs.getBackupSize();
    setState(() {});
  }

  Future<void> _loadPrefs() async {
    autoBackup = await BackupPrefs.getAutoBackup();
    frequency = await BackupPrefs.getFrequency();
    setState(() {});
  }

  Future<void> _loadEmail() async {
    email = await GoogleDriveService.getConnectedEmail();
    setState(() {});
  }

  void _applyTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        themeNotifier.value = ThemeMode.dark;
        break;
      case AppThemeMode.light:
        themeNotifier.value = ThemeMode.light;
        break;
      case AppThemeMode.system:
        themeNotifier.value = ThemeMode.system;
        break;
    }
  }

  Widget _themeBtn(IconData icon, String label, AppThemeMode mode) {
    bool isSelected = selectedTheme == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTheme = mode;
          _applyTheme(mode);
        });
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.teal.withOpacity(0.15)
                  : Theme.of(context).dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.teal : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.teal : Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).textTheme.bodyLarge!.color
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(AppStrings.get("appearance")),
        // centerTitle: true,
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

      body: Stack(
        children: [
          /// 🔹 MAIN UI
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔥 Subtitle
                Text(
                  AppStrings.get("customize_experience"),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const SizedBox(height: 20),

                /// ================= THEME =================
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get("theme"),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _themeBtn(
                            Icons.settings,
                            AppStrings.get("system"),
                            AppThemeMode.system,
                          ),
                          _themeBtn(
                            Icons.nightlight,
                            AppStrings.get("dark"),
                            AppThemeMode.dark,
                          ),
                          _themeBtn(
                            Icons.wb_sunny,
                            AppStrings.get("light"),
                            AppThemeMode.light,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// ================= LANGUAGE =================
                _sectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language, color: Colors.teal),
                    title: Text(AppStrings.get("language")),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: AppStrings.currentLang,
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text("English")),
                          DropdownMenuItem(value: 'hi', child: Text("हिन्दी")),
                          DropdownMenuItem(value: 'pa', child: Text("ਪੰਜਾਬੀ")),
                        ],
                        onChanged: (val) async {
                          if (val != null) {
                            await AppStrings.setLang(val);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                ),

                /// ================= BACKUP =================
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get("backup_restore"),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      /// 🔥 GOOGLE ACCOUNT
                      ListTile(
                        leading: Icon(Icons.account_circle, color: Colors.teal),
                        title: Text(AppStrings.get("google_account")),
                        subtitle: Text(
                          email ?? AppStrings.get("not_connected"),
                        ),
                        trailing: TextButton(
                          child: Text(AppStrings.get("change")),
                          onPressed: () async {
                            await GoogleDriveService.signOut();
                            await GoogleDriveService.uploadNow(
                              context,
                              userId: widget.userId,
                            );
                            _loadEmail();
                          },
                        ),
                      ),

                      /// 🔥 AUTO BACKUP
                      // SwitchListTile(
                      //   contentPadding: EdgeInsets.zero,
                      //   value: autoBackup,
                      //   title: Text(AppStrings.get("auto_backup")),
                      //   subtitle: Text(
                      //     autoBackup
                      //         ? AppStrings.get("on")
                      //         : AppStrings.get("off"),
                      //   ),
                      //   onChanged: (val) async {
                      //     setState(() => autoBackup = val);
                      //     await BackupPrefs.setAutoBackup(val);

                      //     if (val) {
                      //       await GoogleDriveService.uploadNow(
                      //         context,
                      //         userId: widget.userId,
                      //       );
                      //     }
                      //   },
                      // ),

                      /// 🔥 FREQUENCY
                      ListTile(
                        // leading: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule, color: Colors.teal),
                        title: Text("Last Backup"),
                        subtitle: Text(
                          "${formatTime(lastBackup)} • ${formatSize(backupSize)}",
                        ),
                      ),

                      const Divider(),

                      /// 🔥 BACKUP NOW
                      ListTile(
                        leading: const Icon(
                          Icons.cloud_upload,
                          color: Colors.teal,
                        ),
                        title: Text(AppStrings.get("backup_now")),
                        onTap: () async {
                          /// 🔥 CHECK DATA FIRST (ADD THIS)
                          final db = DBHelper.instance;

                          final trips = await db.getAll(
                            "trips",
                            where: "userId = ?",
                            whereArgs: [widget.userId],
                          );

                          if (trips.isEmpty) {
                            AppToast.error(
                              context,
                              AppStrings.get("no_data_backup"),
                            );
                            return; // ❌ STOP BACKUP
                          }
                          setState(() {
                            isLoading = true;
                            progress = 0;
                            progressText = "Preparing backup...";
                          });

                          /// Step 1
                          await Future.delayed(Duration(milliseconds: 300));
                          setState(() {
                            progress = 0.3;
                            progressText = "Creating file...";
                          });

                          /// Step 2
                          await Future.delayed(Duration(milliseconds: 300));
                          setState(() {
                            progress = 0.7;
                            progressText = "Uploading to Drive...";
                          });

                          /// REAL BACKUP
                          await GoogleDriveService.uploadNow(
                            context,
                            userId: widget.userId,
                          );

                          /// Done
                          setState(() {
                            progress = 1.0;
                            progressText = "Completed";
                          });

                          await Future.delayed(Duration(milliseconds: 500));

                          setState(() {
                            isLoading = false;
                          });
                        },
                      ),

                      /// 🔥 RESTORE
                      ListTile(
                        leading: const Icon(
                          Icons.cloud_download,
                          color: Colors.teal,
                        ),
                        title: Text(AppStrings.get("restore_backup")),
                        onTap: () async {
                          /// 🔥 CONFIRM DIALOG
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppStrings.get("confirm_restore")),
                              content: Text(AppStrings.get("restore_warning")),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(AppStrings.get("cancel")),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(AppStrings.get("restore")),
                                ),
                              ],
                            ),
                          );

                          /// ❌ USER CANCEL
                          if (confirm != true) return;

                          /// 🔥 LOADING START
                          setState(() {
                            isLoading = true;
                            progress = 0;
                            progressText = AppStrings.get("downloading_backup");
                          });

                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );

                          setState(() {
                            progress = 0.5;
                            progressText = AppStrings.get("restoring_data");
                          });

                          /// 🔥 RESTORE CALL
                          await GoogleDriveService.restoreNow(
                            context,
                            userId: widget.userId,
                          );

                          setState(() {
                            progress = 1.0;
                            progressText = AppStrings.get("completed");
                          });

                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );

                          setState(() {
                            isLoading = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 LOADER OVERLAY
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  width: 220,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        color: Colors.teal,
                        backgroundColor: Colors.grey.shade300,
                      ),
                      SizedBox(height: 12),
                      Text(progressText, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
