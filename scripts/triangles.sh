#!/usr/bin/env bash
#
# triangles.sh — 씬·에셋의 삼각형과 드로우콜을 센다. 에디터를 열지 않는다.
#
#   scripts/triangles.sh                        main_scene 의 삼각형 총량
#   scripts/triangles.sh scenes/main/main.tscn  씬 하나 (경로는 res:// 도 되고 상대경로도 된다)
#   scripts/triangles.sh --all                  scenes/ 아래 .tscn 전부, 무거운 순으로
#   scripts/triangles.sh --all --budget 150000  예산을 넘는 씬이 있으면 종료 코드 1 (CI 용)
#
#   scripts/triangles.sh --frame                게임을 실제로 띄워 "그 프레임에 그린" 삼각형 (창이 잠깐 뜬다)
#   scripts/triangles.sh --frame <씬> --resolution 1280x720
#
#   scripts/triangles.sh --glb                  Godot 없이 assets/ 의 .glb·.gltf 를 직접 읽는다
#   scripts/triangles.sh --glb path/to/x.glb    파일 하나 · 폴더를 주면 재귀
#
#   공통:  --json          JSON 으로 출력
#          --csv out.csv   CSV 로도 저장
#          --top 20        무거운 노드 상위 N (기본 12)
#          --path ~/game   프로젝트 경로 지정 (기본: 현재 폴더에서 위로 탐색)
#
# 🛑 두 숫자는 다른 것을 센다. 무엇을 물었는지 먼저 정한다.
#   기본 모드(--all 포함)  씬에 **존재하는** 삼각형 총합  — 컬링·카메라와 무관. 예산을 짤 때
#   --frame               그 프레임에 **그린** 삼각형     — 컬링·LOD·그림자 반영. 병목을 볼 때
#   보통 --frame 쪽이 더 작다. 그림자가 있으면 오히려 커질 수도 있다(같은 메시를 광원 수만큼 다시 그린다).
#
# 🛑 런타임에 add_child() 로 만드는 메시는 기본 모드가 못 센다(씬 파일에 없다). 그런 씬은 --frame 으로 잰다.
#
# 자세한 설명 → .claude/skills/godot/references/mesh-geometry.md §15
set -euo pipefail

step() { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m❌\033[0m %s\n' "$*" >&2; exit 1; }

# 심볼릭 링크(scripts/triangles.sh)로 불려도 원본이 있는 폴더를 찾는다.
# 🛑 readlink 가 주는 값은 "링크 파일이 있는 폴더 기준" 상대경로다 — 현재 폴더 기준이 아니다.
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

# ── 인자 파싱 — 모르는 것은 그대로 하위 도구에 넘긴다 ────────────────────
MODE="scene"
PROJECT_ARG=""
RESOLUTION="1280x720"
PASS=()
TARGETS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --frame)      MODE="frame" ;;
    --glb)        MODE="glb" ;;
    --path)       shift; PROJECT_ARG="${1:-}" ;;
    --resolution) shift; RESOLUTION="${1:-1280x720}" ;;
    -h|--help)    awk 'NR>1 { if (/^#/) { sub(/^# ?/, ""); print } else exit }' "$0"; exit 0 ;;
    --all|--json) PASS+=("$1") ;;
    --budget|--csv|--top) PASS+=("$1"); shift; PASS+=("${1:-}") ;;
    -*)           die "알 수 없는 옵션: $1" ;;
    *)            TARGETS+=("$1") ;;
  esac
  shift
done

# ── 프로젝트 루트 (install.sh 와 같은 방식) ─────────────────────────────
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
  || die "project.godot 을 찾지 못했다. Godot 프로젝트 안에서 실행하거나 --path 로 지정한다."
cd "$ROOT"

# ── 스킬 위치 — 링크로 불렸어도 원본 폴더를 안다 ────────────────────────
GD_DIR="$SELF_DIR"
[ -f "$GD_DIR/count_triangles.gd" ] || GD_DIR="$ROOT/.claude/skills/godot/scripts"
[ -f "$GD_DIR/count_triangles.gd" ] || die "count_triangles.gd 를 찾지 못했다: $GD_DIR"

# 스킬이 프로젝트 안(.claude/…)에 있어야 res:// 로 실행할 수 있다.
case "$GD_DIR" in
  "$ROOT"/*) RES_DIR="res://${GD_DIR#"$ROOT"/}" ;;
  *) die "스킬이 프로젝트 밖에 있다($GD_DIR). res:// 로 실행할 수 없으니 프로젝트 안에 두거나 --path 를 확인한다." ;;
esac

# 상대경로·절대경로를 res:// 로 바꾼다. 이미 res:// 면 그대로 둔다.
to_res() {
  case "$1" in
    res://*) echo "$1" ;;
    /*) echo "res://${1#"$ROOT"/}" ;;
    *) echo "res://$(python3 -c 'import os,sys; print(os.path.relpath(os.path.abspath(sys.argv[1]), sys.argv[2]))' "$1" "$ROOT")" ;;
  esac
}

GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"

case "$MODE" in
  glb)
    # Godot 이 없어도 된다 — 파이썬만으로 glTF 를 읽는다
    exec python3 "$GD_DIR/count_triangles.py" --glb --project "$ROOT" \
      "${PASS[@]+"${PASS[@]}"}" "${TARGETS[@]+"${TARGETS[@]}"}"
    ;;

  frame)
    [ -n "$GODOT_BIN" ] || die "godot 실행 파일을 찾지 못했다. GODOT_BIN 환경변수로 경로를 지정한다."
    scene=""
    [ ${#TARGETS[@]} -gt 0 ] && scene=$(to_res "${TARGETS[0]}")
    step "실행해서 잰다 — 창이 잠깐 뜬다 ($RESOLUTION)"
    exec "$GODOT_BIN" --path "$ROOT" --resolution "$RESOLUTION" \
      -s "$RES_DIR/frame_triangles.gd" -- ${scene:+"$scene"}
    ;;

  scene)
    [ -n "$GODOT_BIN" ] || die "godot 실행 파일을 찾지 못했다. GODOT_BIN 환경변수로 경로를 지정한다."
    args=()
    for t in "${TARGETS[@]+"${TARGETS[@]}"}"; do args+=("$(to_res "$t")"); done
    exec python3 "$GD_DIR/count_triangles.py" --project "$ROOT" --godot "$GODOT_BIN" \
      --gd "$RES_DIR/count_triangles.gd" \
      "${PASS[@]+"${PASS[@]}"}" "${args[@]+"${args[@]}"}"
    ;;
esac
