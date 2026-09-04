## 씬에 들어 있는 삼각형·서피스를 전부 세어 준다 — 카메라와 무관한 "정적 총량".
##
## 실행 (에디터를 열지 않는다)
##   godot --headless --path . -s res://tools/count_triangles.gd -- res://scenes/main/main.tscn
##   godot --headless --path . -s res://tools/count_triangles.gd -- --all          # scenes/ 아래 .tscn 전부
##   godot --headless --path . -s res://tools/count_triangles.gd -- <씬> --json out.json --top 20
##
## 🛑 런타임 디버그 패널(scenes/ui/debug_panel.gd)의 `tris` 와 다른 것을 센다. 헷갈리면 안 된다.
##   이 도구      씬 안에 존재하는 삼각형의 총합            — 컬링·LOD·화면 밖과 무관
##   디버그 패널  그 프레임에 GPU 가 실제로 그린 삼각형 수  — 컬링·그림자 패스가 반영된다
##   그래서 이 도구의 값은 언제나 패널의 값보다 크거나 같다. 예산을 짤 때는 이 값, 병목을 볼 때는 패널 값.
##
## 세는 방법 — ArrayMesh 는 배열을 복사하지 않고 길이만 읽는다(surface_get_array_index_len).
## glTF 임포트 결과가 전부 ArrayMesh 라서, 실제 게임 에셋은 이 빠른 경로를 탄다.
extends SceneTree

## 결과 표에서 노드 경로를 몇 자까지 보일지. 넘으면 앞을 자른다.
const PATH_WIDTH := 62

var _rows: Array[Dictionary] = []       # 노드 하나당 한 줄
var _by_kind: Dictionary = {}           # 노드 종류 → {"nodes": n, "tris": n, "surfaces": n}
var _notes: Array[String] = []          # 근사치로 센 것들의 주석


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var scenes: Array[String] = []
	var json_out := ""
	var top := 12

	var i := 0
	while i < args.size():
		var a := args[i]
		match a:
			"--json":
				i += 1
				json_out = args[i] if i < args.size() else ""
			"--top":
				i += 1
				top = int(args[i]) if i < args.size() else top
			"--all":
				scenes.append_array(_find_scenes("res://scenes"))
			_:
				if a.begins_with("--"):
					printerr("모르는 옵션: %s" % a)
				else:
					scenes.append(a)
		i += 1

	if scenes.is_empty():
		var main_scene := String(ProjectSettings.get_setting("application/run/main_scene", ""))
		if main_scene == "":
			printerr("셀 씬이 없다. 씬 경로를 인자로 주거나 --all 을 쓴다.")
			quit(1)
			return
		scenes.append(main_scene)
		print("(인자가 없어 main_scene 을 센다: %s)\n" % main_scene)

	var report := {"scenes": [], "godot": Engine.get_version_info().string}
	for path in scenes:
		var one := _count_scene(path, top)
		if not one.is_empty():
			report["scenes"].append(one)

	if scenes.size() > 1:
		_print_totals(report)

	if json_out != "":
		var f := FileAccess.open(json_out, FileAccess.WRITE)
		if f == null:
			printerr("JSON 을 쓰지 못했다: %s" % json_out)
		else:
			f.store_string(JSON.stringify(report, "  "))
			f.close()
			print("\nJSON 저장: %s" % json_out)
	quit()


# ── 씬 하나 ────────────────────────────────────────────────

func _count_scene(path: String, top: int) -> Dictionary:
	_rows.clear()
	_by_kind.clear()
	_notes.clear()

	if not ResourceLoader.exists(path):
		printerr("씬이 없다: %s" % path)
		return {}
	var packed := load(path) as PackedScene
	if packed == null:
		printerr("씬을 열지 못했다: %s" % path)
		return {}

	# 🛑 instantiate() 만 하고 트리에 넣지 않는다 — _ready() 가 돌면 네트워크 접속 같은 것이 시작된다.
	#    메시는 노드가 트리 밖에 있어도 그대로 들어 있으므로 세는 데 지장이 없다.
	var root := packed.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
	_walk(root, root)
	root.free()

	var tris := 0
	var surfaces := 0
	var nodes := 0
	for k in _by_kind:
		tris += int(_by_kind[k]["tris"])
		surfaces += int(_by_kind[k]["surfaces"])
		nodes += int(_by_kind[k]["nodes"])

	print("═══ %s" % path)
	print("합계   삼각형 %s · 서피스 %s · 메시를 가진 노드 %d개" % [_comma(tris), _comma(surfaces), nodes])
	print("       (서피스 수 = 컬링을 무시했을 때의 최소 드로우콜)")

	print("\n종류별")
	var kinds := _by_kind.keys()
	kinds.sort_custom(func(a, b): return int(_by_kind[a]["tris"]) > int(_by_kind[b]["tris"]))
	for k in kinds:
		var d: Dictionary = _by_kind[k]
		print("  %-24s %4d개   삼각형 %12s   서피스 %5d" % [k, int(d["nodes"]), _comma(int(d["tris"])), int(d["surfaces"])])

	_rows.sort_custom(func(a, b): return int(a["tris"]) > int(b["tris"]))
	var n: int = min(top, _rows.size())
	if n > 0:
		print("\n무거운 노드 상위 %d" % n)
		for j in n:
			var r: Dictionary = _rows[j]
			var pct := 0.0 if tris == 0 else float(r["tris"]) / float(tris) * 100.0
			print("  %2d. %12s  %5.1f%%  %s%s" % [
				j + 1, _comma(int(r["tris"])), pct, _short(String(r["path"])),
				"" if String(r["note"]) == "" else "  ← " + String(r["note"])])

	if not _notes.is_empty():
		print("\n주의")
		for note in _notes:
			print("  · %s" % note)
	print("")

	return {
		"scene": path, "triangles": tris, "surfaces": surfaces, "mesh_nodes": nodes,
		"by_kind": _by_kind.duplicate(true),
		"nodes": _rows.duplicate(true),
	}


# ── 노드 순회 ──────────────────────────────────────────────

func _walk(node: Node, root: Node) -> void:
	var kind := node.get_class()
	var tris := 0
	var surfaces := 0
	var note := ""

	if node is MeshInstance3D:
		var m: Mesh = (node as MeshInstance3D).mesh
		if m != null:
			tris = _mesh_tris(m)
			surfaces = m.get_surface_count()
			note = _res_name(m)

	elif node is MultiMeshInstance3D:
		var mm: MultiMesh = (node as MultiMeshInstance3D).multimesh
		if mm != null and mm.mesh != null:
			var per := _mesh_tris(mm.mesh)
			var count: int = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			tris = per * count
			surfaces = mm.mesh.get_surface_count()      # MultiMesh 는 인스턴스가 몇이든 드로우콜 1
			note = "%s × %d 인스턴스" % [_res_name(mm.mesh), count]

	elif node is GridMap:
		var gm := node as GridMap
		var lib: MeshLibrary = gm.mesh_library
		if lib != null:
			var cache := {}
			for cell in gm.get_used_cells():
				var item := gm.get_cell_item(cell)
				if item == GridMap.INVALID_CELL_ITEM:
					continue
				if not cache.has(item):
					var im := lib.get_item_mesh(item)
					cache[item] = [0, 0] if im == null else [_mesh_tris(im), im.get_surface_count()]
				tris += int(cache[item][0])
				surfaces += int(cache[item][1])
			note = "셀 %d개" % gm.get_used_cells().size()

	elif node is CSGShape3D:
		var csg := node as CSGShape3D
		if csg.is_root_shape():
			# get_meshes() → [Transform3D, Mesh]. 불리언 연산을 끝낸 결과라 자식 CSG 가 전부 반영돼 있다.
			var meshes := csg.get_meshes()
			if meshes.size() >= 2 and meshes[1] is Mesh:
				var cm: Mesh = meshes[1]
				tris = _mesh_tris(cm)
				surfaces = cm.get_surface_count()
				note = "CSG 결과(자식 포함)"
			_notes.append("CSG 는 런타임 CPU 계산이다. 출시 전에 bake_static_mesh() 로 굳힌다 (%s)" % _short(_path_of(node, root)))

	elif node is GPUParticles3D:
		var p := node as GPUParticles3D
		var per := 0
		var sf := 0
		for pass_i in p.draw_passes:
			var pm := p.get_draw_pass_mesh(pass_i)
			if pm != null:
				per += _mesh_tris(pm)
				sf += pm.get_surface_count()
		tris = per * p.amount
		surfaces = sf
		note = "입자 %d개 × 패스 %d" % [p.amount, p.draw_passes]

	elif node is CPUParticles3D:
		var cp := node as CPUParticles3D
		if cp.mesh != null:
			tris = _mesh_tris(cp.mesh) * cp.amount
			surfaces = cp.mesh.get_surface_count()
			note = "입자 %d개" % cp.amount

	elif node is Sprite3D or node is AnimatedSprite3D:
		tris = 2
		surfaces = 1
		note = "판 1장"

	elif node is Label3D:
		# 글자 하나가 사각형 1장(삼각형 2개). 정확한 값은 텍스트·폰트에 따라 달라져 근사로 센다.
		var txt := (node as Label3D).text.strip_edges()
		tris = txt.length() * 2
		surfaces = 1
		note = "글자 %d자 (근사)" % txt.length()
		if txt.length() > 0:
			_notes.append("Label3D 는 글자 수 × 2 로 근사했다 (%s)" % _short(_path_of(node, root)))

	if tris > 0 or surfaces > 0:
		var p := _path_of(node, root)
		_rows.append({"path": p, "kind": kind, "tris": tris, "surfaces": surfaces,
			"visible": (node as Node3D).visible if node is Node3D else true, "note": note})
		if not _by_kind.has(kind):
			_by_kind[kind] = {"nodes": 0, "tris": 0, "surfaces": 0}
		_by_kind[kind]["nodes"] = int(_by_kind[kind]["nodes"]) + 1
		_by_kind[kind]["tris"] = int(_by_kind[kind]["tris"]) + tris
		_by_kind[kind]["surfaces"] = int(_by_kind[kind]["surfaces"]) + surfaces

	for c in node.get_children():
		_walk(c, root)


# ── 메시 하나의 삼각형 수 ──────────────────────────────────

func _mesh_tris(m: Mesh) -> int:
	var total := 0
	if m is ArrayMesh:
		# 빠른 길 — 배열을 복사하지 않고 길이만 읽는다. glTF 임포트 결과가 여기에 해당한다.
		var am := m as ArrayMesh
		for i in am.get_surface_count():
			if am.surface_get_primitive_type(i) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var idx_len := am.surface_get_array_index_len(i)
			total += (idx_len if idx_len > 0 else am.surface_get_array_len(i)) / 3
		return total
	if m is PointMesh:
		return 0                                   # 점 하나짜리라 삼각형이 없다
	# PrimitiveMesh(BoxMesh 등) 은 길이 API 가 없어 배열을 받아 센다.
	for i in m.get_surface_count():
		var a := m.surface_get_arrays(i)
		if a.is_empty():
			continue
		var idx = a[Mesh.ARRAY_INDEX]
		if idx != null and (idx as PackedInt32Array).size() > 0:
			total += (idx as PackedInt32Array).size() / 3
		else:
			total += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total


# ── 도우미 ────────────────────────────────────────────────

func _find_scenes(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if name.begins_with("."):
			name = d.get_next()
			continue
		var full := dir_path.path_join(name)
		if d.current_is_dir():
			out.append_array(_find_scenes(full))
		elif name.ends_with(".tscn"):
			out.append(full)
		name = d.get_next()
	d.list_dir_end()
	out.sort()
	return out


func _path_of(node: Node, root: Node) -> String:
	if node == root:
		return node.name
	return String(root.get_path_to(node))


func _res_name(r: Resource) -> String:
	if r.resource_path != "":
		return r.resource_path.get_file()
	return r.get_class()


func _short(s: String) -> String:
	return s if s.length() <= PATH_WIDTH else "…" + s.substr(s.length() - PATH_WIDTH + 1)


func _comma(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out


func _print_totals(report: Dictionary) -> void:
	var tris := 0
	var surfaces := 0
	for s in report["scenes"]:
		tris += int(s["triangles"])
		surfaces += int(s["surfaces"])
	print("═══ 전체 %d개 씬 합계 — 삼각형 %s · 서피스 %s" % [
		report["scenes"].size(), _comma(tris), _comma(surfaces)])
	print("    (씬끼리 겹치는 에셋도 각각 센 값이다. 한 화면의 부하가 아니라 '만들어 둔 총량'이다)")
