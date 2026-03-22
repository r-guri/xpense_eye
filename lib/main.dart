import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import '../utils/app_info.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  /// Supabase initialize
  await Supabase.initialize(
     url: 'https://mzwevmnzpuhzidzvhdup.supabase.co',
    anonKey: 'sb_publishable_FxwD4ZzQUsZKJ6o1ff_Svw_8fpQQ3hl',
  );

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