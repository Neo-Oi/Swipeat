import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'candidate_pool.dart';

/// 広告 SDK と画面の間に置く v1.0 の広告表示契約。
///
/// Issue 11 ではプレースホルダーを表示し、AdMob の接続は Issue 21 で行う。
class AdService {
  const AdService();

  bool shouldShowBreakAd({
    required CandidatePoolMode mode,
    required int completedCount,
    required bool hasMoreCandidates,
  }) {
    return mode == CandidatePoolMode.free &&
        hasMoreCandidates &&
        completedCount > 0 &&
        completedCount < CandidatePool.maxCandidates &&
        completedCount % CandidatePool.freePageSize == 0;
  }
}

/// AdMob の初期化とテスト広告 ID の選択を担当する。
class AdMobService {
  AdMobService({AdMobConfiguration? configuration})
    : configuration = configuration ?? AdMobConfiguration.fromEnvironment();

  static final AdMobService instance = AdMobService();

  final AdMobConfiguration configuration;
  bool _initialized = false;
  bool _adsAllowed = false;

  bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!isSupportedPlatform || _initialized) return;

    try {
      final consentInformation = ConsentInformation.instance;
      final consentUpdated = Completer<bool>();
      consentInformation.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!consentUpdated.isCompleted) consentUpdated.complete(true);
        },
        (_) {
          if (!consentUpdated.isCompleted) consentUpdated.complete(false);
        },
      );

      if (!await consentUpdated.future) return;

      await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
      if (!await consentInformation.canRequestAds()) return;

      await MobileAds.instance.initialize();
      _adsAllowed = true;
      _initialized = true;
    } catch (_) {
      // Consent/SDK failures must never result in an ad request.
      _adsAllowed = false;
    }
  }

  bool get canLoadAds => _adsAllowed;

  Future<bool> showPrivacyOptionsForm() async {
    if (!isSupportedPlatform) return false;

    try {
      final requirement = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (requirement != PrivacyOptionsRequirementStatus.required) return false;

      final dismissed = Completer<bool>();
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (!dismissed.isCompleted) dismissed.complete(error == null);
      });
      return dismissed.future;
    } catch (_) {
      return false;
    }
  }

  BannerAd? loadBanner({
    required VoidCallback onLoaded,
    required Function(LoadAdError error) onFailedToLoad,
  }) {
    if (!isSupportedPlatform || !configuration.isConfigured) return null;

    final ad = BannerAd(
      adUnitId: configuration.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailedToLoad(error);
        },
      ),
    );
    ad.load();
    return ad;
  }
}

class AdMobConfiguration {
  const AdMobConfiguration({required this.bannerAdUnitId});

  factory AdMobConfiguration.fromEnvironment() {
    const releaseBannerId = String.fromEnvironment('ADMOB_BANNER_AD_UNIT_ID');
    return AdMobConfiguration(
      bannerAdUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/6300978111'
          : releaseBannerId,
    );
  }

  final String bannerAdUnitId;

  bool get isConfigured => bannerAdUnitId.isNotEmpty;
}

/// 区切り画面用の広告領域。Premium では [visible] を false にする。
///
/// ボタンと広告を密着させないため、広告領域自身が上下の余白を含む。
class AdSlot extends StatefulWidget {
  const AdSlot({super.key, this.visible = true, this.height = 180});

  final bool visible;
  final double height;

  @override
  State<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<AdSlot> {
  BannerAd? bannerAd;
  bool adLoaded = false;

  @override
  void initState() {
    super.initState();
    loadAd();
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }

  Future<void> loadAd() async {
    if (!widget.visible) return;
    await AdMobService.instance.initialize();
    if (!mounted || !AdMobService.instance.canLoadAds) return;

    bannerAd = AdMobService.instance.loadBanner(
      onLoaded: () {
        if (mounted) setState(() => adLoaded = true);
      },
      onFailedToLoad: (_) {
        if (mounted) setState(() => adLoaded = false);
      },
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Semantics(
      label: '広告領域',
      container: true,
      child: Container(
        height: widget.height,
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: bannerAd == null || !adLoaded
            ? Text(
                '広告領域',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              )
            : SizedBox(
                width: bannerAd!.size.width.toDouble(),
                height: bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: bannerAd!),
              ),
      ),
    );
  }
}
