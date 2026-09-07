@tool
## 3D 씬의 원점에 **동서남북 화살표와 격자**를 그린다. 에디터 전용 보조선이다.
##
## 🛑 이 스크립트를 씬에 직접 붙이지 않아도 된다. `plugin.gd` 가 3D 씬을 열 때마다
##    스스로 붙인다. 직접 붙이고 싶다면 아무 `Node3D` 에나 이 스크립트를 지정하면 된다.
##
## 방향 규약 — Godot 의 기본 그대로다.
##   북 = `-Z` · 남 = `+Z` · 동 = `+X` · 서 = `-X` · 위 = `+Y`
##   (Godot 카메라의 기본 전방이 `-Z` 이므로, 그 쪽을 북으로 삼는 것이 가장 헷갈리지 않는다)
extends Node3D

## 켜고 끌 때 한꺼번에 찾기 위한 그룹 이름.
const GROUP := "editor_compass"

## 숫자 `0`. 바꾸려면 여기만 고친다.
const TOGGLE_KEYCODE := KEY_0

## 표시 단계 — `0` 을 누를 때마다 순환한다.
##
## 🔑 중간 단계(격자만)를 두는 이유 — 배치 작업 중에는 **격자는 계속 필요하지만**
##    방향은 한 번 확인하면 그만이다. 화살표만 걷어내고 작업을 이어갈 수 있어야 한다.
const MODE_ALL := 0    ## 화살표 + 격자
const MODE_GRID := 1   ## 격자만 (화살표 숨김)
const MODE_NONE := 2   ## 전부 숨김
const MODE_COUNT := 3

## 🛑 출력 콘솔에 그대로 나가므로 **영어**다. 에디터 UI 언어와 섞이지 않고,
##    한글 폰트가 없는 환경에서 네모로 깨지지 않는다. 🛑 주석은 그대로다.
const MODE_LABELS: PackedStringArray = [
	"Arrows + Grid",
	"Grid only (arrows hidden)",
	"All hidden",
]

## 숨길 때 꺼야 할 자식 이름.
const ARROW_HOLDER := "Compass"

## 보조선을 띄울 높이. 0 이면 지면과 z-fighting 이 난다.
const LINE_Y := 0.05
const ARROW_Y := 0.06
const LABEL_Y := 0.9

## 격자를 몇 칸 그릴 것인가(중심에서 한쪽으로).
const GRID_HALF_COUNT := 5

## 선 굵기 — 씬 크기에 비례해 정해지므로 여기 값은 **비율**이다.
const GRID_WIDTH_RATIO := 0.006
const ARROW_WIDTH_RATIO := 0.016
const HEAD_LENGTH_RATIO := 0.16
const HEAD_HALF_WIDTH_RATIO := 0.055

## 글자 크기. `fixed_size` 라 배율과 무관하게 같은 크기로 읽힌다.
const LABEL_SIZE := 12
const ORIGIN_LABEL_SIZE := 9

## 씬이 비어 있거나 크기를 잴 수 없을 때 쓸 기준 반경(미터).
const FALLBACK_RADIUS := 10.0

## 색 — 네 방향을 색으로도 구분한다. 글자를 못 읽는 배율에서도 방향을 안다.
const COLOR_NORTH := Color(0.45, 0.90, 0.65)   # N (-Z)
const COLOR_EAST := Color(0.95, 0.55, 0.45)    # E (+X)
const COLOR_SOUTH := Color(0.82, 0.58, 0.92)   # S (+Z)
const COLOR_WEST := Color(0.48, 0.72, 0.95)    # W (-X)
const COLOR_ORIGIN := Color(0.95, 0.92, 0.78)
const COLOR_GRID := Color(0.46, 0.51, 0.62)

## 씬 크기에서 계산한 나침반 반경. `_rebuild()` 가 채운다.
var _radius := FALLBACK_RADIUS


func _ready() -> void:
	add_to_group(GROUP)
	# 🛑 게임 실행 중에는 존재 자체를 지운다. 숨기는 것으로는 부족하다 —
	#    숨긴 노드도 메모리를 먹고, 무엇보다 **씬에 저장되면 빌드에 따라간다.**
	if not Engine.is_editor_hint():
		queue_free()
		return
	_rebuild()


## 지금 몇 단계인지 사람이 읽을 문장으로. 플러그인이 콘솔에 찍는다.
static func announce_text(mode: int) -> String:
	if mode == MODE_NONE:
		return "Everything is hidden - press 0 in the 3D view to bring it back"
	return "On - now '%s' - press 0 in the 3D view to cycle" % MODE_LABELS[mode]


## 이 이벤트가 보조선 토글인가.
##
## 🔑 판정을 여기 static 함수로 두는 이유 — 플러그인 쪽에 두면 **에디터를 띄워야만**
##    시험할 수 있다. 여기 있으면 헤드리스 테스트가 그냥 부를 수 있다.
static func is_toggle_key(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null:
		return false
	if not key.pressed or key.echo:
		return false
	# 🛑 수정키가 섞이면 무시한다. `Cmd+0`(배율 초기화) 같은 기존 단축키를 빼앗지 않는다.
	if key.ctrl_pressed or key.alt_pressed or key.shift_pressed or key.meta_pressed:
		return false
	# 🛑 `keycode` 로 본다. 넘패드 `0`(KEY_KP_0)은 다른 키다 — 여기서 자연히 걸러진다.
	return key.keycode == TOGGLE_KEYCODE


## 화살표만 따로 숨긴다(격자만 보는 단계).
func set_compass_visible(shown: bool) -> void:
	var holder := get_node_or_null(ARROW_HOLDER) as Node3D
	if holder != null:
		holder.visible = shown


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_radius = _measure_radius()
	_grid()
	_compass()
	# 🛑 에디터에서 실수로 집히거나 끌려가지 않게 잠근다. 보조선은 **보는 것**이지
	#    옮기는 것이 아니고, 배치 작업 중 이것이 집히면 그 자체가 방해다.
	_lock_all(self)


## 씬에 실제로 놓인 것들의 크기를 재서 나침반 반경을 정한다.
##
## 🔑 어느 프로젝트에나 붙일 수 있어야 하므로 **고정 미터 값을 쓰지 않는다.**
##    1m 짜리 소품 씬과 1,000m 짜리 지형 씬에 같은 크기를 그리면 한쪽은 안 보이고
##    한쪽은 화면을 다 덮는다.
func _measure_radius() -> float:
	var parent := get_parent()
	if parent == null:
		return FALLBACK_RADIUS
	var aabb := AABB()
	var first := true
	for n in _all_visual_nodes(parent):
		# 🛑 자기 자신(보조선)은 재지 않는다. 재면 다음 계산이 이전 결과에 끌려간다.
		if n == self or is_ancestor_of(n):
			continue
		var box := n.get_aabb()
		var world := n.global_transform * box
		if first:
			aabb = world
			first = false
		else:
			aabb = aabb.merge(world)
	if first:
		return FALLBACK_RADIUS
	var span := maxf(aabb.size.x, aabb.size.z)
	if span < 0.001:
		return FALLBACK_RADIUS
	# 씬 내용의 절반보다 조금 작게 — 화살표가 내용 밖으로 삐져나가지 않는다.
	return clampf(span * 0.35, 1.0, 500.0)


func _all_visual_nodes(root: Node) -> Array[VisualInstance3D]:
	var out: Array[VisualInstance3D] = []
	var vi := root as VisualInstance3D
	if vi != null:
		out.append(vi)
	for c in root.get_children():
		out.append_array(_all_visual_nodes(c))
	return out


## 격자 — 한 칸의 크기는 나침반 반경에서 정한다.
func _grid() -> void:
	var holder := Node3D.new()
	holder.name = "Grid"
	add_child(holder)
	var step := _radius / float(GRID_HALF_COUNT)
	var reach := step * GRID_HALF_COUNT
	var width := _radius * GRID_WIDTH_RATIO
	for i in range(-GRID_HALF_COUNT, GRID_HALF_COUNT + 1):
		var at := step * i
		_bar(holder, Vector2(at, -reach), Vector2(at, reach), width, COLOR_GRID, LINE_Y)
		_bar(holder, Vector2(-reach, at), Vector2(reach, at), width, COLOR_GRID, LINE_Y)


## 원점에 동서남북 화살표와 글자를 놓는다.
func _compass() -> void:
	var holder := Node3D.new()
	holder.name = ARROW_HOLDER
	add_child(holder)

	var o := Vector2.ZERO
	_arrow(holder, o, Vector2(0.0, -_radius), COLOR_NORTH)
	_arrow(holder, o, Vector2(_radius, 0.0), COLOR_EAST)
	_arrow(holder, o, Vector2(0.0, _radius), COLOR_SOUTH)
	_arrow(holder, o, Vector2(-_radius, 0.0), COLOR_WEST)
	_origin_marker(holder)

	# 🛑 글자는 화살촉 **바깥**에 둔다. 안쪽에 두면 화살촉과 겹쳐 뭉갠다(실측).
	var d := _radius + _radius * 0.22
	_label(holder, "N", Vector2(0.0, -d), "N", COLOR_NORTH, LABEL_SIZE)
	_label(holder, "E", Vector2(d, 0.0), "E", COLOR_EAST, LABEL_SIZE)
	_label(holder, "S", Vector2(0.0, d), "S", COLOR_SOUTH, LABEL_SIZE)
	_label(holder, "W", Vector2(-d, 0.0), "W", COLOR_WEST, LABEL_SIZE)

	# 🛑 원점 글자를 (0,0) 에 그대로 두면 네 화살표와 원점 마커에 겹쳐 읽을 수 없다(실측).
	#    화살표는 축 방향으로만 뻗으므로 **대각선은 비어 있다.** 그쪽으로 비킨다.
	var diag := _radius * 0.42
	_label(holder, "Origin", Vector2(-diag, -diag), "0, 0", COLOR_ORIGIN, ORIGIN_LABEL_SIZE)


## 대(막대) + 채운 삼각형 머리로 화살표를 만든다.
##
## 🔑 머리를 선 두 개로 그리면 `<` 모양이라 화살표가 아니라 꺾쇠로 보인다.
##    `PrismMesh` 는 삼각기둥이라 위에서 내려다보면 **채워진 삼각형**이 된다.
func _arrow(parent: Node3D, from: Vector2, to: Vector2, color: Color) -> void:
	var dir := (to - from).normalized()
	var head_len := _radius * HEAD_LENGTH_RATIO
	_bar(parent, from, to - dir * head_len, _radius * ARROW_WIDTH_RATIO, color, ARROW_Y)
	_arrow_head(parent, to, dir, color, head_len)


## 화살촉 하나. 뾰족한 끝이 `tip` 에 오도록 놓는다.
##
## 🛑 `PrismMesh` 의 삼각형은 **XY 평면에 서 있고** `+Y` 가 뾰족한 쪽이다. 바닥(XZ)에
##    눕히려면 X축으로 −90° 돌려야 하고, 그러면 뾰족한 쪽이 `-Z`(북)를 향한다.
##    거기서 방향만큼 더 돌린다. 회전 두 번을 `rotation` 속성으로 주면 **적용 순서(YXZ)**
##    때문에 어긋나므로 `Basis` 를 직접 곱한다.
func _arrow_head(parent: Node3D, tip: Vector2, dir: Vector2, color: Color, length: float) -> void:
	var mi := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(_radius * HEAD_HALF_WIDTH_RATIO * 2.0, length, 0.04)
	prism.material = _material(color)
	mi.mesh = prism
	# -Z 기준 회전각. 검산 — 북(0,−1)→0 · 동(1,0)→−90° · 남(0,1)→180° · 서(−1,0)→+90°
	var yaw := -atan2(dir.x, -dir.y)
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -PI * 0.5)
	# PrismMesh 의 원점은 한가운데다. 끝이 tip 에 오도록 절반만큼 물린다.
	var center := tip - dir * (length * 0.5)
	mi.transform = Transform3D(basis, Vector3(center.x, ARROW_Y, center.y))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## `BoxMesh` 의 긴 축(+Z)을 두 점 방향으로 돌려 굵은 대를 만든다.
func _bar(parent: Node3D, from: Vector2, to: Vector2, width: float, color: Color, y: float) -> void:
	var delta := to - from
	var length := delta.length()
	if length <= 0.001:
		return
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.04, length)
	bm.material = _material(color)
	mi.mesh = bm
	mi.position = Vector3((from.x + to.x) * 0.5, y, (from.y + to.y) * 0.5)
	mi.rotation.y = atan2(delta.x, delta.y)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _origin_marker(parent: Node3D) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = _radius * 0.045
	cyl.bottom_radius = cyl.top_radius
	cyl.height = 0.06
	cyl.material = _material(COLOR_ORIGIN)
	mi.mesh = cyl
	mi.position = Vector3(0.0, ARROW_Y + 0.01, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## `Label3D` 는 카메라를 항상 바라보고, `fixed_size` 라 **배율과 무관하게** 같은 크기로 읽힌다.
## 3D 메시로 글자를 만들면 줌 아웃에서 점이 되어 못 읽는다.
func _label(parent: Node3D, name_: String, pos: Vector2, text_: String,
		color: Color, size: int) -> void:
	var label := Label3D.new()
	label.name = name_
	label.text = text_
	label.position = Vector3(pos.x, LABEL_Y, pos.y)
	label.font_size = size
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	# 바닥·기물에 가리지 않게 깊이 검사를 끄고, 어떤 배경에서도 읽히도록 외곽선을 준다.
	label.no_depth_test = true
	label.modulate = color
	label.outline_size = 6
	label.outline_modulate = Color(0.05, 0.06, 0.09, 0.85)
	parent.add_child(label)


func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	# 🛑 조명을 받지 않게 한다. 보조선은 씬의 조명 상태와 무관하게 **항상 같은 색**이어야
	#    구분이 된다. 라이트맵을 굽지 않은 씬에서 새까맣게 나오는 것도 막는다.
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_receive_shadows = true
	# 🛑 지면·기물에 가리지 않게 깊이 검사를 끈다.
	#
	#   실측 — 두께 1m 짜리 바닥판(원점 중심, 윗면 +0.5m) 위에서 보조선이 **통째로
	#   파묻혀 글자만 보였다.** 보조선을 지면보다 살짝 띄우는 것으로는 못 막는다.
	#   지형이 얼마나 높은 곳에 있는지 미리 알 수 없기 때문이다.
	#   보조선은 **보는 것**이고, 가려지면 존재 이유가 없다.
	m.no_depth_test = true
	# 불투명 지오메트리 뒤에 그려 항상 위에 오게 한다.
	m.render_priority = 1
	return m


## 에디터에서 집히거나 끌려가지 않게 잠근다.
func _lock_all(node: Node) -> void:
	node.set_meta("_edit_lock_", true)
	for c in node.get_children():
		_lock_all(c)
