# Google Play Billing 設定（Issue 17）

## コード側

- 商品 ID は `PREMIUM_PRODUCT_ID` の `--dart-define` から受け取る。
- 価格は `ProductDetails.price` を表示する。`300円` 等をコードへ固定しない。
- `GooglePlayBillingService` は Android でのみ購入を開始する。
- Web では購入処理を行わず、Issue 19 のサーバー entitlement のみ利用する。
- 7日間無料体験は端末の日付判定をせず、Play Console の subscription offer/status を使用する。
- 購入 token/verificationData は Issue 18 のサーバー検証へ渡す。

## Play Console 側で必要な設定

- Subscription の商品 ID を決める（コードの `PREMIUM_PRODUCT_ID` と一致させる）。
- Base plan、月額価格、地域、7日間の free trial offer を登録する。
- License Tester を登録し、購入・復元・キャンセル・期限切れを検証する。
- 内部テストトラックへ AAB をアップロードしてから Billing を検証する。
- 商品 ID や価格を本番へ変更した場合は、リリース前に表示価格とストア表示を再確認する。
