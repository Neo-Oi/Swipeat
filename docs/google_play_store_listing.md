# Google Play ストア掲載準備（Issue 25）

Play Consoleへ登録する際の原稿と確認票。`[要設定]` は運営者が実値へ置換してから提出する。

## 基本情報

- アプリ名：Swipeat
- 短い説明（80文字以内）：探すより、決める。現在地周辺の営業中のお店から、すぐに候補を提案。
- Application ID：`[要設定：SWIPEAT_APPLICATION_ID と一致]`
- カテゴリ：フード＆ドリンク
- 対象地域・言語：日本語、日本
- サポートメール：`[要設定]`
- プライバシーポリシーURL：`[要設定：公開済みURL]`

## 詳細説明（案）

Swipeatは、現在地周辺の営業中のお店から候補を提案し、スワイプで決めるためのアプリです。

1. 位置情報の許可と、同行者・予算・距離などの条件を指定します。
2. Google Placesの店舗情報から、最大20件の候補を取得します。
3. Freeでは5件ずつ、Premiumでは候補を連続して確認できます。
4. 右スワイプで店舗を決定し、Google Mapsで経路や詳細を確認できます。

Freeはログインなしで利用できます。Freeの区切り画面にはバナー広告が表示されます。PremiumはAndroidのGoogle Play定期購入で提供し、Trial中もPremium機能を利用できます。Webからの購入やStripe決済は提供しません。価格・無料体験・解約条件はPlay Consoleの商品情報を正とします。

## スクリーンショット構成（案）

1. Home：「今すぐ提案」「距離を選んで探す」「希望を指定して探す」
2. Recommendation：候補カード、評価、距離、営業状態、スワイプ説明
3. 区切り画面：「まだ決まりませんか？」「さらに5店舗を見る」、広告領域
4. Premiumジャンル選択：大分類 → 詳細分類 → おまかせ
5. Decision：「今日はここにしよう」「Google Mapsで開く」

実際のスクリーンショットには本番APIキー、個人情報、未許諾の写真を含めない。

## Play Console申告チェックリスト

- [ ] Content ratingの質問へ回答し、位置情報・広告・外部リンクを実装と一致させる。
- [ ] Data Safetyを `docs/google_play_data_safety.md` とFirebase/AdMob設定に突合する。
- [ ] 「アプリに広告が含まれる」をFreeのバナー広告に合わせて申告する。
- [ ] アカウント削除・データ削除の受付方法とプライバシーポリシーURLを登録する。
- [ ] Premium subscriptionのbase plan、価格、7日間Trial、地域、解約説明をPlayの商品情報から転記する。
- [ ] License Testerを登録し、購入・復元・保留・キャンセル・期限切れを内部テストで確認する。
- [ ] ログインが必要なPremium画面には、審査用アカウントまたは手順をPlay ConsoleのApp accessへ登録する。
- [ ] 広告SDKの申告、対象API、位置情報Permission、Application IDをAABと突合する。

## 段階公開

1. Internal testing：開発者・License Testerで課金、同意、位置情報、広告、クラッシュを確認。
2. Closed testing：実機・複数Androidバージョン・低速回線で候補検索と決定遷移を確認。
3. Production：審査提出後、段階的ロールアウトでクラッシュ率、広告、課金状態を監視。

各段階のowner、開始日、完了条件、ロールバック担当をPlay ConsoleのIssueへ記録する。
