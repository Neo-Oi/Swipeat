# Web Premium 共有（Issue 19）

- Web は Stripe 等の決済を持たない。
- Web は Google ログイン後、`premiumEntitlements/{uid}` を読み取る。
- Android の Google Play 契約、Trial、complimentary、developer の active entitlement は同じアカウントで Premium として扱う。
- 未ログインはログイン案内、未契約は Android 契約案内、権限取得失敗は Free/再試行案内とする。
- entitlement が確認できない時にWebをPremiumへ昇格させない。

Firebase Authentication の Web OAuth 設定と Firestore Rules は `docs/firebase_auth_setup.md`、`firestore.rules` を参照する。
