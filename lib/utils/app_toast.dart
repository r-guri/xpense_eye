import 'package:flutter/material.dart';

class AppToast {

  static void success(BuildContext context, String msg) {
    _show(context, msg, Colors.green, Icons.check_circle);
  }

  static void error(BuildContext context, String msg) {
    _show(context, msg, Colors.red, Icons.error);
  }

  static void info(BuildContext context, String msg) {
    _show(context, msg, Colors.blue, Icons.info);
  }

  static void _show(
      BuildContext context,
      String msg,
      Color color,
      IconData icon,
      ) {

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog(

      context: context,
      barrierDismissible: false,
      barrierLabel: "",
      transitionDuration: const Duration(milliseconds: 350),

      pageBuilder: (context, animation, secondaryAnimation) {

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });

        return Center(

          child: Material(

            color: Colors.transparent,

            child: ScaleTransition(

              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),

              child: Container(

                width: 270,

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 26,
                ),

                decoration: BoxDecoration(

                  color: theme.cardColor,

                  borderRadius: BorderRadius.circular(22),

                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black54
                          : Colors.black26,
                      blurRadius: 20,
                    )
                  ],

                ),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    Container(

                      height: 70,
                      width: 70,

                      decoration: BoxDecoration(
                        color: color.withOpacity(.15),
                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        icon,
                        size: 40,
                        color: color,
                      ),

                    ),

                    const SizedBox(height: 16),

                    Text(

                      msg,

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),

                    ),

                  ],

                ),

              ),

            ),

          ),

        );

      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {

        return FadeTransition(
          opacity: animation,
          child: child,
        );

      },

    );

  }

}