#!/usr/bin/env bash
#
# install.sh — Build, install, and run without the Godot editor.
#
#   install.sh                       List available devices by number and prompt for one
#   install.sh 1                     Pick device 1 from the list directly
#   install.sh R58X609XXYV           Specify an Android serial directly
#   install.sh 00008140-001C24C9…    Specify an iOS UDID directly
#   install.sh macos                 Build and run on this Mac
#   bash install.sh --win            Build and run on this Windows PC
#                                    PowerShell: & "C:/Program Files/Git/bin/bash.exe" ./install.sh --win
#
#   install.sh <target> --release    Release build (no prompt)
#   install.sh <target> --debug      Debug build (no prompt)
#   install.sh <target> --release --no-lazy-download
#                                    Release build with every asset bundled (release defaults to lazy-download)
#   install.sh <target> --release --boot-profile
#                                    Emit the [Boot] startup timeline from a release build too
#   install.sh <target> --release --boot-parts
#                                    Also time the world scene load part by part (slower overall; implies --boot-profile)
#   install.sh <target> --staging-server     Connect to the staging server (no server prompt)
#   install.sh <target> --production-server  Connect to the production server (no server prompt; debug builds too)
#                                    With neither, you are asked which server after choosing the build mode (interactive only).
#                                    Only meaningful when the project reads the feature tags staging_server / production_server
#                                    (Laryen 3D: debug defaults to staging, release defaults to production)
#   install.sh <target> --preset "A15 Test"
#                                    Pick an export_presets.cfg preset directly
#                                    (when one platform has several, e.g. per-device debug presets)
#   install.sh <target> --skip-build Skip the build; install and run only
#   install.sh <target> --console    Attach runtime logs to the terminal (Ctrl+C to stop)
#   install.sh <target> --no-launch  Install without launching
#   install.sh <target> --path ~/game
#                                    Godot project directory (default: search upward from the current folder)
#   install.sh --list                List available devices and exit
#
# The selected device decides the platform. Preset names, package IDs, and output paths are
# read from export_presets.cfg, so nothing needs to change per project.
#
# Without --debug/--release, the build mode is asked after the device is chosen (interactive only; default Debug).
#   Debug   — print() logs reach logcat and the remote debugger attaches. The engine is unoptimized, so it is slow
#   Release — The same optimized build as distribution. Use it to measure performance (fps) and loading time
#             🛑 Android release needs a release keystore. Without one, this script signs with the
#                debug keystore and warns (device testing only — cannot be uploaded to a store).
#
# GODOT_BIN overrides automatic Godot detection. Matching export templates are required.
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
PRESET_ARG=""        # --preset 으로 직접 고른 preset 이름
CONSOLE=0
LAUNCH=1
LIST_ONLY=0
PROJECT_ARG=""
WIN=0

# lazy-download — release 빌드에서 **기본으로 켠다**(2026-09-10 사람 결정).
#
#   켜짐: 기물 시각 리소스를 번들에서 빼고 `.pck` 로 R2 에 올린다. 게임은 맵에 들어간 뒤
#         내려받아 화면에 채운다. 콜리전은 언제나 번들에 있으므로 팩이 늦어도 걸어다닐 수 있다.
#   꺼짐(`--no-lazy-download`): 전부 번들에 넣는다. 네트워크 없이 도는 빌드가 필요할 때.
#
# 🛑 debug 빌드에서는 **무조건 꺼진다** — 개발 중에는 늘 모든 자산이 번들에 있어야 한다.
LAZY_DOWNLOAD=1
# 🛑 릴리스 APK 에는 `[Boot]` 로그가 **한 줄도 없다** — `BootProfile.mark()` 가 디버그·autotest·
#    `bootprofile` 기능에서만 찍기 때문이다(`scripts/boot_profile.gd`). 2026-09-12 이것을 모르고
#    릴리스 로그에서 부팅 타임라인을 찾다가 "로그가 밀렸나" 를 한참 의심했다.
#    🔑 그래서 지금까지 인용해 온 부팅 숫자는 **전부 디버그 값**이다. 디버그는 GDScript 가
#    최적화 없이 돌아 훨씬 느리므로, **릴리스의 진짜 부팅 시간을 재려면 이 옵션을 쓴다.**
#    🛑 원본 `export_presets.cfg` 는 건드리지 않는다 — 사본에만 기능 태그를 더한다
#    (`export_from_clone.py --feature`). 그래서 다른 세션의 빌드에 전파되지 않는다.
BOOT_PROFILE=0
BOOT_PARTS=0
# 🌐 접속 서버 — "staging" · "production" · 빈 값(아직 안 정했다 → 빌드할 때 묻는다 · 비대화형이면 빌드 기본값).
#    프로젝트가 기능 태그 `staging_server`·`production_server` 를 읽을 때만 뜻이 있다
#    (라리엔 3D `scripts/client.config.gd`: debug 기본 = 스테이징 · release 기본 = 운영).
#    빌드 기본값과 다른 쪽을 고르면(release→스테이징 · debug→운영) 사본 프리셋에 태그를 심고
#    (모바일 포함 · `export_from_clone.py --feature`), macOS·Windows 는 실행 인자(`--staging-server`·
#    `--production-server`)도 넘긴다 — `--skip-build` 로 이미 만든 데스크톱 앱을 켤 때도 되게.
#    🛑 원본 `export_presets.cfg` 는 건드리지 않는다. 모르는 프로젝트의 앱은 이 인자를 그냥 무시한다.
SERVER_TARGET=""

while [ $# -gt 0 ]; do
  case "$1" in
    --win)        WIN=1 ;;
    --release)    BUILD_MODE="release" ;;
    --debug)      BUILD_MODE="debug" ;;
    --staging-server)
      [ "$SERVER_TARGET" != "production" ] || die "--staging-server and --production-server are mutually exclusive."
      SERVER_TARGET="staging" ;;
    --production-server)
      [ "$SERVER_TARGET" != "staging" ] || die "--staging-server and --production-server are mutually exclusive."
      SERVER_TARGET="production" ;;
    --boot-profile) BOOT_PROFILE=1 ;;
    # 🔑 월드 씬 로드를 **덩어리별로** 가른다(`character_flow._measure_world_parts()`).
    #    🛑 순차 동기 로드라 **총 소요가 평소보다 늘어난다** — "얼마나 빨라졌나" 를 재는
    #    평소 측정에는 쓰지 않는다. 내역이 필요할 때만. `--boot-profile` 을 함께 켠다.
    --boot-parts) BOOT_PROFILE=1; BOOT_PARTS=1 ;;
    --no-lazy-download) LAZY_DOWNLOAD=0 ;;
    --skip-build) SKIP_BUILD=1 ;;
    --preset)
      [ $# -ge 2 ] && [ -n "$2" ] && [[ "$2" != -* ]] || die "--preset requires a preset name."
      shift; PRESET_ARG="$1" ;;
    --console)    CONSOLE=1 ;;
    --no-launch)  LAUNCH=0 ;;
    --list)       LIST_ONLY=1 ;;
    --path)
      [ $# -ge 2 ] && [ -n "$2" ] && [[ "$2" != -* ]] || die "--path requires a project directory."
      shift; PROJECT_ARG="$1" ;;
    -h|--help)    awk 'NR>1 { if (/^#/) { sub(/^# ?/, ""); print } else exit }' "$0"; exit 0 ;;
    -*)           die "Unknown option: $1" ;;
    *)            SELECTION="$1" ;;
  esac
  shift
done

if [ "$WIN" -eq 1 ]; then
  case "$SELECTION" in
    ""|win|windows|Windows) SELECTION="windows" ;;
    *) die "--win cannot be combined with another device selection: $SELECTION" ;;
  esac
fi

is_windows() {
  case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) return 0 ;; esac
  return 1
}

windows_entry() {
  is_windows || return 0
  printf 'windows\tlocal\tRun on this Windows PC (%s)\n' "$(uname -m)"
}

case "$SELECTION" in
  win|windows|Windows)
    is_windows || die "The Windows target requires Git Bash on Windows (not WSL)." ;;
esac

# ── 장치 수집 ───────────────────────────────────────────────────────────
# 각 항목은  플랫폼<TAB>기기ID<TAB>표시이름  한 줄이다.

macos_entry() {
  [ "$(uname -s)" = "Darwin" ] || return 0
  printf 'macos\tlocal\tRun on this Mac (%s)\n' "$(uname -m)"
}

android_entries() {
  command -v adb >/dev/null 2>&1 || return 0
  adb devices -l 2>/dev/null | awk 'NR>1 && $2=="device" {
    serial = $1; model = ""
    for (i = 3; i <= NF; i++) if ($i ~ /^model:/) { model = substr($i, 7); gsub(/_/, " ", model) }
    if (model == "") model = "Android device"
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
      if (model == "") model = "iOS device"
      printf "ios\t%s\t%s — %s\n", uuid, $1, model
    }'
}

collect_devices() { { windows_entry; macos_entry; ios_entries; android_entries; } 2>/dev/null | awk 'NF'; }

DEVICES=$(collect_devices)

print_menu() {
  echo "Available devices:"
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
  printf '%s\n' "$DEVICES" | grep -q '^ios'     || echo "  (No iOS device — connect via USB and tap 'Trust This Computer' on the device)"
  printf '%s\n' "$DEVICES" | grep -q '^android' || echo "  (No Android device — enable USB debugging and connect via USB)"
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
    echo "Pass a device number as an argument:  $(basename "$0") 1"
    exit 0
  fi
  echo
  printf 'Select a number [1]: '
  read -r SELECTION || SELECTION=""
  [ -n "$SELECTION" ] || SELECTION="1"
  echo
fi

ENTRY=$(resolve_selection "$SELECTION") || {
  print_menu >&2
  die "No device matches '$SELECTION'. Use a number above or a device ID."
}

[ -n "$ENTRY" ] || die "No available device matches '$SELECTION'. Use --list."
PLATFORM=$(printf '%s' "$ENTRY" | cut -f1)
DEVICE_ID=$(printf '%s' "$ENTRY" | cut -f2)
DEVICE_LABEL=$(printf '%s' "$ENTRY" | cut -f3)
ok "Selected: $PLATFORM — $DEVICE_LABEL"

# ── 빌드 모드 선택 ──────────────────────────────────────────────────────
# --debug/--release 를 줬으면 묻지 않는다. 비대화형(파이프·CI)에서는 debug 로 간다.
if [ -z "$BUILD_MODE" ]; then
  if [ "$SKIP_BUILD" -eq 1 ]; then
    BUILD_MODE="debug"     # 빌드를 안 하므로 로그 파일 이름에만 쓰인다
  elif [ ! -t 0 ]; then
    BUILD_MODE="debug"
    echo "   (Noninteractive — building Debug. Use --release for Release.)"
  else
    echo
    echo "Build mode:"
    echo
    printf '  \033[1;36m1)\033[0m  Debug     print() logs and remote debugging. \033[90mUnoptimized engine — not for FPS measurements\033[0m\n'
    printf '  \033[1;36m2)\033[0m  Release   The same optimized build as distribution. \033[90mUse this for FPS and loading-time measurements\033[0m\n'
    echo
    printf 'Select a number [1]: '
    read -r MODE_SEL || MODE_SEL=""
    echo
    case "${MODE_SEL:-1}" in
      1|d|debug|Debug)     BUILD_MODE="debug" ;;
      2|r|release|Release) BUILD_MODE="release" ;;
      *) die "Build mode must be '1' (Debug) or '2' (Release): '$MODE_SEL'" ;;
    esac
  fi
fi
ok "Build mode: $BUILD_MODE"

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
  || die "Could not find project.godot. Run inside a Godot project or specify --path."
cd "$ROOT"
ok "Project: $ROOT"

# ── 접속 서버 선택 ──────────────────────────────────────────────────────
# --staging-server/--production-server 를 줬으면 묻지 않는다. 비대화형이면 빌드 모드의 기본 서버로 간다.
# 🔑 엔터(기본)는 빌드 모드의 기본 서버다 — debug = 스테이징 · release = 운영. 엔터만 누르면 예전과 같은 앱이 나온다.
# 🔑 이 스크립트는 여러 프로젝트가 함께 쓴다 — 두 기능 태그를 모두 읽는 프로젝트(라리엔 3D `scripts/client.config.gd`)에서만 묻는다.
#    --skip-build 면 묻지 않는다: 모바일은 서버가 빌드 때 정해졌고, 데스크톱은 옵션을 줬을 때만 실행 인자로 바꾼다.
project_reads_feature() { grep -rqsF --include='*.gd' "\"$1\"" "$ROOT/scripts" 2>/dev/null; }
if [ "$BUILD_MODE" = "release" ]; then SERVER_DEFAULT="production"; else SERVER_DEFAULT="staging"; fi
if [ -z "$SERVER_TARGET" ] && [ "$SKIP_BUILD" -eq 0 ] && [ -f "$ROOT/tools/export_from_clone.py" ] \
   && project_reads_feature "staging_server" && project_reads_feature "production_server"; then
  if [ ! -t 0 ]; then
    SERVER_TARGET="$SERVER_DEFAULT"
    echo "   (Noninteractive — using the build default server ($SERVER_TARGET). Use --staging-server or --production-server to change it.)"
  else
    if [ "$SERVER_DEFAULT" = "production" ]; then SERVER_DEF_NUM=2; else SERVER_DEF_NUM=1; fi
    echo
    echo "Server:"
    echo
    printf '  \033[1;36m1)\033[0m  Staging     Staging (test) server. \033[90mTest accounts and records stay out of the production DB\033[0m\n'
    printf '  \033[1;36m2)\033[0m  Production  Production server with real players. \033[90mPurchases and records are real\033[0m\n'
    echo
    printf 'Select a number [%s]: ' "$SERVER_DEF_NUM"
    read -r SERVER_SEL || SERVER_SEL=""
    echo
    case "${SERVER_SEL:-$SERVER_DEF_NUM}" in
      1|s|staging|Staging)       SERVER_TARGET="staging" ;;
      2|p|production|Production) SERVER_TARGET="production" ;;
      *) die "Server must be '1' (Staging) or '2' (Production): '$SERVER_SEL'" ;;
    esac
  fi
fi
[ -z "$SERVER_TARGET" ] || ok "Server: $SERVER_TARGET"

PRESETS="$ROOT/export_presets.cfg"
[ -f "$PRESETS" ] || die "Missing export_presets.cfg. Create an export preset first."

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

# preset 이름으로 값을 읽는다 — 같은 플랫폼에 preset 이 여러 개일 때 쓴다(예: "macOS Release")
preset_get_named() {
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
      if (k == "name" && !(v in byname)) byname[v] = cur
    }
    END { if (want in byname) print data[byname[want] "\x01" key] }
  ' "$PRESETS"
}

# 쓸 preset 이름을 고른다 — 빈 문자열이면 "그 플랫폼의 첫 preset" 으로 물러선다.
#   $1: release 전용 preset 이름   $2: 이 플랫폼의 platform 값("Android" 등)
# 우선순위: --preset 으로 직접 고른 것 > release 전용 preset > 없음.
pick_preset() {
  if [ -n "$PRESET_ARG" ]; then
    local want; want=$(preset_get_named "$PRESET_ARG" "platform")
    [ -n "$want" ] || die "No preset named \"$PRESET_ARG\" in export_presets.cfg."
    [ "$want" = "$2" ] || die "Preset \"$PRESET_ARG\" targets $want, but the selected device is $2."
    printf '%s\n' "$PRESET_ARG"
    return 0
  fi
  [ "$BUILD_MODE" = "release" ] || return 0
  [ -n "$(preset_get_named "$1" "platform")" ] || return 0
  printf '%s\n' "$1"
}

# ── 플랫폼별 preset 값 ──────────────────────────────────────────────────
# List every preset name for a platform, in export_presets.cfg order.
preset_names_for_platform() {
  awk -v want="$1" '
    { sub(/\r$/, "") }
    /^\[preset\.[0-9]+\]$/ { cur = $0; gsub(/[^0-9]/, "", cur); next }
    /^\[preset\.[0-9]+\.options\]$/ { cur = ""; next }
    /^[A-Za-z]/ {
      if (cur == "") next
      eq = index($0, "=")
      if (eq == 0) next
      k = substr($0, 1, eq - 1)
      v = substr($0, eq + 1)
      gsub(/^[ \t]+|[ \t\r]+$/, "", v)
      gsub(/^"|"$/, "", v)
      if (k == "name") nm[cur] = v
      else if (k == "platform" && v == want && nm[cur] != "") order[++n] = cur
    }
    END { for (i = 1; i <= n; i++) print nm[order[i]] }
  ' "$PRESETS"
}

# True when every custom export template the preset names exists on this machine.
# A preset with empty custom_template uses the official templates, so it is always usable.
# A Steam preset points at GodotSteam templates that live only on the machine that owns
# them; elsewhere it is skipped instead of failing with "Custom debug template not found".
preset_templates_present() {
  local tpl
  for tpl in "$(preset_get_named "$1" "custom_template/debug")" \
             "$(preset_get_named "$1" "custom_template/release")"; do
    [ -n "$tpl" ] || continue
    if is_windows; then tpl=$(cygpath -u "$tpl" 2>/dev/null || printf '%s' "$tpl"); fi
    [ -f "$tpl" ] || return 1
  done
  return 0
}

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

# 🛑 빌드 전에 서브모듈 작업트리가 상위 저장소가 기록한 포인터와 맞는지 본다.
#    git pull 은 서브모듈을 건드리지 않는다 — 상위 코드가 애드온의 새 API 를 부르는데
#    애드온 체크아웃만 옛 커밋에 앉아 있으면, export 는 디스크에 있는 것을 그대로 담으므로
#    **빌드는 성공하고** 어긋남은 기기에서 스크립트 로드 파스 에러로야 드러난다
#    (2026-09-16 라리엔 3D 실제 사고 — 서브모듈이 22커밋 뒤처져 로그인 화면이 죽었다).
#    판정·문구는 프로젝트가 가진 scripts/check-submodules.sh 가 하고, 그 파일이 없는
#    프로젝트에서는 아무 일도 하지 않는다. 앞선 작업트리(애드온을 고치는 중)는 경고만 하고 통과한다.
if [ "$SKIP_BUILD" -eq 0 ] && [ "${LARYEN_SKIP_SUBMODULE_CHECK:-0}" != "1" ] \
   && [ -f "$ROOT/scripts/check-submodules.sh" ]; then
  bash "$ROOT/scripts/check-submodules.sh" \
    || die "Refusing to build with a mismatched submodule checkout (see the fix commands above)."
fi

if [ "$SKIP_BUILD" -eq 0 ]; then
  GODOT_BIN="${GODOT_BIN:-$(find_godot || true)}"
  [ -n "$GODOT_BIN" ] || die "Godot was not found. Set GODOT_BIN to your Godot executable path."
  if is_windows; then GODOT_BIN=$(cygpath -u "$GODOT_BIN"); fi
  command -v "$GODOT_BIN" >/dev/null 2>&1 || die "Godot executable does not exist: $GODOT_BIN"
fi

case "$PLATFORM" in
  windows)
    # Pick the first Windows Desktop preset this machine can actually export with:
    # --preset wins, otherwise skip presets whose custom templates are missing here.
    WIN_PRESET_FIRST=""
    PRESET_NAME=""
    if [ -n "$PRESET_ARG" ]; then
      PRESET_NAME=$(pick_preset "" "Windows Desktop")
    else
      while IFS= read -r win_candidate; do
        [ -n "$win_candidate" ] || continue
        [ -n "$WIN_PRESET_FIRST" ] || WIN_PRESET_FIRST="$win_candidate"
        if preset_templates_present "$win_candidate"; then PRESET_NAME="$win_candidate"; break; fi
      done < <(preset_names_for_platform "Windows Desktop")
      [ -n "$PRESET_NAME" ] || [ -z "$WIN_PRESET_FIRST" ] || die "Every Windows Desktop preset needs a custom template that is missing on this machine: $(preset_names_for_platform "Windows Desktop" | tr '
' ' ')"
    fi
    EXPORT_PATH=$(preset_get_named "$PRESET_NAME" "export_path")
    [ -n "$PRESET_NAME" ] || die 'No platform="Windows Desktop" preset in export_presets.cfg.'
    [ -n "$EXPORT_PATH" ] || EXPORT_PATH="builds/windows/${PRESET_NAME}.exe"
    case "$EXPORT_PATH" in *.exe) ;; *) die "Windows export_path must end in .exe: $EXPORT_PATH" ;; esac
    ARTIFACT="$ROOT/$EXPORT_PATH"
    ;;
  android)
    # SM A12·SM A15 는 같은 arm64-v8a APK 하나로 돈다 — release 는 공용 preset 을 쓴다
    PRESET_NAME=$(pick_preset "Android Release" "Android")
    if [ -n "$PRESET_NAME" ]; then
      PACKAGE_ID=$(preset_get_named "$PRESET_NAME" "package/unique_name")
      EXPORT_PATH=$(preset_get_named "$PRESET_NAME" "export_path")
    else
      PRESET_NAME=$(preset_get "Android" "name")
      PACKAGE_ID=$(preset_get "Android" "package/unique_name")
      EXPORT_PATH=$(preset_get "Android" "export_path")
    fi
    [ -n "$PRESET_NAME" ] || die "No platform=\"Android\" preset in export_presets.cfg."
    [ -n "$PACKAGE_ID" ]  || die "Android preset is missing package/unique_name."
    [ -n "$EXPORT_PATH" ] || EXPORT_PATH="builds/android/${PRESET_NAME}.apk"
    ARTIFACT="$ROOT/$EXPORT_PATH"
    ;;
  ios)
    PRESET_NAME=$(pick_preset "JaeHo16 Release" "iOS")
    if [ -n "$PRESET_NAME" ]; then
      PACKAGE_ID=$(preset_get_named "$PRESET_NAME" "application/bundle_identifier")
      EXPORT_PATH=$(preset_get_named "$PRESET_NAME" "export_path")
      PROJECT_ONLY=$(preset_get_named "$PRESET_NAME" "application/export_project_only")
    else
      PRESET_NAME=$(preset_get "iOS" "name")
      PACKAGE_ID=$(preset_get "iOS" "application/bundle_identifier")
      EXPORT_PATH=$(preset_get "iOS" "export_path")
      PROJECT_ONLY=$(preset_get "iOS" "application/export_project_only")
    fi
    [ -n "$PRESET_NAME" ] || die "No platform=\"iOS\" preset in export_presets.cfg."
    [ -n "$PACKAGE_ID" ]  || die "iOS preset is missing application/bundle_identifier."
    [ -n "$EXPORT_PATH" ] || EXPORT_PATH="builds/ios/${PRESET_NAME}.ipa"
    if [ "$PROJECT_ONLY" = "true" ]; then
      die "The iOS preset has application/export_project_only=true.
   Godot then exports only the Xcode project and stops, so no .ipa is produced.
   Set it to false in export_presets.cfg."
    fi
    IOS_OUT_DIR="$ROOT/$(dirname "$EXPORT_PATH")"
    ;;
  macos)
    # release 는 전용 preset("macOS Release")이 있으면 그것으로 빌드한다 —
    # 산출물 경로가 달라 debug 빌드를 덮어쓰지 않는다.
    PRESET_NAME=$(pick_preset "macOS Release" "macOS")
    if [ -n "$PRESET_NAME" ]; then
      PACKAGE_ID=$(preset_get_named "$PRESET_NAME" "application/bundle_identifier")
      EXPORT_PATH=$(preset_get_named "$PRESET_NAME" "export_path")
    else
      PRESET_NAME=$(preset_get "macOS" "name")
      PACKAGE_ID=$(preset_get "macOS" "application/bundle_identifier")
      EXPORT_PATH=$(preset_get "macOS" "export_path")
    fi
    [ -n "$PRESET_NAME" ] || die "No platform=\"macOS\" preset in export_presets.cfg."
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
      warn "Changed 'debug' to 'release' in output path: $EXPORT_PATH"
    fi
    ;;
  *release*)
    if [ "$BUILD_MODE" = "debug" ]; then
      EXPORT_PATH=${EXPORT_PATH//release/debug}
      ARTIFACT="$ROOT/$EXPORT_PATH"
      warn "Changed 'release' to 'debug' in output path: $EXPORT_PATH"
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
  [ -n "$dbg" ] || die "No release keystore is configured, and no debug keystore was found to fall back on.
   For store builds, create one with keytool and export GODOT_ANDROID_KEYSTORE_RELEASE_PATH/USER/PASSWORD
   (export-build-android.md §5). For now, build with --debug."
  export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$dbg"
  export GODOT_ANDROID_KEYSTORE_RELEASE_USER="androiddebugkey"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="android"
  warn "No release keystore: signing with the debug keystore — device testing only (cannot be uploaded to a store).
    $dbg"
}

# ── 켜 둔 macOS 앱 확인 ─────────────────────────────────────────────────
# 🛑🛑 **실행 중인 앱의 번들 위로 다시 내보내지 않는다**(2026-09-15 라리엔 3D 사람 보고 — 로그아웃이 "Logging out..." 에 갇혔다).
#    export 는 `Contents/` 를 새로 만든다. 켜 둔 게임은 자기 `.pck` 와 작업 폴더를 잃어 **처음 읽는 리소스부터 전부 실패**하고
#    (로그인 씬 `Cannot open file` · `.import … Unterminated string` · `getcwd … is null`) 화면은 멈춘 것처럼 서 있다.
#    게다가 빌드 뒤 `open` 은 **이미 떠 있는 옛 창을 앞으로 가져올 뿐**이라 사람은 새 빌드를 켰다고 믿는다.
#    그래서 빌드 **전에** 같은 번들에서 도는 프로세스를 찾는다 — 대화형이면 묻고 끄고, 비대화형이면 멈춘다(사람의 창을 말없이 끄지 않는다).
# 🔑 pgrep 대신 ps+awk — 셸 래퍼·패턴 해석에 흔들리지 않게 경로를 글자 그대로 비교한다.
# 🛑 경로는 **환경 변수로** 넘긴다 — `awk -v 경로` 로 넘기면 awk 자신의 명령 줄에 그 경로가 찍혀 자기를 실행 중인 앱으로 잡는다(실측).
macos_running_pids() {
  ps -axo pid=,command= | MACOS_APP_ABS="$ARTIFACT/Contents/MacOS/" MACOS_APP_REL="$EXPORT_PATH/Contents/MacOS/" awk '
    { abs = ENVIRON["MACOS_APP_ABS"]; rel = ENVIRON["MACOS_APP_REL"] }
    (length(abs) > 0 && index($0, abs)) || (length(rel) > 0 && index($0, rel)) { print $1 }'
}
if [ "$SKIP_BUILD" -eq 0 ] && [ "$PLATFORM" = "macos" ]; then
  RUNNING_PIDS=$(macos_running_pids)
  if [ -n "$RUNNING_PIDS" ]; then
    warn "The same app is running (PID $(echo $RUNNING_PIDS)) — exporting over it makes that window lose its game files and freeze.
    $ARTIFACT"
    QUIT_RUNNING="n"
    if [ -t 0 ]; then printf 'Quit that app and build? [y/N]: '; read -r QUIT_RUNNING || QUIT_RUNNING="n"; fi
    case "$QUIT_RUNNING" in
      y|Y|yes)
        kill $RUNNING_PIDS 2>/dev/null || true
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          [ -z "$(macos_running_pids)" ] && break
          sleep 1
        done
        [ -z "$(macos_running_pids)" ] || die "It did not quit within 10 seconds — close the window yourself and run again."
        ok "Quit the running app."
        ;;
      *)
        die "Build stopped — close the game window and run again."
        ;;
    esac
  fi
fi

# ── 접속 서버 옵션 확인 ─────────────────────────────────────────────────
# 🌐 고른 서버가 실제로 앱에 들어가는 경우만 통과시킨다 — 조용히 무시되면 사람은 스테이징 빌드라고 믿고 운영에 붙는다(반대도).
#    빌드 기본 서버와 다른 쪽을 골랐을 때만 사본 프리셋에 기능 태그를 심는다(SERVER_FEATURE) — 같은 쪽이면 태그 없이도 그 서버다.
# 🛑 bash 3.2 + `set -u` 는 빈 배열 전개를 unbound 로 본다 — 쓰는 곳은 `${RUN_ARGS[@]+"${RUN_ARGS[@]}"}` 로 쓴다.
RUN_ARGS=()
SERVER_FEATURE=""
if [ -n "$SERVER_TARGET" ]; then
  if [ "$SKIP_BUILD" -eq 0 ] && [ "$SERVER_TARGET" != "$SERVER_DEFAULT" ]; then
    SERVER_FEATURE="${SERVER_TARGET}_server"
    [ -f "$ROOT/tools/export_from_clone.py" ] \
      || die "--$SERVER_TARGET-server requires tools/export_from_clone.py (it adds the feature tag in a clone)."
    project_reads_feature "$SERVER_FEATURE" \
      || die "No script under scripts/ reads the feature tag \"$SERVER_FEATURE\"; the app would still use the $SERVER_DEFAULT server."
  fi
  case "$PLATFORM" in
    macos|windows) RUN_ARGS+=("--$SERVER_TARGET-server") ;;
    *)
      if [ "$SKIP_BUILD" -eq 1 ]; then
        warn "The server of an installed $PLATFORM app is fixed at build time — to switch to $SERVER_TARGET, rebuild without --skip-build."
      fi
      ;;
  esac
fi

# ── 빌드 ────────────────────────────────────────────────────────────────
if [ "$SKIP_BUILD" -eq 0 ]; then
  [ "$PLATFORM" = "android" ] && [ "$BUILD_MODE" = "release" ] && android_release_signing
  step "Building — $PLATFORM / $BUILD_MODE / preset \"$PRESET_NAME\"${SERVER_TARGET:+ / server $SERVER_TARGET}"
  if [ "$PLATFORM" = "windows" ]; then
    mkdir -p "$(dirname "$ARTIFACT")" artifacts/logs
  else
    mkdir -p "$(dirname "$ROOT/$EXPORT_PATH")" artifacts/logs
  fi
  # ── 배포용 맵 분할 · lazy-download · 내보내기 ──────────────────────────────
  # 저작 씬(`main.tscn`)에는 청크가 **전부** 들어 있다 — 맵 디자이너가 늘 하던 대로 작업하기
  # 위해서다(2026-09-10 사람 결정). 그대로 내보내면 A12 에서 씬 파싱에만 3.4초가 들므로
  # **배포본에서만** 잘라 내고 나머지는 입장 뒤 스트리밍한다.
  #
  # 🛑🛑 **release 는 사본에서 내보낸다 — 원본 `main.tscn` 은 한 바이트도 바꾸지 않는다**
  #    (SSOT §3.5 저작 불가침 ② · 2026-09-12 사고). 예전에는 원본을 잘랐다가 되돌렸는데,
  #    그 **사이에** Godot 에디터가 열려 있으면 잘린 씬을 읽어 디자이너에게 청크 2개만 보였다 —
  #    그때 저장하면 잘린 맵이 확정된다. `tools/export_from_clone.py` 가 사본을 만들어
  #    자르고·lazy-download 를 켜고·내보낸 뒤 산출물만 가져오고, 원본 해시가 그대로인지 검사한다.
  #
  # 🔑 debug 는 원본을 바꾸지 않으므로(자르지도 lazy 를 켜지도 않는다) 사본 없이 그대로 내보낸다.
  #    단 debug 인데 운영 서버를 골랐으면 기능 태그를 심어야 하므로 사본에서 내보낸다(자르기·lazy 는 여전히 없다).
  #    사본 도구가 없는 프로젝트의 release 도 원본에서 그대로 내보낸다.
  BUILD_FAIL_MSG="Build failed. See artifacts/logs/install-$PLATFORM-$BUILD_MODE.log. Check matching export templates in Editor > Manage Export Templates.
   If an iOS error has no details, check the icon → Team ID → bundle ID → ios.zip template, in that order."
  # 🔑 **이 스크립트는 여러 프로젝트가 함께 쓴다**(godot 스킬 · 프로젝트의 install.sh 는 이 파일로 가는 링크다).
  #    프로젝트 전용 도구는 **있을 때만** 쓰고, 없는 프로젝트는 예전처럼 원본에서 그대로 내보낸다.
  if [ -f "$ROOT/tools/export_from_clone.py" ] && { [ "$BUILD_MODE" = "release" ] || [ -n "$SERVER_FEATURE" ]; }; then
    EXPORT_ARGS=(--preset "$PRESET_NAME" --out "$EXPORT_PATH" --mode "$BUILD_MODE"
                 --log "artifacts/logs/install-$PLATFORM-$BUILD_MODE.log" --godot "$GODOT_BIN")
    if [ "$BUILD_MODE" = "release" ]; then
      if [ -f "$ROOT/tools/split_map_for_release.py" ]; then
        EXPORT_ARGS+=(--split)
      fi
      # 🛑 `--no-lazy-download` 이면 켜지 않는다. 켜도 모바일 프리셋만 고친다(apply_lazy_download.py).
      if [ "$LAZY_DOWNLOAD" -eq 1 ] && [ -f "$ROOT/tools/apply_lazy_download.py" ]; then
        step "Applying lazy-download in a clone"
        EXPORT_ARGS+=(--lazy)
      else
        echo "   No lazy-download — bundling every asset"
      fi
      # 🔑 릴리스에서도 `[Boot]` 타임라인을 찍게 한다(위 BOOT_PROFILE 주석 참조).
      if [ "$BOOT_PROFILE" -eq 1 ]; then
        step "Adding the bootprofile feature — the release build emits [Boot] logs too"
        EXPORT_ARGS+=(--feature bootprofile)
      fi
      if [ "$BOOT_PARTS" -eq 1 ]; then
        step "Adding the bootparts feature — times the world scene part by part (total load time grows)"
        EXPORT_ARGS+=(--feature bootparts)
      fi
    fi
    # 🌐 빌드 기본과 다른 서버 — 사본 프리셋에만 기능 태그를 심는다(위 SERVER_TARGET 주석 참조).
    case "$SERVER_FEATURE" in
      staging_server)
        step "Adding the staging_server feature — this release build connects to the staging server"
        EXPORT_ARGS+=(--feature staging_server) ;;
      production_server)
        step "Adding the production_server feature — this debug build connects to the production server"
        EXPORT_ARGS+=(--feature production_server) ;;
    esac
    python3 "$ROOT/tools/export_from_clone.py" "${EXPORT_ARGS[@]}" || die "$BUILD_FAIL_MSG"
  else
    "$GODOT_BIN" --headless --path "$ROOT" --import --quit >/dev/null 2>&1 || true
    "$GODOT_BIN" --headless --path "$ROOT" \
      "--export-$BUILD_MODE" "$PRESET_NAME" "$EXPORT_PATH" \
      --log-file "artifacts/logs/install-$PLATFORM-$BUILD_MODE.log" \
      || die "$BUILD_FAIL_MSG"
  fi
fi

# iOS 는 export_path 옆에 .ipa 가 떨어진다.
# 🛑 폴더의 아무 .ipa 나 집으면 **다른 preset 이 예전에 만든 빌드**를 설치하게 된다
#    (preset 이 여러 개면 builds/ios 에 .ipa 가 여러 개 쌓인다).
#    preset 이 지정한 경로를 먼저 쓰고, 없을 때만 가장 최근 .ipa 로 물러선다.
if [ "$PLATFORM" = "ios" ]; then
  if [ -e "$ROOT/$EXPORT_PATH" ]; then
    ARTIFACT="$ROOT/$EXPORT_PATH"
  else
    ARTIFACT=$(find "$IOS_OUT_DIR" -maxdepth 1 -name '*.ipa' -print0 2>/dev/null \
      | xargs -0 ls -t 2>/dev/null | head -1)
  fi
  [ -n "$ARTIFACT" ] || die "Could not find an .ipa: $IOS_OUT_DIR
   Check the signing settings (app_store_team_id and code_sign_identity_debug)."
fi

[ -e "$ARTIFACT" ] || die "Build artifact does not exist: $ARTIFACT"
ok "Artifact: $ARTIFACT ($(du -sh "$ARTIFACT" | cut -f1))"

# ── 설치 · 실행 ─────────────────────────────────────────────────────────
case "$PLATFORM" in
  windows)
    if [ "$LAUNCH" -eq 0 ]; then
      ok "Build ready: $ARTIFACT"
    elif [ "$CONSOLE" -eq 1 ]; then
      step "Launching with console output (Ctrl+C to stop)"
      "$ARTIFACT" --rendering-driver vulkan ${RUN_ARGS[@]+"${RUN_ARGS[@]}"}
    else
      step "Launching the Windows game"
      mkdir -p artifacts/logs
      # Use the desktop Vulkan renderer; D3D12 crashes on this PC.
      "$ARTIFACT" --rendering-driver vulkan ${RUN_ARGS[@]+"${RUN_ARGS[@]}"} >"artifacts/logs/install-windows-$BUILD_MODE-run.log" 2>&1 < /dev/null &
      ok "Launched the Windows game (PID $!)."
      echo "   Logs: artifacts/logs/install-windows-$BUILD_MODE-run.log"
    fi
    ;;
  android)
    step "Installing — $PACKAGE_ID"
    # 🛑 debug ↔ release 를 번갈아 깔면 서명이 달라 -r 이 거부된다(INSTALL_FAILED_UPDATE_INCOMPATIBLE).
    #    지우고 다시 깔면 되지만 **앱 데이터(로그인·세이브)가 함께 지워진다** → 사람에게 묻는다.
    # 🛑 --no-incremental — .idsig 가 APK 옆에 있으면 adb 가 incremental 설치를 골라
    #    /data 를 수십 GB 씩 잠식하는 고아 파일을 남긴다(A12 실측).
    INSTALL_LOG=$(adb -s "$DEVICE_ID" install --no-incremental -r "$ARTIFACT" 2>&1) || true
    printf '%s\n' "$INSTALL_LOG" | tail -2
    if printf '%s' "$INSTALL_LOG" | grep -q "INSTALL_FAILED_UPDATE_INCOMPATIBLE\|signatures do not match"; then
      warn "The installed app has a different signature (debug ↔ release switch). It must be uninstalled and reinstalled —
    🛑 app data (login session, saves) will be deleted with it."
      REINSTALL="n"
      if [ -t 0 ]; then printf 'Uninstall and reinstall? [y/N]: '; read -r REINSTALL || REINSTALL="n"; fi
      case "$REINSTALL" in
        y|Y|yes)
          step "Uninstalling the existing app — $PACKAGE_ID"
          adb -s "$DEVICE_ID" uninstall "$PACKAGE_ID" | tail -1
          adb -s "$DEVICE_ID" install --no-incremental "$ARTIFACT" | tail -2
          ;;
        *)
          die "Installation cancelled. Rebuild with the same mode, or uninstall manually:
   adb -s $DEVICE_ID uninstall $PACKAGE_ID"
          ;;
      esac
    elif ! printf '%s' "$INSTALL_LOG" | grep -q 'Success'; then
      # 🛑 설치가 실패했는데 실행으로 넘어가면 **기기에 이미 있던 예전 빌드**가 떠서
      #    방금 만든 것을 검증한 줄 알게 된다. 여기서 멈춘다.
      die "Installation failed — the app on the device is unchanged (still the previous build).
$(printf '%s' "$INSTALL_LOG" | tail -2)"
    fi

    if [ "$LAUNCH" -eq 1 ]; then
      step "Launching"
      adb -s "$DEVICE_ID" shell monkey -p "$PACKAGE_ID" \
        -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
      ok "Launched — check the device screen."
      if [ "$CONSOLE" -eq 1 ]; then
        step "Logs (Ctrl+C to stop)"
        adb -s "$DEVICE_ID" logcat -c
        adb -s "$DEVICE_ID" logcat -s godot:V GodotEngine:V AndroidRuntime:E DEBUG:V
      else
        echo "   Logs: adb -s $DEVICE_ID logcat -s godot"
      fi
    fi
    ;;

  ios)
    step "Installing — $PACKAGE_ID"
    xcrun devicectl device install app --device "$DEVICE_ID" "$ARTIFACT" \
      | grep -E 'bundleID|installationURL' || true

    if [ "$LAUNCH" -eq 1 ]; then
      step "Launching"
      if [ "$CONSOLE" -eq 1 ]; then
        # 앱이 끝날 때까지 로그를 붙잡는다. Ctrl+C 로 중지.
        xcrun devicectl device process launch \
          --device "$DEVICE_ID" --terminate-existing --console "$PACKAGE_ID"
      else
        xcrun devicectl device process launch \
          --device "$DEVICE_ID" --terminate-existing "$PACKAGE_ID" | tail -1
        ok "Launched — check the device screen."
        echo "   Logs: $(basename "$0") $DEVICE_ID --skip-build --console"
      fi
    fi
    ;;

  macos)
    # export_path 가 .zip 이면 풀어서 .app 을 꺼낸다
    APP="$ARTIFACT"
    case "$ARTIFACT" in
      *.zip)
        step "Extracting archive"
        (cd "$(dirname "$ARTIFACT")" && unzip -oq "$(basename "$ARTIFACT")")
        APP=$(find "$(dirname "$ARTIFACT")" -maxdepth 1 -name '*.app' -print | head -1)
        [ -n "$APP" ] || die "Could not find an .app: $(dirname "$ARTIFACT")"
        ;;
    esac

    # 서명 없이 빌드하면 Gatekeeper 가 막는다 — 내가 만든 빌드에만 쓴다
    xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

    if [ "$LAUNCH" -eq 1 ]; then
      BIN=$(find "$APP/Contents/MacOS" -maxdepth 1 -type f -perm -u+x -print 2>/dev/null | head -1)
      [ -n "$BIN" ] || die "Could not find an executable: $APP/Contents/MacOS"
      if [ "$CONSOLE" -eq 1 ]; then
        step "Launching with console output (Ctrl+C to stop)"
        "$BIN" ${RUN_ARGS[@]+"${RUN_ARGS[@]}"}
      else
        step "Launching"
        # 🌐 `--args` 뒤가 앱의 실행 인자다(`--staging-server`). 🛑 이미 떠 있는 앱이면 `open` 은 인자 없이 그 창만 앞으로 가져온다.
        if [ ${#RUN_ARGS[@]} -gt 0 ]; then open "$APP" --args "${RUN_ARGS[@]}"; else open "$APP"; fi
        ok "Launched — check the app window."
        echo "   Logs: $(basename "$0") macos --skip-build --console"
      fi
    else
      ok "Build ready: $APP"
    fi
    ;;
esac
