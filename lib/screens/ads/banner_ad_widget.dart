import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../utils/app_config.dart';
import '../services/purchase_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  /// TEST Banner ID (production ch replace karna)
  final String adUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  @override
  void initState() {
    super.initState();

    /// ❌ Ads OFF ya Premium user → load hi na karo
    if (!AppConfig.enableAds || PurchaseService.isAdsRemoved) {
      return;
    }

    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // print('Banner error: $error');
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    /// ❌ Ads OFF ya Premium user → show na karo
    if (!AppConfig.enableAds || PurchaseService.isAdsRemoved) {
      return const SizedBox();
    }

    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}