import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  static final InAppReview _review = InAppReview.instance;

  static Future<void> openReview() async {
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
      }

      /// 🔥 ALWAYS open Play Store (IMPORTANT)
      await _review.openStoreListing();
    } catch (e) {
      await _review.openStoreListing();
    }
  }
}