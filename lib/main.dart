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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  PurchaseService.init();
  await AppStrings.loadLang();
  if (AppConfig.enableAds) {
    await MobileAds.instance.initialize();
    AdHelper.loadAd();
  }
  // ✅ Edge-to-edge enable
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const TourKhataApp());
}

class TourKhataApp extends StatelessWidget {
  const TourKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,

      /// Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ✅ Dynamic system UI (PRO setup)
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,

            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,

            systemNavigationBarColor: isDark ? Colors.black : Colors.white,

            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
        );

        return child!;
      },

      home: SplashScreen(),
    );
  }
}
