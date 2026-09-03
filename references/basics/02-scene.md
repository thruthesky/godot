# 2. 씬(Scene) — 파일인가 객체인가

> **[Godot 기본](../basics.md)** 의 파트 **3 / 11**
> [← 1. Godot 의 세계관 — 노드 → 씬 → 씬 속의 씬](01-world.md) · [3. 인스턴싱(Instancing) — 설계도로 실체를 찍어낸다 →](03-instancing.md)

> **이 문서로 오는 상황** — "씬" 이 **파일인지 객체인지** 헷갈릴 때 · 루트 노드와 `get_tree().root` 가 다른 이유

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
정하는 이유**가 이것이다 — 나중에 바꾸려면 전체를 다시 짜야 한다.

> **정리** — 씬을 다루는 코드는 전부 **루트 노드를 주고받는다.**
> `instantiate()` 가 돌려주는 것도, `current_scene` 이 가리키는 것도, `add_child()` 에
> 넘기는 것도 루트 노드다. **"씬"이라는 이름의 객체는 실행 중에 존재하지 않는다** —
> 존재하는 것은 `PackedScene`(설계도)과 노드들뿐이다.


---

---

## 공식 문서

- [Nodes and Scenes](https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html) — 씬 파일과 씬 인스턴스
- [Using SceneTree](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_tree.html) — `root` 와 `current_scene` 이 무엇을 가리키는지
- [클래스 레퍼런스 `PackedScene`](https://docs.godotengine.org/en/stable/classes/class_packedscene.html) — `.tscn` 을 메모리에 올린 것의 정체
