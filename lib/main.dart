import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import '../utils/app_info.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ✅ add this
import 'screens/ads/ad_helper.dart';
import 'screens/services/purchase_service.dart';
import 'utils/app_config.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
   PurchaseService.init();
    if (AppConfig.enableAds) {
    await MobileAds.instance.initialize();
    AdHelper.loadAd();
  }
  runApp(TourKhataApp());
}

class TourKhataApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,

      /// Light Theme
      theme: AppTheme.lightTheme,

      /// Dark Theme
      darkTheme: AppTheme.darkTheme,

      /// Device theme follow
      themeMode: ThemeMode.system,

      home: SplashScreen(),
    );
  }
}