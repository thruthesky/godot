# 2. 씬(Scene) — 파일인가 객체인가

> **[Godot 기본](../basics.md)** 의 파트 **3 / 11**
> [← 1. Godot 의 세계관 — 노드 → 씬 → 씬 속의 씬](01-world.md) · [3. 인스턴싱(Instancing) — 설계도로 실체를 찍어낸다 →](03-instancing.md)

> **이 문서로 오는 상황** — "씬" 이 **파일인지 객체인지** 헷갈릴 때 · 루트 노드와 `get_tree().root` 가 다른 이유 · **`.tscn` 을 고치면 Inspector 가 바뀌는지, Inspector 를 고치면 `.tscn` 이 바뀌는지**

같은 "씬"이라는 말이 **세 가지**를 가리킨다. 이 셋을 구분하지 못하면 계속 막힌다.

| 용어 | 정체 | 어디 있나 |
|---|---|---|
| **씬 파일** (`.tscn`) | 노드 구성을 적어 둔 **텍스트 파일** = **설계도** | 디스크 |
| **씬 인스턴스** | 설계도로 만들어 낸 **실제 노드 묶음** = **실체** | 메모리 |
| **SceneTree** | 지금 돌아가는 게임의 **활성 노드 트리 전체** | 실행 중인 프로세스 |

`.tscn` 은 그냥 텍스트다. 열어 보면 이렇게 생겼다.

```ini
[gd_scene load_steps=2 format=3 uid="uid://..."]

[ext_resource type="Script" path="res://scenes/bullet.gd" id="1_b"]

[node name="Bullet" type="Node3D"]
script = ExtResource("1_b")

[node name="Body" type="MeshInstance3D" parent="."]
```

**이 파일이 있다고 게임에 총알이 생기는 것이 아니다.** 설계도일 뿐이다.
설계도를 실체로 바꾸는 것이 **인스턴싱**이다.

## 목차

| 절 | 내용 |
|---|---|
| [·](#트리-맨-위의-그것은-씬이-아니라-루트-노드다) | 트리 맨 위의 그것은 "씬"이 아니라 **루트 노드**다 |
| 　[·](#-root-라는-말은-두-곳에서-쓰인다--get_treeroot-는-demo-가-아니다) | 　🛑 `root` 라는 말은 두 곳에서 쓰인다 — `get_tree().root` 는 `Demo` 가 아니다 |
| 　[·](#루트-노드만-다른-점--엔진에서-확인한-것) | 　루트 노드만 다른 점 — 엔진에서 확인한 것 |
| 　[·](#씬을-인스턴싱하면-돌아오는-것도-루트-노드다) | 　씬을 인스턴싱하면 돌아오는 것도 **루트 노드**다 |
| 　[·](#새-씬을-만들-때-무엇을-고르나--create-root-node-패널) | 　새 씬을 만들 때 무엇을 고르나 — **`Create Root Node:`** 패널 |
| 　　[·](#-3d-scene-을-누르면-node3d-로-고정된다) | 　　🛑 `3D Scene` 을 누르면 `Node3D` 로 고정된다 |
| 　　[·](#루트-타입은-나중에-바꿀-수-있다--다만-뒷정리가-생긴다) | 　　루트 타입은 나중에 바꿀 수 **있다** — 다만 뒷정리가 생긴다 |
| [·](#inspector-에-보이는-것과-tscn-에-적힌-것--같은-노드의-두-얼굴) | **Inspector 에 보이는 것과 `.tscn` 에 적힌 것** — 같은 노드의 두 얼굴 |
| 　[·](#tscn-에는-기본값과-다른-것만-적힌다--inspector-는-전부-보여-준다) | 　`.tscn` 에는 기본값과 다른 것만 적힌다 — Inspector 는 전부 보여 준다 |
| 　[·](#이름이-11-이-아니다--positionrotationscale-은-transform-한-줄) | 　이름이 1:1 이 아니다 — `position`·`rotation`·`scale` 은 `transform` 한 줄 |
| 　[·](#tscn--inspector--에디터가-디스크에서-다시-읽을지-묻는다) | 　`.tscn` → Inspector — 에디터가 디스크에서 다시 읽을지 묻는다 |
| 　[·](#inspector--tscn--저장-전까지-메모리에만-있고-저장은-파일을-통째로-다시-쓴다) | 　Inspector → `.tscn` — 저장 전까지 메모리에만 있고, 저장은 파일을 통째로 다시 쓴다 |

---

## 트리 맨 위의 그것은 "씬"이 아니라 **루트 노드**다

에디터 Scene 독에서 이런 트리를 볼 때, 맨 위의 `Demo` 를 무엇이라 불러야 하는가.

```
Demo                    ← 이것을 뭐라고 부르나?
└─ StaticBody3D
   └─ MeshInstance3D
```

**`Demo` 를 Root Node(루트 노드)라고 부르는 쪽이 정확하다.** `Demo` 는 **노드 하나**이고,
**씬은 `Demo` 하나가 아니라 `Demo` 와 그 아래 전부를 묶은 것**이다.

| 부르는 말 | 가리키는 것 |
|---|---|
| **루트 노드** | **`Demo` 노드 하나** — 트리의 맨 위 |
| **씬** | `Demo` + `StaticBody3D` + `MeshInstance3D` **전체** |
| **씬 파일** | 그 전체를 적어 둔 `demo.tscn` |

**그렇다고 "Demo 씬"이라는 말이 틀린 것은 아니다** — 그때 `Demo` 는 **씬의 이름**이지
그 노드 하나를 씬이라고 부르는 것이 아니다. 헷갈리는 이유는 관행상 **루트 노드 이름과
씬 파일 이름을 같게 짓기 때문**이다 (`Demo` → `demo.tscn`).

> **한 문장으로** — **씬은 묶음이고, 루트 노드는 그 묶음의 맨 위 노드 하나다.**
> 트리에서 손가락으로 `Demo` 를 짚고 있다면 그것은 **루트 노드**다.

**에디터가 쓰는 말도 "루트 노드"다.** *(4.7.2 바이너리에서 확인한 UI 문자열)*

| 언제 | 에디터가 보여 주는 말 |
|---|---|
| 빈 씬을 만들면 | **`Create Root Node:`** |
| 다른 노드를 맨 위로 올리면 (Scene 독 우클릭) | **`Make Scene Root`** |
| 맨 위 노드를 지우려 하면 | **`Delete the root node "%s"?`** |
| 루트가 없는 채로 저장하면 | `A root node is required to save the scene.` |

### 🛑 `root` 라는 말은 두 곳에서 쓰인다 — `get_tree().root` 는 `Demo` 가 아니다

이쪽이 진짜 함정이다. 게임이 실행되면 Godot 은 씬 위에 **`Window` 를 자동으로 얹는다.**
그리고 **그 `Window` 의 이름도 `root`** 다.

```
root              ← get_tree().root      (Window — 엔진이 만든 것)
└─ Demo           ← get_tree().current_scene  (내 씬의 루트 노드)
   └─ StaticBody3D
      └─ MeshInstance3D
```

```gdscript
# Demo 에 붙인 스크립트에서
print(get_tree().root)            # root:<Window#...>   🛑 Demo 가 아니다
print(get_tree().current_scene)   # Demo:<Node3D#...>   ✅ 이것이 내 씬의 루트 노드
print(get_parent())               # root:<Window#...>   부모는 Window 다
```

| 코드 | 타입 | 돌아오는 것 |
|---|---|---|
| `get_tree().root` | **`Window`** | 엔진이 자동 생성한 최상위 뷰포트 — **씬과 무관** |
| `get_tree().current_scene` | `Node` | **지금 씬의 루트 노드** = `Demo` |

*(4.7.2 `--doctool` 확인 — `SceneTree.root` 는 `type="Window"` 이고 setter 가 없다.
`SceneTree.current_scene` 은 `type="Node"`.)*

### 루트 노드만 다른 점 — 엔진에서 확인한 것

| | 루트 노드 (`Demo`) | 나머지 노드 |
|---|---|---|
| **개수** | 씬마다 **정확히 하나** | 제한 없음 |
| **`owner`** | **`null`** | 루트 노드 (`Demo`) |
| **`.tscn` 의 `parent=`** | **없다** | 있다 (`parent="."` 등) |
| **`scene_file_path`** | **`res://demo.tscn`** | 빈 문자열 |
| **실행 중 부모** | `root` (`Window`) | 씬 안의 다른 노드 |

```gdscript
# 실측 출력 (4.7.2)
Demo.scene_file_path            = 'res://demo.tscn'
StaticBody3D.scene_file_path    = ''
MeshInstance3D.scene_file_path  = ''
```

`.tscn` 에서 **루트 노드에만 `parent=` 가 없는 것**이 눈으로 보이는 증거다.
위의 `.tscn` 예시에서 `[node name="Bullet" type="Node3D"]` 에는 `parent` 가 없고
`[node name="Body" ... parent="."]` 에는 있다. 엔진은 이 규칙을 강제한다 —
`Invalid scene: root node %s cannot specify a parent node.`

### 씬을 인스턴싱하면 돌아오는 것도 **루트 노드**다

```gdscript
var demo = load("res://demo.tscn").instantiate()
```

여기서 `demo` 에 담기는 것은 "씬"이라는 어떤 객체가 아니라 **`Demo` 라는 노드**다.
자식들은 그 아래에 이미 달려 있다.

```gdscript
# 실측 출력 (4.7.2)
instantiate() 반환 타입   = Node3D      # 루트 노드의 타입 그대로
instantiate() 반환 이름   = Demo        # 루트 노드의 이름 그대로
반환된 것의 자식 수       = 1           # 자식은 이미 붙어 있다
반환 직후 owner           = <Object#null>
```

**그래서 씬의 "타입"은 루트 노드의 타입이 정한다.** 루트가 `Node3D` 면 그 씬은 3D 공간에
놓을 수 있고, `Control` 이면 UI 로만 쓴다. **씬을 만들 때 루트 노드 타입을 먼저
정하는 이유**가 이것이다 — 나중에 `Change Type...` 으로 바꿀 수는 있지만
속성이 버려지고 그 씬을 쓰던 곳을 전부 확인해야 한다(바로 아래 절).

> **정리** — 씬을 다루는 코드는 전부 **루트 노드를 주고받는다.**
> `instantiate()` 가 돌려주는 것도, `current_scene` 이 가리키는 것도, `add_child()` 에
> 넘기는 것도 루트 노드다. **"씬"이라는 이름의 객체는 실행 중에 존재하지 않는다** —
> 존재하는 것은 `PackedScene`(설계도)과 노드들뿐이다.

---

### 새 씬을 만들 때 무엇을 고르나 — `Create Root Node:` 패널

**루트 노드 타입이 씬의 타입을 정하므로, 새 씬을 만들 때 가장 먼저 하는 일이 이것이다.**
`Scene > New Scene` 을 누르면 Scene 독이 비고 그 자리에 이 패널이 뜬다.

```
Create Root Node:
  ┌────────────────┐
  │ 2D Scene       │   → Node2D 를 루트로 즉시 만든다
  │ 3D Scene       │   → Node3D 를 루트로 즉시 만든다
  │ User Interface │   → Control 을 루트로 즉시 만든다
  │ Other Node     │   → 노드 검색 대화상자를 연다  ← 나머지 전부가 여기 있다
  └────────────────┘
```

*(4.7.2 바이너리에서 확인한 UI 문자열 — `Create Root Node:` · `2D Scene` ·
`3D Scene` · `User Interface` · `Other Node`)*

**앞의 셋은 바로가기 버튼이고, `Other Node` 만 성격이 다르다.**

| 버튼 | 하는 일 |
|---|---|
| `2D Scene` · `3D Scene` · `User Interface` | **정해진 한 타입**을 즉시 루트로 만든다. 고를 여지가 없다 |
| **`Other Node`** | **`Create Node` 대화상자**를 연다 — 엔진의 **모든 노드 타입을 검색**해 고른다 |

대화상자에는 검색창과 함께 **`Favorites:`** · **`Recent:`** · **`Matches:`** 가 보인다
*(4.7.2 확인)*. 자주 쓰는 타입은 별표를 눌러 `Favorites:` 에 두면 다음부터 검색 없이 고른다.

#### 🛑 `3D Scene` 을 누르면 `Node3D` 로 고정된다

3D 게임을 만든다고 해서 늘 `3D Scene` 이 답인 것은 아니다.
**`Node3D` 는 위치·회전·크기만 갖는 가장 단순한 3D 노드**라 이동 기능이 없다.

| 만들려는 것 | 루트 타입 | 어떻게 고르나 |
|---|---|---|
| 지형·기물처럼 **가만히 있는 것**을 담는 씬 | `Node3D` | ✅ `3D Scene` 버튼 |
| **움직이는 캐릭터** (PC·몹) | `CharacterBody3D` | 🛑 **`Other Node`** 로 검색 |
| 화면 UI (HUD·메뉴) | `Control` · `CanvasLayer` | `User Interface` 또는 `Other Node` |

`CharacterBody3D` 를 골라야 **`velocity` · `move_and_slide()` · `is_on_floor()`** 를
물려받는다. `Node3D` 로 시작하면 이것들이 없어서 캐릭터를 움직일 수 없다
(→ [9. 컨트롤러](09-controller.md)).

#### 루트 타입은 나중에 바꿀 수 **있다** — 다만 뒷정리가 생긴다

*"루트 타입은 나중에 바꿀 수 없다"* 는 말을 듣게 되는데, **사실이 아니다.**
Scene 독에서 노드를 **우클릭 → `Change Type...`** 이 있다
*(4.7.2 확인 — 에디터 액션 `scene_tree/change_node_type`)*.

**그래도 처음에 맞게 고르는 편이 낫다.** 타입을 바꾸면 —

| 바뀌면 | 무슨 일이 생기나 |
|---|---|
| 새 타입에 없는 속성 | **버려진다** — 인스펙터에서 설정한 값이 사라진다 |
| 그 노드에 붙은 스크립트의 `extends` | 맞지 않으면 **오류가 난다** |
| 그 씬을 인스턴싱해 쓰던 다른 씬 | 타입 전제가 깨진 곳을 **직접 찾아 고쳐야 한다** |

**"바꿀 수 없다"가 아니라 "바꾸면 손이 간다"** 가 정확한 이유다.
실제로 `Change Type...` 이 필요한 상황도 있다 —
예제 §9 에서 `Node3D` 로 묶은 벽을 `CSGCombiner3D` 로 바꿔 고친다
([09-step8-walls.md](../example/09-step8-walls.md)).


---

## Inspector 에 보이는 것과 `.tscn` 에 적힌 것 — 같은 노드의 두 얼굴

> **이 절로 오는 상황** — "`.tscn` 을 고치면 Inspector 가 바뀌나? Inspector 를 고치면 `.tscn` 이 바뀌나?"

**둘 다 그렇다. 다만 어느 쪽도 "즉시·자동" 은 아니다.** Inspector 가 보여 주는 것은 파일이 아니라
**메모리에 올라온 노드 객체의 프로퍼티**이고, `.tscn` 은 그 객체를 **만들 때 읽고 · 저장할 때 쓰는** 텍스트다.
둘 사이에 노드 객체(= 위에서 말한 **씬 인스턴스**)가 끼어 있어서, 방향마다 **넘어가는 순간**이 따로 있다.

```
              열 때 · Reload from disk                      값 입력
  demo.tscn  ────────────────────────▶  노드 객체 (메모리)  ◀──────────  Inspector 독
   (디스크)  ◀────────────────────────   = 씬 인스턴스
              Cmd/Ctrl+S — 파일 전체를 다시 쓴다
```

| 방향 | 언제 넘어가나 | 자동인가 |
|---|---|---|
| **`.tscn` → Inspector** | 씬을 **열 때.** 이미 열려 있으면 에디터 창에 **포커스가 돌아올 때** "디스크에서 다시 읽을까" 를 묻고, **`Reload from disk`** 를 눌러야 반영된다 | 🛑 아니다 — 묻는다 |
| **Inspector → `.tscn`** | **저장(<kbd>Cmd/Ctrl</kbd>+<kbd>S</kbd>)할 때.** 그 전까지는 메모리에만 있고 씬 탭 이름에 `(*)` 가 붙는다 | 🛑 아니다 — 저장해야 한다 |

*(4.7.2 — 엔진 소스 `editor/editor_node.cpp`·`editor/inspector/editor_inspector.cpp` 와 헤드리스 실측으로 확인. 아래 절마다 근거를 적는다.)*

### `.tscn` 에는 기본값과 다른 것만 적힌다 — Inspector 는 전부 보여 준다

`.tscn` 을 열어 보면 Inspector 에 보이는 칸의 **일부만** 적혀 있다. **저장할 때 기본값과 같은 값은 빼기 때문이다.**
Inspector 는 기본값이든 아니든 **노드가 가진 프로퍼티 전부**를 보여 준다.

헤드리스에서 `MeshInstance3D` 의 `visible` 을 `false` 로 적어 두고, 읽어서 `true`(기본값)로 되돌린 뒤
`PackedScene.pack()` → `ResourceSaver.save()` 로 저장했다 *(4.7.2 실측 — 에디터의 <kbd>Cmd/Ctrl</kbd>+<kbd>S</kbd> 도 같은 두 함수를 부른다)* —

```ini
; 저장 전 — 손으로 적은 파일
[node name="Body" type="MeshInstance3D" parent="."]
position = Vector3(1, 2, 3)
visible = false

; 저장 후 — visible 줄이 사라졌다 (기본값 true 로 되돌렸으므로)
[node name="Body" type="MeshInstance3D" parent="."]
transform = Transform3D(2, 0, 0, 0, 2, 0, 0, 0, 2, 4, 5, 6)
```

**그래서 `.tscn` 에 어떤 키가 없다고 "그 프로퍼티가 없다" 는 뜻이 아니다** — 기본값이라는 뜻이다.
반대로 Inspector 에서 칸 옆의 ↺ 로 값을 기본값으로 되돌리면 저장할 때 **그 줄이 파일에서 사라진다.**

### 이름이 1:1 이 아니다 — `position`·`rotation`·`scale` 은 `transform` 한 줄

위 실측에서 `position` 을 적어 두었는데 저장 후에는 **`transform = Transform3D(...)`** 로 바뀌었고,
`scale = (2, 2, 2)` 로 바꾼 것도 따로 적히지 않고 같은 줄에 들어갔다.
`Node3D` 의 `position`·`rotation`·`scale` 은 Inspector 에서 세 칸으로 보이지만 **저장되는 것은 `transform` 하나**다 —
세 칸은 `transform` 을 사람이 읽기 쉽게 갈라 보여 주는 것이다.

```
transform = Transform3D(2, 0, 0,   0, 2, 0,   0, 0, 2,   4, 5, 6)
                        └──── basis (회전 × 크기, 3×3) ────┘  └ origin ┘
                             scale (2,2,2) 가 대각선에          = position (4,5,6)
```

읽을 때는 **둘 다 받아들인다** — 손으로 `position = Vector3(1, 2, 3)` 이라고 적어도 노드의 `position` 은
`(1, 2, 3)` 이 된다(실측). 다만 에디터가 한 번 저장하면 `transform` 으로 바뀐다. 라리엔 3D 의 청크 씬을 열어 보면
기물마다 `transform = Transform3D(...)` 한 줄뿐이고 `position` 줄이 없는 것이 그 결과다.

> **인스턴싱한 씬의 노드**(`instance=ExtResource(...)`)에는 원칙적으로 **원본과 다른 값만** 적힌다.
> 다만 `transform` 은 원본과 같은 값으로 되돌려도 그대로 적혔다(4.7.2 실측) — 기물을 배치한 씬에
> `transform` 줄이 빠짐없이 남아 있는 이유다.

### `.tscn` → Inspector — 에디터가 디스크에서 다시 읽을지 묻는다

에디터는 파일을 **계속 감시하지 않는다.** 에디터 창에 **포커스가 돌아오는 순간**
(`NOTIFICATION_APPLICATION_FOCUS_IN`)에 열려 있는 씬마다 **디스크의 수정 시각**과 **에디터가 마지막으로
읽거나 저장한 시각**을 비교한다 *(`editor_node.cpp` `_scan_external_changes()`)*. 디스크 쪽이 새로우면 이 대화상자가 뜬다 —

```
Files have been modified outside Godot
The following files are newer on disk:
    demo.tscn
What action should be taken?
            [ Ignore external changes ]   [ Reload from disk ]
```

| 버튼 | 하는 일 | 소스 |
|---|---|---|
| **`Reload from disk`** (기본 OK) | 그 씬을 **닫았다 다시 연다** → Inspector 가 파일의 값을 보여 준다. 에디터에서 저장하지 않은 변경은 버려진다 | `_reload_modified_scenes()` |
| **`Ignore external changes`** | 🛑 **에디터에 있는 것으로 파일을 즉시 다시 저장한다** → 밖에서 한 수정이 사라진다 | `_resave_externally_modified_scenes()` |

`project.godot` 도 같은 대화상자에 오른다. **열려 있지 않은 씬**은 검사 대상이 아니고, 다음에 열 때 디스크 값을 그대로 읽는다.

🛑 **대화상자를 보지 못하는 경우가 있다** — 에디터 창이 계속 앞에 있는 동안 다른 프로그램이 파일을 바꾸면
포커스 이벤트가 없어 검사가 일어나지 않는다. 그 상태로 <kbd>Cmd/Ctrl</kbd>+<kbd>S</kbd> 를 누르면 저장 함수(`_save_scene()`)는
**디스크를 확인하지 않고** 그냥 쓰므로 밖의 수정이 덮인다. 이 함정과 대처는
[6. 에디터 화면 — 에디터 밖에서 같은 파일을 고칠 때](06-editor-screen.md#-에디터-밖에서-같은-파일을-고칠-때) 에 있다.

### Inspector → `.tscn` — 저장 전까지 메모리에만 있고, 저장은 파일을 통째로 다시 쓴다

Inspector 에서 값을 넣으면 에디터는 **노드 객체의 프로퍼티를 바꿀 뿐**이다 *(`editor_inspector.cpp` `_edit_set()` →
`undo_redo->add_do_property(object, name, value)`)*. 그래서 —

| | |
|---|---|
| 파일은 | **아직 그대로다.** 씬 탭 이름에 `(*)` 가 붙는다 |
| <kbd>Cmd/Ctrl</kbd>+<kbd>Z</kbd> | 메모리의 값만 되돌린다 — 파일과 무관하다 |
| <kbd>Cmd/Ctrl</kbd>+<kbd>S</kbd> | 노드 트리 전체를 `PackedScene` 으로 묶어(`pack`) **파일을 처음부터 다시 쓴다** |

**"다시 쓴다" 는 것은 고친 줄만 바꾸는 것이 아니다.** 파일 전체가 노드 트리에서 새로 만들어지므로 —

- 손으로 넣은 **`;` 주석은 사라진다** *(실측 — 주석 두 줄을 넣고 제자리 저장하니 둘 다 없어졌다)*
- 줄 순서·빈 줄은 에디터 규칙대로 다시 정해진다
- 기본값과 같아진 줄은 빠지고, `position`·`scale` 은 `transform` 이 된다 (위 두 절)

**그래서 `.tscn` 에 남겨 두고 싶은 설명은 주석이 아니라 노드의 `Editor Description`** (Inspector 맨 아래 `Node > Editor Description`) **에 넣는다.**
그것은 프로퍼티라서 저장하면 `editor_description = "..."` 로 파일에 남는다 *(실측)*. 라리엔 3D 가 청크 씬의 뜻을
파일 이름이 아니라 루트 노드의 Editor Description 에 두는 것이 이 방식이다.

---

## 공식 문서

- [Nodes and Scenes](https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html) — 씬 파일과 씬 인스턴스
- [Using SceneTree](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_tree.html) — `root` 와 `current_scene` 이 무엇을 가리키는지
- [클래스 레퍼런스 `PackedScene`](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) — `.tscn` 을 메모리에 올린 것의 정체
- [Inspector dock](https://docs.godotengine.org/en/stable/tutorials/editor/inspector_dock.html) — Inspector 독의 구성
- [Resources](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html) — 노드가 아닌 것(`.tres`)이 파일로 저장되는 방식
