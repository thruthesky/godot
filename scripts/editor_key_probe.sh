#!/bin/bash
# 에디터 단축키가 **3D 뷰포트를 클릭한 상태에서도** 듣는지 실제 에디터에서 확인한다.
#
# 🛑 왜 필요한가 — 플러그인 파일에 `_input` 이 적혀 있다는 것과 그 함수가 **실제로
#    호출된다** 는 것은 다른 문제다. 파일 내용을 보는 검사는 통과하는데 사람이 누르면
#    아무 일도 없는 상태가 실제로 세 번 나왔다(→ references/editor-compass.md §4).
#
# 🔑 검사하는 것 셋
#      ① 3D 뷰포트를 **실제로 클릭**한 뒤 키 → 단계가 바뀌는가   ← 여기가 세 번 틀린 자리
#      ② 씬 독을 클릭한 뒤 키 → 여전히 바뀌는가 (회귀 확인)
#      ③ 세 번 연타 → 정확히 한 바퀴인가 (0회와 3회를 구분한다)
#
# 사용법:
#   bash editor_key_probe.sh <애드온 폴더> <project_metadata 섹션>
#   예) bash editor_key_probe.sh addons/editor_compass editor_compass
set -e
ADDON="${1:-addons/editor_compass}"
SECTION="${2:-editor_compass}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$(pwd)"

if [ ! -d "$PROJECT/$ADDON" ]; then
	echo "🛑 애드온 폴더가 없다: $PROJECT/$ADDON"
	exit 1
fi

WORK="$(mktemp -d)"
OUT="$WORK/result.txt"
trap 'rm -rf "$WORK"' EXIT

# 🔑 대상 프로젝트를 건드리지 않는다 — 사람이 에디터를 열어 두고 작업 중일 수 있다.
#    필요한 것만 복사한 임시 최소 프로젝트에서 돌린다.
NAME="$(basename "$ADDON")"
mkdir -p "$WORK/addons/_probe"
cp -R "$PROJECT/$ADDON" "$WORK/addons/"
cp "$HERE/editor_probe/plugin.gd" "$HERE/editor_probe/plugin.cfg" "$WORK/addons/_probe/"

cat > "$WORK/project.godot" <<EOF
config_version=5
[application]
config/name="단축키 검증"
config/features=PackedStringArray("4.4", "Forward Plus")
[editor_plugins]
enabled=PackedStringArray("res://addons/$NAME/plugin.cfg", "res://addons/_probe/plugin.cfg")
EOF
printf '[gd_scene format=3]\n\n[node name="TestScene" type="Node3D"]\n' > "$WORK/test_scene.tscn"

godot --path "$WORK" --editor -- "--probe-out=$OUT" "--probe-section=$SECTION" 2>&1 \
	| grep -E "\[검증\]" || true

echo
if [ -f "$OUT" ]; then
	cat "$OUT"; echo
	grep -q "실패 0 건" "$OUT" && exit 0 || exit 1
fi
echo "🛑 결과 파일이 없다 — 에디터가 검증을 끝내지 못했다"
exit 1
