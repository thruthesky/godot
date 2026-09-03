# 1. Godot 의 세계관 — 노드 → 씬 → 씬 속의 씬

> **[Godot 기본](../basics.md)** 의 파트 **2 / 11**
> [← 0. 기본적으로 공부해야 할 목록](00-study-list.md) · [2. 씬(Scene) — 파일인가 객체인가 →](02-scene.md)

> **이 문서로 오는 상황** — 노드·씬·씬 트리가 무엇인지, 인스펙터 속성이 어디서 오는지, `MeshInstance3D` 를 넣어도 왜 안 보이는지, 충돌이 왜 안 되는지 — **Godot 의 구조 자체**가 궁금할 때

Godot 의 구조는 세 문장으로 끝난다.

```
① 모든 것은 노드(Node)다.        — 이미지 한 장, 소리 하나, 충돌체 하나가 전부 노드
② 노드를 묶은 것이 씬(Scene)이다. — 여러 노드를 부모-자식으로 엮어 하나의 덩어리로
③ 씬은 다른 씬의 부품이 된다.     — 그 덩어리를 또 다른 씬 안에 넣는다  ← 이것이 인스턴싱
```

**③ 이 Godot 의 핵심**이다. 다른 엔진처럼 "레벨"과 "프리팹"을 다른 개념으로 나누지 않고,
**둘 다 그냥 씬**이다. 총알도 씬, 적도 씬, 맵도 씬, 게임 전체도 씬이다.
크기와 역할만 다를 뿐 **파일 형식도 다루는 법도 똑같다.**

| 다른 엔진 | Godot |
|---|---|
| Scene(레벨) / Prefab(재사용 부품) — 다른 개념 | **둘 다 `.tscn` 씬** |
| GameObject + Component 조합 | **노드 자체가 기능을 가짐**. 조합은 부모-자식으로 |

## 목차

| 절 | 내용 |
|---|---|
| [·](#노드란-무엇인가) | 노드란 무엇인가 |
| [·](#씬-트리가-정하는-것과-정하지-않는-것) | 씬 트리가 정하는 것과 **정하지 않는 것** |
| [·](#인스펙터는-상속-사슬을-그대로-세로로-펼친-것이다) | 인스펙터는 **상속 사슬을 그대로 세로로 펼친 것**이다 |
| [·](#다른-노드를-가리키는-세-가지-방법--export-를-쓴다) | 다른 노드를 가리키는 세 가지 방법 — **`@export` 를 쓴다** |
| [·](#같은-높이에-두-면을-겹치지-않는다--z-fighting) | 같은 높이에 **두 면을 겹치지 않는다** — z-fighting |
| [·](#노드와-리소스는-다르다) | 노드와 리소스는 다르다 |
| [·](#3d-게임에서-실제로-만나는-노드들--몸--모양--그림) | 3D 게임에서 실제로 만나는 노드들 — 몸 · 모양 · 그림 |
| [·](#해-보기--플레이어-캐릭터를-만든다-노드-4개) | 해 보기 — 플레이어 캐릭터를 만든다 (노드 4개) |

---

## 노드란 무엇인가

**한 가지 일을 하는 부품**이다. 이름·위치를 갖고, 부모와 자식을 가질 수 있다.

```
Player (CharacterBody3D)      ← 움직이고 부딪힌다
├─ MeshInstance3D             ← 보인다
├─ CollisionShape3D           ← 부딪힐 모양
├─ Camera3D                   ← 따라다니며 비춘다
└─ AudioStreamPlayer3D        ← 소리를 낸다
```

노드는 **상속 계층**을 갖는다. `CharacterBody3D` 는 `Node3D` 를 물려받고,
`Node3D` 는 `Node` 를 물려받는다. 그래서 `Node3D` 를 상속한 모든 노드는
`position` 을 갖는다 — 개별 노드마다 외울 필요가 없다.


## 씬 트리가 정하는 것과 **정하지 않는 것**

트리에서 부모-자식으로 묶으면 많은 것이 따라오지만, **따라오지 않는 것**도 있다.
이 경계를 모르면 "왜 이게 되지" 또는 "왜 이게 안 되지"에서 계속 막힌다.

| 트리가 **정하는** 것 | |
|---|---|
| **좌표(Transform) 상속** | 부모를 옮기면 자식이 따라 움직인다 |
| **함께 지워진다** | 부모를 `queue_free()` 하면 자식도 사라진다 |
| **생명주기 순서** | 자식의 `_ready()` 가 부모보다 먼저 불린다 |
| **처리·입력 전달 순서** | 트리 순서를 따른다 |

| 트리가 **정하지 않는** 것 | |
|---|---|
| 🔑 **누구와 충돌하는가** | 트리에서 어디에 있든 상관없다 |

### 🔑 충돌은 씬 트리가 아니라 **물리 공간(space)** 에서 일어난다

**같은 3D 월드에 있는 물리 객체끼리는 트리에서 어디에 있든 서로 부딪힌다.**

```
Main
├─ Level
│  └─ Geometry (CSGCombiner3D)   use_collision = true
│     ├─ Floor
│     └─ Walls
└─ Player (CharacterBody3D)      ← Geometry 의 자식이 아니라 형제인데도 바닥 위에 선다
```

화면에서 바닥 **위**에 서 있는 것과, 트리에서 **아래**에 있는 것은 전혀 다른 이야기다.
플레이어는 `Geometry` 의 자식이 아니지만 아무 문제 없이 바닥에 선다.

**엔진에서 확인한 결과** — 플레이어를 트리의 여러 위치로 옮겨 놓고 똑같이 떨어뜨렸다.

| 플레이어를 어디에 두었나 | 낙하 후 `y` | `is_on_floor()` | 옆으로 밀면 |
|---|---|---|---|
| `Main` 의 자식 | `1.00` | `true` | 벽에 막힘 ✅ |
| **`Geometry` 의 자식** | `1.00` | `true` | 벽에 막힘 ✅ |
| **완전히 무관한 다른 가지 아래** | `1.00` | `true` | 벽에 막힘 ✅ |

**세 결과가 소수점까지 똑같다.** 트리 위치는 충돌에 아무 영향이 없다.

물리 객체는 씬 트리에 들어갈 때 **`World3D` 의 물리 공간(space)에 등록**되고,
충돌 판정은 **그 공간 안에서** 이루어진다. 트리는 그 등록에 관여하지 않는다.

### 그럼 무엇이 충돌을 정하는가 — 조건 세 가지

**양쪽 모두** 갖춰야 한다. 한쪽만으로는 아무 일도 일어나지 않는다.

| # | 조건 | 확인할 것 |
|---|---|---|
| ① | **물리 객체일 것** | `CollisionObject3D` 계열이거나 `use_collision` 을 켠 CSG 루트 |
| ② | **모양이 있을 것** | `CollisionShape3D` 의 `Shape` 이 채워져 있는가 |
| ③ | **레이어·마스크가 겹칠 것** | `collision_layer` · `collision_mask` (둘 다 기본 `1`) |

`collision_layer` 는 **"나는 어느 층에 있는가"**(남에게 보이는 방식),
`collision_mask` 는 **"나는 어느 층을 보는가"**(내가 감지하는 대상)다.
**A 가 B 를 감지하려면 `A.collision_mask` 와 `B.collision_layer` 가 겹쳐야 한다.**

### 🔍 물리 바디는 **"자격"과 "형체"가 따로다**

`CharacterBody3D` 에는 `use_collision` 같은 스위치가 없다. 대신 `CollisionShape3D` 를
자식으로 넣는다. **그럼 콜리전은 원래 있는 것인가, 자식이 켜 주는 것인가.**

**둘 다 아니고 그 중간이다.** 상속 계층을 보면 답이 나온다(doctool 확인).

```
CharacterBody3D  →  PhysicsBody3D  →  CollisionObject3D  →  Node3D
                                       ↑ "충돌할 수 있는 물체" 라는 자격
```

**`CollisionObject3D` 를 상속하므로 태어날 때부터 물리 바디이고, 물리 공간에도 등록된다.**
**그런데 모양이 하나도 없다.** 형체가 없으니 아무것과도 부딪히지 않는다.

그래서 **`CollisionShape3D` 는 "옵션을 켜는 것"이 아니라 "빈 몸에 형체를 넣어 주는 것"** 이다.

| | 자격 (물리 객체인가) | 형체 (모양이 있는가) |
|---|---|---|
| `CharacterBody3D` 만 있을 때 | ⭕ **있다** | ❌ **없다** → 아무것과도 안 부딪힌다 |
| `CollisionShape3D` 를 넣으면 | ⭕ 있다 | ⭕ **생긴다** → 비로소 부딪힌다 |

**모양을 따로 넣는 이유** — 보이는 모습과 부딪히는 모양은 **달라야 하는 경우가 많다.**
캐릭터는 팔다리가 있어도 충돌은 **캡슐 하나**로 처리하는 것이 훨씬 싸고 안정적이다.

#### CSG 와는 방향이 정반대다

| | **CSG** (`CSGCombiner3D`) | **`CharacterBody3D`** |
|---|---|---|
| 태생 | **시각 메시**가 주인공 | **물리 바디**가 주인공 |
| 기본 상태 | 콜리전이 **아예 없다** | 몸은 있는데 **모양이 0개** |
| 콜리전을 갖는 법 | `use_collision` 을 켜면 **메시로부터 만들어 준다** | `CollisionShape3D` 가 **모양을 공급한다** |
| 방향 | 보이는 것 **→** 물리 | 물리 **←** 따로 넣어 준 모양 |

**그래서 한쪽에는 스위치가 있고 다른 쪽에는 없다.** CSG 는 이미 있는 메시를 물리에
쓸지 말지를 정하는 것이고, 물리 바디는 없는 모양을 넣어 주는 것이다.

### ⚠️ 단, **내 몸을 조립하는 것**은 트리 관계를 따진다

여기서 혼동이 생긴다. **"누구와 부딪히는가"와 "내 몸이 어떻게 생겼는가"는 다른 문제**다.

| 질문 | 트리 관계가 중요한가 |
|---|---|
| **누구와 부딪히는가** | ❌ 무관 — 물리 공간과 레이어/마스크가 정한다 |
| **내 몸이 어떻게 생겼는가** | ⭕ **중요하다** — 아래 참고 |

`CollisionShape3D` 는 **그 자체로는 물리 객체가 아니다.** 부모를 찾아
**자기 `Shape` 을 등록해 주는 도우미 노드**이고, **직속 부모만** 본다.

```
CharacterBody3D
└─ CollisionShape3D          ✅ 등록된다

CharacterBody3D
└─ Node3D                    ← 중간에 끼면
   └─ CollisionShape3D       🛑 등록되지 않는다
```

**엔진에서 확인한 결과** (물리 서버에 실제로 등록된 shape 개수):

| 구조 | 등록된 shape | 낙하 후 `y` |
|---|---|---|
| `CharacterBody3D` > `CollisionShape3D` | **1** | `1.00` 바닥에 섬 ✅ |
| **`CharacterBody3D` > `Node3D` > `CollisionShape3D`** | **0** | `-18.09` 🛑 뚫고 떨어짐 |
| `CollisionShape3D` 는 있지만 `Shape` 이 비어 있음 | **0** | `-18.09` 🛑 |
| `CollisionShape3D` 가 아예 없음 | **0** | `-18.09` 🛑 |

**CSG 도 같은 함정이 있다** — `CSGCombiner3D` 아래에 `Node3D` 를 끼우면
그 아래 도형이 형상과 콜리전에서 통째로 빠진다.

> 🔑 **한 줄로** — **누구와 부딪히는가는 트리와 무관하지만,
> 내 몸을 이루는 부품은 직속 부모에게만 붙는다.**
> 정리용으로 빈 `Node3D` 를 끼울 때는 **그 아래에 콜리전이나 CSG 도형이 없는지** 확인한다.

실전 예제와 전체 검증 수치는 [example.md](../example.md) §9 에 있다.

## 인스펙터는 **상속 사슬을 그대로 세로로 펼친 것**이다

**질문 셋을 한 번에 답한다.**

1. 인스펙터 맨 위가 현재 노드고, 그 아래로 부모 클래스들의 속성이 이어지는가 → **그렇다**
2. `Node3D` 를 상속하면 전부 `Transform`·`Rotation`·`Scale` 을 갖는가 → **그렇다**
3. 그 값을 수정할 수 있는가 → **그렇다**

### 두 화면이 같은 것을 보여준다

노드를 추가할 때 뜨는 **Create New Node** 창의 `Description` 에 상속 사슬이 적혀 있다.

```
Class CSGCylinder3D < CSGPrimitive3D < CSGShape3D < GeometryInstance3D
      < VisualInstance3D < Node3D < Node < Object
```

**엔진에서 확인한 사슬도 정확히 같다.**

그리고 그 노드를 선택하면 **인스펙터가 이 사슬을 뒤집어 세로로 늘어놓는다.**

```
Create New Node 의 사슬                인스펙터의 그룹 (위 → 아래)
────────────────────────              ─────────────────────────
CSGCylinder3D          ─────────────→  ▸ CSGCylinder3D   ← 현재 노드 자신
  < CSGPrimitive3D     ─────────────→  ▸ CSGPrimitive3D
  < CSGShape3D         ─────────────→  ▸ CSGShape3D
  < GeometryInstance3D ─────────────→  ▸ GeometryInstance3D
  < VisualInstance3D   ─────────────→  ▸ VisualInstance3D
  < Node3D             ─────────────→  ▸ Node3D          ← Transform 이 여기 있다
  < Node               ─────────────→  ▸ Node
  < Object                              (Object 는 표시되지 않는다)
```

**맨 위가 "이 노드만의 것", 아래로 갈수록 "더 많은 노드가 공유하는 것"** 이다.
`Radius`·`Height` 는 원기둥에만 있지만, `Position` 은 3D 노드 전부가 갖는다.

> 🔑 **인스펙터에서 어떤 속성이 안 보이면, 그 노드가 그 클래스를 상속하지 않는 것이다.**
> 반대로 낯선 그룹 이름이 보이면 **그것이 이 노드의 조상**이다.

### `Node3D` 가 주는 것 — 엔진에서 확인한 9개

| 프로퍼티 | 기본값 |
|---|---|
| **`position`** | `Vector3(0, 0, 0)` |
| **`rotation`** | `Vector3(0, 0, 0)` |
| **`scale`** | `Vector3(1, 1, 1)` |
| `transform` | `Transform3D(1,0,0, 0,1,0, 0,0,1, 0,0,0)` |
| `rotation_edit_mode` | `0` (Euler) |
| `rotation_order` | `2` (YXZ) |
| `top_level` | `false` |
| `visible` | `true` |
| `visibility_parent` | `NodePath("")` |

인스펙터의 **`Node3D > Transform`** 을 펼치면 나오는 `Position`·`Rotation`·`Scale`
그리고 그 아래 `Rotation Edit Mode`·`Rotation Order`·`Top Level`·`Visibility` 가
정확히 이 목록이다.

### **120개** 클래스가 이것을 물려받는다

엔진에서 세어 보니 `Node3D` 를 (간접 포함) 상속하는 클래스가 **120개**다.
전부 `Position`·`Rotation`·`Scale` 을 갖고, **전부 수정할 수 있다.**

| 노드 | 사슬 |
|---|---|
| `Camera3D` | `Camera3D < Node3D` |
| `CollisionShape3D` | `CollisionShape3D < Node3D` |
| `MeshInstance3D` | `MeshInstance3D < GeometryInstance3D < VisualInstance3D < Node3D` |
| `CharacterBody3D` | `CharacterBody3D < PhysicsBody3D < CollisionObject3D < Node3D` |
| `DirectionalLight3D` | `DirectionalLight3D < Light3D < VisualInstance3D < Node3D` |
| `CSGBox3D` | `CSGBox3D < CSGPrimitive3D < CSGShape3D < GeometryInstance3D < VisualInstance3D < Node3D` |

**사슬의 길이는 제각각이지만 끝에 `Node3D` 가 있으면 결과는 같다.**
그래서 카메라를 옮기든 캐릭터를 옮기든 **`Position` 을 고치는 방법은 하나**다.

### 🛑 반례 — `WorldEnvironment` 에는 `Transform` 이 없다

3D 씬 안에 있다고 전부 `Node3D` 인 것은 아니다.

```
WorldEnvironment < Node < Object      ← Node3D 가 없다
```

**하늘·안개는 공간의 한 지점에 있는 것이 아니라 씬 전체에 걸리는 설정**이라
위치가 필요 없다. 그래서 인스펙터에도 `Transform` 그룹이 나오지 않는다.

**"3D 씬에 있으니 당연히 위치가 있겠지"가 아니라, 상속 사슬이 답이다.**

### 각 계층이 **무엇을 보태는가** — `MeshInstance3D` 로 읽기

`MeshInstance3D` 를 선택하면 인스펙터에 그룹이 다섯 개 나온다.
**각 그룹은 그 클래스가 새로 보탠 것만** 담는다(엔진에서 프로퍼티를 추출해 대조했다).

| 인스펙터 그룹 | 그 클래스가 보태는 것 | 뜻 |
|---|---|---|
| **`MeshInstance3D`** | `mesh` · `skeleton` · `skin` | **무엇을 그릴 것인가** |
| `GeometryInstance3D` | `cast_shadow` · `material_override` · `visibility_range_*` · `gi_*` · `lod_bias` | 그리는 **방식** — 그림자·LOD·거리 |
| `VisualInstance3D` | `layers` · `sorting_offset` | **어느 레이어**에 그릴 것인가 |
| `Node3D` | `position` · `rotation` · `scale` · `transform` · `visible` | **어디에 놓을 것인가** |
| `Node` | `process_mode` · `editor_description` · `name` · `owner` | 씬 트리의 **일원으로서의 것** |

**아래로 갈수록 추상적이고 위로 갈수록 구체적**이다.
`Node` 는 "트리에 있다", `Node3D` 는 "공간에 있다", `VisualInstance3D` 는 "화면에 그려진다",
`GeometryInstance3D` 는 "형상을 그린다", `MeshInstance3D` 는 "이 메시를 그린다".

### 🛑 `MeshInstance3D` 를 추가하면 왜 아무것도 안 보이나

**`Mesh` 가 `<empty>` 이기 때문이다.** 그릴 형상이 없으니 그릴 것도 없다.

**엔진에서 확인한 것** — 갓 만든 `MeshInstance3D` 는 이렇다.

```
mesh       = <Object#null>
get_aabb() = [P: (0,0,0), S: (0,0,0)]      ← 차지하는 공간이 0
```

`BoxMesh` 를 넣으면 그 자리에서 바뀐다.

```
mesh       = <BoxMesh#…>
get_aabb() = [P: (-0.5,-0.5,-0.5), S: (1,1,1)]
삼각형 12개 · 정점 36개
```

> 🔑 **`MeshInstance3D` 는 "메시를 담는 그릇"이지 형상 자체가 아니다.**
> 그릇만 놓아서는 아무 일도 일어나지 않는다.

**넣는 법** — 인스펙터 `Mesh` 칸 → `<empty>` 클릭 → `New BoxMesh` / `New CapsuleMesh` /
`New PlaneMesh` … 또는 `.obj`·`.glb` 에서 가져온 메시를 지정한다.
**같은 `MeshInstance3D` 가 어떤 메시를 담느냐에 따라 상자도 되고 사람도 된다.**

### `mesh` 는 물려받은 것인가, 고유한 것인가 — **고유하다**

`ClassDB` 로 각 클래스가 **자기가 선언한** 프로퍼티만 뽑아 확인했다.

| 클래스 | 자기가 선언한 `mesh` |
|---|---|
| **`MeshInstance3D`** | ✅ **있다** |
| `GeometryInstance3D` | ❌ |
| `VisualInstance3D` | ❌ |
| `Node3D` | ❌ |
| `Node` | ❌ |

**`mesh` 는 `MeshInstance3D` 가 처음 도입한 것**이고, 그래서 인스펙터에서도
**맨 위 `MeshInstance3D` 그룹**에 놓인다. 위치는 우연이 아니다.

### Mesh · 삼각형 · Collision 을 한 줄씩

| 용어 | 한 줄 |
|---|---|
| **Mesh(메시)** | **삼각형을 모아 만든 3D 형상 데이터.** 노드가 아니라 **리소스**라서 여러 노드가 공유한다 |
| **삼각형** | 3D 형상의 **최소 단위**. GPU 는 삼각형만 그린다 — 상자 하나가 면 6개 × 2 = **12개**(실측) |
| **Collision(콜리전)** | **부딪히는 모양.** 보이는 메시와 **별개**이고, 없으면 그냥 통과한다 |

**보이는 것과 부딪히는 것은 다른 물건이다.** `MeshInstance3D` 는 보이기만 하고
부딪히지 않는다. 부딪히게 하려면 `StaticBody3D` + `CollisionShape3D` 를 따로 둔다.

- 메시·텍스처·머티리얼 상세 → [rendering-3d.md](../rendering-3d.md), [dictionary.md](../dictionary.md)
- 삼각형 수와 성능 → [lowend-3gb-60fps.md](../lowend-3gb-60fps.md) §1
- 콜리전이 성립하는 조건 → 위의 **"씬 트리가 정하는 것과 정하지 않는 것"**, [physics-3d.md](../physics-3d.md)
- 메시에서 콜리전을 자동 생성 → [physics-3d.md](../physics-3d.md)

### `MeshInstance3D` 와 `CSGBox3D` 를 나란히 놓으면

```
MeshInstance3D <                        GeometryInstance3D < VisualInstance3D < Node3D < Node < Object
CSGBox3D < CSGPrimitive3D < CSGShape3D < GeometryInstance3D < VisualInstance3D < Node3D < Node < Object
                                        └──────────────── 여기부터 같다 ────────────────┘
```

**공통 조상은 `GeometryInstance3D` 부터**다. 그래서 둘 다 그림자·LOD·레이어·Transform 을
같은 방식으로 다룬다. 다른 것은 **위쪽 두세 칸뿐**이다.

| | `MeshInstance3D` | `CSGBox3D` |
|---|---|---|
| 형상을 어디서 | **`mesh` 에 담아 준 리소스** | **`size` 로 그 자리에서 계산** |
| 콜리전 | 없다 (따로 만든다) | **`use_collision`** 으로 켤 수 있다 |
| 형상 합치기 | 안 된다 | **`operation`** 으로 더하고 뺀다 |
| 비용 | 싸다 (미리 만든 것을 그린다) | **런타임 CPU 계산** — 최종물로 쓰지 않는다 |

### 🛑 "대부분의 노드가 이 구조인가" — **아니다**

`Node` 는 공통 조상이 맞지만, **아래로 갈수록 급격히 좁아진다.**
엔진의 클래스 1,074개를 세어 본 결과다.

| 클래스 | 이것을 상속하는 클래스 수 | `Node` 자손 중 비율 |
|---|---|---|
| `Node` | **283** | 100 % |
| `Node3D` | **120** | **42 %** |
| `VisualInstance3D` | **43** | **15 %** |
| `GeometryInstance3D` | **18** | **6 %** |

**`GeometryInstance3D` 까지 내려가는 것은 6% 뿐이다.**

게다가 `Node` 바로 아래에서 **갈래가 갈린다.**

| `Node` 를 직접 상속 | 그 아래 자손 |
|---|---|
| **`CanvasItem`** (2D·UI) | **127개** ← `Node3D` 보다 많다 |
| **`Node3D`** (3D) | **120개** |
| `Viewport` | 11개 |
| `Timer` · `HTTPRequest` · `AudioStreamPlayer` · `WorldEnvironment` … | 0개 |

```
Node ─┬─ CanvasItem ──┬─ Node2D ── Sprite2D …        127개  (2D·UI)
      │               └─ Control ── Button …
      ├─ Node3D ──── VisualInstance3D ── …           120개  (3D)
      ├─ Viewport …                                   11개
      └─ Timer · HTTPRequest · WorldEnvironment …      각 0개
```

### 그래서 "대부분 비슷한 속성을 갖나" — **공통은 위쪽에만 있다**

| 속성 | 몇 개가 갖나 |
|---|---|
| `name` · `process_mode` · `owner` (**`Node`**) | **283개 전부** |
| `position` · `rotation` · `scale` (**`Node3D`**) | **120개** — 버튼·타이머·`WorldEnvironment` 에는 없다 |
| `layers` · `sorting_offset` (**`VisualInstance3D`**) | **43개** |
| `cast_shadow` · `visibility_range_*` (**`GeometryInstance3D`**) | **18개** |

**"모든 노드가 비슷하다"가 아니라 "위로 갈수록 공통이 많아진다"** 가 맞다.
`Button` 과 `MeshInstance3D` 가 공유하는 것은 **`Node` 수준의 것뿐**이다.

> 🔑 **그래서 상속 사슬을 읽는 것이 곧 "이 노드가 무엇을 할 수 있는가"를 읽는 것이다.**
> 사슬에 `Node3D` 가 없으면 위치가 없고, `VisualInstance3D` 가 없으면 화면에 그려지지 않는다.


### 상속 사슬을 확인하는 세 가지 방법

| 방법 | 어디서 |
|---|---|
| **Create New Node 창** | 노드를 고르면 `Description` 첫 줄에 사슬이 나온다 |
| **인스펙터의 그룹 머리글** | 위에서 아래로 읽으면 그대로 사슬이다 |
| **온라인 문서** | 클래스 페이지 상단의 **Inherits:** 줄 |

> 💡 **스크립트의 `extends` 도 같은 이야기다.** `extends CharacterBody3D` 라고 쓰면
> 그 사슬 전체(`PhysicsBody3D`·`CollisionObject3D`·`Node3D`·`Node`)의 기능을
> 한꺼번에 물려받는다. 그래서 `velocity` 도 `position` 도 선언 없이 쓸 수 있다.


## 다른 노드를 가리키는 세 가지 방법 — **`@export` 를 쓴다**

카메라가 플레이어를 따라가려면 **카메라 스크립트가 플레이어 노드를 잡아야** 한다.
방법이 셋인데, **깨지는 조건이 다르다.**

| 방법 | 코드 | 이름을 바꾸면 | 노드를 옮기면 |
|---|---|---|---|
| **경로** | `$"../Player"` | 🛑 깨진다 | 🛑 깨진다 |
| **고유 이름** | `%Player` | 🛑 깨진다 | ✅ 버틴다 |
| **`@export` ★** | `@export var target: Node3D` | ✅ **버틴다** | ✅ **버틴다** |

```gdscript
## 카메라가 따라갈 대상. 인스펙터에서 노드를 끌어다 넣는다.
@export var target: Node3D
```

### 🔍 왜 `@export` 만 안 깨지나 — 저장되는 곳이 다르다

**흔한 설명은 "노드 그 자체를 가리키기 때문"인데, 저장 형태를 보면 더 정확해진다.**
엔진에서 `.tscn` 을 직접 만들어 확인했다.

```
[node name="CameraRig" type="Node3D" parent="." node_paths=PackedStringArray("target")]
script = ExtResource("1_ldub0")
target = NodePath("../Player")
```

**`@export` 도 저장되는 값은 경로(`NodePath`)다.** 차이는 그다음이다.

| | 어디에 적히나 | 에디터가 고칠 수 있나 |
|---|---|---|
| `$"../Player"` | **스크립트 안의 문자열** | 🛑 **못 고친다** — 그냥 글자다 |
| `@export` | **씬 데이터**(`node_paths=` 로 표시됨) | ✅ **고친다** |

`node_paths=PackedStringArray("target")` 이 **"이 프로퍼티는 노드 경로다"** 라고
에디터에 알리는 표시다. 그래서 노드 이름을 바꾸거나 옮기면
**에디터가 이 값을 추적해 자동으로 갱신한다.**

**코드 안의 문자열은 에디터가 손댈 수 없다.** 이것이 갈림길이다.

### 깨졌을 때가 특히 고약하다

경로 방식은 **오류가 엉뚱한 곳을 가리킨다.**

```
Invalid access to property 'global_position' on a base object of type 'null instance'
```

좌표 문제처럼 보이지만 **진짜 원인은 그 앞줄의 `$` 경로**다.
`$"../Player"` 가 조용히 `null` 을 돌려준 뒤, 그 `null` 에서 `.global_position` 을
읽으려 할 때서야 터지기 때문이다.

**드래그로 넣으면 그런 실수가 애초에 불가능하다** — 존재하는 노드만 들어가고,
`Node3D` 가 아닌 것은 아예 들어가지 않는다.
**문자열 오타는 아무도 못 잡지만, 드래그는 잡을 게 없다.**

### 카메라라서 더 그렇다

**카메라가 비추는 대상은 바뀐다.** 컷신에서 NPC 를, 관전 모드에서 다른 플레이어를,
데모 씬에서 테스트용 더미를 비춘다.

경로가 코드에 박혀 있으면 **그때마다 스크립트를 고쳐야** 한다.
`@export` 면 인스펙터에서 다른 노드를 넣으면 끝이고,
**`camera_rig.gd` 자체는 어느 씬에서든 그대로 재사용된다.**

### 드래그가 유일한 방법은 아니다

인스펙터의 칸을 클릭하면 **`Assign...`** 이 나오고, 노드 트리에서 골라도 된다.

```
CameraRig 선택 → 인스펙터 > Target > [Assign...] 클릭 → 트리에서 Player 선택
```

### 굳이 코드로 하겠다면 (권장하지 않는다)

```gdscript
## 🛑 이름이나 위치를 바꾸면 조용히 null 이 된다.
@onready var target: Node3D = get_node_or_null("../Player")
```

`get_node_or_null` 을 쓴 것은 **최소한의 방어**다 — `$"../Player"` 는 없으면 오류를
뱉지만 이쪽은 `null` 을 돌려주므로 `if target == null: return` 가드가 받아낸다.
**그래도 왜 카메라가 안 따라오는지 알 수 없는 상태가 되는 건 마찬가지다.**

> 🔑 **연결은 한 번만 하면 되고, 그 대가로 깨지지 않는 값을 얻는다.**


## 같은 높이에 **두 면을 겹치지 않는다** — z-fighting

바닥의 윗면을 `y = 0` 에 맞췄다면, **그 위에 무언가를 겹쳐 놓을 때 `y = 0` 을 그대로
쓰면 안 된다.** 구역 표시, 그림자 대용 원판, 길 표시처럼 **바닥에 딱 붙는 평면**이 여기 해당한다.

### 무슨 일이 벌어지나

두 면이 **정확히 같은 높이**에 있으면 GPU 는 어느 쪽이 앞인지 판단할 수 없다.
깊이 값이 같은데 부동소수점 정밀도는 유한하기 때문이다.
그 결과 **픽셀마다 승자가 뒤바뀌어** 얼룩덜룩해지거나, 각도에 따라 한쪽이 통째로 먹힌다.
이것을 **z-fighting(깊이 다툼, 지글거림)** 이라고 한다.

### 엔진에서 확인한 것

바닥(윗면 `y=0`) 위에 8×8 m 평면을 놓고 높이만 바꿔 렌더했다.
카메라는 −45°, 900×600.

| 평면의 `y` | 겹침 영역에서 **평면 색이 차지한 비율** | 화면 |
|---|---|---|
| **`0.0`** | **65.9 %** | 🛑 **평면 뒤쪽 절반이 바닥에 먹혀 사라졌다** |
| `0.001` | 96.7 % | 정상 |
| **`0.05`** | **96.9 %** | ✅ **온전한 사각형** |
| `0.2` | 97.5 % | 정상 |

`y = 0` 일 때만 **34 % 의 픽셀이 바닥에게 졌다.** 화면에서는 평면 윗변이
잘려 나간 것처럼 보인다.

### 🔑 해법 — **5 cm 띄운다**

```gdscript
zone.position.y = 0.05     # 바닥 윗면(y=0)에서 5cm 위
```

**왜 5cm 로 충분하면서 눈에 띄지 않는가** — 두 값을 함께 만족해야 한다.

| 조건 | |
|---|---|
| 깊이 다툼을 끝낼 만큼 **충분히 떨어질 것** | `0.001` 부터 이미 해결된다(실측). `0.05` 는 넉넉한 여유 |
| 떠 보이지 않을 만큼 **충분히 작을 것** | 아래 계산 |

**엔진에서 잰 화면상 이동량** (900×600 · `fov 75` · 카메라 거리 12.7 m):

| 높이 | 화면에서 위로 |
|---|---|
| **`0.05` m** | **1.09 px** |
| `0.2` m | 4.39 px |

**5cm 는 화면에서 1픽셀** 이다. 카메라가 −45° 로 내려다보므로
높이 차이가 화면 세로 방향으로 `sin(45°) ≈ 0.707` 배만 반영되고,
그마저도 픽셀 하나에 묻힌다. **뜬 것은 보이지 않으면서 겹침만 사라진다.**

> ⚠️ 이 값은 **카메라 각도와 거리에 묶여 있다.** 카메라를 지면 가까이 내리거나
> 크게 줌인하면 1픽셀이 여러 픽셀이 된다. 고정 시점이라 안전한 것이다.

### 이런 곳에서 만난다

| 상황 | 두는 높이 |
|---|---|
| 바닥 위 구역 표시(세이프존·스킬 장판) | `0.05` |
| 여러 겹으로 쌓는 표시 | `0.05`, `0.06`, `0.07` … 층마다 조금씩 |
| 벽에 붙이는 포스터·표지판 | 벽에서 `0.05` 만큼 **띄운다**(축만 다르다) |

> 💡 **더 정석적인 방법도 있다.** 바닥에 무늬를 새기는 것이 목적이라면
> `Decal` 노드를 쓰거나, 머티리얼의 `render_priority` 로 그리는 순서를 정할 수 있다.
> 다만 **띄우는 것이 가장 싸고 확실하다.**


## 노드와 리소스는 다르다

초보자가 가장 많이 헷갈리는 구분이다.

| | 노드(Node) | 리소스(Resource) |
|---|---|---|
| 정체 | **씬 트리에 들어가는 것** | **노드가 쓰는 데이터** |
| 예 | `MeshInstance3D`, `Camera3D` | `Mesh`, `Material`, `Texture2D`, `PackedScene` |
| 위치 | 트리의 한 자리 | 노드의 프로퍼티 안 |
| 공유 | 각자 독립 | **여러 노드가 같은 것을 공유한다** |

**리소스는 기본이 공유**라는 점이 중요하다. 머티리얼 하나를 적 10마리가 쓰고 있으면,
한 마리 색을 바꿨을 때 10마리가 전부 바뀐다. 개별화하려면 `duplicate()` 하거나
`Local to Scene` 을 켠다 ([resources-assets.md](../resources-assets.md)).

**리소스는 직접 만들 수도 있다.** 엔진이 준 것(`Mesh`·`Material`)만 리소스인 게 아니라,
`extends Resource` 로 자기 데이터 타입을 정의해 `.tres` 파일로 저장할 수 있다.
맵 설정·아이템 표·난이도 프리셋처럼 **코드가 아니라 데이터로 두어야 할 값**이 여기 들어간다.

```gdscript
class_name WorldConfig
extends Resource

@export var world_size: float = 1000.0
@export var chunk_size: float = 250.0
```

```
res://resources/maps/plains_4km.tres    ← world_size = 4000
res://resources/maps/arena_750m.tres    ← world_size = 750
```

스크립트에 `const WORLD_SIZE := 4000.0` 으로 박아 두면 맵이 둘이 되는 순간 막히지만,
리소스로 빼면 **`.tres` 만 늘어나고 코드는 그대로**다. 만드는 법과 함정
(**기본값과 같은 값은 파일에 저장되지 않는다** 등)은
[resources-assets.md](../resources-assets.md) §3 에 있다.

### 🔍 인스펙터에서 리소스 프로퍼티는 **한 겹 안쪽**에 있다

이 구분은 개념으로 끝나지 않는다. **에디터에서 값을 찾지 못하는 형태로 곧장 나타난다.**

예 — `MeshInstance3D` 에 `BoxMesh` 를 붙이고 상자 크기를 바꾸려는데
**인스펙터에 `Size` 가 없다.** 대신 `Scale` 만 보인다.

`MeshInstance3D` 가 가진 프로퍼티는 `mesh`·`skeleton`·`skin` **셋뿐**이고(엔진 확인),
`Scale` 은 그 위의 `Node3D` 에서 물려받은 것이다.
**`Size` 는 `BoxMesh` 라는 리소스의 프로퍼티**라 노드 인스펙터에 나올 이유가 없다.

**찾는 법** — 인스펙터의 `Mesh` 슬롯에 있는 `BoxMesh` 썸네일을 **클릭한다.**
인스펙터 아래쪽이 펼쳐지며 `Size`·`Subdivide *`·`Material` 이 나온다. 다시 클릭하면 접힌다.
`Shape`·`Material`·`Texture` 슬롯도 전부 같은 방식이다.

**헷갈리는 이유는 같은 이름이 양쪽에 다 있기 때문이다** (엔진에서 확인한 소속).

| 만지는 값 | 소속 | 상속 | 인스펙터 |
|---|---|---|---|
| `CSGBox3D` 의 `Size` | **노드** | `CSGBox3D` → `CSGPrimitive3D` | 바로 보인다 |
| `BoxMesh` 의 `Size` | **리소스** | `BoxMesh` → `PrimitiveMesh` | `Mesh` 를 클릭해 펼친다 |
| `CapsuleMesh` 의 `Height`·`Radius` | **리소스** | `CapsuleMesh` → `PrimitiveMesh` | `Mesh` 를 클릭해 펼친다 |
| `CapsuleShape3D` 의 `Height`·`Radius` | **리소스** | `CapsuleShape3D` → `Shape3D` | `Shape` 를 클릭해 펼친다 |
| `Scale` | **노드** | `Node3D` | 바로 보인다 |

`CSGBox3D` 는 **노드 자체가 `size` 를 갖는** 경우다. 그래서 CSG 로 바닥·벽을 만들 때는
바로 보이다가, `MeshInstance3D` + `BoxMesh` 로 넘어가는 순간 안 보여서 걸린다.

### 🛑 크기를 `Scale` 로 대신하지 않는다

크기가 리소스 안에 숨어 있으니 **노드의 `Scale` 로 대신하고 싶어진다.**
화면상 결과는 같다 — `BoxMesh` 의 `Size` 를 `1, 1, 1` 로 두고
`Scale` 에 `0.25, 0.25, 0.5` 를 넣으면 똑같이 보인다.

그래도 `Size` 를 쓴다.

| `Scale` 로 크기를 주면 | 무슨 일이 생기나 |
|---|---|
| **자식에게 전파된다** | 아래 달린 노드가 전부 같이 찌그러진다 |
| **비균등 스케일이 노멀을 왜곡한다** | 면이 향한 방향이 틀어져 조명 계산이 어긋난다 |
| **콜리전·물리에서 문제가 된다** | 셰이프에 스케일을 주면 엔진에 따라 동작이 달라진다 |

말단 장식이라면 당장은 차이가 없다. 문제는 **같은 습관을 콜리전이나 조명이 붙은 곳에
그대로 쓸 때**이고, 그때는 원인을 찾기 어렵다.

**메시의 크기는 메시에서, 노드의 배치는 Transform 에서** — 이렇게 나눠 두면 헷갈리지 않는다.

---

## 3D 게임에서 실제로 만나는 노드들 — 몸 · 모양 · 그림

노드 종류는 수백 개지만, **3D 게임을 시작할 때 실제로 쓰는 것은 몇 개 안 된다.**
그리고 그중 가장 먼저 이해해야 하는 것이 **"몸"** 이다.

### 🔑 하나를 놓는 게 아니라 셋을 한 세트로 놓는다

**왕초보가 가장 크게 막히는 지점이다.** 벽 하나를 만들려면 노드 하나가 아니라
**세 가지 역할**이 필요하다.

| 역할 | 노드 | 없으면 |
|---|---|---|
| **① 몸** — 물리 세계에서 무엇으로 취급되나 | `StaticBody3D` 등 | 물리 세계에 존재하지 않는다 |
| **② 모양** — 어디까지가 부딪히는 범위인가 | **`CollisionShape3D`** | **그냥 통과한다** |
| **③ 그림** — 눈에 보이는 겉모습 | `MeshInstance3D` | 안 보인다 (부딪히기는 한다) |

```
Wall (StaticBody3D)          ← ① 몸
├─ CollisionShape3D          ← ② 모양 (BoxShape3D 를 넣는다)
└─ MeshInstance3D            ← ③ 그림 (BoxMesh 를 넣는다)
```

> 🛑 **보이는 것과 부딪히는 것은 완전히 별개다.**
> `MeshInstance3D` 만 놓으면 **벽처럼 보이지만 그대로 통과**하고,
> `CollisionShape3D` 만 놓으면 **보이지 않는 벽**이 된다.
> "분명히 벽을 만들었는데 캐릭터가 지나간다"의 원인은 대부분 ②가 없어서다.

### 🛑 `CSGBox3D` 를 `StaticBody3D` 로 바꿨더니 아무것도 안 보인다

**CSG 로 블록아웃한 맵을 실제 노드로 옮길 때 반드시 만나는 벽이다.**
`Floor` 의 타입을 `CSGBox3D` → `StaticBody3D` 로 바꾸면 **화면에서 사라지고,
인스펙터에 `Size` 칸조차 없다.** 고장이 아니라 **원래 그런 노드**다.

#### 첫 번째 벽 — 한 노드가 하던 일이 셋으로 갈라진다

`CSGBox3D` 는 **혼자서 세 가지를 다 했다.** 그래서 `size` 하나만 고치면 됐다.

```
CSGBox3D 하나        =  👁 형상(보이는 것)  +  📐 크기  +  🧱 충돌(use_collision)
```

`StaticBody3D` 로 오면 그 셋이 **각자의 노드로 갈라진다.**

```
Floor (StaticBody3D)      ← "여기에 움직이지 않는 물체가 있다" 는 자격뿐.
├─ MeshInstance3D         👁  보이는 것        ← 직접 추가한다
└─ CollisionShape3D       🧱  부딪히는 것      ← 직접 추가한다
```

**자식을 하나도 안 달면 화면에도 안 보이고 부딪히지도 않는다.** 씬 트리에
`StaticBody3D` 만 덩그러니 있다면 그것이 원인이다.

**엔진에서 뽑은 자체 프로퍼티** — 물려받은 것을 빼고 그 클래스가 직접 가진 것만이다.

| 노드 | 자체 프로퍼티 | `size` 를 갖나 |
|---|---|---|
| **`CSGBox3D`** | **`size`** · `material` | ✅ **노드가 직접 가진다** |
| `StaticBody3D` | `physics_material_override` · `constant_linear_velocity` · `constant_angular_velocity` | 🛑 **없다** |
| `MeshInstance3D` | `mesh` · `skin` · `skeleton` | 🛑 **없다** |
| `CollisionShape3D` | `shape` · `disabled` · `debug_color` · `debug_fill` | 🛑 **없다** |

> 🔑 **이것이 Godot 의 일반 규칙이다 — 노드 하나 = 역할 하나.**
> **CSG 가 예외적으로 셋을 겸했던 것**이고, 그래서 편했지만 런타임 CPU 로 형상을
> 계산하느라 최종물로 쓸 수 없었다(→ 위 "`MeshInstance3D` 와 `CSGBox3D` 를 나란히 놓으면").

#### 두 번째 벽 — 크기는 **노드가 아니라 리소스**에 있다

`MeshInstance3D` 를 추가해도 **인스펙터에 `Size` 가 없다.** 여기서 한 번 더 막힌다.

```
MeshInstance3D  (노드)  →  mesh  슬롯  →  BoxMesh   (리소스)  →  Size  ← 여기 있다
CollisionShape3D(노드)  →  shape 슬롯  →  BoxShape3D(리소스)  →  Size  ← 여기 있다
```

**노드는 "리소스를 담는 그릇"이고, 값은 리소스 안에 있다.** 슬롯이 비어 있으면
인스펙터에 `<empty>` 라고만 뜨고, **리소스를 먼저 만들어야 `Size` 칸이 나타난다.**

**엔진 실측** — 갓 만든 `MeshInstance3D` 는 `mesh = <Object#null>` 이고 `get_aabb()` 가
`(0, 0, 0)` 이다. **`BoxMesh` 와 `BoxShape3D` 의 `size` 기본값은 둘 다 `Vector3(1, 1, 1)`** 이라,
넣자마자 1m 짜리 정육면체가 된다(→ "노드와 리소스는 다르다", "🛑 `MeshInstance3D` 를
추가하면 왜 아무것도 안 보이나").

#### 고치는 순서

| | 하는 일 | 결과 |
|---|---|---|
| 1 | `Floor` 에 **`MeshInstance3D`** 추가 | 아직 안 보인다 (`mesh` 가 비었다) |
| 2 | 그 노드의 **`Mesh` 슬롯 → `New BoxMesh`** | 1m 정육면체가 보인다 |
| 3 | `BoxMesh` 를 **클릭해 펼치고 `Size`** 입력 | 원하는 크기가 된다 |
| 4 | `Floor` 에 **`CollisionShape3D`** 추가 | 아직 통과한다 (`shape` 이 비었다) |
| 5 | **`Shape` 슬롯 → `New BoxShape3D`** 후 같은 `Size` | 부딪힌다 |

> 🛑 **3번과 5번의 크기를 따로 입력한다는 점을 놓치지 않는다.** 둘은 별개 리소스라
> 한쪽만 바꾸면 **보이는 것과 부딪히는 것이 어긋난다.** CSG 에서는 `size` 하나가
> 둘 다였기 때문에 이 실수가 나올 수 없었다.

> 💡 **바닥처럼 큰 면 하나는 `MeshInstance3D` 대신 `PlaneMesh`**, 지형 전체는
> **`bake_static_mesh()` 로 CSG 를 한 번에 구워** 옮기는 방법도 있다
> (→ [level-design.md](../level-design.md), [dictionary.md](../dictionary.md) 의 CSG).

### 몸(물리 바디) 4종 — 무엇이 이것을 움직이는가

**고르는 기준은 딱 하나다 — "누가 이 물체의 위치를 정하는가."**

| 노드 | 위치를 정하는 주체 | 쓰는 곳 |
|---|---|---|
| **`StaticBody3D`** | **아무도.** 움직이지 않는다 | **벽·바닥·건물·지형** 같은 움직이지 않는 환경 |
| **`CharacterBody3D`** | **내 스크립트.** 매 틱 직접 속도를 써 넣는다 | **점프·미끄러짐처럼 직접 짠 이동 로직이 필요한 개체** — 플레이어·몬스터·NPC |
| `RigidBody3D` | **물리 엔진.** 힘을 주면 알아서 굴러간다 | 굴러가는 통, 무너지는 상자, 던진 물건 |
| `Area3D` | (몸이 아니다) **막지 않고 감지만 한다** | 세이프존 경계, 함정 발동, 아이템 줍기 범위 |

> **`Area3D` 는 부딪히지 않는다.** 통과하면서 **"들어왔다·나갔다"만 알려준다**
> (`body_entered` / `body_exited` 시그널). 나머지 셋은 **실제로 막는다.**

한 가지가 더 있는데, 처음에는 몰라도 된다.

| 노드 | |
|---|---|
| `AnimatableBody3D` | `StaticBody3D` 를 상속한 **"움직이는 정적 바디"** — 엘리베이터, 움직이는 발판. `sync_to_physics` 기본값이 `true` 라 그 위에 탄 캐릭터를 밀지 않고 함께 옮긴다 |

### 고르는 순서

```
막아야 하나?
├─ 아니오 → Area3D              (감지만)
└─ 예
   ├─ 움직이나?
   │  ├─ 아니오 → StaticBody3D      ← 벽·바닥. 맵의 대부분이 이것
   │  └─ 예
   │     ├─ 내가 조종하나? → CharacterBody3D   ← 플레이어·몹
   │     ├─ 정해진 경로로 움직이나? → AnimatableBody3D
   │     └─ 물리에 맡기나? → RigidBody3D
```

**맵을 만들면 노드의 90% 는 `StaticBody3D` 다.** 그리고 살아 움직이는 것은
거의 다 `CharacterBody3D` 다. 이 둘만 알아도 게임 하나가 나온다.

### `StaticBody3D` — 움직이지 않는 환경

**아무 설정 없이 그냥 놓으면 된다.** 속도도 중력도 없다. 물리 엔진은 이것을
**"질량이 무한대인 벽"** 으로 취급해서, 계산 비용이 가장 싸다.

실측 속성은 셋뿐이다 (엔진에서 확인).

| 속성 | 기본값 | 무엇 |
|---|---|---|
| `physics_material_override` | `None` | 마찰·반발력. 얼음 바닥·트램펄린을 만들 때 |
| `constant_linear_velocity` | `Vector3(0, 0, 0)` | **몸은 가만히 있는데 표면만 흐른다** — 컨베이어 벨트 |
| `constant_angular_velocity` | `Vector3(0, 0, 0)` | 회전판 |

> **`constant_linear_velocity` 는 실제로 노드를 움직이지 않는다.**
> 표면에 닿은 물체를 밀어낼 뿐이다. 그래서 컨베이어 벨트를 `StaticBody3D` 로
> 만들 수 있다 — 정적 바디의 싼 비용을 유지한 채로.

**CSG 로 블록아웃할 때는 `CSGCombiner3D` 의 `use_collision` 을 켜면
`StaticBody3D` 를 따로 놓지 않아도 된다** → [level-design.md](../level-design.md)

### `CharacterBody3D` — 직접 짠 이동 로직이 필요할 때

**점프·미끄러짐·계단 오르기처럼 "게임다운" 움직임**을 위한 몸이다.
이런 것을 **키네마틱(kinematic) 바디**라고 부른다.

> **키네마틱 = "물리 법칙에 맡기지 않고 내가 직접 위치를 정한다"**

**왜 캐릭터를 물리 엔진에 맡기지 않는가** — `RigidBody3D` 로 플레이어를 만들면
**미끄러지고, 넘어지고, 밀리고, 관성이 남는다.** 현실적이지만 **조작감이 나쁘다.**
게임 캐릭터는 "키를 떼면 즉시 멈추고, 절대 넘어지지 않는" **비현실적인 움직임이
오히려 옳다.**

역할 분담은 이렇게 나뉜다.

| | 담당 |
|---|---|
| **어디로 얼마나 빨리 갈 것인가** | 🧑‍💻 **내 스크립트** — `velocity` 에 써 넣는다 |
| **가다가 부딪히면 어떻게 할 것인가** | ⚙️ **엔진** — `move_and_slide()` 가 처리한다 |

```gdscript
extends CharacterBody3D

func _physics_process(delta: float) -> void:
	velocity.y -= 9.8 * delta          # ① 내가 속도를 정하고
	move_and_slide()                   # ② 엔진이 부딪힘을 처리한다
```

알아 둘 만한 실측 기본값이다 (엔진에서 확인).

| 속성 | 기본값 | 무엇 |
|---|---|---|
| `velocity` | `Vector3(0, 0, 0)` | **내가 써 넣는 속도.** m/s |
| `up_direction` | `Vector3(0, 1, 0)` | 어느 쪽이 "위"인가 — 바닥 판정의 기준 |
| **`floor_max_angle`** | **`0.7853982` rad = 45°** | **이보다 가파르면 바닥이 아니라 벽**으로 친다 |
| `floor_snap_length` | `0.1` | 내리막에서 지면에 붙어 있게 하는 거리 |
| `motion_mode` | `0` (GROUNDED) | 지면 기반. 우주선처럼 위아래가 없으면 `1`(FLOATING) |
| `max_slides` | `6` | 한 번에 미끄러져 재시도하는 최대 횟수 |
| `slide_on_ceiling` | `true` | 천장에 부딪히면 미끄러진다 |

> **`floor_max_angle` 45° 가 뜻하는 것** — 경사가 45° 를 넘으면 `is_on_floor()` 가
> `false` 가 되어 **캐릭터가 미끄러져 내려온다.** "언덕을 못 올라간다"의 원인이
> 대개 이 값이다.

**라리엔에서는 몹도 `CharacterBody3D` 다. 다만 입력으로 움직이지 않는다** —
**위치는 서버가 정하고**([SSOT §7](../../../game/references/SSOT.md)), 클라이언트는
받은 좌표로 보간해 옮긴다. "내 스크립트가 위치를 정한다"의 *내 스크립트* 가
**서버 스냅샷을 반영하는 코드**인 셈이다.

### 🛑 `CollisionShape3D` 에 셰이프를 넣지 않으면 아무 일도 안 일어난다

`CollisionShape3D` 의 **`shape` 기본값은 `None`** 이다 (엔진에서 확인).
노드를 추가하기만 하고 인스펙터에서 셰이프를 지정하지 않으면 **경고만 뜨고 통과한다.**

| # | 조작 |
|---|---|
| 1 | 몸 노드 선택 → **Cmd+A** → `CollisionShape3D` 추가 |
| 2 | 인스펙터의 **`Shape`** → `New BoxShape3D`(상자) · `New SphereShape3D`(구) · `New CapsuleShape3D`(캡슐 — **사람 모양에 표준**) |
| 3 | 크기를 맞춘다 |

> **셰이프는 눈에 보이는 메시와 자동으로 맞춰지지 않는다.** 메시를 키우면
> 셰이프도 따로 키워야 한다. 이 둘이 어긋난 것이 "허공에서 막힌다"의 원인이다.

### 상속 관계 — 왜 collision_layer 는 전부 갖고 있나 (엔진에서 확인)

```
Node3D
└─ CollisionObject3D          collision_layer = 1 · collision_mask = 1
   ├─ Area3D                  감지만 (monitoring 기본 true)
   └─ PhysicsBody3D           실제로 막는다
      ├─ StaticBody3D
      │  └─ AnimatableBody3D  sync_to_physics = true
      ├─ RigidBody3D          mass = 1.0 · gravity_scale = 1.0
      └─ CharacterBody3D      velocity · move_and_slide()
```

넷 다 `CollisionObject3D` 를 물려받으므로 **`collision_layer` · `collision_mask`
(둘 다 기본 `1`)를 공통으로 갖는다.** 이 둘로 "누가 누구와 부딪히는가"를 정한다
→ [physics-3d.md](../physics-3d.md)

### 흔한 실수

| 증상 | 원인 | 해결 |
|---|---|---|
| **벽을 만들었는데 통과한다** | `CollisionShape3D` 가 없거나 `shape` 가 `None` | 셰이프를 지정한다 |
| **아무것도 안 보이는데 막힌다** | `MeshInstance3D` 가 없다 | 그림을 붙인다 |
| **캐릭터가 계속 떨어진다** | 바닥에 몸(`StaticBody3D`)이 없다 | 바닥도 몸이어야 한다 |
| **언덕을 못 올라간다** | 경사가 `floor_max_angle`(45°)을 넘는다 | 경사를 낮추거나 값을 올린다 |
| **플레이어가 미끄러지고 넘어진다** | `RigidBody3D` 로 만들었다 | `CharacterBody3D` 로 바꾼다 |
| **`Area3D` 인데 안 막힌다** | **정상이다.** 감지 전용이다 | 막으려면 `StaticBody3D` |
| **`RigidBody3D` 충돌 시그널이 안 온다** | `contact_monitor` 기본값이 `false` | 켜고 `max_contacts_reported` 를 올린다 |

**실제 코드로 캐릭터를 움직이는 것은 [§9](09-controller.md#9-실전--3d-캐릭터-컨트롤러를-한-줄씩-읽는다),
물리 전반은 [physics-3d.md](../physics-3d.md) 에 있다.**

---

## 해 보기 — 플레이어 캐릭터를 만든다 (노드 4개)

앞 절에서 **몸 · 모양 · 그림 세 가지가 한 세트**라는 것을 봤다.
여기서는 그것을 **실제로 에디터에서 조립한다.** 노드 4개면 끝난다.

### 목표 구조

```
Main (Node3D)                     ← 메인 씬의 루트
├─ WorldEnvironment
├─ DirectionalLight3D
└─ Player (CharacterBody3D)       ← ① 몸.  이름을 Player 로 바꾼다
   ├─ MeshInstance3D              ← ③ 그림. 눈에 보이는 캡슐
   ├─ CollisionShape3D            ← ② 모양. 부딪히는 캡슐 (보이지 않는다)
   └─ Camera3D                    ← 화면을 찍는 눈
```

**`Player` 아래에 셋을 넣는 이유는 하나다 — 부모가 움직이면 자식이 따라가기 때문**이다.
카메라를 밖에 두면 캐릭터만 걸어가고 화면은 제자리에 남는다.

### 조작 순서

> 🛑 **씬 파일(`.tscn`)은 사람 개발자가 에디터에서 직접 만든다**
> ([CLAUDE.md](../../../../../CLAUDE.md) 작업 규칙). 아래는 그 조작 순서다.

| # | 무엇을 선택하고 | 조작 | 결과 |
|---|---|---|---|
| 1 | **`Main`** (루트) | **Cmd+A** → `CharacterBody3D` | 몸이 생긴다 |
| 2 | **`CharacterBody3D`** | **Cmd+A** → `MeshInstance3D` | 그림 |
| 3 | **`CharacterBody3D`** | **Cmd+A** → `CollisionShape3D` | 모양 |
| 4 | **`CharacterBody3D`** | **Cmd+A** → `Camera3D` | 눈 |
| 5 | `CharacterBody3D` | **F2** → `Player` | 이름 변경 |

`Cmd+A` 는 macOS 의 **자식 노드 추가**다 (Windows·Linux 는 `Ctrl+A`).

> 🛑 **2~4 번에서 매번 `CharacterBody3D` 를 다시 선택한다.**
> `Cmd+A` 는 **지금 선택된 노드의 자식**으로 넣는다. 1번 직후 `CharacterBody3D` 가
> 선택된 상태에서 계속 누르면 `MeshInstance3D` 안에 `CollisionShape3D` 가 들어가
> **점점 깊어진다.** 셋은 **형제**여야 한다.

**이름은 마지막에 바꾼다.** 먼저 바꿔도 되지만, 노드를 추가하는 동안은
타입 이름 그대로 두는 편이 무엇을 만들고 있는지 눈에 보인다.

### 노드마다 반드시 해야 하는 설정

**노드를 추가한 것만으로는 아무것도 보이지 않고 아무것도 부딪히지 않는다.**
셋 다 인스펙터에서 내용물을 지정해야 한다.

| 노드 | 인스펙터에서 | 지정하지 않으면 |
|---|---|---|
| `MeshInstance3D` | **`Mesh`** → `New CapsuleMesh` | **안 보인다** (`mesh` 기본값 `None`) |
| `CollisionShape3D` | **`Shape`** → `New CapsuleShape3D` | **그냥 통과한다** (`shape` 기본값 `None`) |
| `Camera3D` | **위치를 뒤·위로 옮긴다** | **캐릭터 안쪽에서 찍혀 아무것도 안 보인다** |

> 🔑 **`CapsuleMesh` 와 `CapsuleShape3D` 의 기본값이 서로 같다** (엔진에서 확인) —
> 둘 다 `height = 2.0`, `radius = 0.5` 다. **그래서 둘 다 기본값으로 두면
> 보이는 것과 부딪히는 것이 정확히 일치한다.** 한쪽만 크기를 바꾸면 그때부터
> 어긋나기 시작한다.

### 🛑 캡슐이 바닥에 반쯤 묻힌다 — 원점이 중앙이기 때문

**가장 먼저 만나는 함정이다.** 캡슐의 원점은 **가운데**에 있다.
`Player` 를 `y = 0` 에 두면 **아래 절반(1m)이 바닥 밑으로 들어간다.**

| 무엇 | 값 |
|---|---|
| 캡슐 높이 | `2.0` m |
| 중심에서 발끝까지 | **`1.0` m** |
| **바닥(`y = 0`) 위에 세우려면** | **`Player` 의 `position.y = 1`** |

**`MeshInstance3D` 와 `CollisionShape3D` 는 `(0, 0, 0)` 에 그대로 두고,
부모인 `Player` 만 올린다.** 자식을 각각 올리면 나중에 둘이 어긋난다.

### 카메라를 어디에 둘 것인가

`Camera3D` 를 추가한 직후에는 **캐릭터 몸 안쪽**에 있다. 실행하면 캡슐 내부라
아무것도 안 보이거나 온통 회색이다. **인스펙터의 `Transform > Position` 을 옮긴다.**

| 시점 | `Camera3D` 위치 (Player 기준) | 비고 |
|---|---|---|
| **3인칭** | `(0, 1.5, 4)` 정도 | **`+Z` 가 뒤쪽**이다. 뒤로 물러나 등을 본다 |
| **1인칭** | `(0, 0.7, 0)` 정도 | 눈높이. `MeshInstance3D` 를 숨기는 편이 낫다 |

**Godot 에서 `-Z` 가 앞, `+Z` 가 뒤다.** 카메라를 `z = 4` 로 두면 캐릭터 **뒤**에
서게 된다 — 이 좌표 규약은 [§9.3](09-controller.md#93-godot-의-3d-좌표-규약--왕초보가-가장-먼저-넘어지는-곳) 에서 자세히 다룬다.

> `Camera3D.current` 의 기본값은 `false` 지만 (엔진에서 확인),
> **씬에 카메라가 하나뿐이면 엔진이 알아서 그것을 쓴다.** 카메라가 둘 이상일 때만
> 어느 것을 쓸지 `current` 로 정한다.

### ⚠️ 이름 하나 짚고 넘어간다 — `MeshInterface3D` 라는 노드는 없다

학습 자료에서 종종 `MeshInterface3D` 라고 잘못 적힌 것을 보게 되는데,
**실제 노드 이름은 `MeshInstance3D`** 다. *Interface* 가 아니라 ***Instance*(실체)**
— "메시 리소스를 씬에 실체로 놓은 것"이라는 뜻이다.
[노드와 리소스는 다르다](#노드와-리소스는-다르다) 에서 본 구분이 이름에 그대로 들어 있다.

### 🛑 라리엔 3D 에서는 카메라를 `Player` 자식으로 두지 않는다

**위 구조는 자유 시점 게임의 전형이고, 대부분의 Godot 튜토리얼이 이렇게 가르친다.**
캐릭터가 돌면 카메라도 함께 도는 구조다.

**라리엔은 카메라 회전 3축이 전부 고정이다** ([SSOT §1](../../../game/references/SSOT.md)).
카메라를 `Player` 의 자식으로 두면 **캐릭터가 도는 순간 카메라도 돌아서 그 규칙이 깨진다.**

```
Main
├─ CameraRig (Node3D)      ← 카메라는 여기. PC 를 따라가되 회전은 하지 않는다
│  └─ Camera3D
└─ Player (CharacterBody3D)
   ├─ MeshInstance3D
   └─ CollisionShape3D     ← 카메라가 없다
```

**연습으로 만들 때는 자식으로 둬도 된다.** 다만 라리엔 본체에 옮길 때는
`Main` 아래로 빼야 한다는 것을 알고 있어야 한다 → [level-design.md](../level-design.md)

### 여기까지 하면 무엇이 되나

**아직 움직이지 않는다.** 노드만 놓은 상태이고, **움직이려면 스크립트가 필요하다.**

| 지금 되는 것 | 아직 안 되는 것 |
|---|---|
| 캡슐이 화면에 보인다 | 키를 눌러도 반응이 없다 |
| 벽·바닥에 부딪힌다 (바닥에 몸이 있다면) | 중력이 없어 공중에 떠 있다 |
| 카메라가 캐릭터를 따라간다 | |

**다음은 스크립트다** — `Player` 를 선택하고 스크립트를 붙인 뒤,
[§9 실전 — 3D 캐릭터 컨트롤러](09-controller.md#9-실전--3d-캐릭터-컨트롤러를-한-줄씩-읽는다) 를
한 줄씩 읽으면 걸어다니게 된다.

### 흔한 실수

| 증상 | 원인 | 해결 |
|---|---|---|
| **아무것도 안 보인다** | `MeshInstance3D` 의 `Mesh` 가 `None` | `New CapsuleMesh` 를 지정 |
| **화면이 온통 회색·검정이다** | 카메라가 캐릭터 몸 안에 있다 | 카메라를 뒤로 (`z = 4`) 옮긴다 |
| **캡슐이 바닥에 묻혀 있다** | 원점이 중앙인데 `y = 0` 에 뒀다 | `Player.position.y = 1` |
| **캐릭터가 바닥을 통과해 떨어진다** | 바닥에 `StaticBody3D` + `CollisionShape3D` 가 없다 | 바닥도 몸이어야 한다 |
| **노드가 형제가 아니라 점점 깊어진다** | `Cmd+A` 를 연속으로 눌렀다 | 매번 `CharacterBody3D` 를 다시 선택 |
| **카메라가 캐릭터를 안 따라간다** | `Camera3D` 가 `Player` 밖에 있다 | 자식으로 끌어다 넣는다 |
| **몸과 그림이 어긋난다** | 메시와 셰이프의 크기를 따로 바꿨다 | 둘 다 `height 2.0` · `radius 0.5` 로 맞춘다 |

> **저사양을 생각한다면** — `CapsuleMesh` 의 `radial_segments` 기본값은 **`64`** 다
> (엔진에서 확인). 연습용 캡슐 하나야 상관없지만, **이런 프리미티브를 화면에 수십 개
> 놓을 거라면 8~16 으로 낮춘다.** 라리엔의 드로우콜·정점 예산은
> [SSOT §3](../../../game/references/SSOT.md) 에 있다.

---

---

## 공식 문서

- [Nodes and Scenes](https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html) — 노드·씬·씬 트리의 공식 정의
- [Overview of Godot's key concepts](https://docs.godotengine.org/en/stable/getting_started/introduction/key_concepts_overview.html)
- [Using SceneTree](https://docs.godotengine.org/en/stable/tutorials/scripting/scene_tree.html) — 씬 트리가 정하는 것(트리·루트·현재 씬)
- [Physics introduction](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html) — 바디 4종·`CollisionShape3D`·레이어와 마스크(몸·모양·그림 절의 근거)
- [Introduction to 3D](https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html) — `Node3D`·`MeshInstance3D`·3D 뷰포트
- [클래스 레퍼런스 `Node3D`](https://docs.godotengine.org/en/stable/classes/class_node3d.html) — 이 파트에서 센 프로퍼티 9개의 정의
