import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/ad_service.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> openPrivacyOptions(BuildContext context) async {
    final shown = await AdMobService.instance.showPrivacyOptionsForm();
    if (!context.mounted || shown) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('この端末では広告設定の変更は必要ありません。')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プライバシー')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'プライバシーポリシー',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text('最終更新日：2026年8月25日'),
          const SizedBox(height: 24),
          const _PolicySection(
            title: '取得する情報',
            body:
                '現在地は周辺店舗の検索に使用します。Googleログインを使う場合は、アカウント識別子とログインに必要なプロフィール情報を取得します。Premium購入時は購入トークンを検証のためサーバーへ送信します。Free利用ではアカウント登録を必須にしません。',
          ),
          const _PolicySection(
            title: '広告と同意',
            body:
                'Freeの区切り画面に限りGoogle AdMobのバナー広告を表示します。広告SDKの初期化と広告リクエストは、Google User Messaging Platform（UMP）で必要な同意を確認できた場合だけ行います。Premium、Trial、無償付与、開発者用権限では広告を表示しません。',
          ),
          const _PolicySection(
            title: 'Google Places',
            body:
                '検索地点と検索条件をGoogle Places APIへ送信し、店舗名、写真、評価、口コミ件数、住所などを表示します。Google Maps Platformの利用規約と帰属表示に従います。',
          ),
          const _PolicySection(
            title: '保存・共有・削除',
            body:
                'Premium権限はアカウント単位でサーバー管理します。決済情報そのものは保持せず、購入状態の検証に必要な識別子だけを扱います。削除・開示・問い合わせは、公開時に設定するサポート窓口から受け付けます。',
          ),
          const _PolicySection(
            title: '問い合わせ先',
            body:
                '公開前に、運営者名・所在地・問い合わせメールアドレスをこの画面とストア掲載情報へ設定します。未設定のまま正式公開しません。',
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => openPrivacyOptions(context),
              child: const Text('広告・プライバシー設定を変更'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
