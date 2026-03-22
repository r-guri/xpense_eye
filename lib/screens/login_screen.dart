import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import '../db_helper.dart';
import 'dashboard_screen.dart';
import 'utils.dart'; // For hashPassword function
import '../utils/app_toast.dart';
import '../utils/app_info.dart';
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // 👁️ password toggle


  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
       AppToast.error(context, "Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);

    var db = DBHelper.instance;
    var users = await db.getAll(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [
        _emailController.text,
        hashPassword(_passwordController.text),
      ],
    );

    setState(() => _isLoading = false);

    if (users.isNotEmpty) {
      int userId = users.first['id'];
      String userName = users.first['name'] ?? '';

      SharedPreferences prefs = await SharedPreferences.getInstance();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: Theme.of(context).scaffoldBackgroundColor, // soft background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ App Logo
              Image.asset(
                'assets/logo.png',
                height: 100,
              ),
              const SizedBox(height: 10),

              // ✅ App Title
              Text(
                AppInfo.appName,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00796B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Login to continue your journey",
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
              const SizedBox(height: 32),

              // ✅ Email Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF009688)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF009688), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Password Field with Eye Toggle
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF009688)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Color(0xFF009688)
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF009688), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Signup Link
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => SignupScreen()),
                  );
                },
                child: Text(
                  "Don't have an account? Signup",
                  style: TextStyle(
                    color: const Color(0xFF00796B),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),
    Divider(thickness: 1),
                SizedBox(height: 10),
                Text(
                  "Designed & Developed by "+AppInfo.developerName,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    // Open email support (optional)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contact: '+AppInfo.developerEmail),
                      ),
                    );
                  },
                  child: Text(
                    AppInfo.developerEmail,
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
