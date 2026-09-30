#!/usr/bin/env bash
#
# triangles.sh — count the triangles and draw calls of scenes and assets. It never opens the editor.
# This script is shared with remote teammates, so every message it prints is in English.
#
#   scripts/triangles.sh                        total triangles of main_scene
#   scripts/triangles.sh scenes/main/main.tscn  one scene (the path may be res:// or relative)
#   scripts/triangles.sh --all                  every .tscn under scenes/, heaviest first
#   scripts/triangles.sh --all --budget 150000  exit code 1 if any scene is over budget (for CI)
#
#   scripts/triangles.sh --frame                actually run the game and count the triangles "drawn in that frame" (a window pops up briefly)
#   scripts/triangles.sh --frame <scene> --resolution 1280x720
#
#   scripts/triangles.sh --glb                  read the .glb/.gltf files under assets/ directly, without Godot
#   scripts/triangles.sh --glb path/to/x.glb    one file · give a folder to recurse
#
#   Common:  --json          output JSON
#            --csv out.csv   also save as CSV
#            --top 20        top N heaviest nodes (default 12)
#            --path ~/game   project path (default: search upward from the current folder)
#
# 🛑 The two numbers count different things. Decide first what you are asking.
#   default mode (incl. --all)  total triangles that **exist** in the scene  — independent of culling and camera. Use it for budgeting
#   --frame                     triangles **drawn** in that frame            — reflects culling, LOD, shadows. Use it to find bottlenecks
#   Usually --frame is smaller. With shadows it can even be larger (the same mesh is drawn again once per light).
#
# 🛑 Meshes created at runtime with add_child() are not counted by the default mode (they are not in the scene file). Measure such scenes with --frame.
#
# Details → .claude/skills/godot/references/mesh-geometry.md §15
set -euo pipefail

step() { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m❌\033[0m %s\n' "$*" >&2; exit 1; }

# Find the folder of the real file even when called through the symlink (scripts/triangles.sh).
# 🛑 readlink returns a path relative to "the folder that holds the link" — not to the current folder.
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

# ── Argument parsing — unknown values are passed through to the sub-tool ─
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
    -*)           die "unknown option: $1" ;;
    *)            TARGETS+=("$1") ;;
  esac
  shift
done

# ── Project root (same method as install.sh) ────────────────────────────
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
  || die "project.godot not found. Run inside a Godot project or pass it with --path."
cd "$ROOT"

# ── Skill location — knows the real folder even when called through a link ─
GD_DIR="$SELF_DIR"
[ -f "$GD_DIR/count_triangles.gd" ] || GD_DIR="$ROOT/.claude/skills/godot/scripts"
[ -f "$GD_DIR/count_triangles.gd" ] || die "count_triangles.gd not found: $GD_DIR"

# The skill must be inside the project (.claude/…) to run it via res://.
case "$GD_DIR" in
  "$ROOT"/*) RES_DIR="res://${GD_DIR#"$ROOT"/}" ;;
  *) die "the skill is outside the project ($GD_DIR). It cannot run via res://, so put it inside the project or check --path." ;;
esac

# Convert relative/absolute paths to res://. Leave res:// paths as they are.
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
    # Godot is not needed — glTF is read with Python alone
    exec python3 "$GD_DIR/count_triangles.py" --glb --project "$ROOT" \
      "${PASS[@]+"${PASS[@]}"}" "${TARGETS[@]+"${TARGETS[@]}"}"
    ;;

  frame)
    [ -n "$GODOT_BIN" ] || die "godot executable not found. Set its path with the GODOT_BIN environment variable."
    scene=""
    [ ${#TARGETS[@]} -gt 0 ] && scene=$(to_res "${TARGETS[0]}")
    step "Running it to measure — a window pops up briefly ($RESOLUTION)"
    exec "$GODOT_BIN" --path "$ROOT" --resolution "$RESOLUTION" \
      -s "$RES_DIR/frame_triangles.gd" -- ${scene:+"$scene"}
    ;;

  scene)
    [ -n "$GODOT_BIN" ] || die "godot executable not found. Set its path with the GODOT_BIN environment variable."
    args=()
    for t in "${TARGETS[@]+"${TARGETS[@]}"}"; do args+=("$(to_res "$t")"); done
    exec python3 "$GD_DIR/count_triangles.py" --project "$ROOT" --godot "$GODOT_BIN" \
      --gd "$RES_DIR/count_triangles.gd" \
      "${PASS[@]+"${PASS[@]}"}" "${args[@]+"${args[@]}"}"
    ;;
esac
