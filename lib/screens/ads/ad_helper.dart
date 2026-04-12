import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../utils/app_config.dart';
import '../services/purchase_service.dart';

class AdHelper {
  static InterstitialAd? _ad;

  /// 🔥 TEST ID (production ch replace karna)
  static String get adUnitId =>
      'ca-app-pub-3940256099942544/1033173712';

  /// 🔥 LOAD AD
  static void loadAd() {
    /// ❌ Ads disabled OR premium user
    if (!AppConfig.enableAds || PurchaseService.isAdsRemoved) {
      return;
    }

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
        },
      ),
    );
  }

  /// 🔥 SHOW AD
  static void showInterstitialAd({required Function onAdClosed}) {
    /// ❌ Ads disabled OR premium user
    if (!AppConfig.enableAds || PurchaseService.isAdsRemoved) {
      onAdClosed();
      return;
    }

    if (_ad != null) {
      _ad!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _ad = null;

          loadAd(); // preload next

          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _ad = null;

          onAdClosed();
        },
      );

      _ad!.show();
    } else {
      /// Ad ready nahi → direct action
      loadAd();
      onAdClosed();
    }
  }
}