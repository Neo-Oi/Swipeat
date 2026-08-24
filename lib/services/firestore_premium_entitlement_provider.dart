import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/premium_entitlement.dart';
import 'premium_service.dart';

/// Firestore の本人用 entitlement を読む provider。
///
/// このクライアントには書込 API を提供しない。購入検証や complimentary
/// 付与による更新は、信頼できるバックエンド/Admin SDK から行う。
class FirestorePremiumEntitlementProvider
    implements PremiumEntitlementProvider {
  FirestorePremiumEntitlementProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'premiumEntitlements';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<PremiumEntitlement> readEntitlement() async {
    final user = _auth.currentUser;
    if (user == null) return const PremiumEntitlement.none();

    final snapshot = await _firestore
        .collection(collectionName)
        .doc(user.uid)
        .get();
    final data = snapshot.data();
    if (data == null) return const PremiumEntitlement.none();

    return PremiumEntitlement.fromMap(_normalizeFirestoreDates(data));
  }

  static Map<String, dynamic> _normalizeFirestoreDates(
    Map<String, dynamic> data,
  ) {
    return data.map((key, value) {
      if (value is Timestamp) return MapEntry(key, value.toDate());
      return MapEntry(key, value);
    });
  }
}
