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
$env:SWIPEAT_APPLICATION_ID = 'com.example.swipeat'
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

## 提出前確認

- [ ] Play ConsoleのApplication IDと `SWIPEAT_APPLICATION_ID` が一致する。
- [ ] AABがDebug証明書で署名されていないことを `apksigner verify --print-certs` で確認する。
- [ ] `targetSdk`、位置情報Permission、Data Safety、プライバシーポリシーURLをPlay Consoleの申告と突合する。
- [ ] ProGuard/R8、Crashlytics等の難読化・symbol保管方針を決める。
- [ ] AdMob本番ID、Google Placesキー、Firebase設定が用途別に制限されている。
