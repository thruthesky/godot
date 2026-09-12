#!/usr/bin/env bash
#
# uninstall.sh — 기기를 골라, 그 기기에 깔린 이 게임의 앱을 한 번에 지운다.
#
#   uninstall.sh                     장치를 번호로 보여주고 고르게 한다 → 지울 앱 목록 → 확인 → 삭제
#   uninstall.sh 1                   목록의 1번을 바로 고른다
#   uninstall.sh R58X609XXYV         Android 시리얼을 직접 지정
#   uninstall.sh 00008140-001C24C9…  iOS UDID 를 직접 지정
#   uninstall.sh macos               이 맥에 깔린 .app 을 지운다
#
#   uninstall.sh --list              장치 목록만 보고 끝낸다
#   uninstall.sh <선택> --apps       지울 후보만 보여주고 끝낸다 (아무것도 지우지 않는다)
#   uninstall.sh <선택> --dry-run    실행할 명령만 보여준다
#   uninstall.sh <선택> --yes        확인 없이 전부 지운다 (비대화형·스크립트용)
#   uninstall.sh <선택> --pick       후보 중에서 번호로 골라 지운다 (기본은 "전부")
#   uninstall.sh <선택> --match kw   검색어를 더한다 (여러 번 쓸 수 있다)
#   uninstall.sh <선택> --package ID 이 패키지만 지운다 (여러 번 쓸 수 있다. 자동 탐색을 끈다)
#   uninstall.sh <선택> --keep-data  Android — 앱만 지우고 데이터·캐시는 남긴다
#   uninstall.sh <선택> --purge-data macOS·Windows — 앱과 함께 user:// 저장 폴더도 지운다
#   uninstall.sh <선택> --path ~/game  프로젝트 경로 지정 (기본: 현재 폴더에서 위로 탐색)
#
# 무엇을 "이 게임의 앱" 으로 보는가 — 프로젝트에서 스스로 알아낸다. 프로젝트마다 고칠 것이 없다.
#   ① export_presets.cfg 의 모든 preset 에서 package/unique_name(Android)·
#      application/bundle_identifier(iOS·macOS) 를 모은다 → 정확히 같은 것
#   ② 그 ID 로 시작하는 변종도 잡는다  (com.foo.bar.debug · com.foo.bar.test …)
#   ③ 그 ID 의 마지막 마디와 project.godot 의 config/name 을 검색어로 삼아,
#      ID 에 그 말이 들어가는 앱을 모두 잡는다  (com.other.laryen3d · com.old.laryen_2d …)
#      → 그래서 옛 빌드·다른 서명·이름만 바뀐 사본까지 한 번에 지운다
#   흔한 낱말(game·test·app·demo·godot…)은 검색어로 쓰지 않는다 — 남의 앱을 지우지 않기 위해서다.
#
# 🛑 지우면 되돌릴 수 없다. 앱 데이터(로그인 세션·세이브)가 함께 지워진다.
#    그래서 지우기 전에 목록을 보여주고 물어본다. --yes 를 주면 묻지 않는다.
#
# English usage:
#   bash uninstall.sh [number|device-id|macos]  Select a target device
#   --list        List devices           --apps      List removal candidates only
#   --dry-run     Print commands only    --yes       Remove without confirmation
#   --pick        Choose by number       --match     Add a search keyword
#   --package ID  Remove only this ID    --keep-data Android: keep app data
#   --purge-data  macOS/Windows: also delete the user:// data folder
#   --path <dir>  Godot project directory
#
set -euo pipefail

# ── 출력 ────────────────────────────────────────────────────────────────
step() { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✅\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m⚠️\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[1;31m❌\033[0m %s\n' "$*" >&2; exit 1; }

# ── 인자 파싱 ───────────────────────────────────────────────────────────
SELECTION=""
LIST_ONLY=0
APPS_ONLY=0
DRY_RUN=0
ASSUME_YES=0
PICK=0
KEEP_DATA=0
PURGE_DATA=0
PROJECT_ARG=""
EXTRA_MATCHES=()
FORCED_PACKAGES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --list)       LIST_ONLY=1 ;;
    --apps|--list-apps) APPS_ONLY=1 ;;
    --dry-run)    DRY_RUN=1 ;;
    -y|--yes)     ASSUME_YES=1 ;;
    --pick)       PICK=1 ;;
    --keep-data)  KEEP_DATA=1 ;;
    --purge-data) PURGE_DATA=1 ;;
    --match)
      [ $# -ge 2 ] && [ -n "$2" ] && [[ "$2" != -* ]] || die "--match 에 검색어가 필요하다 / --match requires a keyword."
      shift; EXTRA_MATCHES+=("$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')") ;;
    --package|--pkg)
      [ $# -ge 2 ] && [ -n "$2" ] && [[ "$2" != -* ]] || die "--package 에 패키지 ID 가 필요하다 / --package requires an application id."
      shift; FORCED_PACKAGES+=("$1") ;;
    --path)
      [ $# -ge 2 ] && [ -n "$2" ] && [[ "$2" != -* ]] || die "--path 에 프로젝트 경로가 필요하다 / --path requires a project directory."
      shift; PROJECT_ARG="$1" ;;
    -h|--help)    awk 'NR>1 { if (/^#/) { sub(/^# ?/, ""); print } else exit }' "$0"; exit 0 ;;
    -*)           die "알 수 없는 옵션: / Unknown option: $1" ;;
    *)            SELECTION="$1" ;;
  esac
  shift
done

is_windows() {
  case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) return 0 ;; esac
  return 1
}

# ── 장치 수집 ───────────────────────────────────────────────────────────
# 각 항목은  플랫폼<TAB>기기ID<TAB>표시이름  한 줄이다. install.sh 와 같은 목록·같은 번호다.

windows_entry() {
  is_windows || return 0
  printf 'windows\tlocal\t이 Windows PC / This Windows PC (%s)\n' "$(uname -m)"
}

macos_entry() {
  [ "$(uname -s)" = "Darwin" ] || return 0
  printf 'macos\tlocal\t이 맥 / This Mac (%s)\n' "$(uname -m)"
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
        if (i == ui + 2 && $i ~ /^\(/) continue
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
  printf '%s\n' "$DEVICES" | grep -q '^ios'     || echo "  (iOS 기기 없음 — USB 연결 후 '이 컴퓨터를 신뢰' 를 누른다 / No iOS device — connect via USB and select Trust This Computer)"
  printf '%s\n' "$DEVICES" | grep -q '^android' || echo "  (Android 기기 없음 — USB 디버깅을 켜고 연결한다 / No Android device — enable USB debugging and connect via USB)"
}

if [ "$LIST_ONLY" -eq 1 ]; then print_menu; exit 0; fi
[ -n "$DEVICES" ] || die "장치가 하나도 없다. 기기를 연결한다. / No device is available. Connect a device first."

# ── 선택 해석 ───────────────────────────────────────────────────────────
resolve_selection() {
  local sel="$1"
  if printf '%s' "$sel" | grep -Eq '^[0-9]+$'; then
    printf '%s\n' "$DEVICES" | awk -F'\t' -v n="$sel" 'NR == n { print; found = 1 } END { exit !found }'
    return
  fi
  case "$sel" in
    win|windows|Windows) printf '%s\n' "$DEVICES" | awk -F'\t' '$1 == "windows" { print; exit }'; return ;;
    macos|macOS|mac)     printf '%s\n' "$DEVICES" | awk -F'\t' '$1 == "macos" { print; exit }'; return ;;
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

APP_NAME=$(awk -F'=' '/^config\/name=/ { v = $2; gsub(/^"|"[ \t\r]*$/, "", v); print v; exit }' "$ROOT/project.godot")

# ── 무엇을 지울지 정한다 — 패키지 ID 와 검색어 ──────────────────────────
PRESETS="$ROOT/export_presets.cfg"

# export_presets.cfg 의 **모든** preset 에서 앱 ID 를 모은다 (플랫폼을 가리지 않는다).
collect_preset_ids() {
  [ -f "$PRESETS" ] || return 0
  awk '
    { sub(/\r$/, "") }
    /^(package\/unique_name|application\/bundle_identifier)=/ {
      eq = index($0, "=")
      v = substr($0, eq + 1)
      gsub(/^[ \t]+|[ \t\r]+$/, "", v)
      gsub(/^"|"$/, "", v)
      if (v != "" && !(v in seen)) { seen[v] = 1; print v }
    }
  ' "$PRESETS"
}

KNOWN_IDS=()
if [ "${#FORCED_PACKAGES[@]}" -gt 0 ]; then
  KNOWN_IDS=("${FORCED_PACKAGES[@]}")
else
  while IFS= read -r line; do [ -n "$line" ] && KNOWN_IDS+=("$line"); done <<< "$(collect_preset_ids)"
fi

# 검색어 — 앱 ID 의 마지막 마디와 프로젝트 이름에서 뽑는다.
# 흔한 낱말은 버린다. 남의 앱을 지우는 사고를 막기 위해서다.
COMMON_WORDS=" game games test tests app apps demo godot project main example sample new my mobile client server build dev debug release android ios macos windows "
KEYWORDS=()
add_keyword() {
  local w; w=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')
  [ ${#w} -ge 4 ] || return 0
  printf '%s' "$w" | grep -q '[a-z]' || return 0
  case "$COMMON_WORDS" in *" $w "*) return 0 ;; esac
  local k; for k in ${KEYWORDS[@]+"${KEYWORDS[@]}"}; do [ "$k" = "$w" ] && return 0; done
  KEYWORDS+=("$w")
}

if [ "${#FORCED_PACKAGES[@]}" -eq 0 ]; then
  for id in ${KNOWN_IDS[@]+"${KNOWN_IDS[@]}"}; do add_keyword "${id##*.}"; done
  if [ -n "$APP_NAME" ]; then
    for word in $APP_NAME; do add_keyword "$word"; done
    add_keyword "$(printf '%s' "$APP_NAME" | tr -d ' ')"
  fi
fi
for m in ${EXTRA_MATCHES[@]+"${EXTRA_MATCHES[@]}"}; do
  w=$(printf '%s' "$m" | tr -cd 'a-z0-9._-')
  [ -n "$w" ] && KEYWORDS+=("$w")
done

if [ "${#KNOWN_IDS[@]}" -eq 0 ] && [ "${#KEYWORDS[@]}" -eq 0 ]; then
  die "지울 앱을 알아낼 단서가 없다. export_presets.cfg 가 없으면 --package 나 --match 를 준다. / Nothing to match. Pass --package or --match when export_presets.cfg is unavailable."
fi

echo "   찾는 앱 ID: / Application ids: ${KNOWN_IDS[*]:-(없음 / none)}"
[ "${#KEYWORDS[@]}" -gt 0 ] && echo "   검색어: / Keywords: ${KEYWORDS[*]}"

# 이 ID 가 이 게임의 것인가
matches_app_id() {
  local id="$1" low k
  low=$(printf '%s' "$id" | tr '[:upper:]' '[:lower:]')
  for k in ${KNOWN_IDS[@]+"${KNOWN_IDS[@]}"}; do
    [ "$id" = "$k" ] && return 0
    case "$id" in "$k".*) return 0 ;; esac
  done
  [ "${#FORCED_PACKAGES[@]}" -gt 0 ] && return 1
  for k in ${KEYWORDS[@]+"${KEYWORDS[@]}"}; do
    case "$low" in *"$k"*) return 0 ;; esac
  done
  return 1
}

# ── 후보 수집 ───────────────────────────────────────────────────────────
# 한 줄에  앱ID<TAB>부가정보  로 담는다.
CANDIDATES=""

android_collect() {
  local users user pkgs pkg info out=""
  users=$(adb -s "$DEVICE_ID" shell pm list users </dev/null 2>/dev/null \
          | sed -n 's/.*UserInfo{\([0-9]*\):.*/\1/p' | tr -d '\r')
  [ -n "$users" ] || users="0"
  pkgs=$(for user in $users; do
           adb -s "$DEVICE_ID" shell pm list packages --user "$user" </dev/null 2>/dev/null \
             | sed 's/^package://' | tr -d '\r' | awk -v u="$user" 'NF { print $0 "\t" u }'
         done | sort -u)
  # 🛑 fd 3 으로 읽는다 — 루프 안의 adb 가 stdin 을 삼켜 목록이 중간에 끊기는 것을 막는다
  while IFS=$'\t' read -r pkg user <&3; do
    [ -n "$pkg" ] || continue
    matches_app_id "$pkg" || continue
    info=$(adb -s "$DEVICE_ID" shell dumpsys package "$pkg" </dev/null 2>/dev/null | tr -d '\r' \
           | awk -F'=' '/versionName=/ { print $2; exit }')
    out="$out$pkg\tuser $user${info:+ · v$info}\n"
  done 3<<< "$pkgs"
  printf '%b' "$out" | awk 'NF' | sort -u
}

ios_collect() {
  local raw
  raw=$(xcrun devicectl device info apps --device "$DEVICE_ID" </dev/null 2>/dev/null) \
    || die "기기의 앱 목록을 읽지 못했다. 잠금을 풀고 다시 시도한다. / Could not read the app list. Unlock the device and try again."
  printf '%s\n' "$raw" | awk '
    /^-{5,}/ { body = 1; next }
    !body { next }
    {
      id = ""; idx = 0
      for (i = 1; i <= NF; i++)
        if ($i ~ /^[A-Za-z0-9][A-Za-z0-9_.-]*\.[A-Za-z0-9_.-]+$/ && $i ~ /\./) { id = $i; idx = i; break }
      if (id == "") next
      name = ""
      for (i = 1; i < idx; i++) name = name (name == "" ? "" : " ") $i
      ver = (idx + 1 <= NF) ? $(idx + 1) : ""
      printf "%s\t%s%s\n", id, (name == "" ? "" : name), (ver == "" ? "" : " · v" ver)
    }' | while IFS=$'\t' read -r id info; do
      matches_app_id "$id" && printf '%s\t%s\n' "$id" "$info"
      true
    done
}

# macOS·Windows 는 "설치" 가 없다 — 만들어 둔 앱 번들·실행 파일과 user:// 데이터를 찾는다.
desktop_collect() {
  local dir app id out=""
  if [ "$PLATFORM" = "macos" ]; then
    for dir in "/Applications" "$HOME/Applications" "$ROOT/builds"; do
      [ -d "$dir" ] || continue
      while IFS= read -r app; do
        [ -n "$app" ] || continue
        id=$(defaults read "$app/Contents/Info" CFBundleIdentifier </dev/null 2>/dev/null || true)
        if [ -n "$id" ] && matches_app_id "$id"; then
          out="$out$app\t$id\n"
        elif [ -z "$id" ] && matches_app_id "$(basename "$app" .app)"; then
          out="$out$app\t(Info.plist 없음 / no bundle id)\n"
        fi
      done <<< "$(find "$dir" -maxdepth 3 -name '*.app' -prune -print 2>/dev/null)"
    done
  else
    while IFS= read -r app; do
      [ -n "$app" ] || continue
      matches_app_id "$(basename "$app" .exe)" && out="$out$app\t실행 파일 / executable\n"
    done <<< "$(find "$ROOT/builds" -maxdepth 3 -name '*.exe' -print 2>/dev/null)"
  fi
  if [ "$PURGE_DATA" -eq 1 ] && [ -n "$APP_NAME" ]; then
    for dir in "$HOME/Library/Application Support/Godot/app_userdata/$APP_NAME" \
               "$HOME/Library/Application Support/$APP_NAME" \
               "$HOME/Library/Caches/Godot/app_userdata/$APP_NAME" \
               "${APPDATA:-}/Godot/app_userdata/$APP_NAME"; do
      [ -n "$dir" ] && [ -d "$dir" ] && out="$out$dir\t저장 데이터 / user:// data\n"
    done
  fi
  printf '%b' "$out" | awk 'NF' | sort -u
}

step "설치된 앱을 찾는 중 — / Searching installed apps — $DEVICE_LABEL"
case "$PLATFORM" in
  android) CANDIDATES=$(android_collect) ;;
  ios)     CANDIDATES=$(ios_collect) ;;
  macos|windows) CANDIDATES=$(desktop_collect) ;;
esac

if [ -z "$CANDIDATES" ]; then
  ok "지울 것이 없다 — 이 기기에 이 게임의 앱이 없다. / Nothing to remove: this device has none of this project's apps."
  exit 0
fi

COUNT=$(printf '%s\n' "$CANDIDATES" | wc -l | tr -d ' ')
echo
echo "지울 대상 $COUNT 개: / $COUNT item(s) to remove:"
echo
printf '%s\n' "$CANDIDATES" | awk -F'\t' '{ printf "  \033[1;36m%d)\033[0m  %-42s \033[90m%s\033[0m\n", NR, $1, $2 }'
echo

if [ "$APPS_ONLY" -eq 1 ]; then
  echo "(--apps — 아무것도 지우지 않았다. / Nothing was removed.)"
  exit 0
fi

# ── 고르기 · 확인 ───────────────────────────────────────────────────────
TARGETS="$CANDIDATES"
if [ "$PICK" -eq 1 ]; then
  [ -t 0 ] || die "--pick 은 대화형에서만 쓴다. / --pick requires an interactive terminal."
  printf '번호 (빈 칸으로 여러 개, all=전부) [all]: / Numbers (space separated, all) [all]: '
  read -r PICKED || PICKED=""
  case "${PICKED:-all}" in
    all|ALL|a) ;;
    *)
      TARGETS=$(printf '%s\n' "$CANDIDATES" | awk -v sel="$PICKED" '
        BEGIN { n = split(sel, a, /[ ,]+/); for (i = 1; i <= n; i++) if (a[i] != "") want[a[i]+0] = 1 }
        (NR in want) { print }')
      [ -n "$TARGETS" ] || die "고른 것이 없다. / Nothing selected."
      echo
      echo "고른 것: / Selected:"
      printf '%s\n' "$TARGETS" | awk -F'\t' '{ printf "  • %s\n", $1 }'
      echo
      ;;
  esac
fi

TARGET_COUNT=$(printf '%s\n' "$TARGETS" | wc -l | tr -d ' ')

if [ "$DRY_RUN" -eq 0 ] && [ "$ASSUME_YES" -eq 0 ]; then
  case "$PLATFORM" in
    android) [ "$KEEP_DATA" -eq 1 ] \
      && warn "앱만 지우고 데이터는 남긴다 (--keep-data). / Removing apps but keeping their data." \
      || warn "앱 데이터(로그인 세션·세이브)까지 함께 지워진다. 되돌릴 수 없다. / App data, including login sessions and saves, will be deleted. This cannot be undone." ;;
    ios)     warn "앱 데이터(로그인 세션·세이브)까지 함께 지워진다. 되돌릴 수 없다. / App data will be deleted. This cannot be undone." ;;
    *)       warn "파일을 지운다. 되돌릴 수 없다. / Files will be deleted. This cannot be undone." ;;
  esac
  if [ ! -t 0 ]; then
    die "비대화형이다. 확인할 수 없으니 지우지 않았다. 정말 지우려면 --yes 를 준다. / Noninteractive: nothing was removed. Pass --yes to remove without confirmation."
  fi
  printf '%s개를 지운다. 계속할까? [y/N]: / Remove %s item(s)? [y/N]: ' "$TARGET_COUNT" "$TARGET_COUNT"
  read -r CONFIRM || CONFIRM="n"
  case "$CONFIRM" in
    y|Y|yes|YES) ;;
    *) die "취소했다. 아무것도 지우지 않았다. / Cancelled; nothing was removed." ;;
  esac
  echo
fi

# ── 삭제 ────────────────────────────────────────────────────────────────
run() {
  if [ "$DRY_RUN" -eq 1 ]; then printf '   \033[90m$ %s\033[0m\n' "$*"; return 0; fi
  "$@" </dev/null
}

REMOVED=0
FAILED=()

android_remove() {
  local pkg="$1" out rc=0
  local -a args
  args=(-s "$DEVICE_ID" uninstall)
  [ "$KEEP_DATA" -eq 1 ] && args+=(-k)
  args+=("$pkg")
  if [ "$DRY_RUN" -eq 1 ]; then run adb "${args[@]}"; return 0; fi
  out=$(adb "${args[@]}" </dev/null 2>&1) || rc=1
  if printf '%s' "$out" | grep -q 'Success'; then return 0; fi
  # 사용자 프로필에만 남은 것·기기 사전탑재본은 --user 로 다시 시도한다
  local users user done=1
  users=$(adb -s "$DEVICE_ID" shell pm list users </dev/null 2>/dev/null \
          | sed -n 's/.*UserInfo{\([0-9]*\):.*/\1/p' | tr -d '\r')
  for user in ${users:-0}; do
    adb -s "$DEVICE_ID" shell pm uninstall $([ "$KEEP_DATA" -eq 1 ] && echo -k) --user "$user" "$pkg" </dev/null 2>&1 \
      | tr -d '\r' | grep -q 'Success' && done=0
  done
  [ "$done" -eq 0 ] && return 0
  printf '%s' "$out" | tail -1 >&2
  return 1
}

while IFS=$'\t' read -r ITEM INFO <&3; do
  [ -n "$ITEM" ] || continue
  step "지우는 중 — / Removing — $ITEM"
  case "$PLATFORM" in
    android)
      if android_remove "$ITEM"; then REMOVED=$((REMOVED + 1)); ok "$ITEM"; else FAILED+=("$ITEM"); warn "실패 / Failed: $ITEM"; fi
      ;;
    ios)
      if run xcrun devicectl device uninstall app --device "$DEVICE_ID" "$ITEM" >/dev/null 2>&1; then
        REMOVED=$((REMOVED + 1)); ok "$ITEM"
      else
        FAILED+=("$ITEM"); warn "실패 — 기기 잠금을 풀고 다시 시도한다 / Failed; unlock the device and retry: $ITEM"
      fi
      ;;
    macos|windows)
      if run rm -rf "$ITEM"; then REMOVED=$((REMOVED + 1)); ok "$ITEM"; else FAILED+=("$ITEM"); warn "실패 / Failed: $ITEM"; fi
      ;;
  esac
done 3<<< "$TARGETS"

echo
if [ "$DRY_RUN" -eq 1 ]; then
  ok "--dry-run — 위 명령을 실행하지 않았다. / Nothing was executed."
  exit 0
fi

# ── 확인 — 정말 없어졌는지 다시 본다 ────────────────────────────────────
LEFT=""
case "$PLATFORM" in
  android) LEFT=$(android_collect) ;;
  ios)     LEFT=$(ios_collect) ;;
  macos|windows) LEFT=$(desktop_collect) ;;
esac

if [ "${#FAILED[@]}" -gt 0 ]; then
  warn "$REMOVED 개를 지웠고 ${#FAILED[@]} 개가 남았다: / Removed $REMOVED, failed ${#FAILED[@]}: ${FAILED[*]}"
  exit 1
fi

# 지우려던 것 중에 아직 남은 것 — --pick 으로 일부러 남긴 것은 실패가 아니다
STILL=""
if [ -n "$LEFT" ]; then
  STILL=$(awk -F'\t' 'NR == FNR { want[$1] = 1; next } ($1 in want) { print }' \
          <(printf '%s\n' "$TARGETS") <(printf '%s\n' "$LEFT"))
fi

if [ -n "$STILL" ]; then
  warn "$REMOVED 개를 지웠는데 아직 남은 것이 있다: / Removed $REMOVED, but these remain:"
  printf '%s\n' "$STILL" | awk -F'\t' '{ printf "  • %s  \033[90m%s\033[0m\n", $1, $2 }'
  exit 1
fi

if [ -n "$LEFT" ]; then
  ok "$REMOVED 개를 지웠다. 고르지 않은 것은 그대로 두었다: / Removed $REMOVED item(s); the ones you did not select were kept:"
  printf '%s\n' "$LEFT" | awk -F'\t' '{ printf "  • %s  \033[90m%s\033[0m\n", $1, $2 }'
  exit 0
fi

ok "$REMOVED 개를 지웠다. 이 기기에 이 게임의 앱이 남아 있지 않다. / Removed $REMOVED item(s); none of this project's apps remain on the device."
