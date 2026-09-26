import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // RevenueCat API Keys (provided via --dart-define from .env at build time)
  static const String _apiKeyIOS =
      String.fromEnvironment('REVENUECAT_IOS_API_KEY');
  static const String _apiKeyAndroid =
      String.fromEnvironment('REVENUECAT_ANDROID_API_KEY');

  static String get _apiKey => Platform.isIOS ? _apiKeyIOS : _apiKeyAndroid;

  // Entitlement ID (set in RevenueCat dashboard)
  static const String entitlementId = 'premium';

  // Initialize RevenueCat
  static Future<void> init() async {
    await Purchases.setLogLevel(
      kReleaseMode ? LogLevel.error : LogLevel.debug,
    );

    final configuration = PurchasesConfiguration(_apiKey);
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

  /// プレミアム権限の有無を流し続ける。
  ///
  /// [isPremium] は呼んだ瞬間の状態しか返さないため、購入・復元・失効を
  /// 画面が取りこぼしてしまう。RevenueCat の更新通知を購読して、
  /// 変化するたびに流し直す。
  Stream<bool> premiumStream() {
    final controller = StreamController<bool>();
    var latest = false;

    void emit(bool value) {
      if (controller.isClosed) return;
      latest = value;
      controller.add(value);
    }

    bool hasEntitlement(CustomerInfo info) =>
        info.entitlements.all[entitlementId]?.isActive ?? false;

    void onUpdate(CustomerInfo info) => emit(hasEntitlement(info));

    controller.onListen = () async {
      Purchases.addCustomerInfoUpdateListener(onUpdate);
      try {
        emit(hasEntitlement(await Purchases.getCustomerInfo()));
      } catch (e) {
        debugPrint('premiumStream: failed to read customer info: $e');
        emit(latest);
      }
    };

    controller.onCancel = () {
      Purchases.removeCustomerInfoUpdateListener(onUpdate);
    };

    return controller.stream;
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
