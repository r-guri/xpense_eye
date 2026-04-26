import 'package:flutter/material.dart';
import 'package:my_app/utils/app_strings.dart';
import '../db_helper.dart';
import 'package:flutter/services.dart';
import '../utils/app_toast.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final VoidCallback onLogout;

  const ProfileScreen({
    required this.userId,
    required this.userName,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  /// LOAD USER
  void _loadUser() async {

    var users = await DBHelper.instance.getAll(
      'users',
      where: 'id = ?',
      whereArgs: [widget.userId],
    );

    if (users.isNotEmpty) {

      var u = users.first;

      setState(() {
        _nameCtrl.text = u['name'] ?? '';
        _emailCtrl.text = u['email'] ?? '';
        _mobileCtrl.text = u['mobile'] ?? '';
        _addressCtrl.text = u['address'] ?? '';
      });

    }

  }

  /// SAVE PROFILE
  Future<void> _saveProfile() async {

    String mobile = _mobileCtrl.text.trim();

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) {
      AppToast.error(context, AppStrings.get("valid_mobile"));
      return;
    }

    setState(() => _isLoading = true);

    await DBHelper.instance.update(
      'users',
      {
        'name': _nameCtrl.text,
        'mobile': mobile,
        'address': _addressCtrl.text
      },
      'id = ?',
      [widget.userId],
    );

    setState(() => _isLoading = false);

    AppToast.success(context, AppStrings.get("profile_updated"));
  }

  /// INPUT STYLE
  InputDecoration _inputStyle(String label, IconData icon) {

    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(
        icon,
        color: Colors.teal,
      ),

      filled: true,
      fillColor: Theme.of(context).cardColor,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.teal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(

        title:  Text(AppStrings.get("profile")),

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

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            /// PROFILE AVATAR
            CircleAvatar(

              radius: 60,

              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.15),

              child: Icon(
                Icons.person,
                size: 70,
                color: Colors.teal,
              ),

            ),

            const SizedBox(height: 20),

            /// PROFILE FORM
            Container(

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(

                color: Theme.of(context).cardColor,

                borderRadius: BorderRadius.circular(16),

                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],

              ),

              child: Column(

                children: [

                  TextField(
                    controller: _nameCtrl,
                    decoration: _inputStyle(AppStrings.get("name"), Icons.person),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _emailCtrl,
                    readOnly: true,
                    decoration: _inputStyle(AppStrings.get("email"), Icons.email),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        _inputStyle(AppStrings.get("mobile"), Icons.phone),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _addressCtrl,
                    decoration: _inputStyle(AppStrings.get("address"), Icons.home),
                  ),

                  const SizedBox(height: 20),

                  /// BUTTONS
                  Row(

                    children: [

                      Expanded(

                        child: ElevatedButton(

                          onPressed: _isLoading ? null : _saveProfile,

                          style: ElevatedButton.styleFrom(

                          backgroundColor: Colors.teal,

                            padding:
                                const EdgeInsets.symmetric(vertical: 16),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),

                          ),

                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              :  Text(
                                  AppStrings.get("save"),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),

                        ),

                      ),

                      const SizedBox(width: 12),

                      Expanded(

                        child: ElevatedButton(

                          onPressed: widget.onLogout,

                          style: ElevatedButton.styleFrom(

                            backgroundColor: Colors.redAccent,

                            padding:
                                const EdgeInsets.symmetric(vertical: 16),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),

                          ),

                          child:  Text(
                            AppStrings.get("logout"),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),

                        ),

                      ),

                    ],

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

}