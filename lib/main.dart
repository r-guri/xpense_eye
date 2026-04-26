import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import '../utils/app_info.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/ads/ad_helper.dart';
import 'screens/services/purchase_service.dart';
import 'utils/app_config.dart';
import 'utils/app_strings.dart';
import 'utils/user_helper.dart';

/// 🔥 BACKUP IMPORT
import 'screens/services/backup_prefs.dart';
import 'screens/services/google_drive_service.dart';

/// 🔥 THEME CONTROLLER
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  PurchaseService.init();

  await AppStrings.loadLang();

  /// 🔥 ADS INIT
  if (AppConfig.enableAds) {
    await MobileAds.instance.initialize();
    AdHelper.loadAd();
  }

  /// 🔥 EDGE UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const TourKhataApp());
}

class TourKhataApp extends StatefulWidget {
  const TourKhataApp({super.key});

  @override
  State<TourKhataApp> createState() => _TourKhataAppState();
}

class _TourKhataAppState extends State<TourKhataApp> {
  @override
  void initState() {
    super.initState();

    /// 🔥 AUTO BACKUP CHECK (safe delay)
    Future.delayed(const Duration(milliseconds: 300), () {
      _autoBackupCheck();
    });
  }

  /// 🔥 SMART AUTO BACKUP (FINAL)
  Future<void> _autoBackupCheck() async {
    try {
      bool enabled = await BackupPrefs.getAutoBackup();
      if (!enabled) return;

      int last = await BackupPrefs.getLastBackup();
      int now = DateTime.now().millisecondsSinceEpoch;
      int userId = await UserHelper.getUserId();

      BackupFrequency freq = await BackupPrefs.getFrequency();

      int interval = 86400000; // daily

      if (freq == BackupFrequency.weekly) {
        interval = 7 * 86400000;
      } else if (freq == BackupFrequency.monthly) {
        interval = 30 * 86400000;
      }

      if (now - last > interval) {
        await GoogleDriveService.uploadNow(
          context,
          userId: userId,
          manual: false,
        );
      }
    } catch (e) {
      // silent fail
    }
  }

  /// 🔥 NAVIGATOR KEY
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: AppInfo.appName,

          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),

          /// 🔥 THEMES
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,

          /// 🔥 SYSTEM UI
          builder: (context, child) {
            final isDark =
                Theme.of(context).brightness == Brightness.dark;

            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor:
                    isDark ? Colors.black : Colors.white,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
              ),
            );

            return child!;
          },

          home: SplashScreen(),
        );
      },
    );
  }
}