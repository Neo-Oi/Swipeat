# Premium entitlement 検証バックエンド契約（Issue 18）

クライアントは購入tokenを申告するだけでPremiumにならない。次のエンドポイントを信頼できるバックエンドで実装する。

```text
POST /v1/premium/verify-google-play
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

{
  "productId": "<Play subscription product id>",
  "purchaseToken": "<Play verification token>",
  "purchaseId": "<optional>",
  "source": "google_play"
}
```

## サーバー側の必須検証

- Firebase Admin SDK で ID token を検証し、`uid` を取得する。
- リクエストの product ID が許可された Play subscription と一致することを確認する。
- Google Play Developer API で package name、subscription product、purchase token を検証する。
- purchase state、acknowledgement、expiry、auto-renew、free-trial offer を確認する。
- `uid` と Google Play purchase token の紐付けをサーバーで管理する。
- 有効なら `premiumEntitlements/{uid}` を Admin SDK で upsert する。
- `source` はサーバー側で `google_play` / `free_trial` を決定し、クライアント入力を信頼しない。
- 失効、返金、解約、期限切れを RTDN/Pub/Sub または定期同期で反映する。

## レスポンス例

```json
{
  "status": "active",
  "source": "free_trial",
  "validFrom": "2026-08-25T00:00:00.000Z",
  "validUntil": "2026-09-01T00:00:00.000Z",
  "productId": "swipeat_premium_monthly",
  "updatedAt": "2026-08-25T00:01:00.000Z"
}
```

Play Developer API のサービスアカウント鍵、RTDN topic、API URL、Firebase Admin secret はFlutterへ置かず、バックエンドのSecret Managerで管理する。
