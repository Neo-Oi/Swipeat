param(
    [string]$Flutter = 'flutter'
)

$ErrorActionPreference = 'Stop'

$requiredDartDefines = @(
    'GOOGLE_MAPS_API_KEY',
    'ADMOB_BANNER_AD_UNIT_ID',
    'PREMIUM_PRODUCT_ID',
    'PREMIUM_ENTITLEMENT_SYNC_URL',
    'FIREBASE_API_KEY',
    'FIREBASE_APP_ID',
    'FIREBASE_MESSAGING_SENDER_ID',
    'FIREBASE_PROJECT_ID',
    'GOOGLE_SERVER_CLIENT_ID'
)

foreach ($name in $requiredDartDefines) {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$name is required in the environment. Its value is not printed."
    }
}

& dart run tool/android_release_preflight.dart
if ($LASTEXITCODE -ne 0) {
    throw 'Android Release preflight failed.'
}

$dartDefines = @()
foreach ($name in $requiredDartDefines) {
    $dartDefines += "--dart-define=$name=$([Environment]::GetEnvironmentVariable($name))"
}

& $Flutter build appbundle --release @dartDefines
if ($LASTEXITCODE -ne 0) {
    throw 'Flutter Android App Bundle build failed.'
}

Write-Output 'Android App Bundle build completed. Verify the AAB signature, Application ID, and target SDK before upload.'
