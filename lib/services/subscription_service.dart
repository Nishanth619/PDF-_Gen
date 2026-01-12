import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Subscription Service - Ad-Free Model
/// All features are FREE. Premium only removes ads.
class SubscriptionService extends ChangeNotifier {
  static const String _isPremiumKey = 'is_premium_user';
  static const String _subscriptionTypeKey = 'subscription_type';
  
  // Product IDs for Google Play / App Store
  static const String monthlyProductId = 'pdfgen_adfree_monthly';
  static const String yearlyProductId = 'pdfgen_adfree_yearly';
  static const String lifetimeProductId = 'pdfgen_adfree_lifetime';
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  bool _isPremium = false;
  bool _isLoading = true;
  String _subscriptionType = 'free';
  List<ProductDetails> _products = [];
  
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  String get subscriptionType => _subscriptionType;
  List<ProductDetails> get products => _products;
  
  /// Check if ads should be shown
  bool get showAds => !_isPremium;

  SubscriptionService() {
    _initialize();
  }

  Future<void> initialize() async {
    await _initialize();
  }

  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Load saved premium status
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_isPremiumKey) ?? false;
      _subscriptionType = prefs.getString(_subscriptionTypeKey) ?? 'free';
      
      // Initialize in-app purchases
      final available = await _inAppPurchase.isAvailable();
      if (available) {
        await _loadProducts();
        
        // Listen for purchase updates
        _subscription = _inAppPurchase.purchaseStream.listen(
          _onPurchaseUpdate,
          onError: (error) => debugPrint('Purchase error: $error'),
        );
      }
    } catch (e) {
      debugPrint('Error initializing subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProducts() async {
    final productIds = <String>{
      monthlyProductId,
      yearlyProductId,
      lifetimeProductId,
    };
    
    final response = await _inAppPurchase.queryProductDetails(productIds);
    _products = response.productDetails;
    notifyListeners();
  }

  /// Purchase a subscription to remove ads
  Future<bool> purchaseSubscription(String productId) async {
    try {
      final productDetails = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );
      
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Purchase error: $e');
      return false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchase);
      }
      
      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    _isPremium = true;
    
    if (purchase.productID == monthlyProductId) {
      _subscriptionType = 'monthly';
    } else if (purchase.productID == yearlyProductId) {
      _subscriptionType = 'yearly';
    } else if (purchase.productID == lifetimeProductId) {
      _subscriptionType = 'lifetime';
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, true);
    await prefs.setString(_subscriptionTypeKey, _subscriptionType);
    
    notifyListeners();
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Restore error: $e');
    }
  }

  /// For testing: Set premium status manually
  Future<void> setPremiumStatus(bool isPremium) async {
    _isPremium = isPremium;
    _subscriptionType = isPremium ? 'test' : 'free';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, isPremium);
    await prefs.setString(_subscriptionTypeKey, _subscriptionType);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
