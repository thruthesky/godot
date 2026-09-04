# MultiMeshInstance3D — 같은 것을 수천 개 그리고, 콜리전은 따로 푼다

> **이 문서로 오는 상황** — 나무·바위·풀처럼 **같은 메시를 대량으로** 놓아야 할 때,
> 에디터의 **Populate Surface** 로 뿌리는 법, 그리고 **뿌린 것들에 왜 충돌이 없는지**와
> 그것을 어디서 푸는지. 드로우콜 예산 전반은 [lowend-culling-lod.md](lowend-culling-lod.md),
> 메모리 계산은 [lowend-3gb-60fps.md](lowend-3gb-60fps.md) §5.3.

이 문서의 숫자는 전부 **엔진에서 직접 뽑은 것**이다. 기준은 **4.7.2.stable.official** 이고,
물리 판정은 [`tests/multimesh_collision_probe.gd`](../../../../tests/multimesh_collision_probe.gd) 로
직접 쟀다(실행 명령과 출력을 §5 에 그대로 붙였다).

---

## 목차

1. [한눈에 — 무엇이고 무엇이 아닌가](#1-한눈에--무엇이고-무엇이-아닌가)
2. [구조 — 리소스와 노드가 나뉘어 있다](#2-구조--리소스와-노드가-나뉘어-있다)
3. [에디터로 뿌린다 — Populate Surface](#3-에디터로-뿌린다--populate-surface)
4. [Create Collision Shape — 9가지 중 무엇을 고르나](#4-create-collision-shape--9가지-중-무엇을-고르나)
5. [🛑 콜리전은 복제되지 않는다 (실측)](#5--콜리전은-복제되지-않는다-실측)
6. [그러면 충돌은 어디서 푸나 — 해법 여섯](#6-그러면-충돌은-어디서-푸나--해법-여섯)
7. [🛑 세 가지 함정 — 컬링·LOD·삼각형](#7--세-가지-함정--컬링lod삼각형)
8. [코드로 다룰 때](#8-코드로-다룰-때)
9. [라리엔 3D 에서 이것이 걸리는 곳](#9-라리엔-3d-에서-이것이-걸리는-곳)

---

## 1. 한눈에 — 무엇이고 무엇이 아닌가

**MultiMesh 는 "같은 메시를 위치만 바꿔 여러 벌 그리는" 장치다.** GPU 에 메시를 한 번만 보내고
변환 행렬 배열을 함께 넘겨, **드로우콜 1회로 N 개를 그린다.**

```
[개별 노드]  MeshInstance3D × 500          → 노드 500개 · 드로우콜 500
[MultiMesh]  MultiMeshInstance3D × 1       → 노드 1개   · 드로우콜 1
             └ MultiMesh.instance_count = 500
```

| | MultiMesh 가 하는 것 | MultiMesh 가 **하지 않는** 것 |
|---|---|---|
| 렌더링 | ✅ 드로우콜을 1로 묶는다 | |
| 노드 | ✅ 노드 1개로 끝난다 (씬 트리·메모리 절약) | |
| 변환 | ✅ 인스턴스마다 위치·회전·크기가 다를 수 있다 | |
| **물리** | | 🛑 **아무것도 하지 않는다.** 충돌·레이캐스트·클릭이 전부 없다 |
| 컬링 | | 🛑 인스턴스 **하나씩** 잘라내지 못한다 (전부-아니면-전무) |
| LOD | | 🛑 인스턴스마다 다른 LOD 를 못 쓴다 (전부 같은 단계) |
| 애니메이션 | | 🛑 스킨드 메시(캐릭터)는 묶이지 않는다 |

> **핵심 한 줄** — MultiMesh 는 **렌더링 서버에만 존재한다.** 물리 서버는 이것을 모른다.
> 그래서 §5 의 결과가 나온다.

---

## 2. 구조 — 리소스와 노드가 나뉘어 있다

```
MultiMeshInstance3D          노드 — 씬의 어디에 놓을지, 어느 레이어에 그릴지
  └ multimesh: MultiMesh     리소스 — 메시 1개 + 인스턴스 N개의 변환 배열
        ├ mesh: Mesh              무엇을 그리는가 (모든 인스턴스가 공유)
        ├ transform_format        TRANSFORM_3D / TRANSFORM_2D
        ├ instance_count          몇 개인가
        ├ visible_instance_count  그중 몇 개를 그릴 것인가 (−1 = 전부)
        ├ use_colors              인스턴스마다 색을 다르게 줄 것인가
        └ use_custom_data         셰이더로 넘길 4채널 값을 쓸 것인가
```

| 알아 둘 것 | |
|---|---|
| **메시는 하나뿐이다** | 나무 3종을 섞으려면 MultiMesh 도 3개다 |
| **머티리얼도 하나뿐이다** | 인스턴스별로 바꾸려면 `use_colors` 나 `use_custom_data` + 셰이더 |
| `instance_count` 를 바꾸면 | **버퍼가 다시 잡히고 기존 변환이 날아간다.** 개수를 먼저 정하고 채운다 |
| `visible_instance_count` | 버퍼는 그대로 두고 **앞에서부터 N 개만** 그린다. 개수를 자주 바꿀 때 쓴다 |

---

## 3. 에디터로 뿌린다 — Populate Surface

**노드 셋이 필요하다.** 셋 다 있어야 다이얼로그가 열린다.

| 역할 | 무엇 | 제약 |
|---|---|---|
| **Target Surface** | 뿌릴 바닥 | 🛑 **`MeshInstance3D` 여야 한다.** 메시에 면이 있어야 한다 |
| **Source Mesh** | 복제할 것 (나무 1그루) | 🛑 **`MeshInstance3D` 여야 한다** |
| **MultiMeshInstance3D** | 결과가 담길 노드 | 이것을 선택해야 툴바에 메뉴가 뜬다 |

> 🛑 **둘 다 `MeshInstance3D` 다.** `Node3D` 나 glTF 인스턴스 루트를 고르면
> `Surface source is invalid (not a MeshInstance3D).` 로 거절당한다. glTF 를 씬에 넣었다면
> **그 안의 `MeshInstance3D` 를 골라야** 하고, 그러려면 인스턴스에서
> **`Editable Children`(우클릭 메뉴)** 를 켜거나 **`Make Local`** 해야 한다.

### 클릭 순서

```
1. MultiMeshInstance3D 를 씬에 추가하고 선택한다
2. 3D 뷰포트 상단 툴바에  ▸ MultiMesh  메뉴가 나타난다 → 클릭
3. Populate Surface
4. Target Surface  ▸ [..] → 바닥 MeshInstance3D 선택 → OK
5. Source Mesh     ▸ [..] → 나무 MeshInstance3D 선택 → OK
6. Amount 등을 정한다
7. Populate
```

### 다이얼로그의 필드

| 필드 | 기본값 | 하는 일 |
|---|---|---|
| **Target Surface** | — | 인스턴스가 놓일 면. **삼각형을 면적 가중치로 뽑아** 그 위 임의의 점에 놓는다 |
| **Source Mesh** | — | 복제할 메시 |
| **Mesh Up Axis** | `Y-Axis` | 소스 메시의 위쪽 축. **나무가 누워서 심기면 여기** |
| **Random Rotation** | 0 (슬라이더) | 위 축 기준 무작위 회전 — **같은 나무를 복제한 티를 지운다** |
| **Random Tilt** | 0 (슬라이더) | 옆으로 기울이는 무작위 |
| **Random Scale** | 0.0 | 크기 무작위 폭 (`Scale ± Random Scale`) |
| **Scale** | 1.0 | 기본 크기 |
| **Amount** | 128 | 개수 |

> **면적 가중치** — 넓은 삼각형에 더 많이 떨어진다. 그래서 지형이 균일하지 않아도
> 밀도가 눈으로 고르게 보인다.

### 뿌린 뒤

- **Source Mesh 노드는 지워도 된다.** 변환 배열은 이미 `MultiMesh` 리소스 안에 복사됐다.
- 다시 `Populate` 하면 **덮어쓴다**(더해지지 않는다).
- 배치가 마음에 안 들면 `Ctrl/Cmd+Z` 로 되돌아간다.

### 실측 — 나무 3그루를 뿌렸을 때 (강좌 영상, 4.7.2)

| | 뿌리기 전 | 뿌린 뒤 | 변화 |
|---|---|---|---|
| Objects | 23 | 24 | **+1** (노드 1개) |
| Primitives | 12,045 | 18,310 | +6,265 (삼각형은 실제로 늘어난다) |
| **Draw Calls** | 23 | **24** | **+1** |

**나무가 3그루든 300그루든 드로우콜은 +1 이다.** 이것이 MultiMesh 를 쓰는 유일한 이유다.
반대로 **삼각형은 전혀 줄지 않는다** — 개수만큼 그대로 늘어난다(§7).

---

## 4. Create Collision Shape — 9가지 중 무엇을 고르나

`MeshInstance3D` 선택 → 툴바 **Mesh** → **Create Collision Shape**.
엔진 소스(`editor/scene/3d/mesh_instance_3d_editor_plugin.cpp`) 기준으로 다음이 전부다.

### Collision Shape Placement — 2가지

| 항목 | 결과 |
|---|---|
| **Sibling** | 선택한 노드의 **형제**로 `CollisionShape3D` 를 만든다 (부모가 이미 물리 바디일 때) |
| **Static Body Child** | 선택한 노드의 **자식**으로 `StaticBody3D` → `CollisionShape3D` 를 만든다 |

### Collision Shape Type — 9가지

| 항목 | 만드는 것 | 비용 | 언제 |
|---|---|---|---|
| **Trimesh** | 메시 삼각형 전부 | 🛑 **가장 비싸다** | 정적 지형. 움직이는 바디에는 못 쓴다 |
| **Single Convex** | 볼록 껍질 1개 | 중간 | 단순 볼록 물체 |
| **Simplified Convex** | 단순화한 볼록 껍질 | 중간 | Single Convex 가 무거울 때 |
| **Multiple Convex** | 볼록 분해 N개 | 🛑 비싸다 | 오목한 형상을 정확히 |
| **Bounding Box** | `BoxShape3D` | **싸다** | 상자꼴 |
| **Capsule** | `CapsuleShape3D` | **싸다** | 🌳 **나무·기둥·사람** |
| **Cylinder** | `CylinderShape3D` | 싸다 | 원기둥 |
| **Sphere** | `SphereShape3D` | 가장 싸다 | 바위·공 |
| Primitive | 메시 종류에 맞는 원시 도형 | 싸다 | `BoxMesh` 등 **내장 메시일 때만** 활성 |

> **Capsule / Cylinder / Sphere 를 고르면 `Alignment Axis` 가 하나 더 나온다**
> (기본 `Longest Axis`). 캡슐을 어느 축으로 세울지다.

### 🌳 나무에는 왜 Capsule 인가

강좌 영상의 설명이 정확하다 —

> "We're not gonna use this trimesh single convex **since it will create, use more triangles**."

**나무 한 그루의 Trimesh 콜리전은 잎사귀 삼각형까지 전부 물리 형상이 된다.**
그런데 게임에서 필요한 건 **"줄기에 부딪힌다"** 뿐이다. 잎은 통과해도 아무도 모른다.

| | Trimesh | **Capsule** |
|---|---|---|
| 물리 형상 | 잎까지 수천 삼각형 | **캡슐 1개** |
| 필요한가 | ❌ 잎에 부딪힐 일이 없다 | ✅ 줄기만 막으면 된다 |
| 움직이는 바디로 | 🛑 못 쓴다 | ✅ 된다 |

---

## 5. 🛑 콜리전은 복제되지 않는다 (실측)

> # 원본에 콜리전을 만들어 두어도, Populate Surface 로 뿌린 인스턴스에는 콜리전이 없다.

이것이 이 문서에서 가장 중요한 사실이다. **버그가 아니라 설계다.**

### 왜 그런가

```
MultiMesh  →  RenderingServer   (변환 배열을 GPU 버퍼로)   ← 인스턴스는 여기에만 있다
              PhysicsServer3D                              ← 여기에는 아무것도 없다
```

`MultiMesh` 는 **렌더링 서버의 자료구조**다. 물리 서버는 `CollisionObject3D` 를 상속한 **노드**만
안다. MultiMesh 인스턴스는 노드가 아니므로 **물리 세계에 존재하지 않는다.**

에디터 플러그인 소스(`multimesh_editor_plugin.cpp`)에도 **콜리전을 만드는 코드가 한 줄도 없다.**

### 실측

```bash
godot --headless --path . -s res://tests/multimesh_collision_probe.gd
```

```
=== Godot 4.7.2-stable (official) ===

[A] MultiMeshInstance3D 인스턴스에 물리가 있는가
  instance_count = 3 · 노드 수 = 1
  ✅ 인스턴스 0 (x=0)  에 레이 — 기대 충돌없음 / 실제 충돌없음
  ✅ 인스턴스 1 (x=10) 에 레이 — 기대 충돌없음 / 실제 충돌없음
  ✅ 인스턴스 2 (x=20) 에 레이 — 기대 충돌없음 / 실제 충돌없음

[B] 원본 MeshInstance3D 아래 StaticBody3D 를 두면 인스턴스에도 생기는가
    (영상의 'Create Collision Shape > Capsule' 과 같은 구조)
  원본(x=-20) — StaticBody3D 를 직접 붙였다
  ✅ 원본에 레이                    — 기대 충돌함   / 실제 충돌함
  ✅ MultiMesh 사본 (x=-40) 에 레이 — 기대 충돌없음 / 실제 충돌없음
  ✅ MultiMesh 사본 (x=-60) 에 레이 — 기대 충돌없음 / 실제 충돌없음

[C] GridMap + MeshLibrary(shape 포함) 는 콜리전이 자동으로 생기는가
  셀 3개 배치 · 노드 수 = 1 · get_used_cells = 3
  MeshLibrary.get_item_shapes(0).size() = 2  (shape 1개 + Transform 1개 = 2)
  ✅ 셀 0 (x=0) 에 레이 — 기대 충돌함 / 실제 충돌함
  ✅ 셀 1 (x=4) 에 레이 — 기대 충돌함 / 실제 충돌함
  ✅ 셀 2 (x=8) 에 레이 — 기대 충돌함 / 실제 충돌함

실패 0 건
```

**[B] 가 답이다.** 원본에 `Create Collision Shape > Capsule` 로 `StaticBody3D` 를 붙여도,
그 메시를 MultiMesh 로 뿌린 사본에는 **충돌이 생기지 않는다.** 원본만 충돌한다.

**[C] 가 대안이다.** 같은 "노드 1개로 N 개"를 `GridMap` 으로 하면 **콜리전이 셀마다 자동으로 생긴다.**

### 화면에서 어떻게 보이나

- 뿌린 나무를 **뷰포트에서 클릭해도 선택되지 않는다** (선택은 물리가 아니라 별개지만,
  MultiMesh 인스턴스는 개별 객체가 아니라서 마찬가지로 못 고른다)
- 캐릭터가 **나무를 그냥 통과한다**
- `RayCast3D` · `intersect_ray` 가 **아무것도 못 맞힌다**

---

## 6. 그러면 충돌은 어디서 푸나 — 해법 여섯

**엔진 내장에는 "원본 콜리전을 인스턴스에 자동 복제" 하는 버튼이 없다.** 관련 제안이 열려 있으나
(godot-proposals **#10828** `Add collision detection / raycast to MultiMeshInstance3D` — 2024-09-26
개설, **여전히 open · 담당자 없음**; #4344 `MultiColliderInstance` 와 godot#23019 는 **closed**)
아직 기능으로 들어오지 않았다.

대신 **목적에 따라 다섯 갈래**로 나뉜다.

| # | 방법 | 클릭만으로? | 드로우콜 | 콜리전 | 언제 |
|---|---|---|---|---|---|
| **1** | **ProtonScatter + `Keep Static Colliders`** | ✅ **체크박스 하나** | 1 | ✅ **자동** | **자유 배치 + 충돌이 둘 다 필요할 때** |
| **2** | **GridMap + MeshLibrary** (내장) | ✅ **된다** | 배칭됨 | ✅ **자동** | 격자에 놓아도 되는 것 |
| **3** | 충돌이 필요한 것만 개별 노드 | ✅ | 개수만큼 | ✅ | 큰 나무 수십 개 |
| **4** | 콜리전을 아예 안 준다 | ✅ | 1 | ❌ | 풀·꽃·자갈·먼 배경 |
| **5** | 넓은 형상으로 뭉뚱그린다 | ✅ | 1 | ✅ 대략 | 숲 덩어리를 벽으로 |

### 1. ProtonScatter + `Keep Static Colliders` — 요구한 그대로를 해 주는 유일한 도구 ✅

**"원본 씬에 콜리전을 넣어 두면 뿌린 전부에 자동으로 생긴다"를 체크박스 하나로 해 준다.**
엔진 기능이 아니라 애드온([HungryProton/scatter](https://github.com/HungryProton/scatter))이다.

소스(`addons/proton_scatter/src/scatter.gd`)를 열면 왜 되는지가 분명하다 —
**MultiMesh 인스턴스를 채우는 바로 그 루프가, 같은 `Transform3D` 로 물리 서버에 shape 을 등록한다.**

```gdscript
# scatter.gd:74-76 — 프로퍼티
## If enabled, creates static collision shapes for scattered objects.
## Uses the Physics server directly instead of creating actual collision nodes
@export var keep_static_colliders := false

# scatter.gd:448-450 — 결정적. 렌더와 물리가 같은 t 를 쓴다
t = item.process_transform(transforms.list[offset + i])
mmi.multimesh.set_instance_transform(i, t)
_create_collision(static_body, t)
```

```
① AssetLib 에서 ProtonScatter 설치 → Project Settings ▸ Plugins 에서 활성화
② ProtonScatter 노드 추가
③ 자식으로 ScatterItem   → Path 에 나무 씬 지정 (그 씬에 StaticBody3D + CapsuleShape3D 를 넣어 둔다)
④ 자식으로 ScatterShape  → 뿌릴 영역
⑤ 루트 선택 ▸ Inspector
     Render Mode           = Use Instancing   (0 — MultiMesh)
     Keep Static Colliders = ✅ 체크           ← 이 한 번이 전부다
```

| 알아 둘 것 | |
|---|---|
| 지원 shape | Sphere · Box · **Capsule** · Cylinder · ConcavePolygon · ConvexPolygon · HeightMap · SeparationRay |
| `Render Mode` | `Use Instancing`(0)·`Use Particles`(2) 에서 작동한다. 🛑 **`Create Copies`(1) 에서는 무시된다**(그때는 노드가 진짜로 복제되므로 콜리전도 따라온다) |
| 🛑 **씬 트리에 노드가 없다** | `PhysicsServer3D` 에 직접 등록한다. **`Debug ▸ Visible Collision Shapes` 에도 안 보인다**(소스 주석에 명시). 검증은 실제로 부딪혀 보는 수밖에 없다 |
| 🛑 **조상 변환이 반영되지 않는다** | `body_add_shape(..., t * c.transform)` — 곱해지는 건 인스턴스 변환과 **`CollisionShape3D` 로컬 transform** 뿐이다. **[SSOT §3.2](../../game/references/SSOT.md) 의 `Body` 노드 `scale` 은 콜리전에 반영되지 않는다** — 메시만 커지고 콜리전은 원래 크기로 남는다 |
| 🛑 **collision layer 를 설정하지 않는다** | 소스에 `body_set_collision_layer` 호출이 **0회**. 전부 기본 레이어로 들어간다 |
| Godot 4.7 | 최신 커밋 **2026-07-26 "fix compatibility issue with 4.7"** · `plugin.cfg` `4.2.0` |

> ⚠️ **공식 위키는 이 기능을 모른다.** 위키 `Multimesh and duplicates` 는 "Multimesh mode …
> only cares for the MeshInstances, scripts and **colliders are ignored**" 라고 적혀 있지만
> **`keep_static_colliders` 가 생기기 전에 쓰인 문서**다. 소스가 정본이다.

### 2. GridMap + MeshLibrary — 클릭만으로 되는 유일한 *내장* 경로 ✅

**MeshLibrary 아이템에 콜리전을 넣어 두면, GridMap 이 셀을 놓을 때마다 콜리전을 자동으로 만든다.**
§5 [C] 로 실측 확인했다.

```
[준비 씬]  아이템마다 이렇게 만든다
  Tree (MeshInstance3D)          ← 아이템 이름이 된다
    └ StaticBody3D               ← Mesh ▸ Create Collision Shape ▸ Static Body Child ▸ Capsule
        └ CollisionShape3D

[내보내기]  Scene ▸ Export As... ▸ MeshLibrary...  →  tree_lib.tres

[쓰기]     GridMap 노드 추가 ▸ Inspector 의 Mesh Library 에 tree_lib.tres 지정
           ▸ 아래 팔레트에서 아이템 고르고 뷰포트를 클릭해 배치
```

| 얻는 것 | 잃는 것 |
|---|---|
| ✅ **콜리전 자동** — 아이템에 넣은 shape 이 셀마다 생긴다 | 🛑 **격자에만 놓인다** (`Cell Size` 간격) |
| ✅ 렌더링은 octant 단위로 **배칭된다** | 🛑 회전은 **직교 24방향만** (자유 각도 불가) |
| ✅ 노드 1개 | 🛑 인스턴스별 **크기 무작위 불가** |
| ✅ 내비게이션 메시도 아이템에 넣을 수 있다 | 🛑 아이템 종류가 많으면 배칭이 갈라진다 |

> **판단 기준 하나** — "격자에 놓여도 어색하지 않은가?"
> 건물·바닥·벽·울타리·가로등은 ✅. 자연스러운 숲은 ❌(격자 티가 난다).

### 3. 충돌이 필요한 것만 개별 노드로

**대부분의 게임이 실제로 쓰는 방법이다.** 나무 500그루 중 캐릭터가 닿을 수 있는 건 몇십 그루다.

```
큰 나무 30그루  → MeshInstance3D + StaticBody3D + CapsuleShape3D  (드로우콜 30)
작은 풀 5,000  → MultiMeshInstance3D, 콜리전 없음                 (드로우콜 1)
```

### 4. 콜리전을 아예 주지 않는다

**풀·꽃·자갈·먼 배경 나무는 통과해도 아무도 모른다.** 가장 싸고, 대부분 이걸로 충분하다.

### 5. 넓은 형상으로 뭉뚱그린다

숲 한 덩어리를 `StaticBody3D` + `BoxShape3D` **하나로** 막는다.
"이 숲에는 못 들어간다" 가 규칙이면 나무마다 콜리전을 줄 이유가 없다.

### 6. 애드온 없이 스크립트로

- **godot-multimesh-scatter** — 뿌리기 자체를 노드로 만든 애드온. 파라미터를 바꾸면 에디터에서
  즉시 다시 뿌린다. 다만 **콜리전 자동 생성은 이 애드온의 기능이 아니다**(설정에 있는
  collision layer/mask 는 뿌릴 지면을 찾는 레이캐스트용이다).
- **직접 스크립트** — `MultiMesh.get_instance_transform(i)` 를 돌며 `StaticBody3D` 를 만들어 붙인다.
  🛑 **그 순간 노드가 N 개로 늘어나** MultiMesh 의 이점 절반(노드 수·메모리)이 사라진다.
  드로우콜만 1로 남는다.

---

## 7. 🛑 세 가지 함정 — 컬링·LOD·삼각형

### ① 컬링이 전부-아니면-전무

공식 문서 원문 —

> there is no *screen* or *frustum* culling possible for individual instances.
> This means, that millions of objects will be *always* or *never* drawn

```
[맵 전체를 MultiMesh 1개 — 나무 5,000그루]
  화면에 보이는 건 100그루  → 5,000그루 전부 GPU 로     ❌ 50배 헛그림

[청크마다 MultiMesh 1개]
  화면에 걸친 청크 3개만    → 약 150그루                ✅
```

🛑 **맵 전체를 하나로 묶지 않는다. 청크마다 하나씩 만든다.**

### ② LOD 가 전부 같은 단계

MultiMesh 안의 인스턴스는 **거리와 무관하게 전부 같은 LOD** 로 그려진다.
→ 청크로 쪼개면 청크 단위로는 LOD 가 갈리므로 완화된다.

### ③ 삼각형은 줄지 않는다

**MultiMesh 는 드로우콜을 줄이는 것이지 삼각형을 줄이는 것이 아니다.**
§3 실측에서 Primitives 가 12,045 → 18,310 으로 **늘어난 것**이 그 증거다.

| 병목이 무엇인가 | MultiMesh 가 | |
|---|---|---|
| 드로우콜 (CPU) | ✅ **해결한다** | 500 → 1 |
| 삼각형 (GPU) | ❌ 그대로다 | 삼각형은 LOD·임포스터로 |
| 메모리 | ✅ 크게 줄인다 | 노드 500개 → 1개 |

---

## 8. 코드로 다룰 때

```gdscript
var mm := MultiMesh.new()
mm.transform_format = MultiMesh.TRANSFORM_3D   # 🛑 instance_count 보다 먼저
mm.mesh = preload("res://assets/tree.res")
mm.instance_count = 500                        # 🛑 여기서 버퍼가 잡힌다

for i in mm.instance_count:
    var t := Transform3D()
    t = t.rotated(Vector3.UP, randf() * TAU)
    t.origin = Vector3(randf_range(-16, 16), 0, randf_range(-16, 16))
    mm.set_instance_transform(i, t)

var node := MultiMeshInstance3D.new()
node.multimesh = mm
add_child(node)
```

| 함정 | |
|---|---|
| `transform_format` 을 나중에 정하면 | 🛑 버퍼 해석이 어긋난다. **`instance_count` 앞에 둔다** |
| `instance_count` 를 다시 대입하면 | 🛑 **변환이 전부 초기화된다.** 개수를 바꿔 가며 쓸 거면 `visible_instance_count` |
| 인스턴스 색을 쓰려면 | `mm.use_colors = true` 를 **`instance_count` 앞에** 켠다 |
| 헤드리스에서 | 드로우콜은 못 잰다(더미 렌더러). `instance_count` 와 물리 판정은 잴 수 있다 |

---

## 9. 라리엔 3D 에서 이것이 걸리는 곳

카메라가 **직교 · 피치 −45° 고정**([SSOT](../../game/references/SSOT.md))이라는 점이
MultiMesh 의 단점 대부분을 무력화한다.

| 일반 3D 게임에서 | 라리엔 3D 에서 |
|---|---|
| LOD 통일 제약이 손해 | ✅ **무해** — 직교라 화면의 모든 물체가 어차피 같은 거리대다 |
| 컬링 전부-아니면-전무가 위험 | ⚠️ 여전히 위험 → **청크(64m)마다 MultiMesh 를 나눈다** |
| 자유 카메라라 뒷면도 필요 | ✅ 보이는 면만 만들면 된다 |

### 콜리전 방침

라리엔 3D 는 **서버가 walkable 격자로 이동을 판정한다**([SSOT §7.1](../../game/references/SSOT.md)).
즉 **클라이언트의 나무 콜리전은 이동 판정의 근거가 아니다.**

| 대상 | 클라이언트 콜리전 | 왜 |
|---|---|---|
| 풀·꽃·자갈 | ❌ 주지 않는다 | 서버 walkable 에도 없다 |
| 일반 나무·바위 (MultiMesh) | ❌ 주지 않는다 | **서버 walkable 이 막는다.** 클라가 또 막을 이유가 없다 |
| 건물·큰 랜드마크 | ✅ 개별 노드 + Capsule/Box | 클릭 대상이 되거나 카메라 페이드 대상이라 |
| 지면 | ✅ Trimesh 또는 HeightMap | 클릭-이동의 레이캐스트 대상 |

> 🛑 **클라이언트에 콜리전을 촘촘히 깔고 싶어지면 먼저 물어야 한다** —
> "이것이 서버 walkable 과 어긋나면 어느 쪽이 맞나?" 답은 언제나 **서버**다.
> 클라 콜리전은 **연출·클릭 판정**을 위한 것이지 이동 규칙이 아니다.

### 🛑 지금 나무에 콜리전을 붙이면 클릭-이동이 깨진다

**이 저장소의 현재 코드에 실제로 걸리는 함정이다.**

```gdscript
# scenes/main/player.gd — _pick_ground()
var query := PhysicsRayQueryParameters3D.create(from, to)
query.exclude = [get_rid()]   # ← collision_mask 를 지정하지 않는다
var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
```

클릭 광선이 **모든 레이어**를 맞힌다. 지금은 지면만 콜리전을 가지고 있어 문제가 없지만,
나무·바위에 콜리전이 생기는 순간 **나무를 클릭하면 나무 표면이 이동 목표**가 된다.

특히 ProtonScatter 의 `Keep Static Colliders`(§6-1)는 **collision layer 를 아예 설정하지 않아**
전부 기본 레이어로 들어가므로 **반드시** 이 광선에 걸린다.

> **순서가 있다** — 기물 콜리전을 켜기 **전에** `_pick_ground()` 의 `collision_mask` 를
> 지면 레이어로 잠근다. 레이어 번호를 정하는 것은 기획 결정이다.

---

## 참고

| | |
|---|---|
| 공식 | [Using MultiMeshInstance3D](https://docs.godotengine.org/en/stable/tutorials/3d/using_multi_mesh_instance.html) · [Optimization using MultiMeshes](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html) · [Using GridMaps](https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html) |
| 엔진 소스 | `editor/scene/3d/multimesh_editor_plugin.cpp` · `editor/scene/3d/mesh_instance_3d_editor_plugin.cpp` |
| 제안 | [#10828 collision/raycast for MultiMeshInstance3D](https://github.com/godotengine/godot-proposals/issues/10828) (open) · [#4344 MultiColliderInstance](https://github.com/godotengine/godot-proposals/issues/4344) (closed) |
| 애드온 | [HungryProton/scatter (ProtonScatter)](https://github.com/HungryProton/scatter) — `keep_static_colliders` 는 `addons/proton_scatter/src/scatter.gd` |
| 이 저장소 | [tests/multimesh_collision_probe.gd](../../../../tests/multimesh_collision_probe.gd) — §5 의 실측 |
| 이어서 | [lowend-culling-lod.md](lowend-culling-lod.md) 드로우콜 예산 · [lowend-3gb-60fps.md](lowend-3gb-60fps.md) §5.3 메모리 |
