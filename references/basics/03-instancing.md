# 3. 인스턴싱(Instancing) — 설계도로 실체를 찍어낸다

> **[Godot 기본](../basics.md)** 의 파트 **4 / 11**
> [← 2. 씬(Scene) — 파일인가 객체인가](02-scene.md) · [4. 스크립트 — 노드에 붙는 것 →](04-script.md)

> **이 문서로 오는 상황** — 씬을 **코드로 찍어내야** 할 때(`load → instantiate → add_child`) · 만든 노드 묶음을 씬으로 **떼어낼** 때(`Save Branch as Scene`)

**미리 만들어 둔 씬을 불러와 새 노드 묶음을 만들어 내는 것**이다.
탄막 슈팅에서 총알 씬 하나를 만들어 두고 **쏠 때마다 찍어내는** 것이 전형적인 예다.

> 🔑 **인스턴싱하지 않은 씬은 실행되지 않는다.** `.tscn` 이 프로젝트 폴더에 있는 것과
> 게임 안에 존재하는 것은 별개다 — 그 씬의 스크립트에 `_ready()` 를 아무리 써도
> 불리지 않는다. 자세한 것은 §4 [`_ready()` 가 실행되지 않는다](04-script.md#_ready-가-실행되지-않는다--파일이-있다고-실행되는-게-아니다).

## 목차

| 절 | 내용 |
|---|---|
| [·](#왜-필요한가) | 왜 필요한가 |
| [·](#방법-1--에디터에서) | 방법 1 — 에디터에서 |
| [·](#방법-2--코드에서) | 방법 2 — 코드에서 |
| [·](#메모리에-올린다가-무슨-뜻인가--4단계) | "메모리에 올린다"가 무슨 뜻인가 — 4단계 |
| [·](#한-장으로-보는-4단계) | 한 장으로 보는 4단계 |
| [·](#엔진에서-확인한-실제-동작-472) | 엔진에서 확인한 실제 동작 (4.7.2) |
| [·](#preload-와-load-의-차이) | `preload` 와 `load` 의 차이 |
| [·](#반대-방향--save-branch-as-scene-만들어-놓은-묶음을-씬으로-떼어낸다) | 반대 방향 — `Save Branch as Scene...` (만들어 놓은 묶음을 씬으로 떼어낸다) |

---

## 왜 필요한가

| 이유 | 내용 |
|---|---|
| **반복 제작이 사라진다** | 적 100마리를 손으로 100번 만들지 않는다. 씬 하나 + 100번 인스턴싱 |
| **고칠 곳이 한 군데다** | **원본 씬을 고치면 모든 인스턴스에 반영된다.** 총알 크기를 바꾸려고 100개를 찾아다니지 않는다 |
| **코드가 짧아진다** | 노드를 하나씩 `new()` 해서 조립하는 코드가 통째로 사라진다 |

## 방법 1 — 에디터에서

씬 독(Scene 패널)에서 부모 노드를 선택하고,

- **체인 모양 버튼**(`Instantiate Child Scene`) 을 누르거나
- **Cmd+Shift+A** (Windows·Linux 는 `Ctrl+Shift+A`)

`.tscn` 파일을 고르면 그 씬이 자식으로 들어온다.
**파일 독에서 씬을 뷰포트로 드래그해도 같다.**

인스턴스는 씬 독에서 **영화 슬레이트 아이콘**으로 표시되고, 자식 노드들은 접힌 채로 온다.
**원본을 고치면 이 인스턴스도 함께 바뀐다** — 그것이 인스턴싱의 값어치다.

## 방법 2 — 코드에서

3단계다. **각 단계가 무엇을 하는지가 이 절의 핵심**이다.

```gdscript
extends Node3D

const BULLET: PackedScene = preload("res://scenes/bullet.tscn")   # ① 설계도를 메모리로

func fire() -> void:
	var bullet: Node3D = BULLET.instantiate()   # ② 설계도로 실체를 만든다 (아직 트리 밖)
	bullet.speed = 30.0                          # ③ 이 인스턴스만의 값을 준다
	add_child(bullet)                            # ④ 트리에 넣는다 → 여기서 _ready 가 불린다
	bullet.global_position = muzzle.global_position   # ⑤ 전역 좌표는 트리에 들어간 뒤에
```

## "메모리에 올린다"가 무슨 뜻인가 — 4단계

강의·문서에서 자주 나오는 이 말은 **단계마다 다른 것을 가리킨다.**
`.tscn` 하나가 화면의 캐릭터가 되기까지 **네 번의 상태 변화**를 거친다.

```gdscript
var player_scene: PackedScene = load("res://Player.tscn")   # ②
var player: CharacterBody3D = player_scene.instantiate()    # ③
add_child(player)                                            # ④
```

### ① 아무것도 하지 않은 상태 — `.tscn` 은 설계도일 뿐

`res://Player.tscn` 은 디스크에 있는 **텍스트 파일**이다.
파일이 있다는 것만으로는 **게임 실행 중에 아무 일도 일어나지 않는다.**
건축 도면이 있다고 집이 서 있는 것은 아닌 것과 같다.

### ② `load("res://Player.tscn")` — 설계도를 메모리로 읽는다

씬 리소스를 메모리에 불러와 **`PackedScene` 객체**로 만든다.
**아직 설계도를 손에 든 것뿐이다.** 노드는 하나도 생기지 않았고 화면에도 없다.

> 흔한 오해 — "load 했으니 화면에 나오겠지"가 아니다.
> 이 줄만 실행하면 **여전히 아무 일도 일어나지 않는다.**

### ③ `player_scene.instantiate()` — 설계도로 실체를 찍어낸다

**이때 비로소 `Node` 들이 생성된다.** 씬에 적힌 노드 구성이 그대로 메모리에 만들어지고,
자식 노드도 함께 생긴다. 이것이 **"객체화"** 다.

다만 **아직 트리 밖이다.** 화면에 없고 `_ready()` 도 불리지 않았다.
`get_tree()` 는 `null` 이고 `@onready` 변수도 비어 있다.

### ④ `add_child(player)` — 씬 트리에 연결해야 화면에 나온다

**SceneTree 에 붙는 순간** 화면에 표시되고 `_process`·`_physics_process` 가 돌기 시작한다.
`_ready()` 도 여기서 불린다.

## 한 장으로 보는 4단계

| | 단계 | 코드 | 이 시점에 존재하는 것 | 화면에 보이나 | `_ready` |
|---|---|---|---|---|---|
| ① | 아무것도 안 함 | — | 디스크의 `.tscn` 텍스트 | ❌ | ❌ |
| ② | 설계도를 메모리로 | `load()` | ＋ `PackedScene` 객체 | ❌ | ❌ |
| ③ | 실체를 찍어냄 | `instantiate()` | ＋ **노드들** (트리 밖) | ❌ | ❌ |
| ④ | 트리에 연결 | `add_child()` | ＋ SceneTree 안의 자리 | ✅ | ✅ |

```
res://Player.tscn          ①  디스크의 텍스트 — 설계도. 아무 일도 안 일어난다
      │ load() / preload()
      ▼
PackedScene                ②  메모리의 설계도 객체. 노드는 아직 0개
      │ instantiate()
      ▼
CharacterBody3D + 자식들    ③  노드가 생겼다. 하지만 트리 밖 — 화면에 없다
      │ add_child()
      ▼
SceneTree 안               ④  화면에 나오고 _ready·_process 가 돈다
```

**한 줄로 줄이면** — 인스턴싱이란 **씬 리소스를 기반으로 새로운 객체를 메모리에 생성하는
과정**이고, 그 객체가 실제로 동작하려면 **트리에 연결(④)까지** 해야 한다.

## 엔진에서 확인한 실제 동작 (4.7.2)

```
instantiate 직후  is_inside_tree = false      ← ③ 아직 트리 밖
    [_ready] BulletA  speed=5.0               ← ④ add_child() 안에서 즉시 호출된다
add_child 직후    is_inside_tree = true
preload 와 load 가 같은 객체인가? true         ← 같은 경로는 리소스 캐시를 공유한다
```

여기서 나오는 규칙 세 가지다.

| 규칙 | 이유 |
|---|---|
| **`instantiate()` 직후에는 `get_tree()` 가 `null`, `@onready` 도 아직 안 채워졌다** | ③ 은 트리 밖이기 때문 |
| **전역 좌표(`global_position`)는 `add_child()` 뒤에 준다** | 트리 밖에서는 부모 좌표계가 없어 무시된다 |
| **일반 변수(`speed` 등)는 `add_child()` 앞에 줘도 된다** | `_ready()` 가 그 값을 보고 시작할 수 있어 오히려 낫다 |

## `preload` 와 `load` 의 차이

| | `preload()` | `load()` |
|---|---|---|
| 읽는 시점 | **스크립트가 컴파일될 때** (게임 시작 전) | **그 줄이 실행될 때** |
| 인자 | 문자열 **상수만** | 변수 가능 |
| 쓰는 곳 | `const` 로 파일 상단에 | 경로가 실행 중에 정해질 때 |

같은 경로를 여러 번 불러도 **엔진이 캐시해 같은 리소스 객체를 준다**(위 검증의 `true`).
그래서 "여러 번 load 하면 메모리를 여러 배 쓴다"는 걱정은 하지 않아도 된다.

## 반대 방향 — `Save Branch as Scene...` (만들어 놓은 묶음을 씬으로 떼어낸다)

여기까지가 **씬 파일 → 화면 위의 노드**였다면, 이것은 **화면 위의 노드 → 씬 파일**이다.
씬을 미리 만들어 두고 인스턴싱하는 게 정석이지만, 실제로는 **일단 현재 씬에서 만들어 보고
나중에 "이거 재사용하겠다"고 깨닫는 일**이 훨씬 많다. 그때 쓰는 기능이다.

### 브랜치(Branch)란 — **선택한 노드 + 그 아래 전부**

씬은 노드의 트리다. 맨 위가 **루트**, 끝이 **잎**이고,
**루트가 아닌 노드 하나와 그 아래 자손 전체**를 **브랜치**라고 부른다.
`Boxes` 를 선택했다면 브랜치는 이 넷 전부다.

```
Boxes          ← 선택한 노드
├─ Box
├─ Box2
└─ Box3
```

### 실행하면 무슨 일이 일어나나 — 트리

```
[실행 전]                          [실행 후]

light_scene.tscn                   boxes.tscn          ← ① 새 파일로 저장된다
└─ Boxes                           └─ Boxes
   ├─ Box                             ├─ Box
   ├─ Box2                            ├─ Box2
   └─ Box3                            └─ Box3

                                   light_scene.tscn
                                   └─ Boxes  ← ② 그 자리는 boxes.tscn 의 인스턴스로 바뀐다
                                              (자식들은 접혀서 안 보인다)
```

세 가지가 한 번에 일어난다.

1. `Boxes` 와 그 자손을 **별도의 `.tscn` 파일로 저장**한다.
2. 원래 씬의 그 자리는 **새 씬의 인스턴스로 교체**된다 — 씬 독에서 **영화 슬레이트 아이콘**이 붙는다.
3. 이후 `boxes.tscn` 을 **다른 씬 어디에나 인스턴싱**할 수 있고, **원본을 고치면 전부 반영**된다.

한 줄로 줄이면 — **현재 씬 안에서 만든 노드 묶음을 독립적인 재사용 가능 씬으로 분리한다.**

### `.tscn` 텍스트가 실제로 어떻게 바뀌나 (4.7.2 실측)

이것이 "고칠 곳이 한 군데"의 물리적 근거다. **자식 노드 정의가 원본 씬에서 통째로 사라지고
참조 두 줄만 남는다.**

```ini
; 실행 전 — light_scene.tscn 이 상자 3개를 직접 들고 있다
[node name="LightScene" type="Node3D"]
[node name="Boxes" type="Node3D" parent="."]
[node name="Box"  type="MeshInstance3D" parent="Boxes"]
[node name="Box2" type="MeshInstance3D" parent="Boxes"]
[node name="Box3" type="MeshInstance3D" parent="Boxes"]
```

```ini
; 실행 후 — light_scene.tscn
[ext_resource type="PackedScene" path="res://boxes.tscn" id="1_ul0ol"]   ; ← 참조를 선언하고

[node name="LightScene" type="Node3D"]
[node name="Boxes" type="Node3D" parent="." instance=ExtResource("1_ul0ol")]   ; ← 한 줄로 끝난다
```

```ini
; 실행 후 — boxes.tscn (Boxes 가 이 씬의 루트가 된다 → parent="." 로 바뀐다)
[node name="Boxes" type="Node3D"]
[node name="Box"  type="MeshInstance3D" parent="."]
[node name="Box2" type="MeshInstance3D" parent="."]
[node name="Box3" type="MeshInstance3D" parent="."]
```

> 위는 헤드리스 Godot 4.7.2 로 같은 구조를 만들어 저장한 결과다.
> **에디터로 저장하면 `ext_resource` 줄에 `uid="uid://..."` 가 함께 붙는다** — 경로가 바뀌어도
> 참조가 안 깨지게 하는 식별자이고, 의미는 같다.

### 방법

씬 독에서 **떼어낼 노드를 하나만 선택** → **우클릭** → **`Save Branch as Scene...`**
→ 저장할 경로·파일명을 정한다(기본 파일명은 노드 이름에서 자동으로 만들어진다).

**기본 단축키는 없다.** 자주 쓴다면 `Editor > Editor Settings > Shortcuts` 에서
`scene_tree/save_branch_as_scene` 에 직접 지정한다.

### 🛑 저장 대화상자의 `Reset Position` 은 기본이 **켜짐**이다

대화상자 아래에 체크박스 3개가 있고, **기본값이 다르다**(엔진 소스 확인).

| 옵션 | 기본값 | 켜져 있으면 |
|---|---|---|
| **`Reset Position`** | ✅ **켜짐** | 새 씬 안에서 루트의 위치가 **원점(0,0,0)** 이 된다 |
| `Reset Rotation` | ❌ 꺼짐 | 회전을 0 으로 |
| `Reset Scale` | ❌ 꺼짐 | 스케일을 1 로 |

**원본 씬은 그대로 보인다** — 남는 인스턴스는 떼어내기 전의 위치·회전·스케일을 그대로
물려받기 때문이다(연결해 둔 시그널과 `%` 고유 이름도 유지된다).
달라지는 것은 **새로 만들어진 `boxes.tscn` 을 열었을 때**뿐이다. 원점에 놓여 있다.

**이 기본값이 맞는 경우가 대부분이다.** 재사용할 부품은 원점에 있어야 어디에 갖다 놔도
예측 가능하기 때문이다. 다만 **여러 부품의 상대 위치가 의미를 갖는 묶음**(예: 원점에서 멀리
떨어진 지형 위에 배치한 구조물)이라면 끄고 저장한다.

### 언제 쓰나

여러 곳에서 반복해 쓸 물건을 **이미 현재 씬 안에 만들어 놨을 때**다.

- 적 캐릭터와 그 충돌체·애니메이션
- 총과 총구·발사 이펙트
- 문과 손잡이·충돌체
- 상자 여러 개로 이루어진 구조물
- UI 패널과 그 아래 버튼·라벨

라리엔에서는 **맵에 반복 배치할 지물**(가로등, 표지판, 잔해 더미)이 여기에 해당한다.
블록아웃 중 손으로 조합해 본 묶음을 씬으로 떼어내면 그때부터 인스턴싱 대상이 된다.
→ [level-design.md](../level-design.md)

### 비슷한 메뉴와 헷갈리지 않는다

| 메뉴 | 하는 일 | 새 `.tscn` 이 생기나 |
|---|---|---|
| **`Save Branch as Scene...`** | **선택한 노드와 그 자손만** 새 씬으로 분리하고, 그 자리를 인스턴스로 교체 | ✅ |
| `Scene > Save Scene As...` | **지금 열려 있는 씬 전체**를 다른 이름으로 저장 | ✅ (하지만 분리가 아니다) |
| `Duplicate` (`Cmd+D`) | 현재 씬 **안에서** 노드를 복제. 원본과 아무 관계가 없어 **따로 고쳐야 한다** | ❌ |
| `Scene > New Inherited Scene...` | 기존 씬을 **부모로 삼아** 변형 씬을 만드는 상속 기능 | ✅ (브랜치를 떼는 것이 아니다) |
| `Make Local` | 반대 동작. **인스턴스를 풀어** 현재 씬의 평범한 노드들로 되돌린다 | ❌ |

### 🛑 이럴 때는 거부당한다 — 메시지 그대로 읽으면 답이 있다

엔진이 막는 경우가 정해져 있다(4.7.2 소스 확인).

| 상황 | 엔진이 하는 말 | 해야 할 일 |
|---|---|---|
| **루트 노드**를 선택했다 | *Can't save the root node branch as an instantiated scene.* | 씬 전체는 브랜치가 아니다. `Save Scene As...` 나 `New Inherited Scene...` 를 쓴다 |
| 이미 **인스턴스**인 노드를 선택했다 | *Can't save the branch of an already instantiated scene.* | 변형이 필요하면 `New Inherited Scene...` 로 상속 씬을 만든다 |
| **인스턴스의 자식**을 선택했다 | *Can't save a branch which is a child of an already instantiated scene.* | **원본 씬을 열어서** 거기서 떼어낸다 |
| **상속 씬의 일부**를 선택했다 | *Can't save a branch which is part of an inherited scene.* | 마찬가지로 원본 씬에서 한다 |
| 노드를 **2개 이상** 선택했다 | *…requires selecting only one node…* | 하나만 고른다. 여러 개를 묶고 싶으면 **먼저 부모 `Node` 를 하나 만들어 넣고** 그 부모를 고른다 |

마지막 줄이 실무에서 제일 자주 걸린다. **여러 노드를 한 씬으로 떼려면 부모가 먼저 필요하다.**

### 떼어낸 뒤 — 내부를 다시 만지려면

인스턴스가 된 뒤에는 씬 독에서 **자식들이 접혀 보이지 않고, 보이더라도 편집이 잠긴다.**
그 자리에서만 손보고 싶으면 우클릭 → **`Editable Children`** 을 켠다.
다만 이렇게 바꾼 값은 **그 인스턴스에만 남는 재정의(override)** 이고,
**원본 씬에 반영되지 않는다.** 원본을 고칠 생각이면 `boxes.tscn` 을 직접 열어야 한다.

> `Editable Children` 을 다시 끄면 **그 아래에서 바꾼 값이 전부 기본값으로 되돌아간다** —
> 엔진도 끌 때 경고한다(*…will cause all properties of this subscene's descendant nodes to be
> reverted to their default.*).

### 공식 문서

- **[Save Branch as Scene 을 문장으로 설명하는 공식 문서 (3.2 UI 튜토리얼)](https://docs.godotengine.org/en/3.2/getting_started/step_by_step/ui_game_user_interface.html#turn-the-bar-and-counter-into-reusable-ui-components)**
  — *"노드 브랜치를 별도의 씬으로 캡슐화한다"* 는 설명과 브랜치의 정의(루트도 잎도 아닌
  노드와 그 자식들)가 여기 있다. **최신 4.x 문서에는 이 튜토리얼이 없어졌고**, 4.x 문서 어디에도
  이 메뉴를 이름으로 설명한 페이지가 없다(문서 검색 인덱스 확인). 기능 자체는 4.7.2 에서 그대로 동작한다.
- [인스턴싱 (4.x, stable)](https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html) — 떼어낸 씬을 다시 갖다 쓰는 쪽
- [노드와 씬 인스턴스 (4.x, stable)](https://docs.godotengine.org/en/stable/tutorials/scripting/nodes_and_scene_instances.html) — 코드에서 다루기
- [씬 구성 모범 사례 (4.x, stable)](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html) — **어디서 씬을 나눌 것인가**의 판단 기준

- [Instancing with signals](https://docs.godotengine.org/en/stable/tutorials/scripting/instancing_with_signals.html) — 찍어낸 인스턴스와 시그널로 대화하기(파트 5 와 이어진다)
- [Using SceneTree](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_tree.html) — `add_child()` 가 트리에 연결한다는 것의 정확한 뜻
---
