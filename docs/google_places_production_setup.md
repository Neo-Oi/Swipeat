# Google Places 公開運用（Issue 22）

## APIキーの扱い

- `GOOGLE_MAPS_API_KEY` は `--dart-define` でビルド時に注入する。
- `.env` はFlutterアセットにもGitにも含めない。ローカル開発用の値は未追跡ファイルまたはCI Secretで管理する。
- Google Maps Platformのキーはクライアントへ配布されるため、完全な秘密情報ではない。漏えいを前提に利用範囲を制限する。
- これまでリポジトリやWeb成果物へ含まれたキーは、Google Cloud Consoleで無効化・ローテーションする。

## Google Cloud Console の設定

1. Places API (New) など、実際に利用するAPIだけをAPI制限に追加する。
2. Androidキーはアプリケーション制限を「Android apps」にし、正式なApplication IDと各署名証明書のSHA-1/SHA-256を登録する。
3. Webキーは「HTTP referrers (web sites)」にし、本番ドメインと必要なローカル開発オリジンだけを登録する。
4. Android用とWeb用でキーを分離し、用途ごとに日次予算・アラートを設定する。
5. キー更新後は `flutter build web --release --dart-define=GOOGLE_MAPS_API_KEY=...` と Androidビルドを行い、リクエストが成功することを確認する。

## 帰属表示

Places由来の店舗名、写真、評価、口コミ件数、住所を表示するRecommendation/Decision画面に、Google Maps Platformの帰属表示を常時表示する。表示は広告や操作ボタンと誤認されない位置に置き、Google Mapsへの遷移ボタンとは分離する。
