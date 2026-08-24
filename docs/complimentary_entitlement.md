# Complimentary / Developer Premium（Issue 20）

## Complimentary

- 家族・関係者の無償権限は `premiumEntitlements/{uid}` の `source=complimentary` として管理する。
- 付与・解除・期限変更は Firebase Admin SDK または管理バックエンドから行う。
- アプリの Dart コード、Remote Config、Firestore のクライアント書込から付与しない。
- メールアドレスをコードへ直書きしない。管理画面で Firebase `uid` を選択して付与する。
- Firestore Rules はクライアントの create/update/delete を拒否する。

## Developer override

- Debug ビルドでのみ `--dart-define=SWIPEAT_DEVELOPER_PREMIUM=true` を利用できる。
- `DeveloperPremiumOverride` は `kDebugMode` が false の場合に必ず null を返す。
- Release の正式なPlay Billing確認には Google Play License Testing を使用する。
- Developer override の存在だけで、Play の購読・サーバー検証を省略しない。
