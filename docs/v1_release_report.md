# Swipeat v1.0 実装後リリース判定レポート（Issue 27）

判定日：2026年8月25日

## 1. 変更ファイル

- `lib/models`：独自ジャンル、分類結果、Premium entitlement
- `lib/data`：チェーン辞書、Google primaryTypeマッピング
- `lib/services`：Places parser、分類器、候補プール、Auth/Firestore/Billing/entitlement同期、AdMob UMP同意
- `lib/screens`：Recommendation、Premiumジャンル、Privacy、Decision/Home導線
- `android`：AdMob App ID、Release Application ID・署名・Secret必須ガード
- `docs`：技術設計、Product Decision、AdMob、Firebase、Billing、Privacy、Play公開準備
- `test`：分類、候補プール、Premium、課金境界、広告、Privacy、v1回帰

## 2. 新規ファイル

主な新規ファイルは `lib/models/restaurant_genre.dart`、`lib/models/restaurant_classification.dart`、`lib/data/chain_brand_dictionary.dart`、`lib/services/restaurant_classifier.dart`、`lib/services/candidate_pool.dart`、`lib/services/premium_entitlement_resolver.dart`、`lib/services/google_play_billing_service.dart`、`lib/services/premium_entitlement_sync_service.dart`、`lib/services/ad_service.dart`の拡張、`lib/widgets/google_places_attribution.dart`、`lib/screens/privacy_policy_screen.dart`、各セットアップ/公開準備文書、`test/v1_required_regression_test.dart`。

## 3. Freeの検索フロー

ログインなしで現在地を取得し、営業中・距離・カテゴリ条件をGoogle Placesへ送信する。最大20候補を一度だけ取得し、`CandidatePoolMode.free`で5件ずつ表示する。

## 4. Premiumの検索フロー

Premium機能選択時にGoogleログインとサーバーentitlementを確認する。active/trial/complimentary/developerをPremiumとして扱い、独自ジャンルを選択して最大20候補を連続表示する。Webは購入せず、Android契約の権限だけ共有する。

## 5. Freeの5件区切り処理

取得済み候補を `5 / 5 / 5 / 5` でページングする。「さらに5店舗を見る」はPlaces APIを再呼び出しせず、同じCandidatePoolの次バッチへ進む。0/3/20件も範囲外アクセスなく終了する。

## 6. 広告表示位置

Freeの5・10・15件後の区切り画面と、取得済みの全候補を見終えた最終画面にAdSlotを置く。スワイプ中、写真、店舗情報、Premium/Trial/complimentary/developer entitlementには広告リクエストを行わない。UMP同意確認後のみAdMobを初期化する。

## 7. Premium判定方式

Firebase/バックエンドのentitlementを正とし、クライアントのローカルbooleanや購入申告だけで昇格しない。Play購入tokenはFirebase ID tokenとともに同期し、サーバー検証結果を使用する。Developer overrideはDebug専用。

## 8. ジャンル分類方式

チェーン辞書 → 店舗名の高信頼ヒント → Google `primaryType` → 必要時のみGoogle `types` → `other` の順で分類する。Premium一致は `primaryGenre` のみを使用する。

## 9. 登録チェーン数

14ブランド（すき家、吉野家、松屋、松のや、一蘭、丸亀製麺、スシロー、CoCo壱番屋、マクドナルド、びっくりドンキー、サイゼリヤ、餃子の王将、大阪王将、焼肉きんぐ）。

## 10. Google fallback一覧

明示マッピングは `ramen_restaurant`、`sushi_restaurant`、`tonkatsu_restaurant`、`yakiniku_restaurant`、`italian_restaurant`、`hamburger_restaurant`、`japanese_curry_restaurant`、`japanese_restaurant`、`udon_restaurant`、`soba_restaurant`、`pasta_restaurant`、`french_restaurant`、`pizza_restaurant`、`chinese_restaurant`、`korean_restaurant`、`thai_restaurant`、`vietnamese_restaurant`、`indian_restaurant`、`seafood_restaurant`、`cafe`、`bakery`、`dessert_shop`、`bar`。汎用/未知値は推測せず `other` にする。

## 11. Android/WebのPremium共有方式

Firebase Authenticationで同じGoogleアカウントを識別し、Firestoreの本人読み取り可能なentitlementと、Play tokenを検証するバックエンドを共有する。クライアントからentitlementを書き込むFirestore ruleは拒否する。Webに決済処理はない。

## 12. 追加テスト

`test/v1_required_regression_test.dart`を追加し、14チェーン・松のや/松屋・餃子の王将/大阪王将の衝突、primaryType fallback、Free `5 / 5 / 5 / 5`、0/3/20件、Premium連続表示・広告なし、primaryGenre精度、active/trial/complimentary/developer/expiredを明示的なテスト名で固定した。

## 13. テスト結果

`flutter test`：85テスト、全件成功。

## 14. `flutter analyze`結果

`flutter analyze`：No issues found。

## 15. Webビルド結果

`flutter build web --release`：成功（Wasm dry-run warningのみ）。Firebase Hosting `https://swipeat-380b2.web.app` へIssue 23の実行コードをデプロイ済み。Issue 24〜27はWeb実行コードを変更していないため再デプロイ不要。

## 16. Androidビルド結果

`flutter build apk --debug`：成功。`flutter build appbundle --release`：本番Application ID未設定のため、Debug署名での誤出荷を防ぐガードが期待どおり停止。実鍵・Application ID・本番AdMob App IDを設定後に再実行する。

## 17. 未解決事項

- Play Consoleの商品、7日Trial、License Tester、RTDN/Play Developer API、バックエンドの本番運用が未設定。
- 本番Application ID、upload keystore、CI Secret、AdMob本番App/広告ユニットID、Firebase本番設定が未提供。
- Privacy文書の運営者名・所在地・問い合わせ先・公開URLを実値へ置換し、Data Safety申告を最終確定する必要がある。
- Google CloudのPlacesキーをローテーションし、Android SHA/API制限とWeb origin制限を設定する必要がある。
- 実機で位置情報、UMP同意、広告、購入復元、失効、Web共有を手動確認する必要がある。

## 18. ストア公開前に人間側で必要な設定

`docs/android_release_setup.md`、`docs/google_places_production_setup.md`、`docs/google_play_store_listing.md`、`docs/google_play_data_safety.md`、`docs/privacy_policy.md`のチェックリストを完了する。特にRelease環境変数をCI Secretから注入し、署名済みAABを内部テスト → クローズドテスト → 段階公開の順で検証する。

## リリース判定

コードと自動テストは公開候補として安定している。一方、実鍵・Play Console・Backend・法務情報が未設定のため、現時点は「本番提出前の実装完了・設定待ち」とする。設定完了後、Release AABとLicense Testingの手動確認を通過させてから本番公開する。
