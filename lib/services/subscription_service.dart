import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // RevenueCat API Keys (replace with your actual keys)
  static const String _apiKeyIOS = 'YOUR_REVENUECAT_IOS_API_KEY';
  static const String _apiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_API_KEY';

  static String get _apiKey => Platform.isIOS ? _apiKeyIOS : _apiKeyAndroid;

  // Entitlement ID (set in RevenueCat dashboard)
  static const String entitlementId = 'premium';

  // Initialize RevenueCat
  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    configuration = PurchasesConfiguration(_apiKey);

    await Purchases.configure(configuration);
  }

  // Login user to RevenueCat
  Future<void> login(String userId) async {
    await Purchases.logIn(userId);
  }

  // Logout user from RevenueCat
  Future<void> logout() async {
    await Purchases.logOut();
  }

  // Check if user has premium access
  Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  // Add listener for customer info updates
  void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  // Get available packages
  Future<List<Package>> getPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e) {
      return [];
    }
  }

  // Purchase a package
  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      // Handle specific errors
      if (e is PurchasesErrorCode) {
        // User cancelled
        if (e == PurchasesErrorCode.purchaseCancelledError) {
          return false;
        }
      }
      rethrow;
    }
  }

  // Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get customer info
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }
}
