# 7. 에디터 조작을 내 손에 맞춘다 — 마우스와 단축키

> **[Godot 기본](../basics.md)** 의 파트 **8 / 11**
> [← 6. 에디터 화면 — 어디에 무엇이 있나](06-editor-screen.md) · [8. 동영상 강좌 — 손으로 한 번 따라 만들어 본다 →](08-video.md)

> **이 문서로 오는 상황** — 뷰포트 회전이 **안 될** 때(Magic Mouse · 가운데 버튼 없음) · 왼손잡이·macOS 에서 에디터 조작을 바꿀 때

**Godot 의 기본 조작은 "오른손 마우스 + 3버튼 마우스"를 전제로 만들어져 있다.**
그 전제에서 벗어나면 **일부 기능이 아예 동작하지 않는다.** 익숙해지려 애쓰지 말고
설정을 바꾼다. 3D 작업은 뷰포트를 하루에 수백 번 돌리므로 이 차이가 크게 쌓인다.

> 🛑 **에디터 설정은 사람이 직접 바꾼다.** Claude 는 파일을 고치지 않고
> **어느 메뉴에서 무엇을 어떤 값으로** 바꿀지만 알려준다 (→ [CLAUDE.md](../../../../../CLAUDE.md)).
> 아래 표의 "UI 경로"를 그대로 따라가면 된다.

## 목차

| 절 | 내용 |
|---|---|
| [·](#먼저-용어--궤도-회전과-프리룩은-다르다) | 먼저 용어 — 궤도 회전과 프리룩은 다르다 |
| [·](#3d-뷰포트의-기본-조작) | 3D 뷰포트의 기본 조작 |
| [·](#-가운데-버튼이-없는-마우스--magic-mouse-등) | 🖱 가운데 버튼이 없는 마우스 — Magic Mouse 등 |
| [·](#-프리룩-키를-왼손잡이에-맞춘다) | ⌨ 프리룩 키를 왼손잡이에 맞춘다 |
| [·](#macos-에서-먼저-확인할-것) | macOS 에서 먼저 확인할 것 |
| [·](#게임-안의-조작은-별개다--inputmap) | 게임 안의 조작은 별개다 — `InputMap` |

---

## 먼저 용어 — 궤도 회전과 프리룩은 다르다

**둘 다 카메라를 돌리지만 무엇을 중심으로 도는지가 다르다.** 이 둘을 섞어서 이해하면
설정을 어디서 바꿔야 할지 계속 헷갈린다.

| 용어 | 무엇인가 | 비유 |
|---|---|---|
| **궤도 회전 (orbit)** | 카메라가 **한 점을 중심으로 그 주위를 돈다** | **물체를 손에 들고 이리저리 돌려 보는 것** |
| **프리룩 (freelook)** | 카메라가 **제자리에서 방향만 바꾼다** | **서서 고개를 돌리는 것** |

```
궤도 회전 — 중심은 대상, 카메라가 움직인다
        카메라
          ↘
    ●  ← 대상은 화면 가운데 고정
          ↗
        카메라

프리룩 — 중심은 카메라 자신, 카메라는 제자리
      ← ●  →      카메라 위치는 그대로, 보는 방향만 바뀐다
```

**따라서 쓰임도 다르다.**

| | 궤도 회전 | 프리룩 |
|---|---|---|
| 무엇을 볼 때 | **하나의 물체**를 여러 각도에서 | **넓은 공간**을 돌아다니며 |
| 대상이 화면에서 | 가운데 유지된다 | 벗어난다 |
| 라리엔에서 | 건물·캐릭터 모델을 점검할 때 | 맵을 훑어볼 때 |

**팬(pan)** 은 회전이 아니다. **카메라가 보는 방향을 유지한 채 평행으로 미끄러지는 것**이다.
지도를 손으로 밀어 옮기는 것과 같다.

## 3D 뷰포트의 기본 조작

| 동작 | 기본 조작 |
|---|---|
| **궤도 회전** (대상을 중심으로 돌기) | **가운데 버튼 드래그** |
| **팬** (평행 이동) | **Shift + 가운데 버튼** |
| **줌** | 휠 |
| **프리룩** (제자리에서 방향 전환 + 이동) | **우클릭 홀드 + WASD** |
| 프리룩 토글 | Shift+F |

**앞의 둘이 가운데 버튼에 묶여 있다는 점이 중요하다.**

## 🖱 가운데 버튼이 없는 마우스 — Magic Mouse 등

**Magic Mouse 에는 가운데 버튼이 없다. 즉 궤도 회전과 팬이 아예 되지 않는다.**
단축키보다 이쪽이 먼저 막히는 문제다.

**Editor → Editor Settings → Editors → 3D → Navigation** 에서 푼다.

| 설정 | 무엇 | 권장 |
|---|---|---|
| **Emulate 3 Button Mouse** | **Option(Alt) + 좌클릭**을 가운데 버튼으로 대신 쓴다 | ✅ **가장 먼저 켠다** |
| **Navigation Scheme** | Godot / Maya / Modo 중 선택 | **Maya** — Alt 조합 기반이라 3버튼 없는 마우스에 잘 맞는다 |
| **Orbit Mouse Button** | 궤도 회전에 쓸 버튼을 직접 지정 | 위 둘로 안 되면 여기서 바꾼다 |
| **Pan Mouse Button** | 팬에 쓸 버튼 | 동일 |
| **Zoom Mouse Button** | 줌에 쓸 버튼 | 동일 |

> **엔진 확인 (4.7.2)** — 위 다섯 항목은 실제로 존재한다.
> 설정 키는 `editors/3d/navigation/emulate_3_button_mouse`,
> `.../navigation_scheme`, `.../orbit_mouse_button`, `.../pan_mouse_button`,
> `.../zoom_mouse_button` 이다.
> **버튼을 개별 지정하는 세 항목은 버전에 따라 없을 수도 있다고 알려져 있으나,
> 4.7.2 에는 있다.**

**Navigation Scheme 을 Maya 로 두면** 조작이 이렇게 바뀐다 — 이 편이
Magic Mouse 에 훨씬 낫다.

```
Alt + 좌클릭 드래그   → 궤도 회전
Alt + 가운데 드래그    → 팬        (Emulate 3 Button 과 함께 쓰면 Alt+좌클릭에 흡수됨)
Alt + 우클릭 드래그    → 줌
```

## ⌨ 프리룩 키를 왼손잡이에 맞춘다

프리룩(우클릭 홀드 상태의 1인칭 이동)은 기본이 **WASD** 다. 이것은
**마우스를 오른손에 두어 왼손이 키보드 좌측에 있다**는 전제다.

**마우스를 왼손에 두면 오른손이 키보드 우측에 있으므로 WASD 는 손이 겹친다.**
오른손이 자연스럽게 닿는 자리로 옮긴다.

**Editor → Editor Settings → Shortcuts 탭 → `freelook` 으로 검색**

| 단축키 이름 | 기본값 | **IJKL 안** | **화살표 안** |
|---|---|---|---|
| `spatial_editor/freelook_forward` | W | **I** | ↑ |
| `spatial_editor/freelook_backwards` | S | **K** | ↓ |
| `spatial_editor/freelook_left` | A | **J** | ← |
| `spatial_editor/freelook_right` | D | **L** | → |
| `spatial_editor/freelook_up` | E | **O** | PageUp |
| `spatial_editor/freelook_down` | Q | **U** | PageDown |
| `spatial_editor/freelook_speed_modifier` | Shift | 그대로 | 그대로 |
| `spatial_editor/freelook_slow_modifier` | Alt | 그대로 | 그대로 |
| `spatial_editor/freelook_toggle` | Shift+F | 그대로 | 그대로 |

**IJKL 을 권한다.** 화살표는 Scene 독에서 노드 이동·선택에도 쓰여 문맥에 따라
가로채이는 일이 있고, 손을 홈 포지션에서 더 멀리 옮겨야 한다.

> ⚠️ **기존 키를 지우고 새 키로 교체한다.**
> 프리룩 단축키는 **첫 번째로 등록된 키만 인식**되는 동작이 보고된 적이 있다.
> 두 번째 바인딩을 추가하는 방식으로는 안 먹을 수 있으므로,
> **W/A/S/D 를 지운 뒤 I/J/K/L 을 넣는다.**

**Shift(가속)와 Alt(감속)는 그대로 둔다.** 양손 어느 쪽에서도 닿고,
다른 단축키와 충돌하지 않는다.

## macOS 에서 먼저 확인할 것

**시스템 설정 → 마우스 → 보조 클릭(Secondary click)** 이 켜져 있어야 한다.

**꺼져 있으면 우클릭이 안 되고, 우클릭이 안 되면 프리룩 자체가 시작되지 않는다.**
Magic Mouse 는 이 항목이 꺼진 상태로 오는 경우가 있다.

| 항목 | 상태 | 영향 |
|---|---|---|
| 보조 클릭 | **켜야 한다** | 우클릭 → **프리룩 진입**, 뷰포트 컨텍스트 메뉴 |
| 두 손가락 스크롤 | 기본 켜짐 | 휠로 인식되어 **줌은 문제없다** |
| 스크롤 방향(자연스럽게) | 취향 | 줌 방향이 뒤집혀 느껴지면 여기 또는 에디터의 `zoom_style` 을 본다 |

## 게임 안의 조작은 별개다 — `InputMap`

**에디터 설정은 에디터에만 적용된다. 게임 안 조작과 아무 관계가 없다.**

게임 조작은 **Project → Project Settings → Input Map** 에서 **액션(action)** 으로
정의하고, 코드는 **액션 이름으로만** 접근한다.

```gdscript
# ✅ 이렇게 쓴다 — 어떤 키인지 코드가 모른다
if Input.is_action_pressed("move_forward"):
    ...

# 🛑 이렇게 쓰지 않는다 — 키가 코드에 박힌다
if Input.is_key_pressed(KEY_W):
    ...
```

**이유는 리바인딩이다.** 액션으로 감싸 두면 나중에 **플레이어가 직접 키를 바꾸는
설정 메뉴**를 붙일 때 **코드를 한 줄도 고치지 않아도 된다.**
키를 코드에 박아 두면 그 메뉴를 만들 때 전부 다시 써야 한다.

**리바인딩 API** (4.7.2 에서 시그니처 확인)

```gdscript
InputMap.action_erase_events("move_forward")          # 기존 바인딩 전부 삭제
InputMap.action_add_event("move_forward", new_event)  # 새 키 등록

InputMap.action_erase_event(action, event)            # 하나만 삭제
InputMap.action_get_events(action) -> InputEvent[]    # 현재 바인딩 조회
InputMap.action_has_event(action, event) -> bool
InputMap.load_from_project_settings()                 # 기본값으로 되돌리기
```

**키 이벤트는 `physical_keycode` 로 만든다.**

```gdscript
var ev := InputEventKey.new()
ev.physical_keycode = KEY_I        # keycode 가 아니라 physical_keycode
InputMap.action_add_event("move_forward", ev)
```

`keycode` 는 **키캡에 적힌 문자**라 자판 배열(QWERTY/AZERTY/드보락)이 다르면
엉뚱한 키가 된다. `physical_keycode` 는 **키의 물리적 위치**라 배열과 무관하게
같은 자리를 가리킨다 *(엔진 확인: `InputEventKey.physical_keycode`, 기본값 `0`)*.

> **Steam(PC) 버전에서는 리바인딩 메뉴가 사실상 필수다.**
> 왼손잡이, 다른 자판 배열, 접근성 요구가 전부 여기로 들어온다.
> **지금 액션 이름만 제대로 정해 두면 나중에 할 일이 거의 없다.**
> 저장·불러오기 구현은 [input-ui.md](../input-ui.md) 에 있다.

---

---

## 공식 문서

- [Customizing the interface › Customizing editor settings](https://docs.godotengine.org/en/stable/tutorials/editor/customizing_editor.html) — `Editor > Editor Settings` 가 무엇을 바꾸는지
- [Introduction to 3D](https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html) — 3D 뷰포트 조작(궤도·팬·줌·프리룩)의 공식 설명
- [Using InputEvent](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html) — 게임 안의 입력은 에디터 설정과 별개다
- [Input examples](https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html) — `InputMap` 액션·리바인딩 API
