$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Test-Path 'config.json')) {
  Copy-Item 'config.example.json' 'config.json'
  Write-Host 'Preencha config.json com a URL e a chave publica do seu Supabase. Execute supabase/setup.sql no painel antes de continuar.'
  notepad config.json
  exit 0
}
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter run -d chrome --web-port 7357 --dart-define-from-file=config.json
exit $LASTEXITCODE
