@tool
## 3D 씬을 열 때마다 **동서남북 보조선을 자동으로 붙이고**, 숫자 `0` 으로 켜고 끈다.
##
## 설치 — 이 폴더(`addons/editor_compass/`)를 프로젝트에 통째로 복사하고
##        `Project > Project Settings > Plugins` 에서 체크한다. 그 외 설정은 없다.
##
## 왜 자동으로 붙이나 — 보조선 씬을 손으로 끌어다 놓으면 세 가지가 불편하다.
##   ① 씬이 늘어날 때마다 반복해야 한다
##   ② 넣은 채로 저장하면 **씬 파일에 작업용 노드가 남는다** — 남이 보면 정체불명이다
##   ③ 지우는 것을 잊으면 **게임 빌드에 그대로 따라간다**
##
## 🔑 핵심은 `owner` 를 주지 않는 것이다. Godot 은 씬을 저장할 때 **`owner` 가 씬 루트인
##    노드만** 파일에 기록한다. `add_child()` 만 하고 `owner` 를 비워 두면 화면에는 보이지만
##    `Cmd+S` 를 눌러도 `.tscn` 에는 한 글자도 들어가지 않는다(실측).
extends EditorPlugin

## 🔑 상대 경로다 — 스킬 저장소 안(`.claude/skills/godot/addons/…`)에 있든 프로젝트 `addons/` 에
##    복사됐든 같은 폴더의 `compass.gd` 를 찾는다. 절대 경로 `res://addons/…` 로 두면 스킬
##    폴더에 있는 사본을 GDScript LSP 가 파싱할 때 "Preload file does not exist" 로 실패한다.
const COMPASS_SCRIPT := preload("compass.gd")

## 자동으로 붙인 노드의 이름. 씬 독에 보이므로 "손으로 넣은 것이 아니다" 를 이름으로 알린다.
const AUTO_NAME := "Compass (auto - not saved)"

## 표시 단계를 프로젝트별로 기억한다. 에디터를 껐다 켜도 마지막 상태가 유지된다.
const META_SECTION := "editor_compass"
const META_KEY := "mode"

## `Project > Tools` 에 넣을 항목 이름.
##
## 🔑 단축키만 두면 **그것을 모르는 사람은 끌 방법이 없다.** 메뉴는 눈에 보인다.
const MENU_CYCLE := "Compass - Next Step (0)"
const MENU_HIDE := "Compass - Hide All"

var _mode: int = COMPASS_SCRIPT.MODE_ALL

## 마지막으로 단계를 넘긴 프레임. 이벤트가 겹쳐 들어와 단계를 건너뛰는 것을 막는다.
var _last_toggle_frame := -1
var _current: Node = null


func _enter_tree() -> void:
	_mode = _load_mode()
	# 🛑 이 줄이 없으면 `_input` 이 호출되지 않는다.
	set_process_input(true)
	scene_changed.connect(_on_scene_changed)
	# 메뉴도 단축키와 **같은 함수**를 부른다 — 동작이 갈라지지 않는다.
	add_tool_menu_item(MENU_CYCLE, _on_menu_cycle)
	add_tool_menu_item(MENU_HIDE, _on_menu_hide)
	# 플러그인을 켜는 순간 이미 열려 있던 씬에도 바로 붙인다.
	_attach(EditorInterface.get_edited_scene_root())
	print("[Compass] %s" % COMPASS_SCRIPT.announce_text(_mode))


func _exit_tree() -> void:
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	remove_tool_menu_item(MENU_CYCLE)
	remove_tool_menu_item(MENU_HIDE)
	# 🛑 자기가 붙인 것 하나만 떼면 부족하다. 손으로 넣은 보조선이 남으면 사람 눈에는
	#    **"껐는데 안 꺼진다"** 로 보이고, 플러그인이 죽었으니 `0` 키로도 못 지운다(실측).
	_detach()
	_remove_all()


## 🛑🛑 `_input` 을 쓴다. `_unhandled_key_input` 도 `_shortcut_input` 도
##      `_forward_3d_gui_input` 도 아니다.
##
##   같은 버그를 세 번 고치고 세 번 다 실패한 뒤 실측으로 정리한 표다
##   (Godot 4.7, macOS, 2026-09-04). **3D 뷰포트를 클릭한 뒤** `0` 을 누르면:
##
##   | 콜백 | 결과 | 왜 |
##   |---|---|---|
##   | `_unhandled_key_input` | ❌ | "아무도 안 먹은 키" 만 온다. 뷰포트가 먼저 가져간다 |
##   | `_shortcut_input` | ❌ | GUI 처리 **앞**이지만, 뷰포트를 클릭하면 그 안의 `Control` 이 포커스를 쥐어 오지 않는다 |
##   | `_forward_3d_gui_input` | ❌ | `_handles()` 가 **선택된 노드**를 볼 때만 플러그인이 활성화된다. 빈 곳을 클릭하면 선택이 풀려 함수 자체가 죽는다 |
##   | **`_input`** | ✅ | `Viewport::push_input` 의 **가장 앞**이라 누가 포커스를 갖든 먼저 온다 |
##
##   🛑 함정 — `grab_focus()` 로 포커스만 옮겨 시험하면 `_shortcut_input` 도 통과한다.
##      **실제 마우스 클릭**을 넣어야 재현된다. 재현하지 못하는 검증은 통과해도 의미가 없다.
##
##   🛑 `_handles()` 를 두지 않는다 — `true` 를 돌려주면 EditorNode 가 이 플러그인을
##      "현재 오브젝트의 편집기" 로 삼아 **다른 플러그인의 활성화를 방해**한다.
##
##   `_input` 은 대신 **모든** 입력을 받는다. 그래서 아래에서 글자 입력 중인지와
##   3D 화면인지를 직접 확인해 그 둘을 걸러낸다.
func _input(event: InputEvent) -> void:
	# 키 판정(0 인가 · 누르는 순간인가 · 수정키가 안 섞였는가)은 `compass.gd` 가 한다 —
	# 그래야 에디터를 띄우지 않고도 시험할 수 있다. 여기서는 **에디터 상황**만 본다.
	if not COMPASS_SCRIPT.is_toggle_key(event):
		return
	# 🛑 글자를 입력하는 중이면 건드리지 않는다 — 이름 바꾸기·검색창·스크립트 편집에서 친 `0`.
	#    `_input` 은 GUI 보다 먼저 오므로 이 확인을 우리가 직접 해야 한다.
	if _is_typing():
		return
	# 🛑 3D 화면일 때만 반응한다. 2D·스크립트·에셋 화면에서 친 `0` 까지 가로채면
	#    "왜 갑자기 뭔가 바뀌지" 가 된다.
	if not _is_3d_screen():
		return
	if _cycle():
		get_viewport().set_input_as_handled()


## 다음 단계로 넘긴다. 같은 프레임에 이벤트가 겹쳐 들어와도 **한 번만** 센다.
func _cycle() -> bool:
	var frame := Engine.get_process_frames()
	if frame == _last_toggle_frame:
		return false
	_last_toggle_frame = frame
	_set_mode((_mode + 1) % COMPASS_SCRIPT.MODE_COUNT)
	return true


## 메뉴에서 부를 때는 프레임 가드를 거치지 않는다 — 키와 겹칠 일이 없다.
func _on_menu_cycle() -> void:
	_set_mode((_mode + 1) % COMPASS_SCRIPT.MODE_COUNT)


func _on_menu_hide() -> void:
	_set_mode(COMPASS_SCRIPT.MODE_NONE)


## 그룹에 등록된 보조선을 **전부** 떼어 낸다. 플러그인을 끌 때 쓴다.
##
## 🔑 손으로 넣은 것까지 지운다 — 플러그인이 꺼진 뒤에는 그것을 켜고 끌 수단이
##    아무것도 남지 않기 때문이다. 씬 파일에 저장된 것이 아니라면 되돌릴 것도 없다.
func _remove_all() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null or not root.is_inside_tree():
		return
	for n in root.get_tree().get_nodes_in_group(COMPASS_SCRIPT.GROUP):
		if not is_instance_valid(n) or n.is_queued_for_deletion():
			continue
		var parent := n.get_parent()
		if parent != null:
			parent.remove_child(n)
		n.queue_free()


func _on_scene_changed(root: Node) -> void:
	_detach()
	_attach(root)


## 3D 씬이면 보조선을 붙인다. 2D·UI 씬에는 붙이지 않는다.
func _attach(root: Node) -> void:
	if root == null or not (root is Node3D):
		return
	# 사람이 직접 넣어 둔 보조선이 이미 있으면 겹쳐 그리지 않는다.
	if _has_live_compass(root):
		_apply_mode()
		return
	var node := Node3D.new()
	node.name = AUTO_NAME
	node.set_script(COMPASS_SCRIPT)
	# 🛑 owner 를 설정하지 않는다. 이 한 줄이 없어서 저장되지 않는 것이다.
	root.add_child(node)
	_current = node
	_apply_mode()


## 이미 살아 있는 보조선이 있는가.
##
## 🛑 `queue_free()` 는 **프레임 끝**에 처리되어 그때까지 트리에 남아 있다. 그것을
##    "이미 있다" 로 세면 씬을 전환할 때마다 보조선이 통째로 사라진다(실측).
func _has_live_compass(root: Node) -> bool:
	for n in root.get_tree().get_nodes_in_group(COMPASS_SCRIPT.GROUP):
		if is_instance_valid(n) and not n.is_queued_for_deletion() and root.is_ancestor_of(n):
			return true
	return false


func _detach() -> void:
	if _current != null and is_instance_valid(_current):
		# 🛑 `queue_free()` 만으로는 프레임 끝까지 트리에 남는다. 먼저 트리에서 빼야
		#    바로 이어지는 `_attach()` 가 그것을 "이미 있는 보조선" 으로 오해하지 않는다.
		var parent := _current.get_parent()
		if parent != null:
			parent.remove_child(_current)
		_current.queue_free()
	_current = null


func _set_mode(value: int) -> void:
	_mode = value
	_apply_mode()
	var settings := EditorInterface.get_editor_settings()
	if settings != null:
		settings.set_project_metadata(META_SECTION, META_KEY, value)
	print("[Compass] %s - press 0 to cycle" % COMPASS_SCRIPT.MODE_LABELS[value])


## 손으로 넣은 것과 자동으로 붙인 것을 가리지 않고 그룹으로 한꺼번에 처리한다.
func _apply_mode() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null or not root.is_inside_tree():
		return
	for n in root.get_tree().get_nodes_in_group(COMPASS_SCRIPT.GROUP):
		var n3 := n as Node3D
		if n3 == null:
			continue
		n3.visible = _mode != COMPASS_SCRIPT.MODE_NONE
		if n3.has_method("set_compass_visible"):
			n3.set_compass_visible(_mode == COMPASS_SCRIPT.MODE_ALL)


## 지금 글자를 입력하는 중인가 — 포커스를 가진 위젯으로 판단한다.
func _is_typing() -> bool:
	var base := EditorInterface.get_base_control()
	if base == null:
		return false
	var focused := base.get_viewport().gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit


## 지금 에디터가 3D 화면을 보여 주고 있는가.
##
## 메인 화면 컨테이너의 자식 중 **보이는 것 하나**가 현재 화면이다
## (실측: `@CanvasItemEditor@…` · `@Node3DEditor@…` · `@EditorAssetLibrary@…`).
## 🛑 판별하지 못하면 **막지 않는다** — 엔진 버전이 바뀌어 이름이 달라져도 단축키가 죽지 않게 한다.
func _is_3d_screen() -> bool:
	var main := EditorInterface.get_editor_main_screen()
	if main == null:
		return true
	for c in main.get_children():
		var ctl := c as Control
		if ctl != null and ctl.visible:
			return str(ctl.name).contains("Node3DEditor")
	return true


func _load_mode() -> int:
	var settings := EditorInterface.get_editor_settings()
	if settings == null:
		return COMPASS_SCRIPT.MODE_ALL
	var saved: int = int(settings.get_project_metadata(META_SECTION, META_KEY, COMPASS_SCRIPT.MODE_ALL))
	# 저장된 값이 범위를 벗어나면(설정 파일 손상·버전 차이) 기본으로 되돌린다.
	return saved if saved >= 0 and saved < COMPASS_SCRIPT.MODE_COUNT else COMPASS_SCRIPT.MODE_ALL
