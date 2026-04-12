import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_info.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {

  @override
  State<SplashScreen> createState() => _SplashScreenState();

}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {

    super.initState();
      checkLogin(context);
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
      lowerBound: 0.85,
      upperBound: 1.0,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _fadeController.forward();
    _scaleController.forward();

    // checkLogin();

  }

 Future<void> checkLogin(BuildContext context) async {

  final prefs = await SharedPreferences.getInstance();

  int? userId = prefs.getInt('userId');
  String? userName = prefs.getString('userName');

  await Future.delayed(Duration(seconds: 1)); // optional splash

  if (userId != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          userId: userId,
          userName: userName ?? '',
        ),
      ),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(),
      ),
    );
  }
}

  @override
  void dispose() {

    _fadeController.dispose();
    _scaleController.dispose();

    super.dispose();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        decoration: BoxDecoration(

          gradient: LinearGradient(
            colors: [
              Color(0xFFE0F2F1),
              Color(0xFFB2DFDB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),

        ),

        child: Center(

          child: FadeTransition(

            opacity: _fadeAnimation,

            child: ScaleTransition(

              scale: _scaleAnimation,

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Text(
                    AppInfo.appName,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "Smart Expense Manager",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.teal.shade700,
                    ),
                  ),

                  SizedBox(height: 40),

                  CircularProgressIndicator(
                    color: Colors.teal,
                  ),

                ],

              ),

            ),

          ),

        ),

      ),

    );

  }

}