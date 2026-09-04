#!/usr/bin/env bash
#
# build_autotest_release.sh — 릴리즈 성능 측정용 APK 를 만든다.
#
#   릴리즈 APK 는 debuggable 이 아니라 `adb shell run-as` 로 `user://autotest.cfg` 를 만들 수 없다.
#   그래서 **빌드 시점에** 기능 태그 `autotest` 를 넣어 자동 로그인·PERF 로그를 켠다
#   (규칙의 정본: scripts/autotest.gd). 화면 캡처로 fps 를 읽으면 캡처가 fps 를 떨어뜨려 숫자를 못 믿는다
#   — 그래서 로그로 받는다.
#
#   사용:  build_autotest_release.sh [--sweep] [<출력경로>]
#          기본 출력: builds/android/<preset>-autotest.apk  (일반 release 산출물을 덮어쓰지 않는다)
#          --sweep      기능 태그에 `perfsweep` 를 더해, 맵에서 성능 조건을 순회하며 재도록 한다
#                       (scripts/perf_sweep.gd). 없으면 자동 로그인 + PERF 로그만 나온다.
#          --groundfix  기능 태그에 `groundfix` 를 더해, **첫 프레임 전에** 바닥을 UNSHADED 로 바꾼다.
#                       로딩 지연이 lit 셰이더 컴파일 때문인지 가르는 A/B 용. --sweep 과 함께 쓸 수 있다.
#
# 🛑 이 스크립트는 export_presets.cfg 의 custom_features 를 잠깐 바꾸고 **반드시 원복**한다(trap EXIT).
#    원복이 실패하면 스토어 빌드에 자동 로그인이 들어간다 — 끝에 원복 여부를 검증해 출력한다.
set -euo pipefail

step() { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✅\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m❌\033[0m %s\n' "$*" >&2; exit 1; }

ROOT=$PWD
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/project.godot" ]; do ROOT=$(dirname "$ROOT"); done
[ -f "$ROOT/project.godot" ] || die "Godot 프로젝트 안에서 실행한다."
cd "$ROOT"

PRESETS="$ROOT/export_presets.cfg"
[ -f "$PRESETS" ] || die "export_presets.cfg 가 없다."
FEATURES="autotest"
while true; do
  case "${1:-}" in
    --sweep)     FEATURES="$FEATURES,perfsweep"; shift ;;
    --groundfix) FEATURES="$FEATURES,groundfix"; shift ;;
    --fullfix)   FEATURES="$FEATURES,fullfix"; shift ;;
    *) break ;;
  esac
done

PRESET_NAME=$(awk -F'"' '/^name=/ { print $2; exit }' "$PRESETS")
[ -n "$PRESET_NAME" ] || die "preset 이름을 읽지 못했다."
OUT="${1:-builds/android/${PRESET_NAME// /}-autotest.apk}"

BACKUP=$(mktemp -t export_presets)
cp "$PRESETS" "$BACKUP"
restore() {
  cp "$BACKUP" "$PRESETS"
  if grep -q 'custom_features="autotest' "$PRESETS"; then
    printf '\033[1;31m❌ 원복 실패 — export_presets.cfg 에 autotest 가 남아 있다. 직접 지운다.\033[0m\n' >&2
  else
    ok "export_presets.cfg 원복 확인 (custom_features 비어 있음)"
  fi
  rm -f "$BACKUP"
}
trap restore EXIT

step "custom_features=\"$FEATURES\" 로 임시 변경"
sed -i '' "s/^custom_features=.*/custom_features=\"$FEATURES\"/" "$PRESETS"
grep -n '^custom_features=' "$PRESETS"

# 릴리즈 서명 — 없으면 에디터 debug keystore 로 서명한다(기기 테스트 전용).
if [ -z "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ] && ! grep -q '^keystore/release=' "$PRESETS"; then
  for c in "$HOME/Library/Application Support/Godot/keystores/debug.keystore" \
           "$HOME/.local/share/godot/keystores/debug.keystore" "$HOME/.android/debug.keystore"; do
    [ -f "$c" ] && { export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$c"; break; }
  done
  export GODOT_ANDROID_KEYSTORE_RELEASE_USER="androiddebugkey"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="android"
fi

mkdir -p "$(dirname "$OUT")" artifacts/logs
step "릴리즈 빌드 — $OUT"
godot --headless --path "$ROOT" --export-release "$PRESET_NAME" "$OUT" \
  --log-file "artifacts/logs/build-autotest-release.log" \
  || die "빌드 실패 — artifacts/logs/build-autotest-release.log 확인"
ok "산출물: $OUT ($(du -h "$OUT" | cut -f1))"
echo
echo "설치·측정:"
echo "  adb uninstall <패키지>            # 서명이 다르면 필요(앱 데이터도 지워진다)"
echo "  adb install $OUT"
echo "  adb logcat -c && adb shell am start -W -n <패키지>/com.godot.game.GodotAppLauncher"
echo "  adb logcat -s godot:*             # [Login]·[Auth]·[PerfHUD] 로 로딩·fps 를 읽는다"
