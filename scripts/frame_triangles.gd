## 씬을 실제로 띄워, 한 프레임에 GPU 가 그린 삼각형·드로우콜을 잰다 (창이 잠깐 뜬다).
##
##   godot --path . --resolution 1280x720 -s res://tests/frame_triangles.gd -- res://scenes/main/main.tscn
##
## 🛑 tools/count_triangles.gd 와 세는 것이 다르다. 둘을 나란히 봐야 판단이 선다.
##   tools/count_triangles.gd   씬 안에 존재하는 삼각형 총합   — 카메라·컬링과 무관한 "만들어 둔 양"
##   이 스크립트                 그 프레임에 실제로 그린 삼각형 — 컬링·LOD·그림자가 반영된 "지금 내는 비용"
##
## Viewport.get_render_info(type, info) 로 재면 그림자 패스를 분리할 수 있다(Performance 모니터는 합계만 준다).
##   RENDER_INFO_TYPE_VISIBLE  카메라에 보이는 것을 그린 패스
##   RENDER_INFO_TYPE_SHADOW   그림자 맵을 그린 패스 — 같은 메시를 광원 수만큼 다시 그린다
##   RENDER_INFO_TYPE_CANVAS   2D·UI 패스
extends SceneTree

## 몇 프레임을 흘려보낸 뒤 잴 것인가. 첫 프레임은 리소스 로드·셰이더 컴파일 중이라 값이 요동친다.
const WARMUP_FRAMES := 30


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := args[0] if args.size() > 0 else String(ProjectSettings.get_setting("application/run/main_scene", ""))
	if scene_path == "":
		printerr("잴 씬이 없다. 인자로 res:// 경로를 준다.")
		quit(1)
		return

	var err := change_scene_to_file(scene_path)
	if err != OK:
		printerr("씬을 열지 못했다(%d): %s" % [err, scene_path])
		quit(1)
		return

	for i in WARMUP_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var vp := root
	var visible_tris := vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
	var shadow_tris := vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
	var canvas_tris := vp.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
	var visible_calls := vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var shadow_calls := vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var objects := vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME)

	print("═══ %s  (%dx%d)" % [scene_path, vp.size.x, vp.size.y])
	print("  보이는 패스   삼각형 %9s   드로우콜 %5d   오브젝트 %d" % [_comma(visible_tris), visible_calls, objects])
	print("  그림자 패스   삼각형 %9s   드로우콜 %5d" % [_comma(shadow_tris), shadow_calls])
	print("  2D·UI 패스    삼각형 %9s" % _comma(canvas_tris))
	print("  ─────────────────────────────────────────────")
	print("  전체(3D)      삼각형 %9s   드로우콜 %5d" % [_comma(visible_tris + shadow_tris), visible_calls + shadow_calls])
	print("")
	print("  Performance 합계 대조 — tris %s · draw %d · fps %.0f" % [
		_comma(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		Performance.get_monitor(Performance.TIME_FPS)])
	quit()


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
