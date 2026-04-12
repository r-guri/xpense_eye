import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;

  static bool isAdsRemoved = false;
  static List<ProductDetails> products = [];

  /// 🔥 INIT (call in main.dart)
  static void init() {
    /// Listen purchases (new + restore)
    _iap.purchaseStream.listen((purchases) {
      for (var purchase in purchases) {
        if (purchase.productID == 'remove_ads') {
          isAdsRemoved = true;

          /// 🔥 IMPORTANT: complete purchase
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
        }
      }
    });

    /// Load products
    loadProducts();

    /// Restore old purchases
    _iap.restorePurchases();
  }

  /// 🔥 LOAD PRODUCTS
  static Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails({'remove_ads'});

    if (response.notFoundIDs.isEmpty) {
      products = response.productDetails;
    } else {
      print("Product not found ❌");
    }
  }

  /// 🔥 BUY REMOVE ADS
  static Future<void> buyRemoveAds() async {
    if (products.isEmpty) {
      print("Products not loaded ❌");
      return;
    }

    final product = products.first;

    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: product);

    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// 🔁 RESTORE PURCHASE (manual button)
  static Future<void> restore() async {
    await _iap.restorePurchases();
  }
}