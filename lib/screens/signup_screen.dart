import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../db_helper.dart';
import 'utils.dart'; // For hashPassword function
import '../utils/app_toast.dart';
// import '../utils/app_info.dart';
class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
Future<void> _signup() async {

  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {

    /// 1️⃣ Local DB insert (main)
    await DBHelper.instance.insert('users', {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': hashPassword(_passwordController.text),
    });

    AppToast.success(context, "Signup successful! Please login.");

    Future.delayed(Duration(seconds: 1), () {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );

    });

  } catch (e) {

    /// Local DB fail hoya
    AppToast.error(context, "Email already exists.");

  } finally {

    setState(() => _isLoading = false);

  }

}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('assets/logo.png', height: 100),

                // SizedBox(height: 16),
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person, color: Color(0xFF009688)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter name' : null,
                ),
                SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Color(0xFF009688)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter email' : null,
                ),
                SizedBox(height: 16),

                // Password with Eye Toggle
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Set Password',
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF009688)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Color(0xFF009688),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v!.length < 4 ? 'Minimum 4 characters' : null,
                ),
                SizedBox(height: 24),

                // Signup Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Creating Account...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        : Text(
                            'Signup',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),

                SizedBox(height: 20),

                // Already have account
                  SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
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
                    "Already have an account? Login",
                    style: TextStyle(
                      color: Color(0xFF009688),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
                // TextButton(
                //   onPressed: () {
                //     Navigator.pushReplacement(
                //       context,
                //       MaterialPageRoute(builder: (_) => LoginScreen()),
                //     );
                //   },
                //   child: Text(
                //     "Already have an account? Login",
                //     style: TextStyle(color: Colors.teal.shade700),
                //   ),
                // ),

                SizedBox(height: 80),

                // // Footer Section
                // Divider(thickness: 1),
                // SizedBox(height: 10),
                // Text(
                //   "Designed & Developed by "+AppInfo.developerName,
                //   style: TextStyle(color: Colors.grey[700], fontSize: 14),
                // ),
                // SizedBox(height: 6),
                // GestureDetector(
                //   onTap: () {
                //     // Open email support (optional)
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       SnackBar(content: Text('Contact: '+AppInfo.developerEmail)),
                //     );
                //   },
                //   child: Text(
                //     AppInfo.developerEmail,
                //     style: TextStyle(
                //       color: Colors.teal,
                //       fontSize: 14,
                //       decoration: TextDecoration.underline,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
