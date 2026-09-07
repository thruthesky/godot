@tool
## 3D 뷰포트에 **포커스를 준 채로** `0` 키를 주입해, 보조선 단계가 실제로 도는지 확인한다.
##
## 🛑 이 검증이 왜 따로 필요한가 — 파일에 `_forward_3d_gui_input` 이 적혀 있다는 것과
##    그 함수가 **실제로 호출된다**는 것은 다른 문제다. 2026-09-04 에 정확히 그 차이로
##    "검증은 전부 통과했는데 사람이 누르면 안 되는" 상태가 두 번 나왔다.
extends EditorPlugin

## 결과를 쓸 곳. 실행 스크립트가 `--probe-out=<경로>` 로 넘긴다.
const OUT_ARG := "--probe-out="

## 어떤 씬을 열어 검증할지. 실행 스크립트가 `--probe-scene=<경로>` 로 넘긴다.
const SCENE_ARG := "--probe-scene="
## 표시 단계가 저장되는 project_metadata 섹션. 애드온마다 다르므로 인자로 받는다.
const SECTION_ARG := "--probe-section="
var _section := "laryen_zone_overlay"

var _lines: PackedStringArray = []


func _enter_tree() -> void:
	call_deferred("_run")


func _log(s: String) -> void:
	_lines.append(s)
	print("[검증] ", s)


func _mode() -> int:
	var st := EditorInterface.get_editor_settings()
	return int(st.get_project_metadata(_section, "mode", 0))


## 실제 키보드가 만드는 것과 같은 이벤트를 만든다.
func _press_zero() -> void:
	var down := InputEventKey.new()
	down.keycode = KEY_0
	down.physical_keycode = KEY_0
	down.unicode = 48
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventKey.new()
	up.keycode = KEY_0
	up.physical_keycode = KEY_0
	up.pressed = false
	Input.parse_input_event(up)


## 3D 뷰포트 Control 을 찾는다. 이름이 아니라 **클래스**로 찾는다 —
## 이름은 에디터 버전마다 달라질 수 있지만 클래스는 엔진 소스에 박혀 있다.
## 🔑 사람이 3D 화면을 클릭하면 포커스가 가는 것은  자신이 아니라
##    그 자식 **** 다(실측 — 부모는 ).
func _find_viewport(node: Node, depth: int = 0) -> Control:
	if depth > 30:
		return null
	for c in node.get_children():
		if c.get_class() == "Node3DEditorViewport":
			for g in c.get_children():
				if g.get_class() == "SubViewportContainer":
					return g as Control
		var found := _find_viewport(c, depth + 1)
		if found != null:
			return found
	return null


## 트리를 덤프한다 — 포커스를 받을 수 있는(focus_mode != NONE) 노드에 표시를 붙인다.
func _dump(n: Node, d: int) -> void:
	if d > 10:
		return
	var ctl := n as Control
	var cls := n.get_class()
	# 🛑 뷰포트 계열만 본다. 전부 찍으면 버튼 수백 개에 묻혀 정작 찾는 것이 안 보인다.
	if cls.contains("Viewport"):
		var mark := "  ← 포커스 가능" if ctl != null and ctl.focus_mode != Control.FOCUS_NONE else ""
		_log("%s%s [%s]%s" % ["  ".repeat(d), n.name, cls, mark])
	for c in n.get_children():
		_dump(c, d + 1)


## 씬 독(Scene dock)의 트리. 사람이 "씬 패널 빈 공간을 클릭" 했을 때 포커스가 가는 곳이다.
func _find_scene_tree(node: Node, depth: int = 0) -> Control:
	if depth > 30:
		return null
	for c in node.get_children():
		if c.get_class() == "SceneTreeEditor":
			for g in c.get_children():
				if g.get_class() == "Tree":
					return g as Control
		var found := _find_scene_tree(c, depth + 1)
		if found != null:
			return found
	return null


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


## 🛑 `grab_focus()` 가 아니라 **실제 마우스 클릭**을 넣는다.
##
##   2026-09-04 실측 — `grab_focus()` 로 포커스만 옮기면 `_shortcut_input` 이 3D 뷰포트에서도
##   정상 도달해 **버그가 재현되지 않는다.** 사람이 겪은 것은 "뷰포트를 클릭한 뒤" 이고,
##   클릭은 포커스 말고도 뷰포트의 내부 상태를 바꾼다. 재현하지 못하는 검증은 통과해도
##   의미가 없으므로, 마우스를 그 위로 옮기고 실제로 누른다.
func _click(ctl: Control) -> void:
	var center := ctl.get_global_rect().get_center()
	Input.warp_mouse(center)
	await _wait(0.25)
	for pressed in [true, false]:
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		mb.position = center
		mb.global_position = center
		mb.pressed = pressed
		Input.parse_input_event(mb)
		await _wait(0.2)
	await _wait(0.3)


## 주어진 위젯을 클릭한 뒤 `0` 을 눌러 단계가 도는지 본다.
func _check(label: String, target: Control) -> void:
	if target == null:
		_log("%s 건너뜀 — 위젯을 못 찾았다" % label)
		return
	await _click(target)
	var holder := EditorInterface.get_base_control().get_viewport().gui_get_focus_owner()
	var before := _mode()
	_press_zero()
	await _wait(0.7)
	var after := _mode()
	_log("%s %d → %d   %s   (포커스: %s)" % [label, before, after,
		"✅ 전환됨" if after != before else "❌ 안 바뀜",
		holder.get_class() if holder != null else "<없음>"])


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(SECTION_ARG):
			_section = a.substr(SECTION_ARG.length())
	await _wait(3.0)
	var scene := "res://test_scene.tscn"
	for a in OS.get_cmdline_user_args():
		if a.begins_with(SCENE_ARG):
			scene = a.substr(SCENE_ARG.length())
	EditorInterface.open_scene_from_path(scene)
	await _wait(2.0)
	EditorInterface.set_main_screen_editor("3D")
	await _wait(1.5)

	var root := EditorInterface.get_edited_scene_root()
	_log("씬 열림: %s" % (root.name if root != null else "<없음>"))

	var base := EditorInterface.get_base_control()
	var vp := _find_viewport(base)
	var dock := _find_scene_tree(base)
	_log("3D 뷰포트: %s / 씬 독 트리: %s" % [
		"찾음" if vp != null else "🛑 못 찾음", "찾음" if dock != null else "🛑 못 찾음"])

	# ── ① 사람이 겪은 그 증상. 3D 뷰포트를 클릭한 상태에서 0 을 누른다.
	await _check("① 3D 뷰포트 포커스", vp)

	# ── ② 원래 되던 경로가 살아 있는가. 씬 패널을 클릭한 상태에서 0 을 누른다.
	await _check("② 씬 독 포커스   ", dock)

	# ── ③ 뷰포트에서 세 번 연타하면 세 단계를 정확히 밟는가.
	#     🛑 처음과 끝만 비교하면 **한 번도 안 돈 것(0회)** 과 **한 바퀴(3회)** 가 똑같이
	#        보인다. 매번의 값을 다 적어 실제로 걸어간 경로를 남긴다.
	if vp != null:
		await _click(vp)
		var path: PackedStringArray = [str(_mode())]
		for i in 3:
			_press_zero()
			await _wait(0.6)
			path.append(str(_mode()))
		var walked := " → ".join(path)
		var ok := path[0] != path[1] and path[1] != path[2] and path[2] != path[3] and path[0] == path[3]
		_log("③ 뷰포트 3회 연타  %s   %s" % [walked,
			"✅ 세 단계를 정확히 한 바퀴" if ok else "❌ 어긋남 — 안 돌았거나 한 키를 두 번 셌다"])

	var out := "user://probe_result.txt"
	for a in OS.get_cmdline_user_args():
		if a.begins_with(OUT_ARG):
			out = a.substr(OUT_ARG.length())
	var f := FileAccess.open(out, FileAccess.WRITE)
	# 🛑 판정을 사람 눈이 아니라 숫자로 낸다. `❌`·`🛑` 가 한 줄이라도 있으면 실패다.
	var failed := 0
	for line in _lines:
		if line.contains("❌") or line.contains("🛑"):
			failed += 1
	_lines.append("═══ 실패 %d 건 ═══" % failed)
	print("[검증] ═══ 실패 %d 건 ═══" % failed)
	f.store_string("\n".join(_lines))
	f.close()
	await _wait(0.3)
	get_tree().quit()
