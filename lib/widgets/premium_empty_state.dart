import 'package:flutter/material.dart';

/// Premium の条件に一致する営業中店舗がない場合の選択肢。
class PremiumEmptyState extends StatelessWidget {
  const PremiumEmptyState({
    super.key,
    required this.onWidenDistance,
    required this.onChangeGenre,
    required this.onOmakase,
  });

  final VoidCallback onWidenDistance;
  final VoidCallback onChangeGenre;
  final VoidCallback onOmakase;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'この条件では営業中の店舗が\n見つかりませんでした。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onWidenDistance,
            child: const Text('距離を広げる'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onChangeGenre,
            child: const Text('ジャンルを変更'),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onOmakase, child: const Text('おまかせで探す')),
        ],
      ),
    );
  }
}
