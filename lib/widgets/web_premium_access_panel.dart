import 'package:flutter/material.dart';

import '../services/web_premium_access_service.dart';

/// Webでの課金を開始させず、Android契約の共有状態だけを表示する。
class WebPremiumAccessPanel extends StatelessWidget {
  const WebPremiumAccessPanel({super.key, required this.result, this.onSignIn});

  final WebPremiumAccessResult result;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    switch (result.status) {
      case WebPremiumAccessStatus.premium:
        return const _PanelMessage(
          icon: Icons.workspace_premium,
          title: 'Premiumを利用できます',
          message: 'Androidで契約したPremium権限がこのWebアカウントに反映されています。',
        );
      case WebPremiumAccessStatus.unauthenticated:
        return _PanelMessage(
          icon: Icons.login,
          title: 'Googleログインが必要です',
          message: 'Androidで契約したPremiumをWebでも利用するには、同じGoogleアカウントでログインしてください。',
          action: onSignIn == null
              ? null
              : OutlinedButton(
                  onPressed: onSignIn,
                  child: const Text('Googleでログイン'),
                ),
        );
      case WebPremiumAccessStatus.free:
        return const _PanelMessage(
          icon: Icons.phone_android,
          title: 'AndroidでPremiumを契約できます',
          message:
              'Webでは決済できません。AndroidのGoogle Playで契約すると、このアカウントのWebでも利用できます。',
        );
      case WebPremiumAccessStatus.unavailable:
        return const _PanelMessage(
          icon: Icons.sync_problem,
          title: 'Premium権限を確認できません',
          message: '通信または権限サービスを確認してから、もう一度お試しください。',
        );
    }
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
