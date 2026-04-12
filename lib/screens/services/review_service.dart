import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  static final InAppReview _review = InAppReview.instance;

  static Future<void> openReview() async {
    if (await _review.isAvailable()) {
      await _review.requestReview();
    } else {
      await _review.openStoreListing();
    }
  }
}