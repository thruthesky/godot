#!/usr/bin/env bash
#
# xvfb_run.sh — 사람 화면에 창을 띄우지 않고 Godot 을 "그리면서" 실행한다. 스크린샷·녹화·픽셀 판정용.
#
#   리눅스 컨테이너(Docker) 안의 가상 디스플레이(Xvfb)에 창을 만들고 Mesa 소프트웨어 렌더러로 그린다.
#   macOS 창·Dock 아이콘·전면 앱 전환이 하나도 생기지 않는다(WindowServer 로 실측).
#   `--headless` 는 그리지 않는다 — 스크린샷은 null, `--write-movie` 는 비정상 종료. 그림이 필요할 때 이것을 쓴다.
#
#   xvfb_run.sh -s res://tests/login_screen_shot.gd        스크립트 실행 — 컨테이너에 SHOT_DIR=/out 이 잡혀 있다
#   xvfb_run.sh res://scenes/login/login.tscn --quit-after 120
#   xvfb_run.sh --movie login.avi --frames 300 --fps 30    main_scene 을 녹화 (MJPEG .avi · .png 면 프레임 시퀀스)
#   xvfb_run.sh --size 1280x720 -s res://tests/x.gd        창 크기 (기본 720x1600 — 세로 폰)
#   xvfb_run.sh --mobile -s res://tests/x.gd               Mobile 렌더러(Vulkan · lavapipe). 기본은 gl_compatibility
#
#   옵션은 godot 인자보다 앞에 쓴다 — 처음 보는 인자부터 끝까지는 전부 godot 으로 넘어간다.
#     --path <dir>       프로젝트 (기본: 현재 폴더에서 위로 project.godot 탐색)
#     --out <dir>        산출물 폴더. 컨테이너 안에서는 /out 이다 (기본: <캐시>/<프로젝트>/out)
#     --size WxH         창·가상 화면 크기 (기본 720x1600)
#     --movie <파일명>   /out/<파일명> 으로 녹화 — --frames(기본 300) · --fps(기본 30)
#     --mobile           --rendering-method mobile --rendering-driver vulkan
#     --import           동기화 뒤 무조건 임포트 (기본: 새 에셋·크기가 바뀐 에셋·새 .gd 가 있을 때만 — 판정 이유를 찍는다)
#     -e NAME=VALUE      컨테이너 환경변수 (여러 번 쓸 수 있다)
#     --timeout <초>     godot 실행 제한 (기본 600 · 넘으면 종료 코드 124)
#     --build            이미지를 다시 만든다
#
#   환경변수  GODOT_XVFB_CACHE    사본·산출물 위치 (기본 macOS ~/Library/Caches/godot-xvfb · 리눅스 ~/.cache/godot-xvfb)
#            GODOT_XVFB_VERSION  이미지의 Godot 버전 (예: 4.7.2-stable · 기본은 호스트 `godot --version`)
#
# 🛑 원본 프로젝트를 컨테이너에 마운트하지 않는다 — 리눅스 Godot 이 `.godot/` 임포트 캐시를 고쳐 쓴다.
#    <캐시>/<이름>-<cksum>/proj 로 rsync 한 사본을 쓴다. 첫 사본은 오래 걸리고(라리엔 3D 14GB · 53초)
#    그다음부터는 증분이다(변경 없음 1초). 사본에서 뺄 경로는 프로젝트 루트 `.xvfbignore` 에 rsync 패턴으로 적는다.
# 🛑 godot 인자에 호스트 경로를 쓰지 않는다 — 컨테이너 안에는 /work/proj(= res://) 와 /out 뿐이다.
# 🛑 컨테이너마다 user:// 가 비어 있다 — 로그인 세션·설정이 남지 않는다(검사 재현성에는 오히려 좋다).
# 🛑 `ERROR: No GDExtension library found … (linux.arm64)` 는 리눅스용 바이너리가 없는 확장이다.
#    그 확장 없이도 되는 화면만 여기서 찍는다. ERROR 줄 수로 판정하는 검사는 이 줄을 걸러야 한다.
# 🛑 소프트웨어 렌더링이다 — fps·프레임 시간 측정에 쓰지 않는다. 성능은 실기기에서 잰다.
#
# 자세한 설명 → .claude/skills/godot/references/headless-workflow.md §7
set -euo pipefail

step() { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m❌\033[0m %s\n' "$*" >&2; exit 2; }

# 심볼릭 링크로 불려도 원본이 있는 폴더를 찾는다 (Dockerfile 이 원본 옆 xvfb/ 에 있다)
resolve_self_dir() {
  local src="${BASH_SOURCE[0]}" dir
  while [ -L "$src" ]; do
    dir=$(cd -P "$(dirname "$src")" && pwd)
    src=$(readlink "$src")
    case "$src" in /*) ;; *) src="$dir/$src" ;; esac
  done
  (cd -P "$(dirname "$src")" && pwd)
}
SELF_DIR=$(resolve_self_dir)

# ── 인자 ────────────────────────────────────────────────────────────────
PROJECT_ARG=""; OUT_ARG=""; SIZE="720x1600"; MOVIE=""; FRAMES=300; FPS=30
MOBILE=0; FORCE_IMPORT=0; TIMEOUT=600; BUILD=0
ENVS=()
need() { [ "$1" -ge 2 ] || die "$2 뒤에 값이 필요하다"; }
while [ $# -gt 0 ]; do
  case "$1" in
    --path)    need $# "$1"; PROJECT_ARG="$2"; shift 2 ;;
    --out)     need $# "$1"; OUT_ARG="$2"; shift 2 ;;
    --size)    need $# "$1"; SIZE="$2"; shift 2 ;;
    --movie)   need $# "$1"; MOVIE="$2"; shift 2 ;;
    --frames)  need $# "$1"; FRAMES="$2"; shift 2 ;;
    --fps)     need $# "$1"; FPS="$2"; shift 2 ;;
    --timeout) need $# "$1"; TIMEOUT="$2"; shift 2 ;;
    -e)        need $# "$1"; ENVS+=(-e "$2"); shift 2 ;;
    --mobile)  MOBILE=1; shift ;;
    --import)  FORCE_IMPORT=1; shift ;;
    --build)   BUILD=1; shift ;;
    -h|--help) sed -n '3,/^set -euo/p' "${BASH_SOURCE[0]}" | sed -e '/^set -euo/d' -e 's/^# \{0,1\}//'; exit 0 ;;
    *) break ;;
  esac
done
GODOT_ARGS=("$@")

[[ "$SIZE" =~ ^[0-9]+x[0-9]+$ ]] || die "--size 는 720x1600 모양이어야 한다: $SIZE"
W=${SIZE%x*}; H=${SIZE#*x}
case "$MOVIE" in */*) die "--movie 에는 파일 이름만 쓴다(/out 아래에 저장된다): $MOVIE" ;; esac

# ── 프로젝트 ────────────────────────────────────────────────────────────
find_project() {
  local dir
  dir=$(cd -P "${1:-$PWD}" 2>/dev/null && pwd) || die "폴더가 없다: $1"
  while [ "$dir" != "/" ]; do
    [ -f "$dir/project.godot" ] && { printf '%s' "$dir"; return 0; }
    dir=$(dirname "$dir")
  done
  die "project.godot 을 찾지 못했다 — 프로젝트 안에서 실행하거나 --path 로 지정한다"
}
PROJECT=$(find_project "$PROJECT_ARG")

# ── Docker · 이미지 ─────────────────────────────────────────────────────
command -v docker >/dev/null || die "docker 가 없다 — Docker Desktop 을 설치한다"
command -v rsync  >/dev/null || die "rsync 가 없다"
ARCH=$(docker info --format '{{.Architecture}}' 2>/dev/null) || die "Docker 가 꺼져 있다 — Docker Desktop 을 켠다"
case "$ARCH" in
  aarch64|arm64) GARCH=arm64 ;;
  x86_64|amd64)  GARCH=x86_64 ;;
  *) die "지원하지 않는 아키텍처: $ARCH" ;;
esac

if [ -n "${GODOT_XVFB_VERSION:-}" ]; then
  VER="$GODOT_XVFB_VERSION"
else
  GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"
  [ -n "$GODOT_BIN" ] || die "호스트 godot 이 없다 — GODOT_XVFB_VERSION=4.7.2-stable 처럼 지정한다"
  # 4.7.2.stable.official.ed1daf0bf → 4.7.2-stable · 4.7.stable.official → 4.7-stable
  VER=$("$GODOT_BIN" --version 2>/dev/null | tail -1 | awk -F. '{ if ($3 ~ /^[0-9]+$/) printf "%s.%s.%s-%s", $1, $2, $3, $4; else printf "%s.%s-%s", $1, $2, $3 }')
  [ -n "$VER" ] || die "godot --version 을 읽지 못했다 — GODOT_XVFB_VERSION 으로 지정한다"
fi
IMG="godot-xvfb:${VER}-${GARCH}"
if [ "$BUILD" = 1 ] || ! docker image inspect "$IMG" >/dev/null 2>&1; then
  step "이미지를 만든다 — $IMG (처음 한 번 · 몇 분)"
  docker build -t "$IMG" --build-arg GODOT_VERSION="$VER" --build-arg GODOT_ARCH="$GARCH" "$SELF_DIR/xvfb" \
    || die "이미지 빌드 실패 — Godot 리눅스 빌드 주소(버전 $VER · $GARCH)를 확인한다"
fi

# ── 사본 동기화 ─────────────────────────────────────────────────────────
case "$(uname -s)" in
  Darwin) CACHE_DEF="$HOME/Library/Caches/godot-xvfb" ;;
  *)      CACHE_DEF="${XDG_CACHE_HOME:-$HOME/.cache}/godot-xvfb" ;;
esac
CACHE="${GODOT_XVFB_CACHE:-$CACHE_DEF}"
KEY="$(basename "$PROJECT")-$(printf '%s' "$PROJECT" | cksum | cut -d' ' -f1)"
COPY="$CACHE/$KEY/proj"
OUT="${OUT_ARG:-$CACHE/$KEY/out}"
mkdir -p "$COPY" "$OUT"
OUT=$(cd -P "$OUT" && pwd)

EXCL=(--exclude .git --exclude node_modules --exclude .DS_Store
      --exclude /build --exclude /builds --exclude /android --exclude /ios
      --exclude /.cowork --exclude /.claude --exclude /outputs
      --exclude '*.apk' --exclude '*.aab' --exclude '*.ipa' --exclude '*.idsig')
[ -f "$PROJECT/.xvfbignore" ] && EXCL+=(--exclude-from "$PROJECT/.xvfbignore")

DO_IMPORT=$FORCE_IMPORT
if [ ! -f "$COPY/project.godot" ]; then
  # 첫 사본 — 호스트의 .godot 임포트 캐시까지 가져가 컨테이너 임포트를 줄인다
  step "첫 사본을 만든다 — $COPY (프로젝트 크기만큼 걸린다)"
  rsync -a --delete "${EXCL[@]}" "$PROJECT/" "$COPY/" || die "rsync 실패"
  DO_IMPORT=1
else
  # 그다음부터 .godot 은 컨테이너 것을 지킨다 (제외한 경로는 --delete 로도 지워지지 않는다)
  CHANGES=$(rsync -a --delete --itemize-changes "${EXCL[@]}" --exclude /.godot "$PROJECT/" "$COPY/") || die "rsync 실패"
  NCHG=$(printf '%s\n' "$CHANGES" | grep -c '^>f' || true)
  # 임포트가 필요한 변경만 고른다 — 재임포트(라리엔 3D 사본 20초)가 촬영(5초)보다 비싸고,
  # 같은 작업 트리를 다른 세션이 계속 고치므로 "무엇이든 바뀌면 임포트" 는 거의 매번 임포트가 된다(실측 668건).
  #   itemize 첫 칸: >f+++++++++ 새 파일 · >f.s…… 크기가 바뀜 · >f..t…… 시간만 바뀜(내용 같음 → 보지 않는다)
  #   텍스트 리소스·문서·번역 산출물은 임포트 없이 읽힌다 · .gd 는 새 파일일 때만(class_name 캐시) · .gdignore 폴더는 Godot 이 안 본다
  #   🛑 크기가 같고 내용만 바뀐 에셋은 놓친다 — 그림이 옛것이면 --import 로 다시 돈다
  IMPORT_WHY=""
  if [ "$DO_IMPORT" = 0 ]; then
    while IFS= read -r f; do
      d=$(dirname "$f")
      ignored=0
      while [ "$d" != "." ] && [ "$d" != "/" ]; do
        if [ -f "$COPY/$d/.gdignore" ]; then ignored=1; break; fi
        d=$(dirname "$d")
      done
      if [ "$ignored" = 0 ]; then IMPORT_WHY="$f"; break; fi
    done < <(printf '%s\n' "$CHANGES" | awk '
      $1 !~ /^>f/ { next }
      { path = substr($0, index($0, " ") + 1) }
      $1 !~ /^>f\+/ && substr($1, 4, 1) != "s" { next }
      path ~ /\.(md|txt|tscn|tres|translation|cfg|json|uid|gdignore)$/ { next }
      path ~ /\.gd$/ && $1 !~ /^>f\+/ { next }
      { print path }')
    if [ -n "$IMPORT_WHY" ]; then DO_IMPORT=1; fi
  fi
  step "사본 동기화 — 바뀐 파일 ${NCHG}개$([ -n "$IMPORT_WHY" ] && printf ' · 임포트할 변경: %s' "$IMPORT_WHY") · $COPY"
fi

# ── 실행 ────────────────────────────────────────────────────────────────
RENDER=(--rendering-method gl_compatibility)
[ "$MOBILE" = 1 ] && RENDER=(--rendering-method mobile --rendering-driver vulkan)
MOVIE_ARGS=()
[ -n "$MOVIE" ] && MOVIE_ARGS=(--write-movie "/out/$MOVIE" --fixed-fps "$FPS" --quit-after "$FRAMES")

# 🛑 docker run --init 를 빼지 않는다 — xvfb-run 이 컨테이너의 PID 1 이 되면 Xvfb 준비 신호를 못 받아
#    godot 을 띄우지도 않고 영원히 기다린다(실측: 6분 무응답 → --init 로 즉시 끝남).
INNER='
set -u
cd /work/proj
if [ "$XV_IMPORT" = 1 ]; then
  echo "▶ 임포트 (컨테이너 안 · 로그 /out/.xvfb-import.log)"
  godot --headless --path . --import > /out/.xvfb-import.log 2>&1 || echo "⚠️ 임포트 종료 코드 $? — /out/.xvfb-import.log"
fi
exec timeout "$XV_TIMEOUT" xvfb-run -a -s "-screen 0 ${XV_W}x${XV_H}x24" \
  godot --path . --display-driver x11 --audio-driver Dummy --resolution "${XV_W}x${XV_H}" "$@"
'

step "실행 — $IMG · ${W}x${H} · ${RENDER[1]} · 임포트 $([ "$DO_IMPORT" = 1 ] && echo 함 || echo 생략)"
T0=$(date +%s)
set +e
docker run --rm --init \
  -u "$(id -u):$(id -g)" -e HOME=/tmp \
  -v "$COPY":/work/proj -v "$OUT":/out \
  -e SHOT_DIR=/out -e XV_IMPORT="$DO_IMPORT" -e XV_TIMEOUT="$TIMEOUT" -e XV_W="$W" -e XV_H="$H" \
  ${ENVS[@]+"${ENVS[@]}"} \
  "$IMG" bash -c "$INNER" xvfb_run \
  "${RENDER[@]}" ${MOVIE_ARGS[@]+"${MOVIE_ARGS[@]}"} ${GODOT_ARGS[@]+"${GODOT_ARGS[@]}"}
RC=$?
set -e
step "끝 — 종료 코드 $RC · $(( $(date +%s) - T0 ))초 · 산출물 $OUT"
ls -1 "$OUT" | head -20
exit "$RC"
