# Firebase Authentication 設定（Issue 15）

Issue 15 のコードは Firebase の設定値を Dart ソースへ埋め込まず、次の `--dart-define` から読み取ります。

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
FIREBASE_AUTH_DOMAIN       # Web の場合
FIREBASE_STORAGE_BUCKET    # 必要な場合
FIREBASE_MEASUREMENT_ID    # 必要な場合
GOOGLE_SERVER_CLIENT_ID    # Android の Google Sign-In
```

## Firebase Console 側で必要な設定

- `.firebaserc` の `swipeat-380b2` プロジェクトで Authentication を有効化する。
- Sign-in provider の Google を有効化する。
- Android アプリの package name と SHA-1/SHA-256 を登録する。
- Web の承認済みドメインに Hosting ドメインとローカル開発ドメインを追加する。
- OAuth 同意画面と公開範囲を確認する。
- Android の server client ID を Play/Debug の設定に合わせる。

## ビルド例

```text
flutter run \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=...
```

値が不足した状態では、Premium ログイン時に設定エラーを返し、Free の未ログイン導線は利用できます。API キー・OAuth クライアント・サービスアカウント秘密鍵はコミットしません。
