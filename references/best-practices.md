# Best practices — 공식 권장 사항과 GDScript 스타일 가이드

공식 문서 Manual → **Best practices** 12편(Introduction · Applying object-oriented principles ·
Scene organization · When to use scenes versus scripts · Autoloads versus regular nodes ·
When and how to avoid using nodes for everything · Godot interfaces · Godot notifications ·
Data preferences · Logic preferences · Project organization · Version control systems)과
Scripting → **GDScript style guide** 를 **이 스킬의 규범과 맞춰** 정리한 것이다.

**이 스킬에 이미 있는 규범이 어디서 왔는지**가 여기 있다 — SKILL.md 의 "절대 규칙"·"파일 배치 규범",
[nodes-scenes.md §11~12](nodes-scenes.md), [basics/05-signal.md](basics/05-signal.md) 의 "통지는 위로, 명령은 아래로" 가
전부 이 공식 권고의 적용이다. **공식과 이 스킬이 다른 곳은 §12 에 따로 적었다.**

## 목차

| 절 | 내용 |
|---|---|
| [§1](#1-씬-구성--의존성-없는-씬을-만든다) | 씬 구성 — 의존성 없는 씬을 만든다 ★ |
| [§2](#2-씬-vs-스크립트--무엇으로-만드나) | 씬 vs 스크립트 — 무엇으로 만드나 |
| [§3](#3-오토로드-vs-일반-노드--전역은-마지막-수단이다) | 오토로드 vs 일반 노드 — 전역은 마지막 수단이다 ★ |
| [§4](#4-노드-대신-쓰는-것--objectrefcountedresource) | 노드 대신 쓰는 것 — `Object`·`RefCounted`·`Resource` |
| [§5](#5-godot-인터페이스--다른-객체에-닿는-법) | Godot 인터페이스 — 다른 객체에 닿는 법 |
| [§6](#6-godot-알림--_notification-과-콜백-고르기) | Godot 알림 — `_notification()` 과 콜백 고르기 |
| [§7](#7-데이터-선호--arraydictionaryobject) | 데이터 선호 — `Array`·`Dictionary`·`Object` |
| [§8](#8-로직-선호--값을-먼저-트리는-나중에) | 로직 선호 — 값을 먼저, 트리는 나중에 |
| [§9](#9-프로젝트-구성--파일은-씬-옆에-이름은-snake_case) | 프로젝트 구성 — 파일은 씬 옆에, 이름은 snake_case |
| [§10](#10-버전-관리) | 버전 관리 |
| [§11](#11-gdscript-스타일-가이드--이름과-순서) | ★ GDScript 스타일 가이드 — 이름과 순서 |
| [§12](#12-공식-권고와-이-스킬이-다른-곳) | 공식 권고와 이 스킬이 다른 곳 |
| [§13](#13-자주-하는-실수) | 자주 하는 실수 |
| [공식 문서](#공식-문서) | |

---

## 1. 씬 구성 — 의존성 없는 씬을 만든다

### 왕초보가 반드시 겪는 문제

처음엔 씬 하나에 전부 넣는다. 커지면 가지를 `Save Branch as Scene` 으로 떼어낸다. 그러면 **떼어낸
씬 안에서 쓰던 `$"../Player"` 같은 경로와 에디터에서 연결한 시그널이 깨진다** — 그 씬을 다른 곳에
놓으면 `../Player` 가 없기 때문이다.

**공식 답 — 씬은 자기 밖을 몰라야 한다.** 필요한 것은 전부 자기 안에 갖고, 밖의 것이 필요하면
**밖(부모)이 넣어 준다**(의존성 주입). 넣어 주는 방법은 다섯이다.

| # | 방법 | 언제 | 코드 |
|---|---|---|---|
| 1 | **시그널 연결** — 가장 안전 | 자식이 "일어났다" 고 알리고 부모가 반응 | 부모 `$Child.hit.connect(_on_hit)` / 자식 `hit.emit()` |
| 2 | **메서드 호출** | 부모가 자식의 동작을 **시작**시킬 때 | 부모 `$Child.start()` |
| 3 | **`Callable` 을 넣어 준다** | 자식이 "무엇을 부를지" 모른 채 부르게 | 부모 `$Child.on_done = _finish` / 자식 `on_done.call()` |
| 4 | **노드 참조를 넣어 준다** | 자식이 다른 노드가 필요할 때 | 부모 `$Child.target = self` / 자식 `@export var target: Node3D` |
| 5 | **`NodePath` 를 넣어 준다** | 참조 대신 경로로 | 부모 `$Child.target_path = ".."` |

> 🔑 **이 스킬이 `@export var target: Node3D` 를 권하는 이유가 4번이다** — [basics/01-world.md](basics/01-world.md) "다른 노드를 가리키는 세 가지 방법".
> `$"../Player"` 는 씬이 자기 밖을 아는 것이고, `@export` 는 밖이 넣어 주는 것이다.

**형제끼리도 직접 모르게 한다** — 부모가 중재한다. `$Left.target = $Right.get_node("Receiver")`.

**의존성이 있으면 에디터가 알려 주게 만든다** — `@tool` 스크립트에서 `_get_configuration_warnings()` 가
빈 배열이 아닌 것을 돌려주면 Scene 독에 **경고 아이콘**이 뜬다(`Area3D` 에 `CollisionShape3D` 가 없을 때 뜨는 그것).
문서로 적어 두는 대신 씬이 스스로 설명한다.

### 트리 구조 — 공식이 권하는 뼈대

```
Main (main.gd)                    ← 진입점. 게임의 "main 함수"
├─ World (Node3D, game_world.gd)   ← 맵. 레벨 교체는 이 아래를 갈아끼운다
└─ GUI (Control, gui.gd)           ← 메뉴·HUD. 맵과 함께 지워지면 안 되므로 형제
```

이 스킬의 [level-design.md](level-design.md) 뼈대(`Main` → `Level` · `CameraRig` · UI)가 이것이다.

**관계로 생각하고 공간으로 생각하지 않는다** — "부모가 지워지면 자식도 지워져야 하는가?" 가 부모-자식을 정하는 기준이다.
아니라면 형제로 둔다. 위치만 따라가야 하면 부모-자식 대신 **`RemoteTransform3D`** 를 쓰고,
반대로 자식이지만 부모의 변환을 **받지 않아야** 하면 사이에 `Node` 를 끼우거나(선언적) `top_level = true`(명령적).

> **노드는 컴포넌트가 아니다.** 다른 엔진처럼 "기능을 붙이는" 것이 아니라 **집합(aggregation)** 이다.
> `CollisionShape3D` 처럼 부모가 읽어 가는 예외가 있지만 대부분의 노드는 독립적으로 동작한다.

**시스템을 어디 두나** — ① 자기 데이터를 스스로 관리하고 ② 전역 접근이 필요하며 ③ 혼자 존재해야 하면
**오토로드**(§3). 다른 시스템의 데이터를 **고치는** 시스템이면 오토로드가 아니라 씬·스크립트.

---

## 2. 씬 vs 스크립트 — 무엇으로 만드나

| | 스크립트(`.gd`) | 씬(`.tscn`) |
|---|---|---|
| 정체 | 엔진 클래스의 **명령형** 확장 | 노드 합성의 **선언형** 기술 |
| 만들기 | `MyNode.new()` — 엔진 클래스와 같은 호출 | `MyScene.instantiate()` — 다른 호출 |
| 속도 | 노드를 코드로 하나하나 만들면 **느리다**(호출마다 스크립팅 API 를 거친다) | `PackedScene` 은 엔진이 **일괄** 처리 — 빠르다 |
| 이름 붙이기 | `class_name` 으로 노드 추가 창에 뜬다 | 이름이 없다 — `class_name Game` 스크립트에 `const MyScene = preload(...)` 로 이름표를 붙일 수 있다 |

**공식 결론 셋**

1. 여러 프로젝트에서 재사용할 **도구**(프로그래머 아닌 사람도 쓸 것)면 → **스크립트** + `class_name` + 아이콘
2. **이 게임 고유의 개념**(플레이어·몹·맵·HUD)이면 → **항상 씬.** 추적·편집이 쉽고 안전하다
3. 씬에 이름이 필요하면 → 스크립트 클래스를 **네임스페이스**로 쓴다

이 스킬의 [nodes-scenes.md §12](nodes-scenes.md) "하나의 씬 = 하나의 재사용 단위" 가 2번이다.

---

## 3. 오토로드 vs 일반 노드 — 전역은 마지막 수단이다

**오토로드**(`Project > Project Settings > Globals > Autoload`)는 트리 루트 아래에 자동으로 붙어
씬을 바꿔도 살아남는 노드다. 사용법은 [nodes-scenes.md §6](nodes-scenes.md). **여기는 "언제 쓰지 말아야 하나" 다.**

### 공식이 드는 예 — 효과음 매니저

코인을 먹을 때 소리를 내는데 `AudioStreamPlayer` 하나가 재생 중이면 새 소리가 앞 소리를 끊는다.
그래서 **전역 `Sound` 오토로드**를 만들어 플레이어 풀을 돌리고 어디서든 `Sound.play("coin.ogg")` 한다.
당장은 되지만 세 가지가 망가진다.

| 문제 | 뜻 |
|---|---|
| **전역 상태** | 객체 하나가 모두의 데이터를 책임진다. `Sound` 가 잘못되면 그것을 부르는 **전부**가 깨진다 |
| **전역 접근** | 어디서든 `Sound.play(잘못된 경로)` 를 부를 수 있다. 버그가 나면 **찾아볼 범위가 프로젝트 전체**다 |
| **전역 자원 할당** | 풀 크기를 미리 정해야 한다 — 모자라면 버그, 남으면 메모리 낭비 |

**대신** — 각 씬이 **자기가 필요한 만큼의 `AudioStreamPlayer`** 를 안에 둔다. 문제는 그 씬 안에서만 나고,
버그는 한두 스크립트에서 찾고, 자원은 딱 필요한 만큼이다.

### 공유하고 싶은 것이 함수·데이터라면

| 공유할 것 | 오토로드 대신 |
|---|---|
| 함수 | `class_name` 을 가진 노드 타입 — 필요한 씬이 그 노드를 갖는다 |
| 함수(인스턴스 불필요) | **`static func`** — `class_name Util` + `Util.clamp_angle(x)`. 단 멤버 변수·`self` 를 못 쓴다 |
| 변수(인스턴스 간 공유) | **`static var`**(4.1+) |
| 데이터 | 커스텀 **`Resource`**([resources-assets.md §2](resources-assets.md)) 또는 `owner`(씬 루트)로 접근 |

### 그래도 오토로드가 맞는 경우

**자기 정보만 관리하고 남의 데이터를 침범하지 않는, 범위가 넓은 시스템** — 퀘스트·대화 시스템,
**씬 로더**, 세션(로그인 상태). 이 스킬의 `GameState`·`SceneLoader`([nodes-scenes.md §6](nodes-scenes.md))가 그것이다.

> 🔑 **오토로드는 싱글턴이 아니다.** 인스턴스를 더 만드는 것을 막지 않는다. 그저 **루트 자식으로 자동 로드**될 뿐이다.
> `get_node("/root/Sound")` 로도 잡힌다 — 이름은 곧 경로다.

---

## 4. 노드 대신 쓰는 것 — `Object`·`RefCounted`·`Resource`

노드는 싸지만 수만 개가 되면 무겁다. **데이터·구조만 필요하면 노드가 아닌 것**을 쓴다.
저사양 규범([lowend-3gb-60fps.md](lowend-3gb-60fps.md))에서 **노드 수 = 메모리와 처리 시간**이다.

| 클래스 | 무게 | 메모리 관리 | 인스펙터 | 언제 |
|---|---|---|---|---|
| **`Object`** | 가장 가볍다 | 🛑 **수동** — `free()` 를 내가 부른다. 남이 지우면 참조가 조용히 무효가 된다 | ✗ | 트리 구조 등 **커스텀 자료 구조**. `Tree` 노드가 `TreeItem`(Object) 으로 내부를 만드는 것이 예 |
| **`RefCounted`** | 조금 더 | **자동** — 참조가 0 이 되면 사라진다 | ✗ | **대부분의 커스텀 데이터 클래스.** `FileAccess` 가 이것 |
| **`Resource`** | 조금 더 | 자동 + **저장/불러오기** 가능 | ✅ **`@export` 가 인스펙터에 뜬다** | 밸런스·설정·아이템 정의 — [resources-assets.md](resources-assets.md) |
| `Node` | 가장 무겁다 | 트리가 관리 | ✅ | 화면에 있거나 트리 생명주기가 필요할 때만 |

```gdscript
## 트리 구조가 필요하지만 Node 는 과하다 — Object 로 직접 만든다 (공식 예)
class_name TreeNode
extends Object

var _parent: TreeNode = null
var _children: Array[TreeNode] = []

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:   # 소멸자 — 내가 지워질 때 자식도 지운다
		for child in _children:
			child.free()
```

---

## 5. Godot 인터페이스 — 다른 객체에 닿는 법

### 참조를 얻는 방법 — 느린 것에서 빠른 것으로

| 방법 | 속도·안전 | 비고 |
|---|---|---|
| `get_node("Child")` | 느림 — 매번 경로 탐색 | |
| `$Child` | 빠름 — GDScript 가 캐시 | 노드가 옮겨지면 깨진다 |
| `@onready var child = $Child` | **가장 빠름** — 한 번 잡아 둔다 | 트리 안에서 옮기면 깨진다 |
| **`@export var child: Node`** | **가장 빠름 + 옮겨도 안 깨진다** | 인스펙터에서 끌어다 넣는다 — 이 스킬의 기본 |
| 부모가 넣어 주는 `var prop` | 씬이 밖을 모른다(§1) | 🛑 **검증이 필요** — `if not prop: return` / `push_error` / `assert()`(릴리스에서는 안 돈다) |
| 오토로드 | 편하지만 위험(§3) | 진짜 싱글턴에만 |

리소스는 `preload`(로드 시점)·`load`(그 줄에서) — [basics/03-instancing.md](basics/03-instancing.md). **`load()` 는 캐시된 같은 인스턴스**를 준다.
새 것이 필요하면 `duplicate()`.

### 덕 타이핑 — "타입" 이 아니라 "메서드가 있는가"

Godot 은 `obj.set_visible(false)` 를 부를 때 **타입을 검사하지 않고 그 메서드가 있는지**만 본다.
속성 접근도 실제로는 **스크립트 → ClassDB(상속 사슬) → `_set`/`_get`** 순의 조회다.

| 검사 | 코드 |
|---|---|
| 메서드가 있으면 부른다 | `if child.has_method("take_damage"): child.take_damage(3)` |
| 타입이면 여러 개를 안전하게 | `if child is CanvasItem: child.set_visible(false)` |
| 반드시 있어야 한다 | `assert(child.has_method("take_damage"))` — 🛑 릴리스 빌드에서는 `assert` 가 실행되지 않는다 |
| 이름·그룹을 약속으로 | `if a_child.is_in_group("quest"): a_child.complete()` — 팀 안의 **문서화된 약속**이다 |
| 부를 함수를 밖에서 넣어 준다 | `child.fn = print_me` / 자식 `fn.call()` — 의존성 최소 |

이 스킬은 **정적 타입**을 규범으로 하므로([gdscript.md §3](gdscript.md)) `has_method` 보다 `is`·타입 힌트가 먼저다.
덕 타이핑은 **여러 종류의 노드가 같은 메서드를 갖는 경우**(피격 가능한 것들)에 쓴다.

---

## 6. Godot 알림 — `_notification()` 과 콜백 고르기

모든 `Object` 는 `_notification(what)` 을 갖고, 엔진 이벤트가 여기로 온다. 자주 쓰는 것은 **전용 함수**가 있다.

| 전용 함수 | 알림 상수 |
|---|---|
| `_ready()` | `NOTIFICATION_READY` |
| `_enter_tree()` / `_exit_tree()` | `NOTIFICATION_ENTER_TREE` / `NOTIFICATION_EXIT_TREE` |
| `_process(delta)` / `_physics_process(delta)` | `NOTIFICATION_PROCESS` / `NOTIFICATION_PHYSICS_PROCESS` |

**전용 함수가 없는 것 중 쓸모 있는 것**

| 상수 | 언제 | 쓰임 |
|---|---|---|
| `NOTIFICATION_PREDELETE` | 지워지기 직전 — **소멸자** | `Object` 자식 정리(§4) |
| `NOTIFICATION_PARENTED` / `UNPARENTED` | 부모가 생기거나 없어질 때 | 부모에 따라 설정을 바꾸는 부품 |
| `NOTIFICATION_APPLICATION_PAUSED` / `RESUMED` | 모바일 백그라운드 전환 | 저장·소켓 재연결 → [input-ui.md 종료·백그라운드 절](input-ui.md) |
| `NOTIFICATION_WM_CLOSE_REQUEST` | 창 닫기 요청(데스크톱) | 저장 후 종료 |

호출 순서(**엔진 실측 4.7.2**) — `_enter_tree` 는 부모→자식, `_ready` 는 자식→부모,
**`_exit_tree` 는 자식→부모**. [gdscript.md §13](gdscript.md).

### `_process` vs `_physics_process` vs `_input`

| 어디 | 무엇 | 이 스킬 |
|---|---|---|
| `_process(delta)` | 매 프레임. 화면 갱신·카메라·타이머 | 시각·입력 폴링 |
| `_physics_process(delta)` | 고정 틱(60Hz). **이동·충돌** | 🛑 물리는 반드시 여기 — SKILL.md 절대 규칙 |
| `_input(event)` 계열 | 입력이 왔을 때만 | [input-ui.md §1](input-ui.md) 전파 순서 |
| **매 프레임이 아니어도 되면 `Timer`** | 0.5초마다 등 | `timer.timeout.connect(func(): ...)` |

---

## 7. 데이터 선호 — `Array`·`Dictionary`·`Object`

| 연산 | `Array`(연속 메모리) | `Dictionary`(해시맵) | `Object` |
|---|---|---|---|
| 순회 | **가장 빠름** | 빠름 | — |
| 끝에 추가·제거 | 빠름 | **가장 빠름** | — |
| 앞·중간 삽입·제거 | 🛑 느림(뒤를 전부 민다) | **가장 빠름** | — |
| 위치로 읽기 | **가장 빠름**(`a[10]`) | — | — |
| 키로 읽기 | — | **가장 빠름**(`d["hp"]`) | 상속 사슬을 타고 조회 — **가장 느림** |
| 값으로 찾기 | 느림(전부 비교) | 느림(내장 기능 없음) | — |

- **앞에서 많이 넣고 빼야 하면** 배열을 뒤집어 끝에서 작업하고 다시 뒤집는다.
- **정렬된 배열**은 이진 탐색(`bsearch`)으로 빨라진다 — 매번 정렬을 유지해야 한다.
- **`Object` 를 자료 구조로 쓰는 이유**는 속도가 아니라 **제어(캡슐화·시그널)·명확성(속성이 반드시 있다)·편의**다.
- **enum 은 int 가 빠르다.** 출력용이면 `@export_enum` 문자열도 된다.
- 왜 GDScript 가 느린가 — 모든 접근이 "스크립트 → ClassDB → `_get`" 조회 사슬을 탄다. 그래서 [lowend-3gb-60fps.md](lowend-3gb-60fps.md) 는 **반복 계산을 빌드 타임에 굽는다.**

---

## 8. 로직 선호 — 값을 먼저, 트리는 나중에

**노드를 코드로 만들 때 값을 먼저 정하고 `add_child()` 는 마지막에 한다.** 일부 setter 는 트리 안에서
다른 값을 갱신하는 코드가 붙어 있어 느리다. 프로시저럴 생성처럼 많이 만들 때 차이가 크다.
예외 — `global_position` 처럼 **트리 안에서만 뜻이 있는 값**은 `add_child()` 뒤에([basics/03-instancing.md](basics/03-instancing.md) "규칙 3가지").

**`preload` vs `load`** — [basics/03-instancing.md](basics/03-instancing.md). 공식이 덧붙이는 함정:

```gdscript
const BuildingScn = preload("res://building.tscn")     # ✅ 상수 — 스크립트 로드 때 함께 로드, 자동완성 됨

@export var a_building: PackedScene = preload("res://office.tscn")   # 🛑 하지 않는다
# ① 인스펙터 값이 이 preload 를 덮어써 낭비된다 ② .new() 로 만들면 export 값이 무시된다
# → @export 에는 null 을 두고 인스펙터에서 넣는다
```

---

## 9. 프로젝트 구성 — 파일은 씬 옆에, 이름은 snake_case

Godot 은 폴더 구조를 강제하지 않는다. 공식 권장:

| 규칙 | 이유 |
|---|---|
| **에셋을 그 에셋을 쓰는 씬 가까이** | 리소스가 씬 안에 들어 있어 파일 수가 적다. 커져도 유지된다 |
| **파일·폴더는 `snake_case`** | 🛑 **내보낸 PCK 는 대소문자를 구분한다.** Windows·macOS 에서는 되던 `Player.tscn`/`player.tscn` 혼용이 **내보낸 뒤 로드 실패**로 나타난다 |
| **노드 이름은 `PascalCase`** | 내장 노드와 같은 규칙 |
| 서드파티는 **`addons/`** | 무엇이 남의 것인지 한눈에. 캐릭터 에셋처럼 그 씬 전용이면 예외 |
| 임포트하지 말 폴더엔 빈 **`.gdignore`** | 문서·원본 `.blend` 폴더. `load()` 도 못 하고 FileSystem 독에서 숨는다 |

이 스킬의 규범 — **스크립트는 씬 옆에**(`scenes/player/player.tscn` + `player.gd`), 씬에 안 붙는 것만
`autoload/`·`scripts/` → SKILL.md "파일 배치 규범" · [nodes-scenes.md §11](nodes-scenes.md).
공식 예시(`/models/town/house/`, `/characters/player/`)와 폴더 이름은 다르지만 **"씬 가까이"** 원칙은 같다.

---

## 10. 버전 관리

새 프로젝트를 만들 때 **Version Control: Git** 을 켜면 `.gitignore`·`.gitattributes` 가 생긴다.
`.godot/`(임포트 캐시)는 커밋하지 않고 `.import` 는 커밋한다. 상세와 LFS·`.blend` 원본 처리는
[project-config.md §8 Git 설정](project-config.md). 이 스킬 자체가 서브모듈로 관리된다(SKILL.md).

---

## 11. GDScript 스타일 가이드 — 이름과 순서

**내장 이름과 충돌하지 않으려면 엔진과 같은 규칙을 쓴다.** 공식 표 그대로다.

| 대상 | 규칙 | 예 |
|---|---|---|
| **파일 이름** | `snake_case` — `class_name` 을 snake 로 | `yaml_parser.gd` ← `class_name YAMLParser` |
| **클래스 이름** | `PascalCase` | `class_name YAMLParser` |
| **노드 이름** | `PascalCase` | `Camera3D`, `Player` |
| **함수** | `snake_case` | `func load_level():` |
| **변수** | `snake_case` | `var particle_effect` |
| **비공개·가상 함수·변수** | 앞에 `_` 하나 | `var _counter`, `func _recalculate_path()` |
| **시그널** | `snake_case` **과거형** | `signal door_opened`, `signal score_changed` |
| **상수** | `CONSTANT_CASE` | `const MAX_SPEED = 200` |
| **enum 이름** | `PascalCase` **단수** | `enum Element` |
| **enum 멤버** | `CONSTANT_CASE`, **한 줄에 하나** | `EARTH,` `WATER,` … (문서 주석·diff 가 깔끔하다) |
| 스크립트·씬을 담는 상수 | `PascalCase` | `const Weapon = preload("res://weapon.gd")` |

### 코드 순서 — 위에서 아래로 읽히게

```
01. @tool, @icon, @static_unload
02. class_name
03. extends
04. ## 문서 주석

05. signals
06. enums
07. constants
08. static variables
09. @export variables
10. 나머지 일반 변수 (public → private)
11. @onready variables

12. _static_init()
13. 나머지 static 메서드
14. 내장 가상 메서드 덮어쓰기: _init → _enter_tree → _ready → _process → _physics_process → 나머지
15. 커스텀 가상 메서드 덮어쓰기
16. 나머지 메서드 (public → private)
17. 내부 클래스
```

네 가지 원칙 — **① 속성·시그널이 먼저, 메서드는 뒤 ② public 이 private 보다 앞 ③ 가상 콜백이 클래스 인터페이스보다 앞
④ 만드는 것(`_init`·`_ready`)이 바꾸는 것보다 앞.** 이 순서가 [gdscript.md §2](gdscript.md) "파일 구조와 선언 순서" 의 출처다.

```gdscript
@abstract                      # 추상 클래스면 class_name 앞에 (4.5+)
class_name MyNode
extends Node
## 이 클래스의 역할 한 줄.
##
## 더 긴 설명 — 무엇을 할 수 있고 어떻게 쓰는지.

signal player_spawned(position)

enum Job {
	KNIGHT,
	WIZARD,
}

const MAX_LIVES = 3
```

### 그 밖의 형식 규칙(공식)

- **들여쓰기는 탭**(에디터 기본). 한 파일에서 섞지 않는다 — [basics/04-script.md](basics/04-script.md) 의 오류 메시지 참조
- 한 줄에 한 문장 · 줄 길이 100 이하 권장 · **`and`·`or`·`not`**(`&&`·`||`·`!` 대신) · 불필요한 괄호 없음
- 문자열은 **큰따옴표**, 안에 큰따옴표가 있을 때만 작은따옴표
- 여러 줄로 나열하면 **마지막에도 쉼표**(trailing comma)
- 함수 사이 빈 줄 2개, 함수 안 논리 블록 사이 1개

---

## 12. 공식 권고와 이 스킬이 다른 곳

| 주제 | 공식 | 이 스킬 | 왜 |
|---|---|---|---|
| 폴더 구조 | `models/`·`characters/`·`levels/` 처럼 종류별 | `scenes/<이름>/` 에 씬·스크립트·그 씬 전용 모델을 함께 | "씬 가까이" 는 같다. 라리엔은 씬 단위 폴더가 실측상 관리가 쉬웠다(SKILL.md 파일 배치 규범) |
| 덕 타이핑 | `has_method` 로 유연하게 | **정적 타입 우선**, 덕 타이핑은 다형 피격 등에만 | LSP 진단([lsp.md](lsp.md))이 잡아 주는 오류가 늘어난다 |
| 오토로드 | 넓은 범위 시스템에 허용 | 같다 + `GameState`·`SceneLoader`·`AudioManager` 로 한정 | 저사양에서 전역 풀의 메모리를 통제 |
| 첫 3D 게임의 조명·카메라 | `DirectionalLight3D` + 원근 | **광원 0개** + 직교 −45° 고정 | 실측(라이트맵 1fps) 과 게임 규칙 — [getting-started.md §7](getting-started.md) |
| 노드 수 | 수만 개도 가능 | 반복물은 `MultiMeshInstance3D` | 3GB RAM 기준 |

**둘 다 옳다.** 공식은 일반론이고 이 스킬은 라리엔 3D 의 실측이다. 충돌하면 SKILL.md 의 "근거의 우선순위" — **엔진 실측 > 이 스킬 > 공식 문서**.

---

## 13. 자주 하는 실수

| 실수 | 결과 | 고침 |
|---|---|---|
| 자식 씬에서 `$"../Player"` | 다른 곳에 놓는 순간 `null` | `@export var player: Node3D` — 부모가 넣어 준다(§1) |
| 오디오·이펙트를 전역 매니저로 | 버그 범위가 프로젝트 전체 | 씬마다 자기 `AudioStreamPlayer`(§3) |
| 데이터만 필요한데 `Node` | 메모리·처리 낭비 | `RefCounted`·`Resource`(§4) |
| `@export var x = preload(...)` | 인스펙터 값과 충돌 | `@export` 는 `null`, 인스펙터에서 채운다(§8) |
| `Player.tscn` 과 `player.tscn` 혼용 | 내보낸 뒤 로드 실패 | 전부 `snake_case`(§9) |
| 시그널 이름을 명령형으로 (`open_door`) | 무엇이 일어났는지 안 읽힘 | 과거형 `door_opened`(§11) |
| enum 을 한 줄에 | 주석·diff 불가 | 한 줄에 하나(§11) |
| `_exit_tree` 정리를 부모가 먼저 한다고 가정 | 자식이 먼저 나간다(실측) | [gdscript.md §13](gdscript.md) |

---

## 관련 문서

- [nodes-scenes.md](nodes-scenes.md) §6 오토로드 · §11 역할 분리 · §12 씬 설계 원칙
- [gdscript.md](gdscript.md) §2 선언 순서 · §3 정적 타입 · §13 생명주기
- [basics/01-world.md](basics/01-world.md) · [basics/03-instancing.md](basics/03-instancing.md) · [basics/05-signal.md](basics/05-signal.md)
- [resources-assets.md](resources-assets.md) — 커스텀 `Resource`
- [project-config.md](project-config.md) §8 Git
- [getting-started.md](getting-started.md) §6 설계 철학

## 공식 문서

- Best practices (목차): https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html
- Scene organization: https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html
- When to use scenes versus scripts: https://docs.godotengine.org/en/stable/tutorials/best_practices/scenes_versus_scripts.html
- Autoloads versus regular nodes: https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_regular_nodes.html
- When and how to avoid using nodes for everything: https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html
- Godot interfaces: https://docs.godotengine.org/en/stable/tutorials/best_practices/godot_interfaces.html
- Godot notifications: https://docs.godotengine.org/en/stable/tutorials/best_practices/godot_notifications.html
- Data preferences: https://docs.godotengine.org/en/stable/tutorials/best_practices/data_preferences.html
- Logic preferences: https://docs.godotengine.org/en/stable/tutorials/best_practices/logic_preferences.html
- Project organization: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
- Version control systems: https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html
- GDScript style guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
