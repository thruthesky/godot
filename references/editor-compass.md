# 에디터 동서남북 보조선

> **이 문서로 오는 상황** — 3D 씬을 편집하는데 **어느 쪽이 북쪽인지, 원점이 어딘지 모르겠다.**
> 맵을 만들다 보면 방향 감각을 잃고, 카메라를 돌리면 `+X` 가 어디였는지 헷갈린다.
> 씬마다 화살표를 손으로 놓기는 싫고, 놓은 것이 **게임 빌드에 따라가는 것은 더 싫다.**

**그대로 쓸 수 있는 애드온이 이 스킬에 들어 있다** — [`addons/editor_compass/`](../addons/editor_compass/).
폴더를 복사하고 체크 하나만 하면 끝난다. 아래 §1 을 그대로 따라 하면 된다.

## 목차

1. [설치 — 30초](#1-설치--30초)
2. [쓰는 법 — 숫자 `0` 하나](#2-쓰는-법--숫자-0-하나)
3. [무엇이 그려지는가](#3-무엇이-그려지는가)
4. [🛑 단축키는 `_input` 이어야 한다 — 세 번 틀린 자리](#4--단축키는-_input-이어야-한다--세-번-틀린-자리)
5. [🛑 씬 파일에 저장되지 않게 하는 법 — `owner`](#5--씬-파일에-저장되지-않게-하는-법--owner)
6. [🛑 게임 빌드에 따라가지 않게 하는 법](#6--게임-빌드에-따라가지-않게-하는-법)
7. [씬 크기에 맞춰 저절로 커지고 작아진다 · 🛑 굵기는 화면 픽셀로](#7-씬-크기에-맞춰-저절로-커지고-작아진다)
8. [자주 하는 실수](#8-자주-하는-실수)
9. [검증하는 법 — 눌러 보지 않고](#9-검증하는-법--눌러-보지-않고)
10. [프로젝트에 맞게 고치기](#10-프로젝트에-맞게-고치기)

---

## 1. 설치 — 30초

```bash
# ① 이 스킬의 애드온 폴더를 프로젝트로 통째로 복사한다
cp -R .claude/skills/godot/addons/editor_compass <프로젝트>/addons/
```

② Godot 에디터 → `Project > Project Settings > Plugins` → **Editor Compass** 체크

끝이다. 3D 씬을 열면 보조선이 스스로 나타난다. **씬을 고칠 필요도, 노드를 놓을 필요도 없다.**

`project.godot` 을 직접 고쳐도 된다.

```ini
[editor_plugins]

enabled=PackedStringArray("res://addons/editor_compass/plugin.cfg")
```

---

## 2. 쓰는 법 — 숫자 `0` 하나

3D 화면에서 **숫자 `0`** 을 누를 때마다 세 단계를 돈다.

| 단계 | 보이는 것 | 언제 쓰나 |
|---|---|---|
| **화살표 + 격자** | 전부 | 방향을 확인할 때 |
| **격자만** | 화살표 숨김 | 배치 작업 중 — **격자는 계속 필요하지만** 방향은 한 번 보면 그만이다 |
| **전부 숨김** | 없음 | 완성된 그림을 볼 때 |

지금 몇 단계인지는 **출력 콘솔**에 찍힌다. 상태는 프로젝트별로 저장되어 에디터를 껐다 켜도 유지된다.

> 🔑 **중간 단계를 두는 이유** — "켜기/끄기" 둘뿐이면, 격자를 보려고 켤 때마다 화살표가
> 같이 나와 시야를 가린다. 실제 작업에서 필요한 것은 대개 **격자만**이다.

### 🛑 표시되는 글자는 **전부 영어**로 둔다

에디터 플러그인이 화면에 내보내는 글자는 다섯 군데다. **하나라도 빠뜨리기 쉽다.**

| 어디 | 무엇 |
|---|---|
| `plugin.cfg` 의 `name`·`description` | `Project Settings > Plugins` 목록 |
| `add_tool_menu_item()` 의 이름 | `Project > Tools` 메뉴 |
| 자동으로 붙이는 노드 이름 | 씬 독 |
| `print()` | 출력 콘솔 |
| `Label3D.text` | 3D 뷰포트 |

**🛑 주석은 바꾸지 않는다.** 바꾸는 것은 **표시되는 값**뿐이다.

이유 셋 — ① 에디터 UI 언어와 섞이면 읽기 나쁘다 · ② 한글 폰트가 없는 환경에서
**네모로 깨진다** · ③ 개발자만 보는 글자라 번역 대상이 아니다.

> 🔑 **검사는 파일 텍스트 + 실제 메뉴 둘 다 본다.** 파일에 영어가 적혀 있다는 것과
> **메뉴에 실제로 그렇게 나타난다**는 것은 다른 문제다. 에디터의 모든 `PopupMenu` 를
> 훑어 항목 글자를 확인한다 — `Project > Tools` 팝업을 **경로로 집지 않는다**
> (버전마다 구조가 다르다). 위 `editor_disable_probe.sh` 의 ⓪ 이 그것이다.

### 끄는 방법은 셋 — 위에서부터 쓴다

| 방법 | 어떻게 | 언제 |
|---|---|---|
| **숫자 `0`** | 눌러서 **전부 숨김** 까지 돌린다 | **거의 항상 이것.** 상태가 저장되고 `0` 만 누르면 돌아온다 |
| **메뉴** | `Project > Tools > Compass - Hide All` | 단축키가 기억나지 않을 때. `0` 과 **같은 함수**를 부른다 |
| **플러그인을 끈다** | `Project > Project Settings > Plugins` → **`Enabled` 체크 해제** | 한동안 아예 안 쓸 때 |

> 🔑 **메뉴를 반드시 함께 둔다.** 단축키만 있으면 **그것을 모르는 사람은 끌 방법이 없다.**
> 2026-09-05 에 실제로 "disable 시키려면 어떻게 하나요" 라는 질문을 받았다.
>
> ```gdscript
> func _enter_tree() -> void:
> 	add_tool_menu_item(MENU_HIDE, _on_menu_hide)     # Project > Tools 에 나타난다
>
> func _exit_tree() -> void:
> 	remove_tool_menu_item(MENU_HIDE)                 # 🛑 떼지 않으면 항목이 쌓인다
> ```

### 🛑 끌 때는 **그룹 전체**를 떼어 낸다 — `_current` 하나로는 부족하다

`_exit_tree()` 에서 자기가 붙인 노드 하나만 떼면, **손으로 넣은 보조선은 화면에 남는다.**
그러면 사람 눈에는 *"껐는데 안 꺼진다"* 로 보이고, **플러그인이 죽었으니 `0` 키로도 못 지운다.**

```gdscript
func _exit_tree() -> void:
	_detach()          # 자기가 붙인 것
	_remove_all()      # 🛑 그룹에 등록된 나머지 전부
```

실측(2026-09-05) — `_remove_all()` 없이 껐더니 **1개가 남았다.**
넣은 뒤에는 자동 1개 + 손으로 넣은 1개가 **둘 다 사라졌고**, 다시 켜니 자동 1개가 돌아왔다.

**반응하지 않는 경우가 셋 있다. 전부 의도된 것이다.**

| 안 될 때 | 왜 |
|---|---|
| 이름 바꾸기·검색창·스크립트 편집 중 | 글자로 친 `0` 을 빼앗지 않는다 |
| 2D·스크립트·에셋 화면 | 3D 화면에만 보조선이 있다 |
| `Cmd+0` · `Ctrl+0` · 넘패드 `0` | 기존 단축키(배율 초기화 등)를 빼앗지 않는다 |

---

## 3. 무엇이 그려지는가

```
           N (-Z)
             ▲
             │
   0,0       │
      ○──────┼──────▶ E (+X)
             │
             │
             ▼
           S (+Z)
```

| 요소 | 내용 |
|---|---|
| **네 방향 화살표** | 대 + **채운 삼각형** 머리. 색으로도 구분한다 — N 민트 · E 주홍 · S 보라 · W 파랑 |
| **영문 라벨** | `N` `E` `S` `W`. `Label3D` + `fixed_size` 라 **배율과 무관하게 같은 크기**로 읽힌다 |
| **원점 표시** | `0, 0` 글자와 작은 원반 |
| **격자** | 방향축을 기준으로 한 칸씩. 거리 감각을 준다 |

**방향 규약은 Godot 기본 그대로다.**

| | |
|---|---|
| 북 | `-Z` |
| 남 | `+Z` |
| 동 | `+X` |
| 서 | `-X` |
| 위 | `+Y` |

> 🔑 **왜 `-Z` 가 북인가** — Godot 카메라의 기본 전방이 `-Z` 다. 그쪽을 북으로 삼으면
> "카메라가 보는 쪽이 북" 이 되어 가장 헷갈리지 않는다. 다른 규약을 쓰는 프로젝트라면
> `compass.gd` 의 `_compass()` 에서 색과 글자만 바꾸면 된다.

**화살촉을 선 두 개로 그리지 않는다.** `<` 모양이 되어 화살표가 아니라 꺾쇠로 보인다.
`PrismMesh`(삼각기둥)를 눕히면 위에서 볼 때 **채워진 삼각형**이 된다.

```gdscript
# 🛑 PrismMesh 의 삼각형은 XY 평면에 서 있고 +Y 가 뾰족한 쪽이다.
#    바닥(XZ)에 눕히려면 X축으로 −90°, 그러면 뾰족한 쪽이 -Z(북)를 향한다.
#    거기서 방향만큼 더 돌린다.
var yaw := -atan2(dir.x, -dir.y)
var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -PI * 0.5)
```

> 🛑 **회전 두 번을 `rotation` 속성으로 주면 어긋난다.** `rotation` 은 **YXZ 순서**로 적용되어
> 의도한 결과가 나오지 않는다. `Basis` 를 직접 곱한다.
> 검산 — 북 `(0,−1)`→`0` · 동 `(1,0)`→`−90°` · 남 `(0,1)`→`180°` · 서 `(−1,0)`→`+90°`

---

## 4. 🛑 단축키는 `_input` 이어야 한다 — 세 번 틀린 자리

**이 절이 이 문서에서 가장 값진 부분이다.** 같은 버그를 세 번 고치고 세 번 다
"고쳤다" 고 보고했는데 사람이 누르면 안 됐다.

### 실측 결과 (Godot 4.7 · macOS · 2026-09-04)

**3D 뷰포트를 마우스로 클릭한 뒤** 숫자 `0` 을 누르면:

| 콜백 | 결과 | 왜 |
|---|---|---|
| `_unhandled_key_input` | ❌ | **"아무도 안 먹은 키" 만 온다.** 뷰포트가 먼저 가져간다 |
| `_shortcut_input` | ❌ | GUI 처리 **앞**이지만, 뷰포트를 클릭하면 그 안의 `Control` 이 포커스를 쥐어 오지 않는다 |
| `_forward_3d_gui_input` | ❌ | `_handles()` 가 **선택된 노드**를 볼 때만 플러그인이 활성화된다. **빈 곳을 클릭하면 선택이 풀려 함수 자체가 죽는다** |
| **`_input`** | ✅ | `Viewport::push_input` 의 **가장 앞**이라 누가 포커스를 갖든 먼저 온다 |

```gdscript
func _enter_tree() -> void:
	set_process_input(true)      # 🛑 이 줄이 없으면 _input 이 호출되지 않는다

func _input(event: InputEvent) -> void:
	if not _is_my_key(event):
		return
	if _is_typing():             # _input 은 GUI 보다 먼저라 위젯이 막아 주지 않는다
		return
	if not _is_3d_screen():
		return
	_do_something()
	get_viewport().set_input_as_handled()
```

### 🛑 함정 — `grab_focus()` 로 시험하면 버그가 재현되지 않는다

**이것 때문에 세 번 다 "검증 통과" 였다.**

```gdscript
viewport.grab_focus()        # ← 이렇게 시험하면 _shortcut_input 도 통과한다
```

포커스만 옮기는 것과 **실제로 클릭하는 것**은 다르다. 클릭은 뷰포트 내부 상태까지 바꾼다.
반드시 마우스를 그 위로 옮기고 실제 버튼 이벤트를 넣어야 재현된다.

```gdscript
Input.warp_mouse(ctl.get_global_rect().get_center())
var mb := InputEventMouseButton.new()
mb.button_index = MOUSE_BUTTON_LEFT
mb.position = center
mb.global_position = center
mb.pressed = true
Input.parse_input_event(mb)   # 뗄 때도 한 번 더
```

> **재현하지 못하는 검증은 통과해도 의미가 없다.**

### 🛑 `_handles()` 를 함부로 `true` 로 두지 않는다

```gdscript
func _handles(_object: Object) -> bool:
	return true               # 🛑 하지 않는다
```

`true` 를 돌려주면 EditorNode 가 이 플러그인을 **"현재 오브젝트의 편집기"** 로 삼아
`_make_visible()` 을 부르고, **다른 플러그인의 활성화를 방해**한다.
`_forward_3d_gui_input` 을 쓰려고 무심코 넣기 쉬운데, 애초에 그 콜백을 쓸 이유가 없다.

### `_input` 을 쓸 때 반드시 함께 넣는 것

`_input` 은 **모든** 입력을 받는다. 그래서 두 가지를 직접 걸러야 한다.

```gdscript
## 글자를 입력하는 중인가 — 포커스를 가진 위젯으로 판단한다.
func _is_typing() -> bool:
	var focused := EditorInterface.get_base_control().get_viewport().gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit


## 지금 3D 화면인가 — 메인 화면 자식 중 보이는 것 하나가 현재 화면이다.
## 🛑 판별하지 못하면 막지 않는다 — 엔진 버전이 바뀌어도 단축키가 죽지 않게.
func _is_3d_screen() -> bool:
	var main := EditorInterface.get_editor_main_screen()
	if main == null:
		return true
	for c in main.get_children():
		var ctl := c as Control
		if ctl != null and ctl.visible:
			return str(ctl.name).contains("Node3DEditor")
	return true
```

### 키 판정은 `static func` 로 뺀다

```gdscript
static func is_toggle_key(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	if key.ctrl_pressed or key.alt_pressed or key.shift_pressed or key.meta_pressed:
		return false
	return key.keycode == KEY_0
```

> 🔑 **왜 static 인가** — 플러그인 본체에 두면 **에디터를 띄워야만** 시험할 수 있다.
> 밖으로 빼 두면 헤드리스 테스트가 그냥 부를 수 있다.
> `echo`(자동 반복)와 수정키를 거르는 것을 잊기 쉽고, 그 실수는 **누르고 있으면 미친 듯이
> 깜빡이는** 형태로 나타난다.

---

## 5. 🛑 씬 파일에 저장되지 않게 하는 법 — `owner`

보조선을 씬에 넣어 두면 **`.tscn` 에 작업용 노드가 그대로 남는다.** 남이 보면 정체불명이고,
지우는 것을 잊으면 빌드에 따라간다.

**Godot 은 씬을 저장할 때 `owner` 가 씬 루트인 노드만 파일에 기록한다.**

```gdscript
var node := Node3D.new()
node.set_script(COMPASS_SCRIPT)
root.add_child(node)
# 🛑 node.owner 를 설정하지 않는다. 이 한 줄이 없어서 저장되지 않는 것이다.
```

화면에는 보이고 씬 독에도 뜨지만, `Cmd+S` 를 눌러도 **`.tscn` 에는 한 글자도 들어가지 않는다.**

> 이름을 `Compass(자동·저장 안 됨)` 처럼 지어 두면 씬 독에서 본 사람이
> "이건 손으로 넣은 게 아니구나" 를 바로 안다.

---

## 6. 🛑 게임 빌드에 따라가지 않게 하는 법

`@tool` 스크립트는 **게임에서도 돈다.** 숨기는 것만으로는 부족하다.

```gdscript
func _ready() -> void:
	add_to_group(GROUP)
	if not Engine.is_editor_hint():
		queue_free()        # 🛑 visible = false 가 아니다. 존재 자체를 지운다
		return
	_rebuild()
```

| | |
|---|---|
| 🛑 `visible = false` | 노드가 남아 메모리를 먹고, **씬에 저장되면 빌드에 따라간다** |
| ✅ `queue_free()` | 게임에는 애초에 존재하지 않는다 |

---

## 7. 씬 크기에 맞춰 저절로 커지고 작아진다

**고정 미터 값을 쓰면 어느 프로젝트에나 붙일 수 없다.** 1m 짜리 소품 씬과 1,000m 짜리
지형 씬에 같은 크기를 그리면 한쪽은 안 보이고 한쪽은 화면을 다 덮는다.

그래서 씬에 놓인 `VisualInstance3D` 들의 AABB 를 합쳐 크기를 재고, 그 **35%** 를 반경으로 쓴다.

```gdscript
for n in _all_visual_nodes(parent):
	if n == self or is_ancestor_of(n):
		continue                     # 🛑 자기 자신은 재지 않는다 — 재면 계산이 이전 결과에 끌려간다
	aabb = aabb.merge(n.global_transform * n.get_aabb())
return clampf(maxf(aabb.size.x, aabb.size.z) * 0.35, 1.0, 500.0)
```

빈 씬이면 기본값 10m 를 쓴다. 선 굵기·화살촉 크기·글자 간격도 전부 이 반경에 **비례**한다.

---

### 🛑 선 굵기는 **화면 픽셀**로 정한다 — 미터 감각으로 정하면 두꺼워진다

"0.35m 면 얇지" 는 틀린 감각이다. **화면에서 몇 px 로 보이는가**가 사람이 느끼는 두께다.

```
청크 한 변 64m 를 1,280px 화면에 담으면   1m ≈ 20px
  영역선 0.35m → 6.6px    보조선이 아니라 그려 넣은 도로처럼 보인다
  영역선 0.14m → 2.8px    ✅ 가늘다고 느낀다
  격자선 0.06m → 1.2px    ✅
```

| | |
|---|---|
| 상한 | **3px** — 넘으면 배치 작업을 가린다 |
| 하한 | **1px** — 아래로 내려가면 줌 아웃에서 **깜빡이며 사라진다** |

이 애드온은 씬 크기에 비례한 **비율**(`*_RATIO`)로 굵기를 정하므로, 어느 배율에서 보든
화면 비율이 일정하다.

> 🔑 **선을 가늘게 만들면 나침반도 같이 키워야 한다.** 굵기만 줄이면 나침반이 화면에서
> 사라진다(실측 — 청크 대비 20% 짜리 나침반이 선을 얇게 하자 거의 안 보였다).
> 지름이 **작업 영역의 30% 안팎**이면 방향은 읽히고 배치는 가리지 않는다.

---

## 8. 자주 하는 실수

| 증상 | 원인 | 고치는 법 |
|---|---|---|
| **키를 눌러도 반응이 없다** | `_unhandled_key_input`·`_shortcut_input` 을 썼다 | `_input` 으로 바꾼다 (§4) |
| **`set_process_input(true)` 를 안 했다** | `_input` 이 아예 호출되지 않는다 | `_enter_tree()` 에 넣는다 |
| **씬을 바꾸면 보조선이 사라진다** | `queue_free()` 는 **프레임 끝**에 처리되는데, 그 사이에 "이미 있다" 로 세었다 | `is_queued_for_deletion()` 을 함께 보고, 뗄 때 `remove_child()` 로 **즉시** 분리한다 |
| **`.tscn` 에 보조선이 저장됐다** | `owner` 를 설정했다 | 설정하지 않는다 (§5) |
| **게임에 보조선이 나온다** | `visible = false` 로만 숨겼다 | `queue_free()` (§6) |
| **누르고 있으면 미친 듯이 깜빡인다** | `key.echo` 를 안 걸렀다 | 키 판정에서 `echo` 를 거른다 |
| **`Cmd+0` 이 안 먹는다** | 수정키를 안 걸러 보조선이 가로챘다 | 수정키가 하나라도 눌렸으면 무시한다 |
| **화살촉 방향이 제각각이다** | 회전 두 번을 `rotation` 으로 줬다 | `Basis` 를 직접 곱한다 (§3) |
| **글자가 줌 아웃에서 점이 된다** | 3D 메시로 글자를 만들었다 | `Label3D` + `fixed_size = true` |
| **선이 지형에 파묻혀 글자만 보인다** | 선에 깊이 검사가 켜져 있다 | 선 머티리얼에도 `no_depth_test = true` (§7 아래) |
| **선이 도로처럼 두껍다** | 미터 감각으로 정했다 | 화면 픽셀로 계산한다 — 2~3px |
| **글자가 바닥에 파묻힌다** | 깊이 검사가 켜져 있다 | `no_depth_test = true` + `outline_size` |
| **보조선이 자꾸 집힌다** | 잠그지 않았다 | 모든 자식에 `set_meta("_edit_lock_", true)` |
| **조명 없는 씬에서 새까맣다** | 기본 머티리얼이 조명을 받는다 | `SHADING_MODE_UNSHADED` |

---

## 9. 검증하는 법 — 눌러 보지 않고

**"코드가 있다" 와 "그 코드가 호출된다" 는 다른 문제다.** 파일에
`_input` 이 적혀 있는지 보는 검사는 §4 의 버그를 **하나도 잡지 못한다.**

에디터를 실제로 띄워 **클릭 → 키 주입 → 상태 확인**까지 해야 한다.
**이 스킬에 그 스크립트가 들어 있다.**

```bash
# 프로젝트 루트에서 — ① 단축키가 실제로 듣는가
bash .claude/skills/godot/scripts/editor_key_probe.sh addons/editor_compass editor_compass

# ② 끄면 정말 꺼지는가 · 다시 켜면 돌아오는가
bash .claude/skills/godot/scripts/editor_disable_probe.sh addons/editor_compass editor_compass \
  res://addons/editor_compass/compass.gd
```

```
① 3D 뷰포트 포커스 0 → 1   ✅ 전환됨   (포커스: Control)
② 씬 독 포커스    1 → 2   ✅ 전환됨   (포커스: Tree)
③ 뷰포트 3회 연타  2 → 0 → 1 → 2   ✅ 세 단계를 정확히 한 바퀴
═══ 실패 0 건 ═══
```

| 검사 | 무엇을 잡는가 |
|---|---|
| ① 3D 뷰포트를 **실제로 클릭**한 뒤 키 | **세 번 틀린 자리.** 여기만 실패하면 §4 의 그 버그다 |
| ② 씬 독을 클릭한 뒤 키 | 고치다가 다른 곳을 망가뜨리지 않았는가 |
| ③ 세 번 연타 | 0회와 3회를 구분한다 |

끄기 검사가 보는 것 — ① 자동으로 붙은 것 + **손으로 넣은 것** 둘 다 보이는가 ·
② 껐을 때 **둘 다** 사라지는가 · ③ 다시 켜면 돌아오는가(한 번 끄면 못 켜는 것도 결함이다).

> 🔑 **대상 프로젝트를 건드리지 않는다.** 애드온만 복사한 임시 최소 프로젝트에서 돌리므로,
> 다른 사람이 에디터를 열어 두고 작업 중이어도 안전하다.
>
> 🛑 **검사가 자기 자신을 끄지 않는다.** 끄는 순간 코드가 죽어 다시 켤 수 없다
> (실제로 그렇게 되어 `project.godot` 을 손으로 고쳤다). **별도 플러그인**이 대상을 끈다.

직접 쓸 때의 뼈대는 이렇다.

```gdscript
# 검증용 EditorPlugin 안에서
await _click(viewport)                       # 실제 마우스 클릭 (grab_focus 아님!)
var before := _mode()
_press_zero()
await _wait(0.7)
var after := _mode()
assert(after != before)
```

### 🛑 에디터는 유휴 상태에서 프레임을 거의 돌리지 않는다

자동화 스크립트가 **끝나지 않는** 가장 흔한 원인이다. `await create_timer(...)` 도
`await process_frame` 도 흐르지 않는다.

```gdscript
OS.low_processor_usage_mode = false
EditorInterface.get_editor_settings().set("interface/editor/update_continuously", true)
```

무엇을 기다리든 **그 전에** 켠다. 그리고 안전장치로 데드라인을 둔다 — 사람 화면에
창이 뜬 채 방치되는 것이 가장 나쁘다.

### 🛑 판정은 처음과 끝만 비교하지 않는다

3단계를 세 번 누르면 처음과 끝이 같다. **한 번도 안 돈 것(0회)** 과 구분되지 않는다.

```gdscript
var path := [str(_mode())]
for i in 3:
	_press_zero()
	await _wait(0.6)
	path.append(str(_mode()))
# 2 → 0 → 1 → 2  ✅   /   1 → 1 → 1 → 1  ❌ (한 번도 안 돌았다)
```

### 게임에 따라가지 않는지도 **실제로 열어서** 본다

`_ready()` 에 `queue_free()` 가 적혀 있는 것과, **씬을 게임으로 열었을 때 정말 사라지는가**는
다른 문제다. 씬을 하나씩 인스턴스화해 그룹을 세면 된다.

```gdscript
extends SceneTree            # 🔑 이 스크립트는 is_editor_hint() 가 false — 게임과 같은 상황이다

func _initialize() -> void:
	var node := (load(path) as PackedScene).instantiate()
	root.add_child(node)
	await process_frame      # 🛑 queue_free() 는 프레임 끝에 처리된다
	await process_frame
	assert(root.get_tree().get_nodes_in_group(GROUP).is_empty())
```

> 🔑 **씬에 박아 넣어도 "0개" 가 나오는 것이 정상이다** — 자가 제거가 작동한 것이다.
> 이 검사가 잡는 것은 **그 안전망이 망가진 경우**다. 시험하려면 `queue_free()` 를
> `visible = false` 로 바꿔 본다(그러면 `❌` 가 나온다).
> "씬 파일에 저장돼 있는가" 는 별도로 `.tscn` **텍스트**를 봐야 한다 — 역할이 다르다.

### 🛑 검증이 실패를 잡는지 반드시 확인한다

고치기 전 상태로 되돌려 **실패가 나는지** 본다. 실패가 안 나면 그 검증은 껍데기다.

```bash
sed -i '' 's/^func _input(/func _shortcut_input(/' addons/editor_compass/plugin.gd
# → ① 실패 · ③ 1→1→1→1 이 나와야 한다
```

---

## 10. 프로젝트에 맞게 고치기

| 바꾸고 싶은 것 | 어디 |
|---|---|
| 단축키 | `compass.gd` 의 `TOGGLE_KEYCODE` |
| 색 | `compass.gd` 의 `COLOR_NORTH` 외 |
| 격자 칸 수 | `compass.gd` 의 `GRID_HALF_COUNT` |
| 선 굵기·화살촉 비율 | `compass.gd` 의 `*_RATIO` (전부 반경에 대한 비율이다) |
| 글자 크기 | `compass.gd` 의 `LABEL_SIZE` |
| 방향 규약 | `compass.gd` 의 `_compass()` |
| 기본 크기 (빈 씬) | `compass.gd` 의 `FALLBACK_RADIUS` |

**프로젝트 고유의 영역선(세이프존·사냥터·청크 경계 등)을 같이 그리고 싶다면**
`compass.gd` 를 복사해 그 프로젝트의 좌표 상수를 읽는 판을 따로 만든다.
단축키·자동 부착·저장 방지 구조(`plugin.gd`)는 그대로 쓰면 된다.

---

## 관련 문서

- [editor-plugin.md](editor-plugin.md) — `@tool`·`EditorPlugin` 전반
- [level-design.md](level-design.md) — 맵 만들기
- [headless-workflow.md](headless-workflow.md) — 창 없이 검증하기
