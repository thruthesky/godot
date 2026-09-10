#!/usr/bin/env bash
#
# install.sh — Godot 에디터 없이 빌드·설치·실행한다.
#
#   install.sh                       사용 가능한 장치를 번호로 보여주고 고르게 한다
#   install.sh 1                     목록의 1번을 바로 고른다
#   install.sh R58X609XXYV           Android 시리얼을 직접 지정
#   install.sh 00008140-001C24C9…    iOS UDID 를 직접 지정
#   install.sh macos                 이 맥에서 빌드·실행
#
#   install.sh <선택> --release      릴리즈 빌드로 (묻지 않는다)
#   install.sh <선택> --debug        디버그 빌드로 (묻지 않는다)
#   install.sh <선택> --skip-build   빌드 생략, 설치·실행만
#   install.sh <선택> --console      실행 로그를 터미널에 붙여서 본다
#   install.sh <선택> --no-launch    설치만 하고 실행하지 않는다
#   install.sh <선택> --path ~/game  프로젝트 경로 지정 (기본: 현재 폴더에서 위로 탐색)
#   install.sh --list                목록만 보고 끝낸다
#
# 어느 플랫폼인지는 고른 장치가 정한다. preset 이름·패키지 ID·산출물 경로는
# export_presets.cfg 에서 직접 읽으므로 프로젝트마다 고칠 필요가 없다.
#
# 빌드 모드는 --debug/--release 를 주지 않으면 장치를 고른 뒤 물어본다(대화형일 때. 기본 Debug).
#   Debug   — print() 로그가 logcat 에 나오고 원격 디버그가 붙는다. 엔진이 비최적화라 느리다
#   Release — 실제 배포와 같은 최적화 빌드. 성능(fps)·로딩 시간 측정은 이쪽이 정답이다
#             🛑 Android release 는 release keystore 가 필요하다. 없으면 이 스크립트가
#                **debug keystore 로 서명**하고 경고한다(기기 테스트 전용 — 스토어 업로드 불가).
#
#   bash install.sh --win            이 Windows PC에서 빌드·실행 / Build and run on this Windows PC
#   PowerShell: & "C:/Program Files/Git/bin/bash.exe" ./install.sh --win
#   GODOT_BIN overrides automatic Godot detection. Matching export templates are required.
#
# English usage:
#   bash install.sh [number|device-id|macos]  Select a target device
#   bash install.sh --win                    Build and run on this Windows PC
#   --debug / --release                     Choose the build mode without prompting
#   --skip-build                            Use an existing build
#   --console                               Attach runtime logs (Ctrl+C to stop)
#   --no-launch                             Build/install without launching
#   --path <directory>                      Specify the Godot project directory
#   --list                                  List available devices
#
set -euo pipefail

# ── 출력 ────────────────────────────────────────────────────────────────
step() { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✅\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m⚠️\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[1;31m❌\033[0m %s\n' "$*" >&2; exit 1; }

# ── 인자 파싱 ───────────────────────────────────────────────────────────
SELECTION=""
BUILD_MODE=""          # 빈 값 = 아직 안 정했다 → 장치 선택 후 물어본다(비대화형이면 debug)
SKIP_BUILD=0
CONSOLE=0
LAUNCH=1
LIST_ONLY=0
PROJECT_ARG=""
WIN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --win)        WIN=1 ;;
    --release)    BUILD_MODE="release" ;;
    --debug)      BUILD_MODE="debug" ;;
    --skip-build) SKIP_BUILD=1 ;;
    --console)    CONSOLE=1 ;;
    --no-launch)  LAUNCH=0 ;;
    --list)       LIST_ONLY=1 ;;
    --path)
      [ $# -ge 2 ] && [ -n "$2" ] && [[ "$2" != -* ]] || die "--path 에 프로젝트 경로가 필요하다 / --path requires a project directory."
      shift; PROJECT_ARG="$1" ;;
    -h|--help)    awk 'NR>1 { if (/^#/) { sub(/^# ?/, ""); print } else exit }' "$0"; exit 0 ;;
    -*)           die "알 수 없는 옵션: / Unknown option: $1" ;;
    *)            SELECTION="$1" ;;
  esac
  shift
done

if [ "$WIN" -eq 1 ]; then
  case "$SELECTION" in
    ""|win|windows|Windows) SELECTION="windows" ;;
    *) die "--win 은 다른 장치 선택과 함께 쓸 수 없다 / --win cannot be combined with another device selection: $SELECTION" ;;
  esac
fi

is_windows() {
  case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) return 0 ;; esac
  return 1
}

windows_entry() {
  is_windows || return 0
  printf 'windows\tlocal\t이 Windows PC에서 실행 / Run on this Windows PC (%s)\n' "$(uname -m)"
}

case "$SELECTION" in
  win|windows|Windows)
    is_windows || die "Windows Git Bash가 필요하다 / Use Git Bash on Windows, not WSL." ;;
esac

# ── 장치 수집 ───────────────────────────────────────────────────────────
# 각 항목은  플랫폼<TAB>기기ID<TAB>표시이름  한 줄이다.

macos_entry() {
  [ "$(uname -s)" = "Darwin" ] || return 0
  printf 'macos\tlocal\t이 맥에서 실행 / Run on this Mac (%s)\n' "$(uname -m)"
}

android_entries() {
  command -v adb >/dev/null 2>&1 || return 0
  adb devices -l 2>/dev/null | awk 'NR>1 && $2=="device" {
    serial = $1; model = ""
    for (i = 3; i <= NF; i++) if ($i ~ /^model:/) { model = substr($i, 7); gsub(/_/, " ", model) }
    if (model == "") model = "Android 기기 / Android device"
    printf "android\t%s\t%s\n", serial, model
  }'
}

# devicectl 이 available 로 판정한 것만 — 설치가 실제로 가능한 기기다
ios_entries() {
  command -v xcrun >/dev/null 2>&1 || return 0
  xcrun devicectl list devices 2>/dev/null | awk '
    {
      uuid = ""; ui = 0
      for (i = 1; i <= NF; i++)
        if ($i ~ /^[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}$/) { uuid = $i; ui = i }
      if (uuid == "" || $(ui + 1) != "available") next
      model = ""
      for (i = ui + 2; i <= NF; i++) {
        if (i == ui + 2 && $i ~ /^\(/) continue          # (paired) 는 건너뛴다
        model = model (model == "" ? "" : " ") $i
      }
      if (model == "") model = "iOS 기기 / iOS device"
      printf "ios\t%s\t%s — %s\n", uuid, $1, model
    }'
}

collect_devices() { { windows_entry; macos_entry; ios_entries; android_entries; } 2>/dev/null | awk 'NF'; }

DEVICES=$(collect_devices)

print_menu() {
  echo "사용 가능한 장치: / Available devices:"
  echo
  printf '%s\n' "$DEVICES" | awk -F'\t' '{
    label = toupper(substr($1,1,1)) substr($1,2)
    if ($1 == "macos")   label = "macOS"
    if ($1 == "ios")     label = "iOS"
    if ($1 == "android") label = "Android"
    printf "  \033[1;36m%d)\033[0m  %-9s %s\n", NR, label, $3
    if ($2 != "local") printf "        %*s\033[90m%s\033[0m\n", 9, "", $2
  }'
  echo
  # 연결이 없는 플랫폼은 왜 안 보이는지 알려 준다
  printf '%s\n' "$DEVICES" | grep -q '^ios'     || echo "  (iOS 기기 없음 — USB 연결 후 '이 컴퓨터를 신뢰' 를 누른다 / No iOS device — connect via USB and select Trust This Computer on a Mac)"
  printf '%s\n' "$DEVICES" | grep -q '^android' || echo "  (Android 기기 없음 — USB 디버깅을 켜고 연결한다 / No Android device — enable USB debugging and connect via USB)"
}

if [ "$LIST_ONLY" -eq 1 ]; then print_menu; exit 0; fi

# ── 선택 해석 ───────────────────────────────────────────────────────────
# 번호 → 목록에서, 그 외 → 기기 ID·플랫폼 이름으로 직접 매칭
resolve_selection() {
  local sel="$1"
  if printf '%s' "$sel" | grep -Eq '^[0-9]+$'; then
    printf '%s\n' "$DEVICES" | awk -F'\t' -v n="$sel" 'NR == n { print; found = 1 } END { exit !found }'
    return
  fi
  case "$sel" in
    win|windows|Windows) printf '%s\n' "$DEVICES" | awk -F'\t' '$1 == "windows" { print; exit }'; return ;;
    macos|macOS|mac) printf '%s\n' "$DEVICES" | awk -F'\t' '$1 == "macos" { print; exit }'; return ;;
  esac
  printf '%s\n' "$DEVICES" | awk -F'\t' -v id="$sel" '$2 == id { print; found = 1 } END { exit !found }'
}

if [ -z "$SELECTION" ]; then
  print_menu
  if [ ! -t 0 ]; then
    echo "번호를 인자로 준다: / Pass a device number as an argument:  $(basename "$0") 1"
    exit 0
  fi
  echo
  printf '번호 선택 [1]: / Select a number [1]: '
  read -r SELECTION || SELECTION=""
  [ -n "$SELECTION" ] || SELECTION="1"
  echo
fi

ENTRY=$(resolve_selection "$SELECTION") || {
  print_menu >&2
  die "'$SELECTION' 에 해당하는 장치가 없다. 위 번호나 기기 ID 를 쓴다. / No device matches '$SELECTION'. Use a number above or a device ID."
}

[ -n "$ENTRY" ] || die "선택한 장치가 없다 / No available device matches '$SELECTION'. Use --list."
PLATFORM=$(printf '%s' "$ENTRY" | cut -f1)
DEVICE_ID=$(printf '%s' "$ENTRY" | cut -f2)
DEVICE_LABEL=$(printf '%s' "$ENTRY" | cut -f3)
ok "선택: / Selected: $PLATFORM — $DEVICE_LABEL"

# ── 빌드 모드 선택 ──────────────────────────────────────────────────────
# --debug/--release 를 줬으면 묻지 않는다. 비대화형(파이프·CI)에서는 debug 로 간다.
if [ -z "$BUILD_MODE" ]; then
  if [ "$SKIP_BUILD" -eq 1 ]; then
    BUILD_MODE="debug"     # 빌드를 안 하므로 로그 파일 이름에만 쓰인다
  elif [ ! -t 0 ]; then
    BUILD_MODE="debug"
    echo "   (비대화형 — Debug 로 빌드한다. Release 는 --release / Noninteractive — building Debug. Use --release for Release.)"
  else
    echo
    echo "빌드 모드: / Build mode:"
    echo
    printf '  \033[1;36m1)\033[0m  Debug     print() 로그·원격 디버그. / print() logs and remote debugging. \033[90m엔진 비최적화 — fps 측정에는 부적합 / Use Release for FPS measurements\033[0m\n'
    printf '  \033[1;36m2)\033[0m  Release   실제 배포와 같은 최적화 빌드. / Optimized build for distribution. \033[90mfps·로딩 시간 측정은 이쪽 / Use this for FPS and loading-time measurements\033[0m\n'
    echo
    printf '번호 선택 [1]: / Select a number [1]: '
    read -r MODE_SEL || MODE_SEL=""
    echo
    case "${MODE_SEL:-1}" in
      1|d|debug|Debug)     BUILD_MODE="debug" ;;
      2|r|release|Release) BUILD_MODE="release" ;;
      *) die "빌드 모드가 '1'(Debug) 또는 '2'(Release) 여야 한다: / Build mode must be '1' (Debug) or '2' (Release): '$MODE_SEL'" ;;
    esac
  fi
fi
ok "빌드 모드: / Build mode: $BUILD_MODE"

# ── 프로젝트 루트 찾기 ──────────────────────────────────────────────────
find_project_root() {
  local dir="${1:-$PWD}"
  dir=$(cd "$dir" 2>/dev/null && pwd) || return 1
  while [ "$dir" != "/" ]; do
    [ -f "$dir/project.godot" ] && { echo "$dir"; return 0; }
    dir=$(dirname "$dir")
  done
  return 1
}

ROOT=$(find_project_root "${PROJECT_ARG:-$PWD}") \
  || die "project.godot 을 찾지 못했다. Godot 프로젝트 안에서 실행하거나 --path 로 지정한다. / Could not find project.godot. Run inside a Godot project or specify --path."
cd "$ROOT"
ok "프로젝트: / Project: $ROOT"

PRESETS="$ROOT/export_presets.cfg"
[ -f "$PRESETS" ] || die "export_presets.cfg 가 없다. 먼저 export preset 을 만든다. / Missing export_presets.cfg. Create an export preset first."

# ── export_presets.cfg 파싱 ─────────────────────────────────────────────
# $1: platform 값("Android"/"iOS"/"macOS"), $2: 읽을 키
preset_get() {
  awk -v want="$1" -v key="$2" '
    { sub(/\r$/, "") }
    /^\[preset\.[0-9]+\]$/ { cur = $0; gsub(/[^0-9]/, "", cur); next }
    /^\[preset\.[0-9]+\.options\]$/ { cur = $0; gsub(/[^0-9]/, "", cur); next }
    /^[A-Za-z]/ {
      eq = index($0, "=")
      if (eq == 0 || cur == "") next
      k = substr($0, 1, eq - 1)
      v = substr($0, eq + 1)
      gsub(/^[ \t]+|[ \t\r]+$/, "", v)
      gsub(/^"|"$/, "", v)
      data[cur "\x01" k] = v
      if (k == "platform" && !(v in first)) first[v] = cur
    }
    END { if (want in first) print data[first[want] "\x01" key] }
  ' "$PRESETS"
}

# ── 플랫폼별 preset 값 ──────────────────────────────────────────────────
find_godot() {
  local candidate dir drive
  for candidate in godot godot4 godot_console; do
    command -v "$candidate" 2>/dev/null && return 0
  done
  is_windows || return 1
  # Check PATH and portable installations, including the project drive's apps folder.
  drive=$(cygpath -u "$(cygpath -w "$ROOT" | cut -c1-2)/")
  local -a search_dirs
  IFS=: read -r -a search_dirs <<< "$PATH"
  search_dirs+=("${drive%/}/apps" "$HOME/Downloads" "$HOME/apps" "/c/Program Files/Godot")
  for dir in "${search_dirs[@]}"; do
    for candidate in "$dir"/Godot*_console.exe "$dir"/Godot*/Godot*_console.exe \
                     "$dir"/Godot*.exe "$dir"/Godot*/Godot*.exe; do
      [ -f "$candidate" ] && { printf '%s\n' "$candidate"; return 0; }
    done
  done
  return 1
}

if [ "$SKIP_BUILD" -eq 0 ]; then
  GODOT_BIN="${GODOT_BIN:-$(find_godot || true)}"
  [ -n "$GODOT_BIN" ] || die "godot 실행 파일을 찾지 못했다. GODOT_BIN 환경변수로 경로를 지정한다. / Godot was not found. Set GODOT_BIN to your Godot executable path."
  if is_windows; then GODOT_BIN=$(cygpath -u "$GODOT_BIN"); fi
  command -v "$GODOT_BIN" >/dev/null 2>&1 || die "Godot 실행 파일이 없다 / Godot executable does not exist: $GODOT_BIN"
fi

case "$PLATFORM" in
  windows)
    PRESET_NAME=$(preset_get "Windows Desktop" "name")
    EXPORT_PATH=$(preset_get "Windows Desktop" "export_path")
    [ -n "$PRESET_NAME" ] || die 'Windows Desktop preset 이 없다 / No platform="Windows Desktop" preset in export_presets.cfg.'
    [ -n "$EXPORT_PATH" ] || EXPORT_PATH="builds/windows/${PRESET_NAME}.exe"
    case "$EXPORT_PATH" in *.exe) ;; *) die "Windows export_path 는 .exe 로 끝나야 한다 / Windows export_path must end in .exe: $EXPORT_PATH" ;; esac
    ARTIFACT="$ROOT/$EXPORT_PATH"
    ;;
  android)
    PRESET_NAME=$(preset_get "Android" "name")
    PACKAGE_ID=$(preset_get "Android" "package/unique_name")
    EXPORT_PATH=$(preset_get "Android" "export_path")
    [ -n "$PRESET_NAME" ] || die "export_presets.cfg 에 platform=\"Android\" preset 이 없다. / No platform=\"Android\" preset in export_presets.cfg."
    [ -n "$PACKAGE_ID" ]  || die "Android preset 에 package/unique_name 이 없다. / Android preset is missing package/unique_name."
    [ -n "$EXPORT_PATH" ] || EXPORT_PATH="builds/android/${PRESET_NAME}.apk"
    ARTIFACT="$ROOT/$EXPORT_PATH"
    ;;
  ios)
    PRESET_NAME=$(preset_get "iOS" "name")
    PACKAGE_ID=$(preset_get "iOS" "application/bundle_identifier")
    EXPORT_PATH=$(preset_get "iOS" "export_path")
    PROJECT_ONLY=$(preset_get "iOS" "application/export_project_only")
    [ -n "$PRESET_NAME" ] || die "export_presets.cfg 에 platform=\"iOS\" preset 이 없다. / No platform=\"iOS\" preset in export_presets.cfg."
    [ -n "$PACKAGE_ID" ]  || die "iOS preset 에 application/bundle_identifier 가 없다. / iOS preset is missing application/bundle_identifier."
    [ -n "$EXPORT_PATH" ] || EXPORT_PATH="builds/ios/${PRESET_NAME}.ipa"
    if [ "$PROJECT_ONLY" = "true" ]; then
      die "iOS preset 의 application/export_project_only 가 true 다. / The iOS preset has application/export_project_only=true.
   이러면 Godot 이 Xcode 프로젝트만 만들고 멈춰서 .ipa 가 나오지 않는다. / This exports only the Xcode project, without an .ipa.
   export_presets.cfg 에서 false 로 바꾼다. / Set it to false in export_presets.cfg."
    fi
    IOS_OUT_DIR="$ROOT/$(dirname "$EXPORT_PATH")"
    ;;
  macos)
    PRESET_NAME=$(preset_get "macOS" "name")
    PACKAGE_ID=$(preset_get "macOS" "application/bundle_identifier")
    EXPORT_PATH=$(preset_get "macOS" "export_path")
    [ -n "$PRESET_NAME" ] || die "export_presets.cfg 에 platform=\"macOS\" preset 이 없다. / No platform=\"macOS\" preset in export_presets.cfg."
    [ -n "$EXPORT_PATH" ] || EXPORT_PATH="builds/macos/${PRESET_NAME}.app"
    ARTIFACT="$ROOT/$EXPORT_PATH"
    ;;
esac

# 산출물 이름에 모드가 박혀 있으면(…-debug.apk) 실제 모드로 바꾼다 — debug 빌드와 release 빌드가
# 같은 파일을 덮어써서 "무엇을 깔았는지" 를 알 수 없게 되는 것을 막는다.
case "$EXPORT_PATH" in
  *debug*)
    if [ "$BUILD_MODE" = "release" ]; then
      EXPORT_PATH=${EXPORT_PATH//debug/release}
      ARTIFACT="$ROOT/$EXPORT_PATH"
      warn "산출물 이름의 'debug' 를 'release' 로 바꿨다 → / Changed 'debug' to 'release' in output path: $EXPORT_PATH"
    fi
    ;;
  *release*)
    if [ "$BUILD_MODE" = "debug" ]; then
      EXPORT_PATH=${EXPORT_PATH//release/debug}
      ARTIFACT="$ROOT/$EXPORT_PATH"
      warn "산출물 이름의 'release' 를 'debug' 로 바꿨다 → / Changed 'release' to 'debug' in output path: $EXPORT_PATH"
    fi
    ;;
esac

if [ "$PLATFORM" = "windows" ]; then
  # Godot presets may contain relative paths or absolute Windows paths.
  EXPORT_PATH=$(cygpath -u "$EXPORT_PATH")
  case "$EXPORT_PATH" in
    /*) ARTIFACT="$EXPORT_PATH" ;;
    *) ARTIFACT="$ROOT/$EXPORT_PATH" ;;
  esac
fi

# ── Android release 서명 ────────────────────────────────────────────────
# Godot 는 release 빌드에서 keystore/release 가 없으면 "Release keystore incorrectly configured" 로 멈춘다
# (엔진 platform/android/export/export_plugin.cpp). preset·환경변수에 아무것도 없으면 에디터가 만들어 둔
# debug keystore 로 서명해 **기기 테스트만** 가능하게 한다. 스토어에 올릴 빌드는 사람이 release keystore 를 만든다.
android_release_signing() {
  local rk; rk=$(preset_get "Android" "keystore/release")
  if [ -n "$rk" ] || [ -n "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ]; then
    ok "release keystore: ${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-$rk}"
    return 0
  fi
  local dbg=""
  for c in "$HOME/Library/Application Support/Godot/keystores/debug.keystore" \
           "$HOME/.local/share/godot/keystores/debug.keystore" \
           "$HOME/.android/debug.keystore"; do
    [ -f "$c" ] && { dbg="$c"; break; }
  done
  [ -n "$dbg" ] || die "release keystore 가 없다. / No release keystore is configured.
   스토어용은 keytool 로 만들어 GODOT_ANDROID_KEYSTORE_RELEASE_PATH/USER/PASSWORD 를 export 한다. / For store builds, use keytool and export GODOT_ANDROID_KEYSTORE_RELEASE_PATH/USER/PASSWORD.
   (export-build-android.md §5). 임시로는 --debug 로 빌드한다. / See export-build-android.md section 5. For now, use --debug."
  export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$dbg"
  export GODOT_ANDROID_KEYSTORE_RELEASE_USER="androiddebugkey"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="android"
  warn "release keystore 가 없어 debug keystore 로 서명한다 — 기기 테스트 전용이다(스토어 업로드 불가). / No release keystore: signing with the debug keystore for device testing only (not for store uploads).
    $dbg"
}

# ── 빌드 ────────────────────────────────────────────────────────────────
if [ "$SKIP_BUILD" -eq 0 ]; then
  [ "$PLATFORM" = "android" ] && [ "$BUILD_MODE" = "release" ] && android_release_signing
  step "빌드 중 — / Building — $PLATFORM / $BUILD_MODE / preset \"$PRESET_NAME\""
  if [ "$PLATFORM" = "windows" ]; then
    mkdir -p "$(dirname "$ARTIFACT")" artifacts/logs
  else
    mkdir -p "$(dirname "$ROOT/$EXPORT_PATH")" artifacts/logs
  fi
  # ── 배포용 맵 분할 ────────────────────────────────────────────────────
  # 저작 씬(`main.tscn`)에는 청크가 **전부** 들어 있다 — 맵 디자이너가 늘 하던 대로
  # 작업하기 위해서다(2026-09-10 사람 결정). 그대로 내보내면 A12 에서 씬 파싱에만
  # 3.4초가 들므로, **배포본에서만** 잘라 내고 나머지는 입장 뒤 스트리밍한다.
  #
  # 🛑 `trap` 으로 되돌린다 — 빌드가 실패하든 Ctrl-C 로 끊기든 저작 씬이 잘린 채
  #    남으면 안 된다. 다음 사람이 맵을 열었을 때 청크가 사라져 있게 된다.
  MAP_SPLIT=0
  if [ "$BUILD_MODE" = "release" ] && [ -f "$ROOT/tools/split_map_for_release.py" ]; then
    python3 "$ROOT/tools/split_map_for_release.py" --split \
      || die "배포용 맵 분할에 실패했다 / Map split for release failed."
    MAP_SPLIT=1
    trap 'python3 "$ROOT/tools/split_map_for_release.py" --restore >/dev/null 2>&1' EXIT INT TERM
  fi
  "$GODOT_BIN" --headless --path "$ROOT" --import --quit >/dev/null 2>&1 || true
  "$GODOT_BIN" --headless --path "$ROOT" \
    "--export-$BUILD_MODE" "$PRESET_NAME" "$EXPORT_PATH" \
    --log-file "artifacts/logs/install-$PLATFORM-$BUILD_MODE.log" \
    || die "빌드 실패. artifacts/logs/install-$PLATFORM-$BUILD_MODE.log 를 확인한다. / Build failed. See artifacts/logs/install-$PLATFORM-$BUILD_MODE.log. Check matching export templates in Editor > Manage Export Templates.
   iOS 에서 오류 본문이 비어 있으면 아이콘 → Team ID → bundle id → ios.zip 템플릿 순으로 점검한다. / For empty iOS errors, check the icon, Team ID, bundle ID, and ios.zip template."
  if [ "$MAP_SPLIT" -eq 1 ]; then
    python3 "$ROOT/tools/split_map_for_release.py" --restore
    trap - EXIT INT TERM
  fi
fi

# iOS 는 export_path 옆에 .ipa 가 떨어진다
if [ "$PLATFORM" = "ios" ]; then
  ARTIFACT=$(find "$IOS_OUT_DIR" -maxdepth 1 -name '*.ipa' -print 2>/dev/null | head -1)
  [ -n "$ARTIFACT" ] || die ".ipa 를 찾지 못했다: / Could not find an .ipa: $IOS_OUT_DIR
   서명 설정(app_store_team_id·code_sign_identity_debug)을 확인한다. / Check signing settings (app_store_team_id and code_sign_identity_debug)."
fi

[ -e "$ARTIFACT" ] || die "설치할 파일이 없다: / Build artifact does not exist: $ARTIFACT"
ok "산출물: / Artifact: $ARTIFACT ($(du -sh "$ARTIFACT" | cut -f1))"

# ── 설치 · 실행 ─────────────────────────────────────────────────────────
case "$PLATFORM" in
  windows)
    if [ "$LAUNCH" -eq 0 ]; then
      ok "빌드만 완료 / Build ready: $ARTIFACT"
    elif [ "$CONSOLE" -eq 1 ]; then
      step "실행 중 (Ctrl+C 로 중지) / Launching with console output (Ctrl+C to stop)"
      "$ARTIFACT" --rendering-driver vulkan
    else
      step "Windows 게임 실행 / Launching Windows game"
      mkdir -p artifacts/logs
      # Use the desktop Vulkan renderer; D3D12 crashes on this PC.
      "$ARTIFACT" --rendering-driver vulkan >"artifacts/logs/install-windows-$BUILD_MODE-run.log" 2>&1 < /dev/null &
      ok "Windows 게임 실행 완료 / Launched Windows game (PID $!)."
      echo "   로그 / Logs: artifacts/logs/install-windows-$BUILD_MODE-run.log"
    fi
    ;;
  android)
    step "설치 중 — / Installing — $PACKAGE_ID"
    # 🛑 debug ↔ release 를 번갈아 깔면 서명이 달라 -r 이 거부된다(INSTALL_FAILED_UPDATE_INCOMPATIBLE).
    #    지우고 다시 깔면 되지만 **앱 데이터(로그인·세이브)가 함께 지워진다** → 사람에게 묻는다.
    INSTALL_LOG=$(adb -s "$DEVICE_ID" install -r "$ARTIFACT" 2>&1) || true
    printf '%s\n' "$INSTALL_LOG" | tail -2
    if printf '%s' "$INSTALL_LOG" | grep -q "INSTALL_FAILED_UPDATE_INCOMPATIBLE\|signatures do not match"; then
      warn "이미 깔린 앱과 서명이 다르다 (debug ↔ release 전환). 지우고 새로 깔아야 한다 — / The installed app has a different signature (debug/release switch). Reinstallation is required —
    🛑 앱 데이터(로그인 세션·세이브)가 함께 지워진다. / WARNING: app data, including login sessions and saves, will be deleted."
      REINSTALL="n"
      if [ -t 0 ]; then printf '지우고 새로 설치할까? [y/N]: / Uninstall and reinstall? [y/N]: '; read -r REINSTALL || REINSTALL="n"; fi
      case "$REINSTALL" in
        y|Y|yes)
          step "기존 앱 삭제 — / Uninstalling the existing app — $PACKAGE_ID"
          adb -s "$DEVICE_ID" uninstall "$PACKAGE_ID" | tail -1
          adb -s "$DEVICE_ID" install "$ARTIFACT" | tail -2
          ;;
        *)
          die "설치를 중단했다. 같은 모드로 다시 빌드하거나, 직접 지운다: / Installation cancelled. Rebuild with the same mode, or uninstall manually:
   adb -s $DEVICE_ID uninstall $PACKAGE_ID"
          ;;
      esac
    fi

    if [ "$LAUNCH" -eq 1 ]; then
      step "실행 중 / Launching"
      adb -s "$DEVICE_ID" shell monkey -p "$PACKAGE_ID" \
        -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
      ok "기기 화면을 확인한다. / Application launched on the device."
      if [ "$CONSOLE" -eq 1 ]; then
        step "로그 (Ctrl+C 로 중지) / Logs (Ctrl+C to stop)"
        adb -s "$DEVICE_ID" logcat -c
        adb -s "$DEVICE_ID" logcat -s godot:V GodotEngine:V AndroidRuntime:E DEBUG:V
      else
        echo "   로그: / Logs: adb -s $DEVICE_ID logcat -s godot"
      fi
    fi
    ;;

  ios)
    step "설치 중 — / Installing — $PACKAGE_ID"
    xcrun devicectl device install app --device "$DEVICE_ID" "$ARTIFACT" \
      | grep -E 'bundleID|installationURL' || true

    if [ "$LAUNCH" -eq 1 ]; then
      step "실행 중 / Launching"
      if [ "$CONSOLE" -eq 1 ]; then
        # 앱이 끝날 때까지 로그를 붙잡는다. Ctrl+C 로 중지.
        xcrun devicectl device process launch \
          --device "$DEVICE_ID" --terminate-existing --console "$PACKAGE_ID"
      else
        xcrun devicectl device process launch \
          --device "$DEVICE_ID" --terminate-existing "$PACKAGE_ID" | tail -1
        ok "기기 화면을 확인한다. / Application launched on the device."
        echo "   로그: / Logs: $(basename "$0") $DEVICE_ID --skip-build --console"
      fi
    fi
    ;;

  macos)
    # export_path 가 .zip 이면 풀어서 .app 을 꺼낸다
    APP="$ARTIFACT"
    case "$ARTIFACT" in
      *.zip)
        step "압축 해제 / Extracting archive"
        (cd "$(dirname "$ARTIFACT")" && unzip -oq "$(basename "$ARTIFACT")")
        APP=$(find "$(dirname "$ARTIFACT")" -maxdepth 1 -name '*.app' -print | head -1)
        [ -n "$APP" ] || die ".app 을 찾지 못했다: / Could not find an .app: $(dirname "$ARTIFACT")"
        ;;
    esac

    # 서명 없이 빌드하면 Gatekeeper 가 막는다 — 내가 만든 빌드에만 쓴다
    xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

    if [ "$LAUNCH" -eq 1 ]; then
      BIN=$(find "$APP/Contents/MacOS" -maxdepth 1 -type f -perm -u+x -print 2>/dev/null | head -1)
      [ -n "$BIN" ] || die "실행 바이너리를 찾지 못했다: / Could not find an executable: $APP/Contents/MacOS"
      if [ "$CONSOLE" -eq 1 ]; then
        step "실행 중 (로그 붙임 — Ctrl+C 로 중지) / Launching with console output (Ctrl+C to stop)"
        "$BIN"
      else
        step "실행 중 / Launching"
        open "$APP"
        ok "창을 확인한다. / Application window launched."
        echo "   로그: / Logs: $(basename "$0") macos --skip-build --console"
      fi
    else
      ok "빌드만 완료: / Build ready: $APP"
    fi
    ;;
esac
