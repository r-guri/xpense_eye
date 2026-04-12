import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'signup_screen.dart';
import '../db_helper.dart';
import 'dashboard_screen.dart';
import 'utils.dart';
import '../utils/app_toast.dart';
import '../utils/app_info.dart';
import 'services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoginLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  /// 🔐 NORMAL LOGIN
  Future<void> _login() async {

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AppToast.error(context, "Please fill all fields");
      return;
    }

    setState(() => _isLoginLoading = true);

    var users = await DBHelper.instance.getAll(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [
        _emailController.text,
        hashPassword(_passwordController.text),
      ],
    );

    setState(() => _isLoginLoading = false);

    if (users.isNotEmpty) {

      int userId = users.first['id'];
      String userName = users.first['name'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', userId);
      await prefs.setString('userName', userName);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(userId: userId, userName: userName),
        ),
      );

    } else {
      AppToast.error(context, "Invalid credentials");
    }
  }
Future<bool>hasInternet() async{
  try{
    final result =await InternetAddress.lookup('google.com');
    return result.isNotEmpty && 
    result[0].rawAddress.isNotEmpty;

  } catch(_){
    return false;
  }
}
  /// 🔥 GOOGLE LOGIN
  Future<void> _googleLogin() async {
      bool isOnline = await hasInternet();
      if(!isOnline){
        AppToast.error(context,"Internet required for Google Login");
        return;
      }
    setState(() => _isGoogleLoading = true);

    var user = await GoogleAuthService.signInWithGoogle();

    if (user == null) {
      setState(() => _isGoogleLoading = false);
      return;
    }

    var existing = await DBHelper.instance.getAll(
      'users',
      where: 'email = ?',
      whereArgs: [user.email],
    );

    int userId;
    String userName = user.displayName ?? '';

    if (existing.isEmpty) {
      userId = await DBHelper.instance.insert('users', {
        'name': userName,
        'email': user.email,
        'password': 'google_login',
      });
    } else {
      userId = existing.first['id'];
      userName = existing.first['name'] ?? userName;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
    await prefs.setString('userName', userName);

    setState(() => _isGoogleLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          userId: userId,
          userName: userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Image.asset('assets/logo.png', height: 100),

              // const SizedBox(height: 10),

              Text(
                AppInfo.appName,
                style: const TextStyle(
                  fontSize: 30,
                 fontWeight: FontWeight.bold,
                    color: Colors.teal,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Login to continue your journey",
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),

              const SizedBox(height: 32),

              /// EMAIL
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF009688)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF009688)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF009688),
                    ),
                    onPressed: () {
                      setState(() =>
                          _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoginLoading || _isGoogleLoading)
                      ? null
                      : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoginLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              /// OR Divider
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              /// GOOGLE BUTTON
              GestureDetector(
                onTap: (_isLoginLoading || _isGoogleLoading)
                    ? null
                    : _googleLogin,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Image.asset('assets/google.png', height: 22),

                      const SizedBox(width: 10),

                      _isGoogleLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// SIGNUP BUTTON
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => SignupScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF009688)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Create New Account",
                    style: TextStyle(
                      color: Color(0xFF009688),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
                SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}