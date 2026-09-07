#!/bin/bash
# 플러그인을 **끄면 보조선이 정말 사라지는가**, 다시 켜면 돌아오는가.
#
# 🛑 왜 필요한가 — `_exit_tree()` 에서 자기가 붙인 노드 하나만 떼면, 손으로 넣은 것은
#    **화면에 그대로 남는다.** 사람 눈에는 "껐는데 안 꺼진다" 로 보이고, 플러그인이
#    죽었으니 단축키로도 못 지운다(2026-09-05 실측 — `_remove_all()` 없이 1개가 남았다).
#
# 사용법:
#   bash editor_disable_probe.sh <애드온 폴더> <섹션·그룹> <보조선 스크립트>
#   예) bash editor_disable_probe.sh addons/editor_compass editor_compass \
#         res://addons/editor_compass/compass.gd
set -e
ADDON="${1:-addons/editor_compass}"
SECTION="${2:-editor_compass}"
SCRIPT="${3:-res://addons/editor_compass/compass.gd}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$(pwd)"
NAME="$(basename "$ADDON")"

[ -d "$PROJECT/$ADDON" ] || { echo "🛑 애드온 폴더가 없다: $PROJECT/$ADDON"; exit 1; }

WORK="$(mktemp -d)"
OUT="$WORK/result.txt"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/addons/_dis"
cp -R "$PROJECT/$ADDON" "$WORK/addons/"
cp "$HERE/editor_probe/disable.gd" "$WORK/addons/_dis/plugin.gd"
cp "$HERE/editor_probe/disable.cfg" "$WORK/addons/_dis/plugin.cfg"

cat > "$WORK/project.godot" <<EOF
config_version=5
[application]
config/name="끄기 검증"
config/features=PackedStringArray("4.4", "Forward Plus")
[editor_plugins]
enabled=PackedStringArray("res://addons/$NAME/plugin.cfg", "res://addons/_dis/plugin.cfg")
EOF
printf '[gd_scene format=3]\n\n[node name="TestScene" type="Node3D"]\n' > "$WORK/test_scene.tscn"

godot --path "$WORK" --editor -- "--probe-out=$OUT" "--probe-target=$NAME" \
	"--probe-group=$SECTION" "--probe-script=$SCRIPT" 2>&1 | grep -E "\[끄기검증\]" || true

echo
if [ -f "$OUT" ]; then
	cat "$OUT"; echo
	grep -q "실패 0 건" "$OUT" && exit 0 || exit 1
fi
echo "🛑 결과 파일이 없다"
exit 1
