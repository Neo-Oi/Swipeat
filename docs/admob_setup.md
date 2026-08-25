# AdMob 設定（Issue 21）

## コード側の制約

- Free の5・10・15件区切り画面と、全候補を見終えた最終画面の `AdSlot` だけがバナーをロードする。
- Premium、Trial、complimentary、developer entitlement では区切り画面自体を出さず、AdMobを初期化しても広告をロードしない。
- 通常の店舗スワイプ画面、写真、店舗情報には広告を出さない。
- インタースティシャル広告は導入しない。
- Debug は Google のテストバナー IDを使用する。
- Release は `ADMOB_BANNER_AD_UNIT_ID` と Android `ADMOB_APP_ID` をビルド環境から注入する。

## AdMob / Play Console 側で必要な設定

- AdMob アプリ（Android）とバナー広告ユニットを作成する。
- 本番の App ID と Banner Ad Unit ID を CI/Release 環境へ登録する。
- Google Play Data Safety、広告 SDK 申告、必要な同意フローを Issue 23 で一致させる。
- 開発者自身が本番広告をクリックせず、テスト広告またはテスト端末を使う。
