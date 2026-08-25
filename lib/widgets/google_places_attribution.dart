import 'package:flutter/material.dart';

/// Google Places の店舗情報を表示する画面に置く帰属表示。
///
/// 店名、写真、評価、口コミ件数、住所などの情報が Google Places 由来で
/// あることを、操作要素と誤認されない控えめな表示で明示する。
class GooglePlacesAttribution extends StatelessWidget {
  const GooglePlacesAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700);

    return Semantics(
      label: 'Google Maps Platform のデータを利用しています',
      container: true,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          'Google Maps Platform のデータを利用しています',
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }
}
