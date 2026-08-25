# Swipeat v1.0 技術設計メモ（Issue 01）

作成日: 2026-08-25  
対象: Android / Flutter Web  
目的: 既存の決定支援体験を維持したまま、Free と Premium の責務を段階的に追加する。

## 1. 現状の棚卸し

### 既存の実装

| 領域 | 現状 | v1.0 への影響 |
| --- | --- | --- |
| エントリポイント | `lib/main.dart` から `HomeScreen` を表示 | Free はログインなしを維持する |
| 店舗モデル | `lib/models/restaurant.dart` の `Restaurant` | 分類情報と Google `primaryType` を追加する |
| Places | `lib/services/google_places_service.dart` が Places API (New) の Nearby Search を実行 | `maxResultCount: 20` を維持し、FieldMask に `primaryType` を加える |
| 位置情報 | `lib/services/location_service.dart` が `geolocator` を利用 | Android Permission と Web の利用可否を回帰確認する |
| Free 検索 | `HomeScreen` と `CompanionSelectScreen` から Places を取得し、営業中のみ採用 | 初回取得した候補を `CandidatePool` へ渡す |
| スワイプ | `RecommendationScreen` が現状5件単位の index 管理を内包 | `CandidatePool` へ責務を移し、Free/Premium の差を明示する |
| 決定 | `DecisionScreen` が Google Maps URL を開く | v1.0 でも変更しない |
| 認証 | Firebase Authentication のコード・依存は現時点で確認できない | Premium 機能導入時に追加する |
| 課金 | Google Play Billing のコード・依存は現時点で確認できない | Android 専用の購入層とサーバー検証層を追加する |
| 広告 | AdMob のコード・依存は現時点で確認できない | Free の区切り画面専用に追加する |
| Web | Flutter Web と Firebase Hosting 設定が存在する | Web 決済は行わず、認証後の entitlement のみ共有する |
| API キー | `String.fromEnvironment('GOOGLE_MAPS_API_KEY')` | ビルド時注入を維持し、Cloud 側制限を別途設定する |
| Firebase | `.firebaserc` は `swipeat-380b2` を参照、Flutter アプリの Auth/Firestore 実装は未確認 | Auth/entitlement の導入時に設定を追加する |

### 既存の注意点

- 現在の `RecommendationScreen` には、候補終了後の「再検索」導線がある。v1.0 で20候補を使い切った後の動作は未確定のため、Issue 02 の決定までは意味を変更しない。
- `CompanionSelectScreen` は候補が0件の時に距離を自動拡大して再検索する。Free の既存挙動として保持するが、Premium のジャンル精度優先検索へそのまま流用しない。
- Google Places の `types` は現在表示用のカテゴリ・タグにも使われている。Premium の代表ジャンル判定には使わず、`RestaurantClassifier` の結果を唯一の判定元にする。
- `.firebase/hosting.*.cache` は生成物であり、ソース変更としてコミットしない。

## 2. v1.0 の責務分割

```text
HomeScreen / CompanionSelectScreen
        │  検索条件・現在地
        ▼
GooglePlacesService ── Place DTO / FieldMask / 最大20件
        ▼
RestaurantClassifier
  ├─ ChainBrandDefinition（データ辞書）
  ├─ 店舗名の高信頼度判定
  ├─ Google primaryType mapper
  └─ other fallback
        ▼
CandidatePool
  ├─ placeId の重複排除
  ├─ Free: 5件ずつ
  └─ Premium: 最大20件を連続
        ▼
RecommendationScreen ── DecisionScreen ── Google Maps

Premium 機能入口
        ▼
Authentication → PremiumEntitlement（サーバー判定）
        ├─ Free / Trial / Google Play / complimentary / developer
        └─ AdService（Free 区切り画面だけ）
```

### モデルの責務

- `RestaurantGenre`: 安定した ID と日本語表示名、大分類と詳細分類の定義。
- `RestaurantClassification`: `primaryGenre`（最大1つ）、`subTags`、`style`、`brand`、`isChain`、`classificationSource`。
- `ChainBrandDefinition`: ブランド名、別名、代表ジャンル、style をデータとして保持する。
- `RestaurantClassifier`: 分類優先順位を実行し、分類結果を返す。画面や API クライアントは分類規則を持たない。
- `CandidatePool`: 一度取得した候補のセッション状態を管理する。次ページ操作で Places API を呼ばない。
- `PremiumEntitlement`: 権限の status/source/期間を表す。UI は boolean のローカル保存値を信頼しない。
- `AdService`: 広告のロード・表示可否を抽象化する。Premium 判定と表示位置は画面に散在させない。

## 3. Free 検索フロー

```text
未ログインで起動
  → 現在地取得
  → 営業中・指定距離で Nearby Search（最大20件）
  → placeId 重複排除・シャッフル
  → CandidatePool(Free)
  → 1〜5件をスワイプ
  → 区切り画面 + 広告スロット（5・10・15件後、全候補終了時）
  → 取得済みの6〜10件を表示（再検索なし）
  → 最大20件まで繰り返す
```

- 候補が20件未満なのは正常系とする。
- 候補が3件なら3件表示後に候補終了、0件なら既存の空状態を表示する。
- 通常の店舗カードには広告を表示しない。
- チェーン店は Free から除外しない。

## 4. Premium 検索フロー

```text
Premium ジャンルを選択
  → 未ログインなら Google ログイン
  → entitlement をサーバーから確認
  → Trial / Google Play / complimentary / developer が active なら継続
  → 現在地・営業中・条件で Nearby Search（最大20件）
  → RestaurantClassifier で分類
  → primaryGenre のみで厳密フィルタ
  → CandidatePool(Premium)
  → 最大20件を広告なしで連続スワイプ
```

- `subTags` のみ一致する店舗や、ジャンルを判断できない店舗を候補数確保のために混ぜない。
- 0件時は他ジャンルを混ぜず、「距離を広げる」「ジャンルを変更」「おまかせで探す」を提示する。
- Web では決済を行わず、同じ Google アカウントの entitlement を確認する。

## 5. Places API 境界

- `GooglePlacesService` は HTTP 応答の変換までを担当し、Premium の分類・表示制限を担当しない。
- Nearby Search の `maxResultCount` は20を上限とする。100件取得やページングは v1.0 に追加しない。
- FieldMask は現在の表示項目に加え、`places.primaryType` を要求する。
- API のモックを差し替えられるようにし、分類・候補プールの単体テストから実ネットワークを排除する。
- Google の API キーは Dart のソースへ直書きせず、既存どおりビルド時変数から注入する。Android/Web のキー制限は Issue 22 で扱う。

## 6. 認証・課金・権限境界

- Free は認証不要。Premium 機能の選択時だけ認証を要求する。
- Google Play の購入・Trial は Android で開始する。7日間の判定は Play の subscription offer/status を基準にし、端末のインストール日時を保存して判定しない。
- クライアントは購入結果をサーバーへ送信するが、Premium 権限の最終判定はサーバーで行う。
- `source` は少なくとも `google_play`、`free_trial`、`complimentary`、`developer` を表現する。
- developer override は Debug ビルドだけに限定し、Release ビルドで有効経路を作らない。
- 家族・関係者のメールアドレスはコードへ書かず、サーバー上の entitlement として管理する。

## 7. Android / Web 方針

### Android

- Google Play Store 公開対象。
- Billing、Trial、AdMob、位置情報 Permission を有効化する。
- Release 署名は Debug 署名と分離する。
- 本番 Application ID は Issue 02 の決定後に設定する。

### Web

- 既存 Flutter Web と Firebase Hosting を維持する。
- Web から Stripe 等の決済は追加しない。
- Google ログイン後、サーバー entitlement によって Android 契約済み Premium を解放する。
- Android 専用 SDK を Web で初期化しない。

## 8. Issue 01 の完了条件と後続 Issue

Issue 01 で確定したのは責務境界と現状制約であり、Firebase/Auth/Billing/AdMob 自体はまだ導入しない。

後続の実装順は次のとおり。

```text
Issue 02（未確定仕様の決定）
  ↓
Issue 03 → 04・05 → 06 → 07 → 08
  ↓                         ↓
Issue 09 → 10 → 11 → 21    Issue 12 → 13 → 14
  ↓
Issue 15 → 16 → 17 → 18 → 19 → 20
  ↓
Issue 22 → 23 → 24 → 25 → 26 → 27
```

Issue 02 で決めるまで、次の値はコード上で固定しない。

- Premium の月額価格（「300円前後」は候補値に留める）。
- 20候補を使い切った後の動作。
- Premium v1.0 に含める追加絞り込み。
- 日本国外の Premium 分類方針。
- 本番 Application ID。
