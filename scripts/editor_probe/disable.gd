@tool
## 플러그인을 **끄면 보조선이 정말 사라지는가**, 다시 켜면 돌아오는가.
##
## 🛑 왜 따로 확인하는가 — 사람이 `Project Settings > Plugins` 에서 체크를 해제하면
##   `_exit_tree()` 가 불린다. 그런데 거기서 **자기가 붙인 노드 하나(`_current`)만** 떼면,
##   어떤 이유로 그 참조를 잃은 보조선은 **화면에 그대로 남는다.** 그러면 사람 눈에는
##   "껐는데 안 꺼진다" 로 보이고, 플러그인이 죽었으니 `0` 키로도 못 지운다.
##
## 🛑 자기 자신을 끄지 않는다 — 끄는 순간 코드가 죽어 다시 켤 수 없다
##   (2026-09-04 실제로 그렇게 되어 `project.godot` 을 손으로 고쳤다).
##   그래서 **별도 플러그인인 이 스크립트가** 대상 플러그인을 끈다.
extends EditorPlugin

const OUT_ARG := "--probe-out="
const TARGET_ARG := "--probe-target="
const GROUP_ARG := "--probe-group="
const SCENE_ARG := "--probe-scene="
## 손으로 넣어 볼 보조선 스크립트. 애드온마다 다르므로 인자로 받는다.
const SCRIPT_ARG := "--probe-script="

var _lines: PackedStringArray = []
var _target := "editor_compass"
var _group := "editor_compass"


func _enter_tree() -> void:
	call_deferred("_run")
	call_deferred("_deadline")


func _deadline() -> void:
	await get_tree().create_timer(120.0).timeout
	_log("🛑 시간이 다 됐다 — 여기서 끝낸다")
	_save()
	get_tree().quit()


func _log(s: String) -> void:
	_lines.append(s)
	print("[끄기검증] ", s)


func _arg(key: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(key):
			return a.substr(key.length())
	return fallback


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


## 지금 화면에 **살아 있는** 보조선의 수.
##
## 🛑 `queue_free()` 로 예약만 된 것을 "있다" 고 세면 안 된다 — 프레임 끝에 사라진다.
func _alive() -> int:
	var n := 0
	for x in get_tree().get_nodes_in_group(_group):
		if is_instance_valid(x) and not x.is_queued_for_deletion():
			n += 1
	return n


## 에디터의 모든 `PopupMenu` 를 훑어 이 플러그인이 넣은 항목을 찾는다.
##
## 🔑 `Project > Tools` 팝업을 경로로 집으려 하지 않는다 — 에디터 버전마다 구조가 다르다.
##    항목 **글자**로 찾는 편이 버전에 덜 흔들린다.
func _scan_menus(node: Node, out: PackedStringArray, depth: int) -> void:
	if depth > 12:
		return
	var pm := node as PopupMenu
	if pm != null:
		for i in pm.item_count:
			var t := pm.get_item_text(i)
			if t.contains("Overlay") or t.contains("Compass") or t.contains("보조선"):
				out.append(t)
	for c in node.get_children():
		_scan_menus(c, out, depth + 1)


func _run() -> void:
	# 🛑 에디터는 유휴 상태에서 프레임을 거의 돌리지 않는다. 켜지 않으면 await 가 흐르지 않는다.
	OS.low_processor_usage_mode = false
	var st := EditorInterface.get_editor_settings()
	if st != null:
		st.set("interface/editor/update_continuously", true)

	_target = _arg(TARGET_ARG, _target)
	_group = _arg(GROUP_ARG, _group)
	await _wait(3.0)
	EditorInterface.open_scene_from_path(_arg(SCENE_ARG, "res://test_scene.tscn"))
	await _wait(2.5)
	EditorInterface.set_main_screen_editor("3D")
	await _wait(1.5)

	# 🔑 사람이 손으로 넣은 보조선을 하나 더 만든다.
	#    플러그인이 자기가 붙인 것 하나만 떼면 **이것이 남는다** — 그때 사람 눈에는
	#    "껐는데 안 꺼진다" 로 보이고, 플러그인이 죽어 `0` 키로도 못 지운다.
	var root := EditorInterface.get_edited_scene_root()
	if root != null:
		var extra := Node3D.new()
		extra.name = "손으로넣은보조선"
		extra.set_script(load(_arg(SCRIPT_ARG, "res://addons/editor_compass/compass.gd")))
		root.add_child(extra)
		await _wait(1.0)

	# ── 메뉴가 실제로 `Project > Tools` 에 등록됐는가 · 그 글자가 영어인가.
	#    🛑 파일에 영어가 적혀 있다는 것과 **메뉴에 실제로 나타난다**는 것은 다른 문제다.
	var found: PackedStringArray = []
	_scan_menus(EditorInterface.get_base_control(), found, 0)
	var korean := RegEx.create_from_string("[가-힣]")
	var bad: PackedStringArray = []
	for item in found:
		if korean.search(item) != null:
			bad.append(item)
	_log("⓪ Project > Tools 항목  %s   %s" % [str(found),
		"✅ 등록됐고 전부 영어다" if found.size() >= 2 and bad.is_empty()
		else ("❌ 한글이 있다: " + str(bad) if not bad.is_empty() else "❌ 항목을 못 찾았다")])

	var before := _alive()
	_log("① 켜져 있을 때        보조선 %d개   %s" % [before,
		"✅ 둘 다 보인다" if before >= 2 else "❌ %d개뿐 — 손으로 넣은 것이 안 붙었다" % before])

	# ── 끈다. 사람이 Project Settings 에서 체크를 해제하는 것과 같은 경로다.
	EditorInterface.set_plugin_enabled(_target, false)
	await _wait(1.5)
	var off := _alive()
	_log("② 껐을 때            보조선 %d개   %s" % [off,
		"✅ 사라졌다" if off == 0 else "❌ 남아 있다 — 껐는데 안 꺼진다"])

	# ── 다시 켠다. 껐다가 못 켜면 그것도 결함이다.
	EditorInterface.set_plugin_enabled(_target, true)
	await _wait(2.0)
	var on_again := _alive()
	_log("③ 다시 켰을 때        보조선 %d개   %s" % [on_again,
		"✅ 돌아왔다" if on_again > 0 else "❌ 안 돌아온다 — 한번 끄면 못 켠다"])

	_save()
	await _wait(0.3)
	get_tree().quit()


func _save() -> void:
	var failed := 0
	for line in _lines:
		if line.contains("❌") or line.contains("🛑"):
			failed += 1
	_lines.append("═══ 실패 %d 건 ═══" % failed)
	print("[끄기검증] ═══ 실패 %d 건 ═══" % failed)
	var f := FileAccess.open(_arg(OUT_ARG, "user://disable_result.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines))
		f.close()
