# Android正式リリース設定（Issue 24）

Releaseビルドは、DebugのApplication ID・署名鍵・AdMobテストApp IDを使わない。CIまたはローカルの安全なSecretから次の環境変数を注入する。

| 環境変数 | 用途 |
| --- | --- |
| `SWIPEAT_APPLICATION_ID` | Play Consoleで確定した本番Application ID（例：`com.example.swipeat`） |
| `ANDROID_KEYSTORE_FILE` | upload keyのkeystore絶対パス |
| `ANDROID_KEYSTORE_PASSWORD` | keystoreパスワード |
| `ANDROID_KEY_ALIAS` | upload keyのalias |
| `ANDROID_KEY_PASSWORD` | aliasパスワード |
| `ADMOB_APP_ID` | 本番AdMob Android App ID |
| `ADMOB_BANNER_AD_UNIT_ID` | 本番バナー広告ユニットID（Dart `--dart-define`） |

## ビルド例（PowerShell）

```powershell
$env:SWIPEAT_APPLICATION_ID = 'jp.yourcompany.swipeat'
$env:ANDROID_KEYSTORE_FILE = 'C:\secure\swipeat-upload.jks'
$env:ANDROID_KEYSTORE_PASSWORD = '<secret-store-password>'
$env:ANDROID_KEY_ALIAS = 'swipeat-upload'
$env:ANDROID_KEY_PASSWORD = '<secret-key-password>'
$env:ADMOB_APP_ID = 'ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy'

flutter build appbundle --release `
  --dart-define=ADMOB_BANNER_AD_UNIT_ID=ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz `
  --dart-define=GOOGLE_MAPS_API_KEY=<restricted-production-key>
```

`flutter build appbundle --release` は上記の必須値が欠けると意図的に失敗する。keystore、パスワード、サービスアカウント鍵はGitへ追加しない。Play App Signingへ登録するupload keyと、CIの秘密管理・ローテーション手順を運営者が確定してから正式公開する。

## Release事前検証（Issue 11）

PowerShellでは、Release用のGradle環境変数とDart defineを環境変数へ設定した後、次のコマンドで値の不足を検査してからAABを作成する。検査は値そのものを表示しない。

```powershell
$env:SWIPEAT_APPLICATION_ID = 'jp.yourcompany.swipeat'
$env:ANDROID_KEYSTORE_FILE = 'C:\secure\swipeat-upload.jks'
$env:ANDROID_KEYSTORE_PASSWORD = '<secret-store-password>'
$env:ANDROID_KEY_ALIAS = 'swipeat-upload'
$env:ANDROID_KEY_PASSWORD = '<secret-key-password>'
$env:ADMOB_APP_ID = 'ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy'
$env:GOOGLE_MAPS_API_KEY = '<restricted-production-key>'
$env:ADMOB_BANNER_AD_UNIT_ID = 'ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz'
$env:PREMIUM_PRODUCT_ID = 'swipeat_premium_monthly'
$env:PREMIUM_ENTITLEMENT_SYNC_URL = 'https://api.example.com/entitlement'
$env:FIREBASE_API_KEY = '<firebase-api-key>'
$env:FIREBASE_APP_ID = '<firebase-app-id>'
$env:FIREBASE_MESSAGING_SENDER_ID = '<sender-id>'
$env:FIREBASE_PROJECT_ID = 'swipeat-380b2'
$env:GOOGLE_SERVER_CLIENT_ID = '<android-server-client-id>'

.\tool\build_android_release.ps1
```

実際の値はCI Secretまたはローカルの安全な環境変数から注入する。`tool/android_release_preflight.dart` は公開用Application ID、keystoreファイル、HTTPSの購入検証エンドポイント、テスト用AdMob IDの混入を検査する。

生成後のAABについて、Android SDKの`apkanalyzer`またはPlay ConsoleのApp bundle explorerでApplication ID・versionCode/versionName・target SDKを確認し、`apksigner verify --print-certs`でDebug証明書でないことを確認する。2026年8月31日以降の新規提出に備え、target SDKは36以上にする。

## 提出前確認

- [ ] Play ConsoleのApplication IDと `SWIPEAT_APPLICATION_ID` が一致する。
- [ ] AABがDebug証明書で署名されていないことを `apksigner verify --print-certs` で確認する。
- [ ] `targetSdk`、位置情報Permission、Data Safety、プライバシーポリシーURLをPlay Consoleの申告と突合する。
- [ ] ProGuard/R8、Crashlytics等の難読化・symbol保管方針を決める。
- [ ] AdMob本番ID、Google Placesキー、Firebase設定が用途別に制限されている。
