#!/usr/bin/env bash
#
# install_godotty.sh — Godot 프로젝트에 Godotty 터미널 애드온(완성된 릴리스 ZIP)을 설치한다.
#
#   bash .claude/skills/godot/scripts/install_godotty.sh                  현재 폴더의 프로젝트에 v0.9.7
#   bash .claude/skills/godot/scripts/install_godotty.sh --project ~/game 대상 프로젝트 지정
#   bash .claude/skills/godot/scripts/install_godotty.sh --dry-run        무엇을 할지만 보여 준다
#
#   옵션:  --project <경로>   project.godot 가 있는 폴더 (기본: 현재 폴더에서 위로 → 아래로 탐색)
#          --version <태그>   릴리스 태그 (기본 v0.9.7)
#          --zip <파일>       이미 받은 설치 ZIP 을 쓴다 (다운로드 생략 · 해시는 그대로 대조)
#          --godot <실행파일> Godot 에디터 실행 파일 (기본: $GODOT → PATH 의 godot → /Applications/Godot.app)
#          --skip-verify      설치 뒤 헤드리스 확장 로드 검사를 건너뛴다
#          --dry-run          파일을 바꾸지 않는다
#
# 🛑 하지 않는 것 — Godot 에디터 다운로드·재설치 · Rust/Zig/Git 설치·소스 빌드 · Source code ZIP 설치 ·
#    plugin.cfg 생성 · project.godot 수정 · 실행 중인 에디터 종료 · git 커밋
# 🛑 설치 직후 `godot --headless --import` 를 돌리지 않는다 — 확장이 처음 등록되는 그 실행이
#    SIGSEGV(종료 코드 134)로 죽는다(4.7.2 + v0.9.7 실측 4/4). 검사는 `--editor --quit-after` 로 한다.
#
# 종료 코드: 0 성공 · 1 사용법 · 2 대상 프로젝트 불명확 · 3 대상 에디터 실행 중 · 4 Godot 없음/4.7 미만
#            5 다운로드·ZIP 검사 실패 · 6 설치 후 검사 실패
#
# 자세한 설명 → .claude/skills/godot/references/godotty.md
set -euo pipefail

step() { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
ok()   { printf '  \033[1;32m✅\033[0m %s\n' "$*"; }
warn() { printf '  \033[1;33m⚠️\033[0m  %s\n' "$*"; }
die()  { local code="$1"; shift; printf '\033[1;31m❌\033[0m %s\n' "$*" >&2; exit "$code"; }

VERSION="v0.9.7"
PROJECT_ARG=""
ZIP_ARG=""
GODOT_BIN="${GODOT:-}"
SKIP_VERIFY=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --project)     PROJECT_ARG="${2:?--project 뒤에 경로}"; shift ;;
    --version)     VERSION="${2:?--version 뒤에 태그}"; shift ;;
    --zip)         ZIP_ARG="${2:?--zip 뒤에 파일}"; shift ;;
    --godot)       GODOT_BIN="${2:?--godot 뒤에 실행 파일}"; shift ;;
    --skip-verify) SKIP_VERIFY=1 ;;
    --dry-run)     DRY_RUN=1 ;;
    -h|--help)     sed -n '2,28p' "$0"; exit 0 ;;
    *)             die 1 "모르는 인자: $1 (--help)" ;;
  esac
  shift
done

REPO="thruthesky/godotty"
ZIP_NAME="godotty-${VERSION}.zip"
ZIP_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ZIP_NAME}"

# ── 1. 대상 프로젝트 루트 ─────────────────────────────────────────────
step "대상 프로젝트 확인"
find_up() {
  local d="$1"
  while [ "$d" != "/" ]; do
    [ -f "$d/project.godot" ] && { echo "$d"; return 0; }
    d=$(dirname "$d")
  done
  return 1
}
if [ -n "$PROJECT_ARG" ]; then
  [ -d "$PROJECT_ARG" ] || die 2 "폴더가 없다: $PROJECT_ARG"
  ROOT=$(cd "$PROJECT_ARG" && pwd -P)
  [ -f "$ROOT/project.godot" ] || die 2 "project.godot 이 없다: ${ROOT} — Godot 프로젝트 루트를 지정한다"
elif ROOT=$(find_up "$(pwd -P)"); then
  :
else
  # 위에 없으면 아래(3단계)를 찾는다. 하나일 때만 고르고, 0개·여러 개면 사람에게 묻는다.
  CANDIDATES=$(find "$(pwd -P)" -maxdepth 3 \( -name .godot -o -name addons -o -name node_modules -o -name .git \) -prune -o -name project.godot -print 2>/dev/null | sed 's#/project.godot$##')
  COUNT=$(printf '%s' "$CANDIDATES" | grep -c . || true)
  if [ "$COUNT" = "1" ]; then
    ROOT="$CANDIDATES"
  elif [ "$COUNT" = "0" ]; then
    die 2 "현재 폴더 위·아래에서 project.godot 을 찾지 못했다 — --project <경로> 로 대상을 알려 달라"
  else
    printf '%s\n' "$CANDIDATES" | sed 's/^/     /' >&2
    die 2 "Godot 프로젝트가 ${COUNT}개다 — 어느 것에 설치할지 --project <경로> 로 지정한다"
  fi
fi
[ ! -e "$ROOT/addons/godotty/plugin.cfg" ] || warn "기존 addons/godotty 에 plugin.cfg 가 있다 — 교체하면 사라진다(Godotty 는 plugin.cfg 를 쓰지 않는다)"
ok "프로젝트 루트: $ROOT"

# ── 2. Godot 에디터 버전 ≥ 4.7 ────────────────────────────────────────
step "설치된 Godot 버전 확인 (다운로드·재설치는 하지 않는다)"
if [ -z "$GODOT_BIN" ]; then
  if command -v godot >/dev/null 2>&1; then GODOT_BIN=$(command -v godot)
  elif [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
  fi
fi
[ -n "$GODOT_BIN" ] && [ -x "$(command -v "$GODOT_BIN" 2>/dev/null || echo "$GODOT_BIN")" ] \
  || die 4 "Godot 실행 파일을 찾지 못했다 — --godot <경로> 로 알려 달라(에디터를 새로 받지 않는다)"
GODOT_VER=$("$GODOT_BIN" --version 2>/dev/null | head -1 || true)
MAJOR=$(printf '%s' "$GODOT_VER" | cut -d. -f1)
MINOR=$(printf '%s' "$GODOT_VER" | cut -d. -f2)
case "$MAJOR$MINOR" in *[!0-9]*|"") die 4 "Godot 버전을 읽지 못했다: '${GODOT_VER}' (${GODOT_BIN})" ;; esac
if [ "$MAJOR" -lt 4 ] || { [ "$MAJOR" -eq 4 ] && [ "$MINOR" -lt 7 ]; }; then
  die 4 "Godot ${GODOT_VER} — Godotty ${VERSION} 는 4.7 이상이 필요하다(godotty.gdextension compatibility_minimum = 4.7). 에디터는 사람이 올린다"
fi
ok "Godot ${GODOT_VER} (${GODOT_BIN})"

# ── 현재 OS 용 바이너리 이름 ──────────────────────────────────────────
case "$(uname -s)" in
  Darwin)               OS_LIB="libgodotty.macos.dylib" ;;
  Linux)                OS_LIB="libgodotty.linux.x86_64.so" ;;
  MINGW*|MSYS*|CYGWIN*) OS_LIB="libgodotty.windows.x86_64.dll" ;;
  *) die 4 "지원하지 않는 OS: $(uname -s) — macOS·Windows x86_64·Linux x86_64 만 있다" ;;
esac

# ── 3. 대상 프로젝트의 에디터가 떠 있으면 멈춘다 (종료시키지 않는다) ──────
step "대상 프로젝트의 에디터가 실행 중인지 확인"
RUNNING=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  pid=${line%% *}; cmd=${line#* }
  case "$cmd" in *--headless*) continue ;; esac     # 다른 세션의 헤드리스 검사는 에디터가 아니다
  p=$(printf '%s' "$cmd" | sed -n 's/.*--path[ =]\([^ ]*\).*/\1/p')
  if [ -n "$p" ] && [ -d "$p" ] && [ "$(cd "$p" && pwd -P)" = "$ROOT" ]; then RUNNING="$RUNNING $pid"; continue; fi
  if [ -z "$p" ] && command -v lsof >/dev/null 2>&1; then
    cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | tail -1)
    [ "$cwd" = "$ROOT" ] && RUNNING="$RUNNING $pid"
  fi
done <<EOF
$(ps -axo pid=,command= 2>/dev/null | grep -i '[g]odot' | grep -v install_godotty | sed 's/^ *//')
EOF
if [ -f "$ROOT/addons/godotty/bin/$OS_LIB" ] && command -v lsof >/dev/null 2>&1; then
  holders=$(lsof -t "$ROOT/addons/godotty/bin/$OS_LIB" 2>/dev/null | tr '\n' ' ' || true)
  [ -n "$holders" ] && RUNNING="$RUNNING $holders"
fi
if [ -n "${RUNNING// /}" ]; then
  die 3 "이 프로젝트를 연 Godot 이 실행 중이다(PID:${RUNNING}) — 작업을 저장하고 그 에디터를 닫은 뒤 다시 실행한다. 로드 중인 라이브러리를 덮어쓰지 않으며, 에디터를 대신 종료하지 않는다"
fi
ok "대상 프로젝트를 연 에디터 없음 (다른 프로젝트의 에디터는 건드리지 않는다)"

if [ "$DRY_RUN" = "1" ]; then
  step "--dry-run — 여기서 멈춘다. 실제로는 아래를 한다"
  echo "     ZIP     : ${ZIP_ARG:-$ZIP_URL}"
  echo "     설치    : ${ROOT}/addons/godotty"
  [ -e "$ROOT/addons/godotty" ] && echo "     백업    : ${ROOT}/addons/godotty → \$HOME/.godotty-backups/ (프로젝트 바깥)"
  echo "     검사    : ${ROOT}/addons/godotty/bin/${OS_LIB} · 헤드리스 확장 로드"
  exit 0
fi

# ── 4. 프로젝트 바깥 임시 폴더로 받고 푼다 ─────────────────────────────
step "설치 ZIP 받기 (프로젝트 바깥 임시 폴더)"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/godotty-install.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
case "$WORK/" in "$ROOT"/*) die 5 "임시 폴더가 프로젝트 안이다: $WORK" ;; esac
ZIP="$WORK/$ZIP_NAME"
if [ -n "$ZIP_ARG" ]; then
  [ -f "$ZIP_ARG" ] || die 5 "ZIP 이 없다: $ZIP_ARG"
  cp "$ZIP_ARG" "$ZIP"
else
  curl -fL --retry 3 --progress-bar -o "$ZIP" "$ZIP_URL" || die 5 "다운로드 실패: $ZIP_URL"
fi
ok "$(du -h "$ZIP" | cut -f1) ${ZIP_NAME}"

# 릴리스 자산의 sha256 (GitHub API digest) 와 대조한다. API 를 못 읽으면 경고만 한다.
WANT=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/tags/${VERSION}" 2>/dev/null \
  | python3 -c "import json,sys
d=json.load(sys.stdin)
print(next((a.get('digest') or '' for a in d.get('assets',[]) if a.get('name')=='${ZIP_NAME}'),'').replace('sha256:',''))" 2>/dev/null || true)
if command -v shasum >/dev/null 2>&1; then GOT=$(shasum -a 256 "$ZIP" | cut -d' ' -f1); else GOT=$(sha256sum "$ZIP" | cut -d' ' -f1); fi
if [ -n "$WANT" ]; then
  [ "$GOT" = "$WANT" ] || die 5 "sha256 불일치 — 받은 ${GOT} · 릴리스 ${WANT}"
  ok "sha256 일치 ${GOT}"
else
  warn "릴리스 digest 를 읽지 못해 해시 대조를 건너뛴다 (받은 파일 sha256 ${GOT})"
fi

unzip -q "$ZIP" -d "$WORK/unz" || die 5 "압축 해제 실패 — 설치 ZIP 이 맞는지 확인한다"
GDEXT=$(find "$WORK/unz" -path '*/addons/godotty/godotty.gdextension' | head -1)
[ -n "$GDEXT" ] || die 5 "ZIP 안에 addons/godotty/godotty.gdextension 이 없다 — Source code ZIP 을 받은 것 아닌가? 설치 ZIP(${ZIP_NAME})만 쓴다"
SRC=$(dirname "$GDEXT")
[ -s "$SRC/bin/$OS_LIB" ] || die 5 "ZIP 안에 현재 OS 용 바이너리가 없다: bin/${OS_LIB}"
ok "ZIP 구성 확인: $(cd "$SRC" && find . -type f | sed 's#^\./##' | sort | tr '\n' ' ')"

# ── 5. 기존 Godotty 는 프로젝트 바깥에 백업하고 교체 ──────────────────────
PG_BEFORE=$(cksum < "$ROOT/project.godot")
BACKUP=""
if [ -e "$ROOT/addons/godotty" ]; then
  step "기존 addons/godotty 백업 (프로젝트 바깥)"
  BACKUP="$HOME/.godotty-backups/$(basename "$ROOT")-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP"
  mv "$ROOT/addons/godotty" "$BACKUP/godotty"
  ok "백업: $BACKUP/godotty"
fi

step "addons/godotty 복사"
mkdir -p "$ROOT/addons"
cp -R "$SRC" "$ROOT/addons/godotty"
if [ "$(uname -s)" = "Darwin" ] && xattr -r -l "$ROOT/addons/godotty" 2>/dev/null | grep -q com.apple.quarantine; then
  xattr -dr com.apple.quarantine "$ROOT/addons/godotty"
  ok "macOS 격리 속성(com.apple.quarantine) 제거 — addons/godotty 안만"
fi

# ── 6. 파일 검사 ───────────────────────────────────────────────────────
step "설치 결과 검사"
FAIL=0
chk() { if eval "$2"; then ok "$1"; else printf '  \033[1;31m❌\033[0m %s\n' "$1"; FAIL=1; fi; }
chk "addons/godotty/godotty.gdextension 있음"           '[ -f "$ROOT/addons/godotty/godotty.gdextension" ]'
chk "addons/godotty/bin/${OS_LIB} 있음 ($(du -h "$ROOT/addons/godotty/bin/$OS_LIB" 2>/dev/null | cut -f1))" '[ -s "$ROOT/addons/godotty/bin/$OS_LIB" ]'
chk "ZIP 원본과 파일 내용 동일"                        'diff -rq "$SRC" "$ROOT/addons/godotty" >/dev/null'
chk "중첩 설치 없음 (addons/addons/godotty · addons/godotty/addons)" '[ ! -e "$ROOT/addons/addons/godotty" ] && [ ! -e "$ROOT/addons/godotty/addons" ]'
chk "plugin.cfg 없음"                                   '[ ! -e "$ROOT/addons/godotty/plugin.cfg" ]'
chk "project.godot 변경 없음"                           '[ "$(cksum < "$ROOT/project.godot")" = "$PG_BEFORE" ]'
[ "$FAIL" = "0" ] || die 6 "파일 검사 실패 — 위 ❌ 항목"

# ── 7. 헤드리스로 확장이 실제로 로드되는지 ─────────────────────────────
VERIFY="건너뜀(--skip-verify)"
if [ "$SKIP_VERIFY" = "0" ]; then
  step "헤드리스 확장 로드 검사 (창을 띄우지 않는다)"
  # 🛑 --import 금지 — 확장이 처음 등록되는 실행이 SIGSEGV 로 죽는다. --editor --quit-after 는 안전하다.
  # 첫 스캔이 .godot/extension_list.cfg 에 확장을 올린다. 큰 프로젝트는 이 스캔(임포트)이 몇 분 걸린다.
  "$GODOT_BIN" --headless --editor --path "$ROOT" --quit-after 300 > "$WORK/editor.log" 2>&1 || true
  if grep -q handle_crash "$WORK/editor.log"; then
    warn "헤드리스 에디터가 크래시했다 — 한 번 더 돌린다"
    "$GODOT_BIN" --headless --editor --path "$ROOT" --quit-after 300 > "$WORK/editor.log" 2>&1 || true
  fi
  grep -q 'res://addons/godotty/godotty.gdextension' "$ROOT/.godot/extension_list.cfg" 2>/dev/null \
    && ok ".godot/extension_list.cfg 에 등록됨" \
    || { FAIL=1; printf '  \033[1;31m❌\033[0m extension_list.cfg 에 godotty 없음\n'; }
  cat > "$WORK/check_godotty.gd" <<'GD'
extends SceneTree
func _initialize() -> void:
	var names := []
	for c in ["Terminal", "TerminalPanel", "TerminalTabs"]:
		if ClassDB.class_exists(c):
			names.append(c)
	print("GODOTTY_CLASSES=", ",".join(names))
	print("GODOTTY_LOADED=", "res://addons/godotty/godotty.gdextension" in GDExtensionManager.get_loaded_extensions())
	quit()
GD
  OUT=$("$GODOT_BIN" --headless --path "$ROOT" -s "$WORK/check_godotty.gd" 2>&1 || true)
  CLASSES=$(printf '%s\n' "$OUT" | sed -n 's/^GODOTTY_CLASSES=//p' | tail -1)
  LOADED=$(printf '%s\n' "$OUT" | sed -n 's/^GODOTTY_LOADED=//p' | tail -1)
  if [ "$LOADED" = "true" ] && [ "$CLASSES" = "Terminal,TerminalPanel,TerminalTabs" ]; then
    ok "확장 로드됨 · 클래스 ${CLASSES}"
    VERIFY="통과 — 확장 로드 · 클래스 ${CLASSES}"
  else
    FAIL=1
    printf '  \033[1;31m❌\033[0m 확장 로드 실패 (loaded=%s classes=%s)\n' "$LOADED" "$CLASSES"
    printf '%s\n' "$OUT" | grep -E 'ERROR|godotty' | head -10 | sed 's/^/     /'
  fi
  [ "$(cksum < "$ROOT/project.godot")" = "$PG_BEFORE" ] || warn "헤드리스 에디터 실행 뒤 project.godot 이 바뀌었다 — git diff 로 확인한다"
  [ "$FAIL" = "0" ] || die 6 "헤드리스 검사 실패 — 위 ❌ 항목"
fi

# ── 8. 보고 ───────────────────────────────────────────────────────────
step "완료"
cat <<EOF
     프로젝트   : ${ROOT}
     설치 위치  : ${ROOT}/addons/godotty
     바이너리   : ${ROOT}/addons/godotty/bin/${OS_LIB}
     버전·해시  : ${VERSION} · sha256 ${GOT}
     백업       : ${BACKUP:-없음 (새 설치)}
     파일 검사  : 통과
     헤드리스   : ${VERIFY}
     남은 확인  : 에디터로 프로젝트를 다시 열고 → 하단 Terminal 버튼 → + 로 터미널 2개가 동시에 보이는지 (사람 · UI)
EOF
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "     git        : addons/godotty 는 $(du -sh "$ROOT/addons/godotty" | cut -f1) — 커밋하지 않았다. 커밋·.gitignore·LFS 는 사람이 정한다"
fi
