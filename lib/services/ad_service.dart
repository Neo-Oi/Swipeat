import 'package:flutter/material.dart';

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

/// 区切り画面用の広告領域。Premium では [visible] を false にする。
///
/// ボタンと広告を密着させないため、広告領域自身が上下の余白を含む。
class AdSlot extends StatelessWidget {
  const AdSlot({super.key, this.visible = true, this.height = 180});

  final bool visible;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Semantics(
      label: '広告領域',
      container: true,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          '広告領域',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ),
    );
  }
}
