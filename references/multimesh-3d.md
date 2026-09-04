# MultiMeshInstance3D — 같은 것을 수천 개 그리고, 콜리전은 따로 푼다

> **이 문서로 오는 상황** — 나무·바위·풀처럼 **같은 메시를 대량으로** 놓아야 할 때.
> 씬을 처음부터 만드는 법, 에디터 **Populate Surface** 로 뿌리는 법, **뿌린 것들에 왜
> 충돌이 없는지**, 그리고 **콜리전을 붙이는 여섯 가지 방법** 전부.
> 드로우콜 예산 전반은 [lowend-culling-lod.md](lowend-culling-lod.md),
> 메모리 계산은 [lowend-3gb-60fps.md](lowend-3gb-60fps.md) §5.3.

이 문서의 숫자는 전부 **엔진에서 직접 뽑은 것**이다. 기준은 **4.7.2.stable.official** 이고,
물리 판정은 아래 세 프로브로 직접 쟀다(명령과 출력을 각 절에 그대로 붙였다).

| 프로브 | 무엇을 재나 |
|---|---|
| [`tests/multimesh_collision_probe.gd`](../../../../tests/multimesh_collision_probe.gd) | MultiMesh 에 물리가 없다 · GridMap 에는 있다 |
| [`tests/mm_add_collision_probe.gd`](../../../../tests/mm_add_collision_probe.gd) | 콜리전을 직접 붙이는 두 방법 |
| [`tests/protonscatter_collision_probe.gd`](../../../../tests/protonscatter_collision_probe.gd) | ProtonScatter 의 `Keep Static Colliders` |

---

## 목차

1. [한눈에 — 무엇이고 무엇이 아닌가](#1-한눈에--무엇이고-무엇이-아닌가)
2. [구조 — 리소스와 노드가 나뉘어 있다](#2-구조--리소스와-노드가-나뉘어-있다)
3. [씬을 처음부터 만든다](#3-씬을-처음부터-만든다)
4. [에디터로 뿌린다 — Populate Surface](#4-에디터로-뿌린다--populate-surface)
5. [Create Collision Shape — 9가지 중 무엇을 고르나](#5-create-collision-shape--9가지-중-무엇을-고르나)
6. [🛑 콜리전은 복제되지 않는다 (실측)](#6--콜리전은-복제되지-않는다-실측)
7. [콜리전을 붙이는 여섯 가지 방법](#7-콜리전을-붙이는-여섯-가지-방법)
8. [ProtonScatter 완전 안내](#8-protonscatter-완전-안내)
9. [GridMap + MeshLibrary 완전 안내](#9-gridmap--meshlibrary-완전-안내)
10. [🛑 세 가지 함정 — 컬링·LOD·삼각형](#10--세-가지-함정--컬링lod삼각형)
11. [코드로 다룰 때](#11-코드로-다룰-때)
12. [직접 해 본다 — 실습 씬 넷](#12-직접-해-본다--실습-씬-넷)
13. [라리엔 3D 에서 이것이 걸리는 곳](#13-라리엔-3d-에서-이것이-걸리는-곳)

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
> 그래서 §6 의 결과가 나오고, §7 이 필요해진다.

---

## 2. 구조 — 리소스와 노드가 나뉘어 있다

처음 만지면 여기서 한 번 헷갈린다. **노드와 리소스가 두 층으로 나뉘어 있다.**

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

**`MultiMeshInstance3D` 를 씬에 추가하면 `multimesh` 칸이 `<empty>` 다.** Populate Surface 를
쓰면 자동으로 채워지고, 코드로 만들 때는 `MultiMesh.new()` 를 넣어 줘야 한다.

| 알아 둘 것 | |
|---|---|
| **메시는 하나뿐이다** | 나무 3종을 섞으려면 MultiMesh 도 3개다 |
| **머티리얼도 하나뿐이다** | 인스턴스별로 바꾸려면 `use_colors` 나 `use_custom_data` + 셰이더 |
| `instance_count` 를 바꾸면 | **버퍼가 다시 잡히고 기존 변환이 날아간다.** 개수를 먼저 정하고 채운다 |
| `visible_instance_count` | 버퍼는 그대로 두고 **앞에서부터 N 개만** 그린다. 개수를 자주 바꿀 때 쓴다 |

---

## 3. 씬을 처음부터 만든다

**Populate Surface 를 쓰려면 노드 셋이 한 씬 안에 있어야 한다.** 하나라도 빠지면 다이얼로그가
열리지 않거나 거절당한다.

| 역할 | 노드 타입 | 하는 일 |
|---|---|---|
| **Target Surface** | 🛑 `MeshInstance3D` | 인스턴스가 **놓일 바닥**. 면이 있어야 한다 |
| **Source Mesh** | 🛑 `MeshInstance3D` | **복제할 것** (나무 1그루) |
| **결과** | `MultiMeshInstance3D` | 뿌려진 결과가 담긴다 |

### 최소 절차

```
1. Scene ▸ New Scene ▸ 3D Scene            루트가 Node3D 로 생긴다
2. 루트 우클릭 ▸ Add Child Node
     MeshInstance3D        → Inspector ▸ Mesh ▸ New PlaneMesh (Size 30 × 30)   … 바닥
     DirectionalLight3D                                                        … 빛
     Camera3D                                                                  … 시점
     MultiMeshInstance3D                                                       … 결과가 담길 곳
3. 바닥에 콜리전을 준다 (캐릭터가 서 있으려면 필요하다)
     바닥 선택 ▸ 툴바 Mesh ▸ Create Collision Shape
       Placement = Static Body Child · Type = Trimesh → Create
4. 뿌릴 나무를 씬에 넣는다  (아래 두 경로 중 하나)
5. MultiMeshInstance3D 선택 ▸ 툴바 MultiMesh ▸ Populate Surface
6. Ctrl/Cmd + S 로 저장
```

### 🛑 4단계 — `.glb` 를 넣었다면 한 단계가 더 있다

**여기가 처음 하는 사람이 반드시 걸리는 곳이다.**

`.glb` 파일을 FileSystem 에서 뷰포트로 끌어다 놓으면, 씬 트리에는 이렇게 들어온다:

```
Node3D
└── grass-trees2          ← 🎬 씬 인스턴스 아이콘. 이 노드의 타입은 Node3D 다
```

**이 노드를 Source Mesh 로 고르면 거절당한다** — `MeshInstance3D` 가 아니기 때문이다.

```
Surface source is invalid (not a MeshInstance3D).
```

메시는 그 **안쪽**에 있는데, 인스턴스는 기본적으로 내부가 접혀 있어 보이지 않는다.
꺼내는 방법은 둘이다.

| 방법 | 어떻게 | 결과 | 언제 |
|---|---|---|---|
| **Editable Children** | 인스턴스 우클릭 ▸ **Editable Children** 체크 | 자식이 펼쳐진다. 이름이 **다른 색**으로 표시된다(원본 씬 소유라는 뜻) | 원본 `.glb` 와의 연결을 유지하고 싶을 때 |
| **Make Local** | 인스턴스 우클릭 ▸ **Make Local** | 인스턴스 연결이 끊기고 **평범한 노드 묶음**이 된다 | 이 씬에서만 자유롭게 고칠 때 |

`Editable Children` 을 켜면 이렇게 된다:

```
Node3D
├── WorldEnvironment
├── grass-trees2                     🎬 인스턴스 (Editable Children ✅)
│   └── grass-trees                  ← MeshInstance3D. 이것을 Source Mesh 로 고른다
├── MeshInstance3D                   ← 바닥 (Target Surface)
│   └── StaticBody3D
│       └── CollisionShape3D
├── MultiMeshInstance3D              ← 결과가 담길 곳
└── Camera3D
```

> **이름 색이 다른 이유** — 그 노드는 **원본 씬이 소유**한다. 값을 바꾸면 되돌리기 화살표가
> 뜨고, 원본 `.glb` 를 다시 임포트하면 덮어써진다.

### 🛑 `MultiMeshInstance3D` 를 인스턴스 **안에** 넣지 않는다

`Editable Children` 을 켜 두면 인스턴스 안에도 노드를 추가할 수 있다. **하지만 그렇게 하지 않는다.**

```
🛑 이렇게 하지 않는다                    ✅ 이렇게 한다
Node3D                                  Node3D
└── grass-trees2  (인스턴스)             ├── grass-trees2  (인스턴스)
    ├── grass-trees                      │   └── grass-trees      ← Source Mesh 로만 쓴다
    └── MultiMeshInstance3D  ← 여기       ├── MultiMeshInstance3D  ← 루트 바로 아래
                                         └── ...
```

| 왜 |
|---|
| 인스턴스 안의 노드는 **원본 씬의 구조에 얹힌 덧붙임**이라, 원본 `.glb` 를 다시 임포트하거나 구조가 바뀌면 **자리를 잃거나 사라질 수 있다** |
| 인스턴스의 transform 이 **결과 전체에 곱해진다** — 나무 한 그루를 옮겼을 뿐인데 뿌린 숲이 통째로 움직인다 |
| 나중에 **Source Mesh 를 지우고 싶어도** MultiMesh 가 그 안에 있어 같이 지워진다 |

**결과 노드는 항상 바깥에, 뿌릴 좌표의 기준이 되는 자리에 둔다.**

### 다 뿌린 뒤 Source Mesh 는 어떻게 하나

**지워도 된다.** 변환 배열은 이미 `MultiMesh` 리소스 안에 복사됐다.

다만 **나무 한 그루가 화면에 계속 서 있는 게 싫다면** 지우고, **나중에 다시 뿌릴 생각이면**
남겨 두거나 `Visibility ▸ Visible` 를 꺼 둔다. (`.glb` 인스턴스는 지워도 원본 파일은 그대로다.)

---

## 4. 에디터로 뿌린다 — Populate Surface

### 클릭 순서

```
1. 씬 트리에서 MultiMeshInstance3D 를 클릭해 선택한다
     🛑 선택하지 않으면 툴바에 MultiMesh 메뉴가 나타나지 않는다
2. 3D 뷰포트 상단 툴바 ▸ MultiMesh  → 클릭
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

### 🛑 막히는 곳과 원인

| 증상 | 원인 |
|---|---|
| 툴바에 `MultiMesh` 메뉴가 **없다** | `MultiMeshInstance3D` 를 **선택하지 않았다**. 다른 노드를 선택 중이면 안 뜬다 |
| `Surface source is invalid (not a MeshInstance3D).` | 고른 노드가 `MeshInstance3D` 가 아니다 → §3 의 `Editable Children` |
| `Surface source is invalid (no faces).` | 바닥 메시에 면이 없다. `PlaneMesh` 등 실제 면이 있는 메시여야 한다 |
| `No mesh source specified…` | Source Mesh 를 안 골랐거나, 고른 노드의 `Mesh` 가 비어 있다 |
| 나무가 **누워서** 심긴다 | `Mesh Up Axis` 를 소스 메시의 위쪽 축에 맞춘다 |
| 다시 Populate 했더니 **더해지지 않는다** | 정상이다. **덮어쓴다** |
| 뿌린 나무가 **전부 같은 방향** | `Random Rotation` 을 올린다 |

### 실측 — 나무 3그루를 뿌렸을 때 (4.7.2)

| | 뿌리기 전 | 뿌린 뒤 | 변화 |
|---|---|---|---|
| Objects | 23 | 24 | **+1** (노드 1개) |
| Primitives | 12,045 | 18,310 | +6,265 (삼각형은 실제로 늘어난다) |
| **Draw Calls** | 23 | **24** | **+1** |

**나무가 3그루든 300그루든 드로우콜은 +1 이다.** 이것이 MultiMesh 를 쓰는 유일한 이유다.
반대로 **삼각형은 전혀 줄지 않는다** — 개수만큼 그대로 늘어난다(§10).

---

## 5. Create Collision Shape — 9가지 중 무엇을 고르나

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
| **Trimesh** | 메시 삼각형 전부 | 🛑 **가장 비싸다** | 정적 지형·바닥. 움직이는 바디에는 못 쓴다 |
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

**나무 한 그루의 Trimesh 콜리전은 잎사귀 삼각형까지 전부 물리 형상이 된다.**
그런데 게임에서 필요한 건 **"줄기에 부딪힌다"** 뿐이다. 잎은 통과해도 아무도 모른다.

| | Trimesh | **Capsule** |
|---|---|---|
| 물리 형상 | 잎까지 수천 삼각형 | **캡슐 1개** |
| 필요한가 | ❌ 잎에 부딪힐 일이 없다 | ✅ 줄기만 막으면 된다 |
| 움직이는 바디로 | 🛑 못 쓴다 | ✅ 된다 |

---

## 6. 🛑 콜리전은 복제되지 않는다 (실측)

> # 원본에 콜리전을 만들어 두어도, Populate Surface 로 뿌린 인스턴스에는 콜리전이 없다.

**버그가 아니라 설계다.**

```
MultiMesh  →  RenderingServer   (변환 배열을 GPU 버퍼로)   ← 인스턴스는 여기에만 있다
              PhysicsServer3D                              ← 여기에는 아무것도 없다
```

`MultiMesh` 는 **렌더링 서버의 자료구조**다. 물리 서버는 `CollisionObject3D` 를 상속한 **노드**만
안다. MultiMesh 인스턴스는 노드가 아니므로 **물리 세계에 존재하지 않는다.**

그리고 `Populate Surface` 는 **`Mesh` 리소스만** 복사한다 — 원본 씬 트리에 매달린
`StaticBody3D` 는 구조적으로 따라올 수가 없다. 에디터 플러그인 소스
(`multimesh_editor_plugin.cpp`)에도 **콜리전을 만드는 코드가 한 줄도 없다.**

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
    (에디터의 'Create Collision Shape > Capsule' 과 같은 구조)
  ✅ 원본에 레이                    — 기대 충돌함   / 실제 충돌함
  ✅ MultiMesh 사본 (x=-40) 에 레이 — 기대 충돌없음 / 실제 충돌없음
  ✅ MultiMesh 사본 (x=-60) 에 레이 — 기대 충돌없음 / 실제 충돌없음

[C] GridMap + MeshLibrary(shape 포함) 는 콜리전이 자동으로 생기는가
  셀 3개 배치 · 노드 수 = 1 · get_used_cells = 3
  ✅ 셀 0 (x=0) 에 레이 — 기대 충돌함 / 실제 충돌함
  ✅ 셀 1 (x=4) 에 레이 — 기대 충돌함 / 실제 충돌함
  ✅ 셀 2 (x=8) 에 레이 — 기대 충돌함 / 실제 충돌함

실패 0 건
```

**[B] 가 답이다** — 원본만 충돌하고 사본은 통과한다.

### 화면에서 어떻게 보이나

- 뿌린 나무를 **뷰포트에서 클릭해도 선택되지 않는다** (개별 객체가 아니다)
- 캐릭터가 **나무를 그냥 통과한다**
- `RayCast3D` · `intersect_ray` 가 **아무것도 못 맞힌다**

---

## 7. 콜리전을 붙이는 여섯 가지 방법

**엔진 내장에는 "원본 콜리전을 인스턴스에 자동 복제" 하는 버튼이 없다.** 제안
[#10828](https://github.com/godotengine/godot-proposals/issues/10828) 은 2024-09-26 에 열린 뒤
아직 **open** 이고 담당자도 없다. (#4344 `MultiColliderInstance`, godot#23019 는 **closed**.)

그래서 방법이 갈린다. **먼저 두 갈래를 구분해야 한다.**

```
[한꺼번에 붙인다]   인스턴스 N개에 대응하는 shape N개를, 바디 1개에 몰아 넣는다
                    → 방법 A · B · C · D.  노드 수가 폭발하지 않는다

[하나씩 붙인다]     인스턴스마다 StaticBody3D 를 따로 만든다
                    → 방법 E.  MultiMesh 를 쓰는 의미가 절반 사라진다
```

| # | 방법 | 클릭만으로? | 드로우콜 | 만드는 노드 | 에디터에 보이나 | 언제 |
|---|---|---|---|---|---|---|
| **A** | **ProtonScatter + `Keep Static Colliders`** | ✅ 체크박스 하나 | 1 | **0** | ❌ | **자유 배치 + 충돌** |
| **B** | **GridMap + MeshLibrary** (내장) | ✅ 된다 | 배칭됨 | 0 | ✅ | 격자에 놓아도 되는 것 |
| **C** | 스크립트 — `StaticBody3D` 1개 + `CollisionShape3D` N개 | ❌ 코드 | 1 | **N+1** | ✅ | 디버그 뷰로 **보고 싶을 때** |
| **D** | 스크립트 — `PhysicsServer3D` 직접 | ❌ 코드 | 1 | **0** | ❌ | 인스턴스가 **아주 많을 때** |
| **E** | 충돌이 필요한 것만 개별 노드 | ✅ | 개수만큼 | N | ✅ | 큰 나무 **수십 그루** |
| **F** | 콜리전을 아예 안 준다 / 넓게 뭉뚱그린다 | ✅ | 1 | 0~1 | ✅ | 풀·꽃·자갈·먼 배경 |

**A·B 는 §8·§9 에서 따로 다룬다.** 여기서는 코드로 붙이는 C·D 를 본다.

### 방법 C — `StaticBody3D` 1개 + `CollisionShape3D` N개

**가장 이해하기 쉽고, 에디터 디버그 뷰에서 눈으로 확인된다.**

```gdscript
# MultiMeshInstance3D 아래에 바디 하나를 두고, 인스턴스마다 shape 노드를 붙인다
var body := StaticBody3D.new()
mmi.add_child(body)                       # MultiMesh 와 같은 좌표계에 둔다

var shape := CapsuleShape3D.new()         # 🛑 shape 리소스는 하나만 만들어 공유한다
shape.radius = 0.45
shape.height = 3.2

for i in mmi.multimesh.instance_count:
    var col := CollisionShape3D.new()
    col.shape = shape                     # 같은 리소스를 N개가 함께 쓴다 (메모리 1벌)
    col.transform = mmi.multimesh.get_instance_transform(i)
    body.add_child(col)
```

| 장점 | 단점 |
|---|---|
| ✅ `Debug ▸ Visible Collision Shapes` 로 **보인다** | 🛑 노드가 **N+1개** 생긴다 |
| ✅ 레이어·마스크를 `body` 에서 한 번에 정한다 | 🛑 인스턴스가 수천이면 씬 트리가 무거워진다 |
| ✅ 나중에 하나씩 지우거나 옮길 수 있다 | |

### 방법 D — `PhysicsServer3D` 에 직접 등록

**노드를 하나도 만들지 않는다.** ProtonScatter 가 내부에서 쓰는 방식이다.

```gdscript
# 바디 하나를 물리 서버에 직접 만든다
var body_rid := PhysicsServer3D.body_create()
PhysicsServer3D.body_set_mode(body_rid, PhysicsServer3D.BODY_MODE_STATIC)
PhysicsServer3D.body_set_space(body_rid, get_world_3d().space)
PhysicsServer3D.body_set_state(
    body_rid, PhysicsServer3D.BODY_STATE_TRANSFORM, mmi.global_transform)

# shape 도 하나만 만들어 N번 재사용한다
var shape_rid := PhysicsServer3D.capsule_shape_create()
PhysicsServer3D.shape_set_data(shape_rid, {"radius": 0.45, "height": 3.2})

for i in mmi.multimesh.instance_count:
    PhysicsServer3D.body_add_shape(
        body_rid, shape_rid, mmi.multimesh.get_instance_transform(i))

# 🛑 RID 는 직접 지운다. 노드가 아니라서 queue_free() 가 챙겨 주지 않는다
# PhysicsServer3D.free_rid(body_rid)
# PhysicsServer3D.free_rid(shape_rid)
```

| 장점 | 단점 |
|---|---|
| ✅ 노드 **0개**. 씬 트리가 그대로다 | 🛑 `Debug ▸ Visible Collision Shapes` 에 **안 보인다** |
| ✅ 인스턴스가 수천이어도 가볍다 | 🛑 **RID 를 직접 해제**해야 한다 (안 하면 샌다) |
| | 🛑 레이어·마스크도 `body_set_collision_layer` 로 직접 설정해야 한다 |

> **레이어를 잊지 말 것** — `body_create()` 의 기본 레이어는 1이다.
> `PhysicsServer3D.body_set_collision_layer(body_rid, 원하는_비트)` 를 반드시 부른다.

### 실측 — C·D 둘 다 동작한다

```bash
godot --headless --path . -s res://tests/mm_add_collision_probe.gd
```

```
=== Godot 4.7.2-stable (official) · MultiMesh 에 콜리전 붙이기 실측 ===

[기준선] MultiMesh 만 놓았을 때
  ✅ 레이 24발 중  0발 명중 · 만들어진 노드  0개

[방법 C] StaticBody3D 1개 + CollisionShape3D N개
         노드가 보이고 Debug ▸ Visible Collision Shapes 로 확인된다
  ✅ 레이 24발 중 24발 명중 · 만들어진 노드 25개

[방법 D] PhysicsServer3D 에 shape 을 직접 등록 (ProtonScatter 방식)
         노드가 0개다. 그래서 Debug 뷰에도 안 보인다
  ✅ 레이 24발 중 24발 명중 · 만들어진 노드  0개

실패 0 건
```

### 🛑 방법 E 를 고를 때의 판단

"인스턴스마다 `StaticBody3D` 를 하나씩" 은 **MultiMesh 를 쓰는 의미를 절반 없앤다.**
드로우콜은 1로 남지만 **노드 수·메모리·씬 트리 부담이 개별 배치와 같아진다.**

**충돌이 필요한 것이 수십 개뿐이라면 애초에 MultiMesh 를 쓰지 말고 개별 노드로 두는 편이 낫다.**
MultiMesh 는 "수백~수천 개를 싸게 그린다" 가 목적이지 "콜리전을 붙인다" 가 목적이 아니다.

---

## 8. ProtonScatter 완전 안내

> 📘 **클릭 순서만 따라 하려면 [protonscatter.md](protonscatter.md) 로 간다** —
> 설치부터 `Keep Static Colliders` 까지 10단계로 나눠 적었다. 이 절은 요약이다.

**"원본 씬에 콜리전을 넣어 두면 뿌린 전부에 자동으로 생긴다" 를 체크박스 하나로 해 주는
유일한 도구다.** 엔진 기능이 아니라 애드온([HungryProton/scatter](https://github.com/HungryProton/scatter))이다.

### 왜 되는가 — 소스가 근거다

`addons/proton_scatter/src/scatter.gd` 를 열면 분명하다.
**MultiMesh 인스턴스를 채우는 바로 그 루프가, 같은 `Transform3D` 로 물리 서버에 shape 을 등록한다.**

```gdscript
# scatter.gd:74-76 — 프로퍼티 선언
## If enabled, creates static collision shapes for scattered objects.
## Uses the Physics server directly instead of creating actual collision nodes
@export var keep_static_colliders := false

# scatter.gd:45-51 — render_mode 의 의미
## Use Instancing (0): Uses MultiMesh instances for efficient rendering of identical objects.
## Create Copies (1): Creates individual node copies for each scattered object.
## Use Particles (2): Uses GPU particles system for very large numbers of objects.

# scatter.gd:448-450 — 결정적. 렌더와 물리가 같은 t 를 쓴다
t = item.process_transform(transforms.list[offset + i])
mmi.multimesh.set_instance_transform(i, t)   # 렌더
_create_collision(static_body, t)            # 물리

# scatter.gd:609-611 — MultiMesh 모드(0)에서 작동한다. 끄는 것은 1(Create Copies)뿐
func _create_collision(body: StaticBody3D, t: Transform3D) -> void:
	if not keep_static_colliders or render_mode == 1:
		return
```

즉 **§7 의 방법 D 를 애드온이 대신 해 주는 것**이다.
지원 shape 은 Sphere · Box · **Capsule** · Cylinder · ConcavePolygon · ConvexPolygon ·
HeightMap · SeparationRay.

> ⚠️ **공식 위키는 이 기능을 모른다.** 위키 `Multimesh and duplicates` 에는
> "Multimesh mode … only cares for the MeshInstances, scripts and **colliders are ignored**"
> 라고 적혀 있지만, `keep_static_colliders` 가 생기기 전에 쓰인 문서다. **소스가 정본이다.**

### 설치

```
방법 A  에디터 ▸ AssetLib 탭 ▸ "ProtonScatter" 검색 ▸ Download ▸ Install
방법 B  저장소를 받아 addons/proton_scatter/ 에 직접 넣는다 (버전 고정 벤더링)
그다음  Project ▸ Project Settings ▸ Plugins ▸ ProtonScatter 를 Enable
```

**Godot 4.7 호환** — 최신 커밋 **2026-07-26 "fix compatibility issue with 4.7"**,
`plugin.cfg` version `4.2.0`.

### 노드 구성

```
ProtonScatter                     ← 여기에 Keep Static Colliders 가 있다
├── ScatterItem                     무엇을 뿌릴 것인가
│     Source = From disk
│     Path   = res://…/mm_tree.tscn   🛑 프로퍼티 이름은 path 다 (source_scene 아니다)
└── ScatterShape                    어디에 뿌릴 것인가
      Shape  = ProtonScatterBoxShape (Size 11 × 2 × 11)
```

### 인스펙터에서 켤 것

| 위치 | 값 |
|---|---|
| `ProtonScatter` ▸ **Render Mode** | **`Use Instancing`** (= MultiMesh) |
| `ProtonScatter` ▸ **Keep Static Colliders** | **✅ 체크** ← 이 한 번이 전부다 |

### Modifier Stack — 에디터는 자동으로 채우고, 코드는 비어 있다

ProtonScatter 는 "몇 개를 어디에 놓을지" 를 **Modifier Stack** 에서 정한다.

| 경로 | 스택 |
|---|---|
| **에디터에서 노드 추가 → 인스펙터를 연다** | ✅ **기본 프리셋 4개가 자동으로 들어온다** (`stack_panel.gd:73-76` 이 `presets/scatter_default.tscn` 을 적용) |
| **코드로 `ProtonScatter.new()`** | 🛑 **비어 있다.** 인스턴스가 **0개**가 되고 화면에 아무것도 안 나온다 |

자동으로 들어오는 넷 — `Create Inside (Random)`(amount 75) · `Randomize Transforms`
(rotation 20/360/20) · `Relax Position` · `Project On Colliders`.
**뿌리고 → 흩고 → 겹침을 풀고 → 지면에 붙이는** 순서다.

코드로 만들 때는 직접 넣는다. 최소 두 개면 된다:

| Modifier | 하는 일 |
|---|---|
| **Create Inside (Random)** | 영역 안에 무작위로 N개 생성 (`Amount` 로 개수) |
| **Randomize Transforms** | 회전·크기를 흩는다 (`Rotation` 을 `0, 360, 0` 으로) |

자주 함께 쓰는 것 — `Project On Geometry`(지면에 붙이기) · `Relax`(간격 고르게) ·
`Create Inside (Poisson)`(겹치지 않게).

코드로 만들 때는 이렇게 된다:

```gdscript
var create = load("res://addons/proton_scatter/src/modifiers/create_inside_random.gd").new()
create.amount = 40
var rand_t = load("res://addons/proton_scatter/src/modifiers/randomize_transforms.gd").new()
rand_t.rotation = Vector3(0, 360, 0)
var stack := ProtonScatterModifierStack.new()
var mods: Array[ScatterBaseModifier] = [create, rand_t]
stack.stack = mods
scatter.modifier_stack = stack
```

### 🛑 반드시 알아야 할 제약 넷 — 전부 실측으로 확인했다

**① 씬 트리에 콜리전 노드가 생기지 않는다**

`PhysicsServer3D` 에 직접 등록하므로 **`Debug ▸ Visible Collision Shapes` 를 켜도 안 보인다.**
소스 주석에 그렇게 적혀 있다("This also means you can't see these colliders").
확인 방법은 **실제로 걸어가서 부딪혀 보는 것**뿐이다.

**② 부모 노드의 `scale` 이 버려진다**

ProtonScatter 는 원본 씬에서
- `MeshInstance3D` 를 재귀로 찾아 **그 노드 자신의** transform 만 살리고
  (`scatter_util.gd` — `mesh_instances[0].duplicate()`)
- `CollisionShape3D` 를 재귀로 찾아 **그 노드 자신의** 로컬 transform 만 살린다
  (`get_collision_data()` — `body.remove_child(child)` 후 새 바디로 옮긴다)

**그 사이에 있는 부모 노드의 transform 은 전부 버려진다.** 루트도 `source.transform = Transform3D()`
로 초기화된다.

```
🛑 이렇게 하면 안 된다                ✅ 이렇게 한다
MMTree                                MMTree
└── Body (scale = 5)  ← 버려진다      ├── Visual (MeshInstance3D)  ← 크기를 메시에 넣는다
     └── MeshInstance3D                └── StaticBody3D
                                            └── CollisionShape3D
```

**③ `Source Scale Multiplier` 로 키우면 콜리전이 따라오지 않는다**

```bash
godot --headless --path . -s res://tests/protonscatter_collision_probe.gd
```

```
[A. keep_static_colliders = false]                    레이 12발 중  0발 명중  ✅ 콜리전 없음
[B. keep_static_colliders = true]                     레이 12발 중 12발 명중  ✅ 콜리전 있음
   콜리전 윗면 높이 ≈ 2.27 m
[C. B + source_scale_multiplier = 4 (콜리전 안 따라옴)] 레이 12발 중  0발 명중  ✅ 실측된 한계
실패 0 건
```

**크기는 원본 씬에서 정한다.** `Source Scale Multiplier` 는 보기에만 쓴다.

**④ collision layer 를 설정하지 않는다**

소스 전체에 `body_set_collision_layer` 호출이 **0회**다. 전부 **기본 레이어**로 들어간다.
레이어로 구분하는 프로젝트라면 이것이 곧바로 문제가 된다(§13).

---

## 9. GridMap + MeshLibrary 완전 안내

**애드온 없이 "노드 1개 + 콜리전 자동" 을 얻는 유일한 내장 경로다.**

핵심은 `MeshLibrary` 아이템이 **shape 을 들고 있는 것** 하나뿐이다. 그러면 `GridMap` 이
셀을 놓을 때마다 콜리전을 자동으로 만든다. 엔진 소스(`modules/gridmap/grid_map.cpp`
`_octant_update()`)가 같은 함수 안에서 `RS::multimesh_create()` 로 배칭하면서
`PhysicsServer3D::body_add_shape(g.static_body, …)` 로 콜리전을 만든다.

### MeshLibrary 를 만드는 절차

```
[준비 씬] 아이템마다 이 형식으로 만든다
  Tree (MeshInstance3D)        ← 이 노드 이름이 아이템 이름이 된다
    └ StaticBody3D             ← Mesh ▸ Create Collision Shape ▸ Static Body Child ▸ Capsule
        └ CollisionShape3D

[내보내기]  Scene ▸ Export As... ▸ MeshLibrary...   →  tree_library.tres

[쓰기]     GridMap 노드 추가 ▸ Inspector ▸ Mesh Library 에 .tres 지정
           ▸ 아래 팔레트에서 아이템을 고르고 뷰포트를 클릭해 배치
```

> 🛑 **이 형식만 인식된다.** 공식 문서 원문 — 아이템은 `MeshInstance3D` 여야 하고
> "Have up to one StaticBody3D child, for collision. The StaticBody3D should have one or more
> CollisionShape3D children." + "**Only this specific format is recognized.**"

코드로 만들 때는 이 한 줄이 전부다:

```gdscript
var lib := MeshLibrary.new()
lib.create_item(0)
lib.set_item_name(0, "tree")
lib.set_item_mesh(0, tree_mesh)
# [shape, transform] 순서로 넣는다 — 이것이 GridMap 콜리전의 전부다
lib.set_item_shapes(0, [capsule_shape, Transform3D(Basis(), Vector3(0, 1.6, 0))])
```

### 얻는 것과 잃는 것

| ✅ 얻는 것 | 🛑 잃는 것 |
|---|---|
| **콜리전 자동** — 아이템에 넣은 shape 이 셀마다 생긴다 | **격자에만** 놓인다 (`Cell Size` 간격) |
| 렌더링은 **octant 단위로 배칭**된다 | 회전은 **직교 24방향만** (자유 각도 불가) |
| 노드 1개 | 인스턴스별 **크기 무작위 불가** (`cell_scale` 은 전체 공통) |
| 내비게이션 메시도 아이템에 넣을 수 있다 | 아이템 종류가 많으면 배칭이 갈라진다 |

> **판단 기준 하나** — "격자에 놓여도 어색하지 않은가?"
> 건물·바닥·벽·울타리·가로등은 ✅. 자연스러운 숲은 ❌(격자 티가 난다).

---

## 10. 🛑 세 가지 함정 — 컬링·LOD·삼각형

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
§4 실측에서 Primitives 가 12,045 → 18,310 으로 **늘어난 것**이 그 증거다.

| 병목이 무엇인가 | MultiMesh 가 | |
|---|---|---|
| 드로우콜 (CPU) | ✅ **해결한다** | 500 → 1 |
| 삼각형 (GPU) | ❌ 그대로다 | 삼각형은 LOD·임포스터로 |
| 메모리 | ✅ 크게 줄인다 | 노드 500개 → 1개 |

---

## 11. 코드로 다룰 때

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

## 12. 직접 해 본다 — 실습 씬 넷

**[`scenes/demo/multimesh/`](../../../../scenes/demo/multimesh/)** 에 실습 씬이 있다.
에디터에서 열어 **F5** 로 실행한다. 방향키로 이동, 마우스 휠로 줌.
주황색 캡슐이 사람이고, 화면 왼쪽 위에 실시간 **드로우콜·삼각형·FPS** 가 뜬다.

| 순서 | 씬 | 무엇을 보나 |
|---|---|---|
| ① | `01_basics.tscn` | 화면 왼쪽 `MeshInstance3D` 300개 vs 오른쪽 `MultiMeshInstance3D` 1개 — **드로우콜 차이** |
| ② | `02_populate.tscn` | **Populate Surface 를 직접 눌러 본다.** 재료(Ground · SourceTree · 빈 MultiMeshInstance3D)만 들어 있다 |
| ③ | `03_collision.tscn` | 🛑 **핵심.** 왼쪽 MultiMesh(통과) vs 오른쪽 ProtonScatter(막힘) |
| ④ | `04_gridmap.tscn` | GridMap + MeshLibrary — 애드온 없이 콜리전 자동 |

> 🛑 **드로우콜은 F5 로 실행해서 봐야 한다.** 에디터 뷰포트의 숫자에는 기즈모·그리드가 섞인다.

**씬을 다시 굽고 싶으면**(초기 상태로 되돌리기):

```bash
godot --headless --path . -s res://tools/build_multimesh_demo.gd
```

### ③ 이 주장하는 것은 실측으로 확인했다

사람이 걸어가 보기 전에 캐릭터와 **똑같은 캡슐**로 숲을 가로지르는 직선을 훑었다
([`tests/autopilot_mm_walk_test.gd`](../../../../tests/autopilot_mm_walk_test.gd)):

```
[왼쪽 MultiMesh]       숲 중심까지 4.5 m 를 훑었으나 걸리는 것이 없었다   ✅ 통과
[오른쪽 ProtonScatter]  출발 0.2 m 지점에서 막혔다                       ✅ 막힘
실패 0 건
```

콜리전이 실제로 어디에 있는지 격자로 스캔해 아스키 지도로 찍는
[`tests/mm_collision_map.gd`](../../../../tests/mm_collision_map.gd) 도 있다.

---

## 13. 라리엔 3D 에서 이것이 걸리는 곳

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

특히 ProtonScatter 의 `Keep Static Colliders`(§8 제약 ④)는 **collision layer 를 설정하지 않아**
전부 기본 레이어로 들어가므로 **반드시** 이 광선에 걸린다.

> **순서가 있다** — 기물 콜리전을 켜기 **전에** `_pick_ground()` 의 `collision_mask` 를
> 지면 레이어로 잠근다. 레이어 번호를 정하는 것은 기획 결정이다.

또 하나 — ProtonScatter 의 "부모 `scale` 이 버려진다"(§8 제약 ②)는
[SSOT §3.2](../../game/references/SSOT.md)("정적 기물의 크기는 기물 씬 `Body` 노드의 `scale` 로
맞춘다")와 **정면으로 충돌한다.** 실제 맵에 쓰려면 이 점을 먼저 정리해야 한다.

---

## 참고

| | |
|---|---|
| 공식 | [Using MultiMeshInstance3D](https://docs.godotengine.org/en/stable/tutorials/3d/using_multi_mesh_instance.html) · [Optimization using MultiMeshes](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html) · [Using GridMaps](https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html) |
| 엔진 소스 | `editor/scene/3d/multimesh_editor_plugin.cpp` · `editor/scene/3d/mesh_instance_3d_editor_plugin.cpp` · `modules/gridmap/grid_map.cpp` |
| 제안 | [#10828 collision/raycast for MultiMeshInstance3D](https://github.com/godotengine/godot-proposals/issues/10828) (open) · [#4344 MultiColliderInstance](https://github.com/godotengine/godot-proposals/issues/4344) (closed) |
| 애드온 | [HungryProton/scatter (ProtonScatter)](https://github.com/HungryProton/scatter) — `keep_static_colliders` 는 `addons/proton_scatter/src/scatter.gd` |
| 실습 | [scenes/demo/multimesh/](../../../../scenes/demo/multimesh/) · 굽는 도구 [tools/build_multimesh_demo.gd](../../../../tools/build_multimesh_demo.gd) |
| 이어서 | [lowend-culling-lod.md](lowend-culling-lod.md) 드로우콜 예산 · [lowend-3gb-60fps.md](lowend-3gb-60fps.md) §5.3 메모리 |
