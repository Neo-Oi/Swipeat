# Swipeat v1.0 フリーミアム実装 Issue バックログ

この文書は「Swipeat v1.0 Android / Web フリーミアム実装指示書」を、独立してレビュー・実装・検証できる GitHub Issue 単位に分割したものです。

## 進め方

- Issue は原則として番号順に進める。
- `依存` に未完了 Issue がある場合は、先に依存 Issue を完了する。
- 各 Issue は、実装・テスト・必要なドキュメント更新を含めて完了とする。
- Android の変更であっても、Web の回帰確認が必要な Issue では Web ビルドを行う。
- 課金、広告、認証、ストア設定は外部コンソール作業を含むため、「コード完了」と「人間による設定完了」を分けて管理する。
- 未確定事項を実装者判断で確定しない。必要なものは `decision-needed` ラベルを付けて別 Issue で決定する。

## 推奨ラベル

| ラベル | 用途 |
| --- | --- |
| `v1.0` | v1.0 対象 |
| `foundation` | モデル・共通基盤 |
| `free` | Free 導線 |
| `premium` | Premium 導線 |
| `android` | Android 固有 |
| `web` | Web 固有 |
| `backend` | Firebase / サーバー権限 |
| `billing` | Google Play Billing |
| `ads` | AdMob |
| `privacy` | ポリシー・申告 |
| `testing` | 自動テスト・回帰確認 |
| `release` | ストア公開準備 |
| `decision-needed` | 人間による仕様決定が必要 |

## 全 Issue 共通の Definition of Done

- Issue の受け入れ条件を満たしている。
- 新規ロジックに対する自動テストが追加されている。
- `flutter analyze` で新規エラー・警告を発生させていない。
- Android 対応によって Web 版を破壊していない。
- API キー、メールアドレス、Premium の固定フラグ等の秘密・権限情報をハードコードしていない。
- 実装範囲外の全面リファクタリングを行っていない。

## Milestone 0: 調査と仕様固定

### Issue 01: 既存実装の棚卸しと v1.0 技術設計を確定する

**Labels:** `v1.0`, `foundation`, `android`, `web`

**目的:** 現状を壊さず、以降の Issue が同じ設計前提で進められる状態にする。

**作業:** 

- `Restaurant`、`GooglePlacesService`、各画面、Firebase、Web、API キー、FieldMask、認証・Premium 既存実装を調査する。
- Free/Premium の状態遷移と責務分割を設計書にする。
- Android と Web で共通利用する層、プラットフォーム固有層を明記する。
- 現在の自動距離拡大挙動を記録し、Premium ジャンル検索には適用しない方針を明記する。

**受け入れ条件:**

- 調査結果、変更予定ファイル、責務分割、既知の技術的リスクが文書化されている。
- `RestaurantGenre`、`RestaurantClassification`、`RestaurantClassifier`、`CandidatePool`、`PremiumEntitlement`、広告・課金境界の配置方針が決まっている。

**依存:** なし

---

### Issue 02: 未確定仕様を Product Decision として管理する

**Labels:** `v1.0`, `decision-needed`

**目的:** 未確定項目を実装者判断で固定しないようにする。

**決定対象:**

- 20候補を使い切った後の動作。
- Free の候補不足時に自動距離拡大を継続するか。
- Premium v1.0 に含める絞り込み（評価、価格帯、チェーン制御、個人店優先）の範囲。
- Google Play の商品 ID、最終価格、課金周期。
- 日本国外での Premium 動作。
- 本番 Application ID。

**受け入れ条件:**

- 各項目に owner、決定期限、採用案または保留理由が記録されている。
- 未決定の項目は関連 Issue のスコープ外として明示されている。

**依存:** Issue 01

## Milestone 1: ジャンル分類基盤

### Issue 03: Swipeat 独自ジャンルと店舗分類モデルを実装する

**Labels:** `v1.0`, `foundation`, `premium`

**目的:** Google の `types` と独立した、型安全な分類モデルを用意する。

**作業:**

- 指示書記載の全ジャンルを `RestaurantGenre` として定義する。
- 大分類と詳細分類の対応、表示名、安定した ID を定義する。
- `RestaurantClassification` に `primaryGenre`、`subTags`、`style`、`brand`、`isChain`、`classificationSource` を持たせる。
- `primaryGenre` は 1 店舗につき最大 1 つにする。

**受け入れ条件:**

- 正式ジャンル一覧を漏れなく表現できる。
- 大分類から詳細分類を取得できる。
- `primaryGenre` と `subTags` を別々に扱える。
- モデルの単体テストがある。

**依存:** Issue 01

---

### Issue 04: 日本主要チェーン辞書をデータとして実装する

**Labels:** `v1.0`, `foundation`, `premium`

**目的:** 巨大な条件分岐を使わず、主要チェーンを高精度に分類する。

**作業:**

- `ChainBrandDefinition` を定義する。
- 少なくとも指定テスト対象の 13 チェーンを初期 seed に含める。
- 表記揺れ・支店名を扱える正規化とマッチ方法を定義する。
- より具体的なブランド名を優先し、「松のや」と「松屋」等の衝突を防ぐ。
- 辞書を後から追加・変更できるデータ構造にする。

**受け入れ条件:**

- すき家、松屋、松のや、一蘭、丸亀製麺、スシロー、CoCo壱番屋、マクドナルド、びっくりドンキー、サイゼリヤ、餃子の王将、大阪王将、焼肉きんぐが指定ジャンルに分類される。
- `松のや → 松屋`、`餃子の王将 → 大阪王将` の誤判定がない。
- ブランド追加に分類ロジックの変更が不要である。

**依存:** Issue 03

---

### Issue 05: Google primaryType マッパーを実装する

**Labels:** `v1.0`, `foundation`, `premium`

**目的:** 未登録店舗を Google の代表分類から保守的に分類する。

**作業:**

- Google `primaryType` から Swipeat ジャンルへのテーブル駆動マッパーを実装する。
- 少なくとも指示書記載のマッピングを含める。
- 汎用 `restaurant` は `other` とし、無理な推測をしない。

**受け入れ条件:**

- `ramen_restaurant → ramen`、`sushi_restaurant → sushi`、`restaurant → other` がテストされている。
- マッピング追加時に巨大な `if / else` が不要である。

**依存:** Issue 03

---

### Issue 06: RestaurantClassifier を実装する

**Labels:** `v1.0`, `foundation`, `premium`, `testing`

**目的:** 指定された優先順位で、1 店舗に 1 つの代表ジャンルを付与する。

**分類順:** チェーン辞書 → 高信頼度店舗名判定 → Google `primaryType` → 必要時のみ `types` → `other`

**作業:**

- 分類ソースとマッチしたブランドを結果に保持する。
- `subTags` は補助情報として保持するが、Premium 検索判定には使わない。
- Debug ビルドで分類品質を確認できる構造化ログを用意する。
- Release では位置情報や大量の店舗データを不用意に出力しない。

**受け入れ条件:**

- チェーン辞書が Google fallback より優先される。
- 不明店舗は無理に推測されず `other` になる。
- `placeName`、`placeId`、`googlePrimaryType`、`googleTypes`、`matchedBrand`、`primaryGenre`、`classificationSource` を Debug 時に確認できる。
- Issue 04、05 のケースを含む分類テストが通る。

**依存:** Issue 04, Issue 05

---

### Issue 07: Google Places レスポンスと Restaurant モデルを分類対応にする

**Labels:** `v1.0`, `foundation`, `free`, `premium`

**目的:** Places の取得結果を分類・Premium フィルタに必要な情報付きで扱えるようにする。

**作業:**

- FieldMask に `primaryType` を追加する。
- `Restaurant` が Google `primaryType`、`types`、分類結果を保持できるようにする。
- 同一レスポンス内の `placeId` 重複を除外する。
- `maxResultCount: 20` を維持し、20件未満を正常系として扱う。
- Places API をモック可能な境界に分離する。

**受け入れ条件:**

- API レスポンスから分類結果まで変換される。
- `placeId` が同じ店舗を検索セッション内で重複表示しない。
- 0件、3件、20件で例外にならない。
- API キーの値をソースへ追加していない。

**依存:** Issue 06

## Milestone 2: Free 候補プールと5件区切り

### Issue 08: CandidatePool を実装する

**Labels:** `v1.0`, `foundation`, `free`, `premium`, `testing`

**目的:** 候補、表示済み件数、残り件数、5件区切りを画面から独立して管理する。

**作業:**

- 取得済み最大20候補を検索セッション単位で保持する。
- Free は 5 件単位、Premium は全件連続で取り出せるようにする。
- `placeId` 重複を防止する。
- API 再検索を CandidatePool の「次の5件」に含めない。

**受け入れ条件:**

- 20件の Free 候補が `5 / 5 / 5 / 5` になる。
- 3件は3件表示後に終了し、0件も正常に終了する。
- Premium は20件を中断なしで返す。
- 次ページ取得のテストで Places API 呼び出し回数が増えない。

**依存:** Issue 07

---

### Issue 09: PremiumEntitlement のドメインモデルと機能ゲートを実装する

**Labels:** `v1.0`, `foundation`, `premium`

**目的:** UI がローカル boolean に依存せず、Free/Premium/Trial を判定できるようにする。

**作業:**

- `PremiumEntitlement` に status、source、有効期間等を表現する。
- source は最低限 `google_play`、`free_trial`、`complimentary`、`developer` を扱う。
- Trial を完全 Premium として判定する。
- Premium 失効・未確認時は安全側で Free として扱う方針を定義する。
- データ取得元を抽象化し、後続 Issue で Firebase / Billing を接続できるようにする。

**受け入れ条件:**

- active、trial、expired、unknown の判定テストがある。
- UI や候補プールに `premium = true` の固定値を置かない。
- Free はログインなしで利用できる。

**依存:** Issue 01

---

### Issue 10: RecommendationScreen を CandidatePool ベースに移行する

**Labels:** `v1.0`, `free`, `premium`

**目的:** Free/Premium の表示差を画面内の場当たり的な index 判定から分離する。

**作業:**

- 既存のスワイプ、Decision、Google Maps 遷移を維持する。
- Free は現在のバッチ内だけ連続表示する。
- Premium/Trial は最大20件を連続表示する。
- 0件と候補終了を明確に表示する。

**受け入れ条件:**

- Free では5件スキップ後に区切りへ遷移する。
- Premium では5件目で止まらない。
- 5件未満、20件未満でも範囲外アクセスが発生しない。
- Decision への遷移と Google Maps 連携が回帰テストされている。

**依存:** Issue 08, Issue 09

---

### Issue 11: Free の5件区切り画面と広告スロットを実装する

**Labels:** `v1.0`, `free`, `ads`

**目的:** 5・10・15件終了時に、再検索せず次の5件へ進める区切り UI を用意する。

**作業:**

- 「まだ決まりませんか？」、広告領域、十分な余白、「さらに5店舗を見る」を配置する。
- 広告 SDK 未接続時にもテスト用プレースホルダーでレイアウト確認可能にする。
- 最終バッチ終了時は「さらに5店舗」を表示しない。
- Premium には区切り画面と広告領域を表示しない。

**受け入れ条件:**

- 区切りは5・10・15件後だけに表示される。
- 「さらに5店舗を見る」で Places API が再実行されない。
- 広告と操作ボタンが密着せず、誤タップを誘発しない。
- 通常のスワイプ画面に広告がない。

**依存:** Issue 10

## Milestone 3: Premium 検索 UX

### Issue 12: Premium ジャンル選択 UI を実装する

**Labels:** `v1.0`, `premium`

**目的:** 「少し希望を伝えて、より合う候補から決める」入口を作る。

**作業:**

- 大分類 → 詳細分類の2段階 UI を実装する。
- 「おまかせ」を提供する。
- Free ユーザーが詳細ジャンルを選んだ時点で Premium 導線を表示する。
- 起動直後に課金案内を強制表示しない。
- 価格文言は設定・商品情報から受け取り、固定値を画面に散在させない。

**受け入れ条件:**

- 全詳細ジャンルを1画面へ並べていない。
- Premium/Trial は選択を続行できる。
- Free はコアの「今すぐ提案」をログインなしで使える。
- Web では購入ボタンではなく Android 契約案内になる。

**依存:** Issue 03, Issue 09

---

### Issue 13: Premium のジャンル精度優先フィルタを実装する

**Labels:** `v1.0`, `premium`, `testing`

**目的:** 指定ジャンルと確実に分類できた店舗だけを候補にする。

**作業:**

- `primaryGenre` だけで一致判定する。
- `subTags` だけ一致する店舗を除外する。
- 件数確保のために他ジャンルを混ぜない。
- 0件時に「距離を広げる」「ジャンルを変更」「おまかせで探す」の選択肢を表示する。
- 0件時の距離自動拡大は行わない。

**受け入れ条件:**

- `primaryGenre = gyudon, subTags = [curry]` の店舗がカレー検索に出ない。
- ラーメン0件時に他ジャンルが混入しない。
- Premium候補は最大20件を広告なしで連続スワイプできる。

**依存:** Issue 07, Issue 10, Issue 12

---

### Issue 14: Premium v1.0 の追加絞り込みを実装する

**Labels:** `v1.0`, `premium`, `decision-needed`

**目的:** Product Decision で v1.0 採用となった追加条件だけを実装する。

**候補:** 詳細距離、評価、価格帯、チェーン店を含む/少なめ、個人店優先。

**受け入れ条件:**

- Issue 02 で採用された条件だけが実装されている。
- 候補不足時に制限を緩和する場合、そのルールがユーザーに不意打ちにならず、テストされている。
- 同一チェーン連続回避は候補数に余裕がある時だけ適用される。

**依存:** Issue 02, Issue 13

## Milestone 4: 認証・権限・課金

### Issue 15: Firebase Authentication と Google ログインを Android/Web に導入する

**Labels:** `v1.0`, `premium`, `android`, `web`, `backend`

**目的:** Free の匿名利用を維持しながら、Premium 権限をアカウントに紐付ける。

**作業:**

- Android と Web の Google ログインを実装する。
- Premium 機能利用時だけログインを要求する。
- Firebase のプラットフォーム設定値は適切な設定ファイルで管理する。
- サインアウト・キャンセル・失敗を扱う。

**受け入れ条件:**

- Free の「今すぐ提案」は未ログインで使える。
- Android/Web で同じ Google アカウントを識別できる。
- ログインキャンセル後も Free 機能へ戻れる。

**人間側設定:** Firebase プロジェクト、Android SHA 証明書、OAuth 同意画面、Web OAuth origin。

**依存:** Issue 09

---

### Issue 16: サーバー管理の Premium entitlement を実装する

**Labels:** `v1.0`, `premium`, `backend`

**目的:** 端末ローカル値ではなく、アカウント単位で Premium 権限を管理する。

**作業:**

- Firebase/バックエンドに entitlement スキーマと読み取り API を用意する。
- クライアントが自分で Premium を書き換えられない Security Rules にする。
- source、status、開始・終了、更新日時を保持する。
- 一時的なオフライン/通信失敗時の扱いを定義する。

**受け入れ条件:**

- クライアントから権限昇格できない。
- 同じアカウントで Android/Web が同じ entitlement を取得できる。
- expired/revoked が反映される。

**依存:** Issue 09, Issue 15

---

### Issue 17: Android に Google Play Billing サブスクリプションを導入する

**Labels:** `v1.0`, `premium`, `android`, `billing`

**目的:** Android で Play Console 管理の月額 Premium を購入・復元できるようにする。

**作業:**

- 商品 ID は集中設定し、表示価格は Play の商品情報から取得する。
- 購入、保留、キャンセル、復元、失敗を扱う。
- 7日間無料体験は Play Console の offer として設定し、端末日時で自作しない。
- Trial 中を完全 Premium として扱う。
- Web に購入処理を含めない。

**受け入れ条件:**

- License Testing で購入・復元・キャンセルの動作を確認できる。
- 無料体験期間がコード内のインストール日時判定になっていない。
- 起動直後ではなく Premium 機能選択時に導線が表示される。

**人間側設定:** Play Console の subscription、base plan、7日 trial offer、License Tester。

**依存:** Issue 02, Issue 15

---

### Issue 18: Play 購読を検証してサーバー entitlement へ同期する

**Labels:** `v1.0`, `premium`, `android`, `backend`, `billing`

**目的:** 購入情報を信頼できるサーバー側で検証し、Web と共有する。

**作業:**

- 購入 token をバックエンドで Google Play Developer API により検証する。
- 検証結果から active/trial/expired/revoked を entitlement へ反映する。
- Real-time Developer Notifications 等による解約・失効同期方針を実装する。
- token、サービスアカウント秘密鍵をクライアントへ置かない。

**受け入れ条件:**

- クライアント申告だけで Premium にならない。
- Android で契約した権限が同じアカウントの Web に反映される。
- 解約・期限切れ・返金が最終的に反映される。

**人間側設定:** Play Developer API、サービスアカウント、RTDN/Pub/Sub、バックエンド secret。

**依存:** Issue 16, Issue 17

---

### Issue 19: Web の Premium 共有導線を実装する

**Labels:** `v1.0`, `premium`, `web`

**目的:** Android 契約済みユーザーが Web でも Premium を利用できるようにする。

**作業:**

- Web ログイン後にサーバー entitlement を確認する。
- active/trial/complimentary を Premium として扱う。
- Web には Stripe 等の決済を追加しない。
- 未契約時は Android での契約案内を表示する。

**受け入れ条件:**

- 同一 Google アカウントの Android 契約が Web に反映される。
- Web から課金が発生しない。
- 未ログイン/未契約/期限切れの各 UI が確認できる。

**依存:** Issue 18

---

### Issue 20: Complimentary と Debug 限定 Developer Premium を実装する

**Labels:** `v1.0`, `premium`, `backend`, `testing`

**目的:** 関係者への無償付与と、安全な開発時確認を可能にする。

**作業:**

- 管理側から complimentary 権限を付与・解除・期限設定できるようにする。
- メールアドレスをアプリコードに直書きしない。
- Developer override は Debug ビルド限定のコンパイル時保証を入れる。
- Release ビルドで override を有効化できないテストまたは検査を追加する。

**受け入れ条件:**

- complimentary の付与・失効が Android/Web に反映される。
- Release ビルドに Developer override の有効経路がない。
- 正式課金確認には License Testing を使う手順が文書化されている。

**依存:** Issue 16

## Milestone 5: 広告・プライバシー・公開準備

### Issue 21: AdMob バナー/ネイティブ広告を Free 区切り画面へ接続する

**Labels:** `v1.0`, `free`, `ads`, `android`, `web`

**目的:** Free の区切り画面だけに広告を表示し、Premium では完全に非表示にする。

**作業:**

- Android の区切り広告スロットへ AdMob を接続する。
- Debug とテストでは Google のテスト広告 ID を必ず使う。
- Premium/Trial/complimentary/developer では SDK の広告表示を行わない。
- Web で未対応の広告 SDK を呼ばないプラットフォーム分岐を用意する。
- インタースティシャル広告は導入しない。

**受け入れ条件:**

- Free の5・10・15件後だけ広告が表示される。
- Premium の全画面で広告が表示されない。
- スワイプ中、店舗写真・情報表示中に広告がない。
- Debug ビルドが本番広告 ID を使用しない。

**依存:** Issue 11, Issue 09

---

### Issue 22: Google Places 帰属表示と API キー運用を公開仕様にする

**Labels:** `v1.0`, `android`, `web`, `release`, `privacy`

**目的:** Google Maps Platform の表示・キー制限要件を満たす。

**作業:**

- 現行の Places データ・写真表示に必要な帰属表示を確認し実装する。
- Android 用と Web 用のキー制限方針を文書化する。
- 使用 API 制限、Android application ID/SHA 制限、Web origin 制限を設定する。
- `.env` やビルド成果物へのキー混入を点検する。

**受け入れ条件:**

- 必要な画面に適切な帰属表示がある。
- 本番キーが無制限で運用されない。
- キーを「完全な秘密」と誤認しない防御方針が文書化されている。

**人間側設定:** Google Cloud Console の API・Application restrictions。

**依存:** Issue 07

---

### Issue 23: プライバシーポリシー・同意・Data Safety を整備する

**Labels:** `v1.0`, `ads`, `billing`, `privacy`, `release`

**目的:** 位置情報、認証、課金、広告 SDK を含む正式公開要件を満たす。

**作業:**

- プライバシーポリシーを実データフローに合わせて更新する。
- 必要なユーザー同意フローを実装する。
- Google Play Data Safety の回答案を作る。
- 広告 ID、位置情報、アカウント情報、購入情報の収集・共有・保持を整理する。
- アプリ内からポリシーへ到達できるようにする。

**受け入れ条件:**

- SDK 実装とポリシー/Data Safety の内容が矛盾していない。
- 必要な地域で同意前の広告動作が適切に制御される。
- 公開 URL と問い合わせ先が用意されている。

**依存:** Issue 15, Issue 17, Issue 21

---

### Issue 24: Android の正式リリース設定を行う

**Labels:** `v1.0`, `android`, `release`

**目的:** Google Play へ提出できる署名済み AAB を生成する。

**作業:**

- 本番 Application ID、アプリ表示名、versionCode/versionName を設定する。
- targetSdk/minSdk を依存 SDK と Play 要件に合わせる。
- Release 署名を Debug 署名から分離する。
- 位置情報 Permission と説明を最小権限で確認する。
- アイコン、AAB、ProGuard/R8、クラッシュ時の symbol 運用を確認する。
- iOS 対応は追加しない。

**受け入れ条件:**

- Release が Debug 鍵で署名されない。
- `flutter build appbundle --release` が成功する。
- Play の pre-launch report に投入可能である。

**人間側設定:** Application ID 決定、upload key/Play App Signing、Play Console アプリ作成。

**依存:** Issue 02, Issue 18, Issue 21, Issue 23

---

### Issue 25: Google Play ストア掲載情報と審査項目を準備する

**Labels:** `v1.0`, `android`, `release`

**目的:** コード外の公開作業を漏れなく完了する。

**作業:**

- ストア説明、短い説明、アイコン、Feature Graphic、スクリーンショットを用意する。
- コンテンツレーティング、Data Safety、広告申告、アプリ アクセス、プライバシーポリシーを登録する。
- Subscription の価格・地域・無料体験表示を最終確認する。
- 内部テスト → クローズドテスト → 本番の公開計画を作る。

**受け入れ条件:**

- Play Console の必須項目に owner と完了状況が付いている。
- Free/Premium の説明が実装と一致する。
- 「7日後から月額○○円」が Play の実価格と一致する。

**依存:** Issue 23, Issue 24

## Milestone 6: 品質保証とリリース判定

### Issue 26: 分類・候補プール・Premium の必須自動テストを完成させる

**Labels:** `v1.0`, `testing`, `free`, `premium`

**目的:** 指示書の最低限テストを CI で再現可能にする。

**必須テスト:**

- 指定13チェーンの分類。
- 松のや/松屋、餃子の王将/大阪王将の衝突。
- Google primaryType fallback。
- Free 20件の `5 / 5 / 5 / 5` と API 再呼び出しなし。
- 0件、3件、20件の候補境界。
- Premium 20件連続、広告なし、ジャンル指定。
- `primaryGenre` 一致、`subTags` のみ一致は除外。
- Entitlement の active/trial/expired/complimentary/developer。

**受け入れ条件:**

- 必須ケースがテスト名から判別できる。
- 外部 API を直接呼ばず、決定的に実行できる。
- CI で `flutter test` が成功する。

**依存:** Issue 06, Issue 08, Issue 13, Issue 20, Issue 21

---

### Issue 27: Android/Web 回帰テストとリリース判定を行う

**Labels:** `v1.0`, `testing`, `android`, `web`, `release`

**目的:** 既存コア体験を維持したまま v1.0 を出せることを確認する。

**確認項目:**

- 現在地取得、営業中検索、距離検索、Recommendation、Decision、Google Maps 遷移。
- Free のログイン不要、5件区切り、候補不足、広告位置。
- Premium のログイン、Trial、購入復元、20件連続、ジャンル精度、広告なし。
- Android 契約の Web 共有、Web で決済不可。
- `flutter analyze`、`flutter test`、Web release build、Android AAB build。

**受け入れ条件:**

- 各コマンドの結果と手動確認結果が Issue に添付されている。
- 重大な未解決事項がない、または明示的なリリース判断を得ている。
- 指示書の「実装後の報告」18項目を埋めたリリースレポートがある。

**依存:** Issue 14（採用時）, Issue 19, Issue 22, Issue 24, Issue 26

## 明示的に v1.0 の対象外とするもの

- iOS 対応。
- 100店舗候補プール。
- 5件ごとの Places API 再検索。
- インタースティシャル広告。
- Web 決済、Stripe。
- お気に入り、履歴、表示済み店舗除外、条件保存（別 Milestone 候補）。
- 未決定の「20件消費後」動作。
- 日本国外向け Premium 分類の独自判断。

## 推奨実行順

```text
01 → 02
 ├─ 03 → 04・05 → 06 → 07 → 08 → 10 → 11 → 21
 ├─ 09 → 10 → 12 → 13 → 14
 └─ 09 → 15 → 16 → 17 → 18 → 19
                         └→ 20

07 → 22
15・17・21 → 23
02・18・21・23 → 24 → 25
06・08・13・20・21 → 26
最終的に 27
```

Issue 03〜08 と Issue 09 は、責務が衝突しない範囲で並行作業可能です。Issue 17（Billing）と Issue 21（AdMob）は外部コンソール準備を早めに始められますが、製品コードへの接続は依存 Issue 完了後に行います。
