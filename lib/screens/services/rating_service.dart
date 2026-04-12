import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'review_service.dart';

class RatingService {
  static int actionCount = 0;

  /// 🔥 Call this anywhere
  static Future<void> trigger(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    bool hasShown = prefs.getBool('ratingShown') ?? false;
// prefs.remove('ratingShown');
    actionCount++;
    if (actionCount >= 5 && !hasShown) {
      await prefs.setBool('ratingShown', true);
      _showDialog(context);
    }
  }

  static void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Enjoying Xpense Eye? 😊"),
        content: Text("If you like the app, please rate us!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ReviewService.openReview();
            },
            child: Text("Rate Now ⭐"),
          ),
        ],
      ),
    );
  }
}