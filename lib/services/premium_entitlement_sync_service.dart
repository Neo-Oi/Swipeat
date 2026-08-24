import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/premium_entitlement.dart';
import 'google_play_billing_service.dart';

/// 購入tokenをバックエンドへ渡すための最小ペイロード。
class PurchaseVerificationPayload {
  const PurchaseVerificationPayload({
    required this.productId,
    required this.purchaseToken,
    required this.source,
    this.purchaseId,
  });

  factory PurchaseVerificationPayload.fromPurchaseUpdate(
    PremiumPurchaseUpdate update,
  ) {
    return PurchaseVerificationPayload(
      productId: update.productId,
      purchaseToken: update.verificationData.serverVerificationData,
      purchaseId: update.purchaseId,
      source: 'google_play',
    );
  }

  final String productId;
  final String purchaseToken;
  final String source;
  final String? purchaseId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'productId': productId,
      'purchaseToken': purchaseToken,
      'source': source,
      if (purchaseId != null) 'purchaseId': purchaseId,
    };
  }
}

abstract interface class AuthTokenProvider {
  Future<String?> getIdToken();
}

class FirebaseAuthTokenProvider implements AuthTokenProvider {
  FirebaseAuthTokenProvider({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Future<String?> getIdToken() async => _auth.currentUser?.getIdToken();
}

abstract interface class PremiumEntitlementVerificationClient {
  Future<PremiumEntitlement> verifyPurchase({
    required PurchaseVerificationPayload payload,
    required String firebaseIdToken,
  });
}

class EntitlementSyncEndpointConfiguration {
  const EntitlementSyncEndpointConfiguration({required this.endpoint});

  factory EntitlementSyncEndpointConfiguration.fromEnvironment() {
    return const EntitlementSyncEndpointConfiguration(
      endpoint: String.fromEnvironment('PREMIUM_ENTITLEMENT_SYNC_URL'),
    );
  }

  final String endpoint;

  bool get isConfigured => endpoint.isNotEmpty;
}

class PremiumEntitlementSyncException implements Exception {
  const PremiumEntitlementSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Play tokenをサーバー検証エンドポイントへ送るHTTPクライアント。
///
/// サーバーはFirebase ID tokenを検証し、Google Play Developer APIで購入を
/// 検証した後にのみ entitlement を返す。クライアントは権限を生成・更新しない。
class HttpPremiumEntitlementVerificationClient
    implements PremiumEntitlementVerificationClient {
  HttpPremiumEntitlementVerificationClient({
    EntitlementSyncEndpointConfiguration? configuration,
    http.Client? client,
  }) : configuration =
           configuration ??
           EntitlementSyncEndpointConfiguration.fromEnvironment(),
       _client = client ?? http.Client();

  final EntitlementSyncEndpointConfiguration configuration;
  final http.Client _client;

  @override
  Future<PremiumEntitlement> verifyPurchase({
    required PurchaseVerificationPayload payload,
    required String firebaseIdToken,
  }) async {
    if (!configuration.isConfigured) {
      throw const PremiumEntitlementSyncException(
        'PREMIUM_ENTITLEMENT_SYNC_URL が未設定です。',
      );
    }

    final response = await _client.post(
      Uri.parse(configuration.endpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $firebaseIdToken',
      },
      body: jsonEncode(payload.toMap()),
    );

    if (response.statusCode != 200) {
      throw PremiumEntitlementSyncException(
        'Premium権限の検証に失敗しました: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const PremiumEntitlementSyncException('Premium権限レスポンスの形式が不正です。');
    }
    return PremiumEntitlement.fromMap(decoded);
  }
}

/// Billing更新とサーバー検証をつなぐサービス。
class PremiumEntitlementSyncService {
  const PremiumEntitlementSyncService({
    required this.authTokenProvider,
    required this.verificationClient,
  });

  final AuthTokenProvider authTokenProvider;
  final PremiumEntitlementVerificationClient verificationClient;

  Future<PremiumEntitlement> sync(PremiumPurchaseUpdate update) async {
    if (!update.isEntitlementCandidate) {
      throw const PremiumEntitlementSyncException(
        '購入済み・復元済み以外の状態はentitlement検証へ送れません。',
      );
    }

    final firebaseIdToken = await authTokenProvider.getIdToken();
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw const PremiumEntitlementSyncException(
        'Premium権限の同期にはGoogleログインが必要です。',
      );
    }

    final payload = PurchaseVerificationPayload.fromPurchaseUpdate(update);
    if (payload.purchaseToken.isEmpty) {
      throw const PremiumEntitlementSyncException(
        '購入tokenが空のためPremium権限を付与できません。',
      );
    }

    return verificationClient.verifyPurchase(
      payload: payload,
      firebaseIdToken: firebaseIdToken,
    );
  }
}
