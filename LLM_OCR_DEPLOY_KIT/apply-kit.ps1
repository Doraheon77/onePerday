param(
  [string]$TargetRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$kitRoot = $PSScriptRoot
$dropIn = Join-Path $kitRoot "drop-in"

if (-not (Test-Path $dropIn)) {
  throw "drop-in 폴더를 찾을 수 없습니다: $dropIn"
}

$requiredTargets = @("backend", "frontend")
foreach ($target in $requiredTargets) {
  if (-not (Test-Path (Join-Path $TargetRoot $target))) {
    throw "TargetRoot가 onePerDay 프로젝트 루트가 아닌 것 같습니다. 누락: $target"
  }
}

Copy-Item -Path (Join-Path $dropIn "*") -Destination $TargetRoot -Recurse -Force

Write-Host "LLM/OCR integration kit applied to: $TargetRoot"
Write-Host "Next:"
Write-Host "  1. backend/.env 값을 설정하세요. 템플릿: LLM_OCR_DEPLOY_KIT/backend.env.template"
Write-Host "  2. cd backend; npm ci; npm run build"
Write-Host "  3. pip install -r backend/scripts/requirements.txt"
Write-Host "  4. cd frontend; flutter pub get; flutter analyze"
