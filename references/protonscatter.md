# ProtonScatter — 처음부터 끝까지 따라 하기

> **이 문서로 오는 상황** — 나무·바위·풀을 **자유롭게 흩뿌리면서 충돌도 필요할 때**.
> 설치부터 `Keep Static Colliders` 로 콜리전을 얻기까지 **클릭 순서 그대로** 적었다.
> MultiMesh 자체의 원리와 다른 해법은 [multimesh-3d.md](multimesh-3d.md) 를 본다.

기준 — Godot **4.7.2.stable** · ProtonScatter **4.2.0**
(최신 커밋 2026-07-26 *"fix compatibility issue with 4.7"*).
값은 전부 애드온 소스와 기본 프리셋에서 직접 읽은 것이고, 물리 판정은
[`tests/protonscatter_collision_probe.gd`](../../../../tests/protonscatter_collision_probe.gd) 로 쟀다.

---

## 목차

- [Step 0. 시작 전에 있어야 하는 것](#step-0-시작-전에-있어야-하는-것)
- [Step 1. 설치](#step-1-설치)
- [Step 2. 플러그인 활성화](#step-2-플러그인-활성화)
- [Step 3. 노드 3개를 만든다](#step-3-노드-3개를-만든다)
- [Step 4. 뿌릴 영역을 정한다 — ScatterShape](#step-4-뿌릴-영역을-정한다--scattershape)
- [Step 5. 뿌릴 대상을 지정한다 — ScatterItem](#step-5-뿌릴-대상을-지정한다--scatteritem)
- [Step 6. Set Amount — 개수](#step-6-set-amount--개수)
- [Step 7. Set Rotation — 방향과 크기 흩기](#step-7-set-rotation--방향과-크기-흩기)
- [Step 8. Set Object Boundaries — 겹침 풀기](#step-8-set-object-boundaries--겹침-풀기)
- [Step 9. 🛑 Set Collision — 이 문서의 핵심](#step-9--set-collision--이-문서의-핵심)
- [Step 10. 확인한다](#step-10-확인한다)
- [부록 A. Modifier 전체 목록](#부록-a-modifier-전체-목록)
- [부록 B. Performance 섹션 전체](#부록-b-performance-섹션-전체)
- [부록 C. 🛑 막히는 곳 모음](#부록-c--막히는-곳-모음)
- [부록 D. 코드로 만들 때](#부록-d-코드로-만들-때)

---

## Step 0. 시작 전에 있어야 하는 것

**ProtonScatter 는 "무엇을" 과 "어디에" 를 스스로 만들지 않는다.** 씬에 이 둘이 먼저 있어야 한다.

| 있어야 하는 것 | 왜 |
|---|---|
| **뿌릴 대상** — `MeshInstance3D` 또는 씬 파일 | Step 5 에서 지정한다 |
| **바닥** — `MeshInstance3D` + `StaticBody3D` + `CollisionShape3D` | Step 8 의 `Project On Colliders` 가 **레이캐스트로 지면을 찾는다.** 콜리전이 없으면 지면에 붙지 못한다 |

> 🛑 **바닥에 콜리전이 없으면** 나무가 지면에 붙지 않고 영역(`ScatterShape`) 안에 공중부양한다.
> 바닥 `MeshInstance3D` 를 선택하고 **툴바 `Mesh ▸ Create Collision Shape ▸ Static Body Child ▸ Trimesh`** 로 먼저 만들어 둔다.

**충돌까지 원한다면(Step 9) 뿌릴 대상에도 콜리전이 있어야 한다.**

```
Tree (MeshInstance3D)         ← 이것을 뿌린다
  └ StaticBody3D              ← Mesh ▸ Create Collision Shape ▸ Static Body Child ▸ Capsule
      └ CollisionShape3D      ← 이 shape 이 인스턴스마다 복제된다
```

---

## Step 1. 설치

두 경로 중 하나를 고른다.

### A. AssetLib (권장 — 클릭만으로)

```
에디터 상단 ▸ AssetLib 탭 ▸ "ProtonScatter" 검색 ▸ Download ▸ Install
```

### B. 저장소에서 직접 (버전 고정이 필요할 때)

```bash
git clone --depth 1 https://github.com/HungryProton/scatter.git
# scatter/addons/proton_scatter/ 를 프로젝트의 addons/ 로 복사한다
```

> **용량 주의** — 저장소의 `addons/proton_scatter/` 는 **13MB** 이고 그중 **11MB 가 `demos/`** 다.
> 저장소에 넣을 거라면 `demos/` 와 `tests/` 를 빼면 **1.5MB** 로 줄어든다.
>
> 🛑 **단 `demos/` 를 빼면** 기본 프리셋의 `ScatterItem` 이
> `demos/assets/brick.tscn` 을 가리켜 콘솔에 `Cannot open file` 이 한 번 뜬다.
> **Step 5 에서 Path 를 자기 모델로 바꾸면 사라진다.**

---

## Step 2. 플러그인 활성화

```
Project ▸ Project Settings…  ▸  Plugins 탭  ▸  ProtonScatter 의 Enabled 를 ✅
```

활성화되면 `ProtonScatter` · `ProtonScatterItem` · `ProtonScatterShape` 노드를
**Create New Node** 목록에서 검색할 수 있게 된다. 안 보이면 활성화가 안 된 것이다.

---

## Step 3. 노드 3개를 만든다

**Create New Node 에서 "scatter" 로 검색해 세 개를 만든다.** 부모-자식 관계가 정해져 있다.

```
ProtonScatter                 ← 루트. 설정과 Modifier Stack 이 여기 있다
├── ProtonScatterItem         ← 무엇을 뿌릴 것인가
└── ProtonScatterShape        ← 어디에 뿌릴 것인가
```

| | |
|---|---|
| `ProtonScatterItem` · `ProtonScatterShape` 는 | 반드시 **`ProtonScatter` 의 자식**이어야 한다 |
| 여러 종류를 섞으려면 | `ProtonScatterItem` 을 **여러 개** 둔다 (각 `Proportion` 으로 비율 조절) |
| 영역을 여러 개 쓰려면 | `ProtonScatterShape` 도 **여러 개** 둘 수 있다 |

### ✅ 인스펙터를 여는 순간 Modifier 4개가 자동으로 들어온다

`ProtonScatter` 를 선택해 인스펙터를 열면, **기본 프리셋이 자동 적용된다.**
(근거 — `src/stack/inspector_plugin/ui/stack_panel.gd:73-76` 이 `just_created` 인 스택에
`presets/scatter_default.tscn` 을 적용한다.)

**들어오는 값을 그대로 읽으면 이렇다** (`tests/protonscatter_preset_probe.gd` 실측):

```
modifier 4개
  ▸ Create Inside (Random)   [Create]   amount = 75
  ▸ Randomize Transforms     [Edit]     position (0.15, 0.15, 0.15)
                                        rotation (20.0, 360.0, 20.0)
                                        scale    (0.1, 0.1, 0.1)
  ▸ Relax Position           [Edit]     iterations 3 · offset_step 0.2
                                        consecutive_step_multiplier 0.75
  ▸ Project On Colliders     [Edit]     ray_direction (0, -1, 0) · ray_length 5.0
                                        ray_offset 5.0 · remove_points_on_miss false
                                        max_slope 90.0 · collision_mask 1
```

**이 넷이 Step 6~8 에서 만질 대상 전부다.** 순서에도 뜻이 있다 —
**뿌리고(Create) → 흩고(Randomize) → 겹침을 풀고(Relax) → 지면에 붙인다(Project).**

> 🛑 **코드로 `ProtonScatter.new()` 를 하면 스택이 비어 있다.** 자동 적용은 **에디터 인스펙터
> 전용**이다. 코드 경로는 [부록 D](#부록-d-코드로-만들-때) 를 본다.

---

## Step 4. 뿌릴 영역을 정한다 — ScatterShape

`ProtonScatterShape` 를 선택하면 인스펙터에 **`Shape`** 칸이 `<empty>` 로 있다.
클릭해 **New** 에서 모양을 고른다.

| 고를 수 있는 것 | 무엇 | 크기 프로퍼티 |
|---|---|---|
| **ProtonScatterBoxShape** | 상자 (가장 흔하다) | `size` — `Vector3` |
| **ProtonScatterSphereShape** | 구 | `radius` |
| **ProtonScatterPathShape** | 곡선을 따라 | `Curve3D` |
| ProtonScatterBaseShape | 다른 모양의 부모 클래스 | (직접 쓰지 않는다) |

**뷰포트에 노란 상자가 나타난다.** 이 안쪽이 뿌려질 범위다.
`ProtonScatterShape` 노드를 옮기면 범위도 함께 움직인다.

| 알아 둘 것 | |
|---|---|
| **`Negative` 를 켜면** | 그 영역을 **빼낸다** (구멍을 낸다). 길·건물 자리를 비울 때 |
| `size.y` | 높이도 범위에 들어간다. `Project On Colliders` 가 지면에 붙여 주므로 **2 정도면 충분** |

---

## Step 5. 뿌릴 대상을 지정한다 — ScatterItem

`ProtonScatterItem` 을 선택하고 인스펙터에서 **두 칸**을 정한다.

### ① Source — 어디서 가져오나

| 값 | 뜻 | `Path` 에 넣는 것 |
|---|---|---|
| **From current scene** | **지금 이 씬 안의 노드** | 씬 트리의 노드 (`Assign…` 버튼으로 고른다) |
| From disk | 다른 씬 파일 | `res://…/tree.tscn` |

**처음이라면 `From current scene` 이 쉽다.** 씬에 이미 놓아 둔 나무를 그대로 가리키면 된다.

### ② Path — 무엇을 가져오나

`Path` 줄의 **`Assign…`** 을 누르면 **Select a Node** 창이 뜬다.
씬 트리에서 **뿌릴 대상**을 고른다.

```
Node3D
├── Ground
│   └── StaticBody3D
│       └── CollisionShape3D
├── CommonTree_12
│   └── CommonTree_1          ← 이것을 고른다 (Type: MeshInstance3D)
│       └── StaticBody3D
│           └── CollisionShape3D
└── ProtonScatter
    ├── ProtonScatterItem     ← 지금 여기를 설정 중
    └── ProtonScatterShape
```

> 🛑 **콜리전(Step 9)까지 원한다면 고른 노드 아래에 `StaticBody3D ▸ CollisionShape3D` 가
> 있어야 한다.** ProtonScatter 는 그 shape 을 복제한다. 없으면 메시만 뿌려진다.

**고르는 순간 뷰포트에 인스턴스가 나타난다.** 안 나타나면 [부록 C](#부록-c--막히는-곳-모음) 를 본다.

### 그 밖에 알아 둘 것

| 프로퍼티 | |
|---|---|
| `Proportion` | 여러 `ScatterItem` 을 섞을 때의 **비율** (기본 100) |
| `Source Scale Multiplier` | 🛑 **크기를 여기서 키우면 콜리전이 따라오지 않는다**(Step 9 제약). 크기는 원본에서 정한다 |
| `Override Material` | 뿌린 것 전체의 머티리얼을 한 번에 바꾼다 |

---

## Step 6. Set Amount — 개수

`ProtonScatter` 루트를 선택하고 인스펙터 아래쪽 **Modifier Stack** 을 본다.

```
Modifier Stack
  + Add modifier
  ▸ Create Inside (Random)    ← 이것을 클릭해 펼친다
  ▸ Randomize Transforms
  ▸ Relax Position
  ▸ Project On Colliders
```

**`Create Inside (Random)` 의 `▸` 를 눌러 펼치고 `Amount` 를 정한다.**
기본 **75**. 값을 바꾸면 뷰포트가 **즉시** 다시 뿌려진다.

| 개수를 정하는 다른 방법 | |
|---|---|
| **Create Inside (Poisson)** | 개수 대신 **`radius`(최소 간격)** 로 정한다. **겹치지 않는 배치**가 필요하면 이쪽 |
| **Create Inside (Grid)** | 격자로 규칙적으로 |
| **Create Along Edge (…)** | 영역의 **가장자리**를 따라 (울타리·가로수) |

> **좌표계** — modifier 오른쪽 아래 `Local / Global` 토글이 있다.
> `Local` 이면 `ProtonScatter` 노드를 옮길 때 배치가 따라온다.

---

## Step 7. Set Rotation — 방향과 크기 흩기

**`Randomize Transforms`** 를 펼친다. 세 줄이 있고, 각각 **무작위 폭**이다(값이 0이면 흩지 않는다).

| 항목 | 기본값 | 뜻 |
|---|---|---|
| **Position** | `(0.15, 0.15, 0.15)` | 원래 자리에서 ±0.15m 씩 흔든다 |
| **Rotation** | `(20.0, 360.0, 20.0)` | X ±20° · **Y 360°(완전 무작위)** · Z ±20° |
| **Scale** | `(0.1, 0.1, 0.1)` | 크기를 ±10% 흔든다 |

**`Rotation` 의 Y 가 360 인 것이 핵심이다** — 위 축 기준으로 완전히 무작위로 돌려
**같은 나무를 복제한 티를 지운다.** X·Z 의 20° 는 살짝 기울여 자연스럽게 만드는 값이다.

| 하고 싶은 것 | 어떻게 |
|---|---|
| 나무가 **똑바로만** 서게 | `Rotation` 을 **`(0, 360, 0)`** 으로. X·Z 를 0 으로 만든다 |
| 바위처럼 **아무렇게나** | `(360, 360, 360)` |
| 크기를 더 다양하게 | `Scale` 을 `(0.3, 0.3, 0.3)` 처럼 올린다 |

> 🛑 **회전만 필요하면 `Randomize Rotation` 이라는 별도 modifier 도 있다.**
> 다만 그쪽 기본값은 **`(360, 360, 360)`** 이라 그대로 쓰면 **나무가 눕는다.**
> 반드시 `(0, 360, 0)` 으로 고쳐서 쓴다.

---

## Step 8. Set Object Boundaries — 겹침 풀기

**`Relax Position`** 을 펼친다. 무작위로 뿌리면 나무끼리 겹치는데,
이 modifier 가 **서로 밀어내며 간격을 고르게** 만든다.

| 항목 | 기본값 | 뜻 |
|---|---|---|
| **Iterations** | `3` | 몇 번 반복해 밀어낼지. 올릴수록 고르지만 느리다 |
| **Offset Step** | `0.2` | 한 번에 밀어내는 거리(m) |
| **Consecutive Step Multiplier** | `0.75` | 반복할수록 밀어내는 양을 줄이는 비율 |
| **Use Computeshader** | ✅ | GPU 로 계산. 켜 두는 편이 빠르다 |

**나무가 서로 파고들면 `Iterations` 를 올리거나 `Offset Step` 을 키운다.**

> **겹침을 아예 만들지 않으려면** Step 6 에서 `Create Inside (Poisson)` 을 쓰는 편이
> 더 확실하다. `Relax Position` 은 이미 뿌려진 것을 나중에 미는 방식이다.

### 함께 보는 것 — Project On Colliders

**`Project On Colliders`** 는 인스턴스를 **아래로 레이캐스트해 지면에 붙인다.**

| 항목 | 기본값 | 뜻 |
|---|---|---|
| `Ray Direction` | `(0, -1, 0)` | 아래로 쏜다 |
| `Ray Length` | `5.0` | 5m 까지 찾는다 |
| `Ray Offset` | `5.0` | 5m 위에서 쏘기 시작한다 |
| **`Remove Points On Miss`** | **`false`** | 못 맞혀도 지우지 않는다 |
| `Collision Mask` | `1` | **레이어 1** 만 찾는다 |

🛑 **바닥 콜리전이 레이어 1 에 없으면 지면에 붙지 않는다.** 나무가 공중에 뜨면 여기를 본다.
`Ray Length`·`Ray Offset` 이 5m 이므로 **높낮이 차가 5m 를 넘는 지형**에서도 놓친다.

> **소스 기본값은 `Remove Points On Miss = true` 지만 프리셋이 `false` 로 덮는다.**
> 직접 modifier 를 추가했을 때는 `true` 라서, **바닥을 못 맞히면 인스턴스가 전부 사라진다.**

---

## Step 9. 🛑 Set Collision — 이 문서의 핵심

**여기가 다른 방법과 갈리는 지점이다.** `ProtonScatter` 루트를 선택하고
인스펙터의 **`Performance`** 그룹을 펼친다.

```
▾ Performance
    Render Mode              Use Instancing        ← ① 이것이어야 한다
    Keep Static Colliders    ✅ On                 ← ② 이 체크 하나가 전부다
    Force Rebuild On Load    ✅ On
    Enable Updates In Game   ☐  Off
    Use Chunks               ✅ On
    Chunk Dimensions         (15, 15, 15)
```

| 순서 | 무엇을 | 왜 |
|---|---|---|
| ① | **Render Mode = `Use Instancing`** | MultiMesh 로 그린다 = 드로우콜 1 |
| ② | **Keep Static Colliders ✅** | 인스턴스마다 물리 shape 을 등록한다 |

### 왜 이것만으로 되는가

**MultiMesh 인스턴스를 채우는 바로 그 루프가, 같은 `Transform3D` 로 물리 서버에 shape 을 등록한다.**

```gdscript
# scatter.gd:448-450
t = item.process_transform(transforms.list[offset + i])
mmi.multimesh.set_instance_transform(i, t)   # 렌더
_create_collision(static_body, t)            # 물리 — 같은 t

# scatter.gd:609-611 — 끄는 것은 Create Copies(1) 뿐이다
func _create_collision(body: StaticBody3D, t: Transform3D) -> void:
	if not keep_static_colliders or render_mode == 1:
		return
```

지원 shape — Sphere · Box · **Capsule** · Cylinder · ConcavePolygon · ConvexPolygon ·
HeightMap · SeparationRay.

### 실측

```bash
godot --headless --path . -s res://tests/protonscatter_collision_probe.gd
```

```
[A. keep_static_colliders = false]            레이 12발 중  0발 명중  ✅ 콜리전 없음
[B. keep_static_colliders = true]             레이 12발 중 12발 명중  ✅ 콜리전 있음
   콜리전 윗면 높이 ≈ 2.27 m
[C. B + source_scale_multiplier = 4]          레이 12발 중  0발 명중  ✅ 실측된 한계
실패 0 건
```

### 🛑 제약 넷 — 전부 실측·소스로 확인했다

**① 씬 트리에 콜리전 노드가 생기지 않는다**
`PhysicsServer3D` 에 직접 등록하므로 **`Debug ▸ Visible Collision Shapes` 를 켜도 안 보인다.**
소스 주석에 그렇게 적혀 있다. 확인은 **실제로 걸어가 부딪혀 보는 것**뿐이다.

**② 부모 노드의 `scale` 이 버려진다**
`MeshInstance3D` 와 `CollisionShape3D` 를 재귀로 찾아 **그 노드 자신의** transform 만 살린다.
사이에 낀 부모의 transform 은 전부 버려지고, 루트도 초기화된다.
→ **크기는 메시와 shape 자체에 넣는다. 중간 노드에 `scale` 을 주지 않는다.**

**③ `Source Scale Multiplier` 로 키우면 콜리전이 따라오지 않는다** (위 실측 C)

**④ collision layer 를 설정하지 않는다**
소스 전체에 `body_set_collision_layer` 호출이 **0회**. 전부 **기본 레이어**로 들어간다.
레이어로 구분하는 프로젝트라면 이것이 곧바로 문제가 된다.

---

## Step 10. 확인한다

| 무엇을 | 어떻게 |
|---|---|
| **뿌려졌나** | 뷰포트에 보이는가. `ProtonScatter` 아래 `ScatterOutput` 이 생겼는가 |
| **드로우콜이 1인가** | **F5 로 실행**해 모니터를 본다. 에디터 뷰포트 숫자에는 기즈모가 섞인다 |
| **충돌하나** | 🛑 **디버그 뷰로는 안 보인다**(제약 ①). **캐릭터로 직접 부딪혀 본다** |

### 자동으로 확인하는 법

캐릭터와 **똑같은 캡슐**로 숲을 가로지르는 직선을 훑으면 사람이 걷지 않아도 판정할 수 있다
([`tests/autopilot_mm_walk_test.gd`](../../../../tests/autopilot_mm_walk_test.gd)):

```
[왼쪽 MultiMesh]       숲 중심까지 4.5 m 를 훑었으나 걸리는 것이 없었다   ✅ 통과
[오른쪽 ProtonScatter]  출발 0.2 m 지점에서 막혔다                       ✅ 막힘
실패 0 건
```

콜리전이 실제로 **어디에** 있는지는
[`tests/mm_collision_map.gd`](../../../../tests/mm_collision_map.gd) 가 아스키 지도로 찍어 준다.

---

## 부록 A. Modifier 전체 목록

`+ Add modifier` 를 누르면 카테고리별로 나온다.

| 카테고리 | Modifier | 하는 일 |
|---|---|---|
| **Create** | **Create Inside (Random)** | 영역 안 무작위 N개 ★ 기본 |
| | **Create Inside (Poisson)** | **겹치지 않게** 최소 간격으로 |
| | Create Inside (Grid) | 격자로 규칙적으로 |
| | Create Along Edge (Random / Even / Continuous) | 가장자리를 따라 — 울타리·가로수 |
| | Add Single Item | 하나만 콕 집어 |
| | Array | 일정 간격으로 줄지어 |
| **Edit** | **Randomize Transforms** | 위치·회전·크기를 한꺼번에 흩는다 ★ 기본 |
| | Randomize Rotation | 회전만 (🛑 기본값 360,360,360) |
| | **Relax Position** | 겹침을 밀어내 간격을 고르게 ★ 기본 |
| | **Project On Colliders** | 아래로 레이캐스트해 지면에 붙인다 ★ 기본 |
| | Look At | 특정 방향을 보게 |
| | Clusterize | 무리 지어 뭉치게 |
| | Snap Transforms | 격자에 맞춰 스냅 |
| **Offset** | Edit Position / Rotation / Scale / Transform | 전부에 같은 값을 더한다 |
| **Remove** | Remove Outside | 영역 밖을 지운다 |
| | Remove Random | 무작위로 솎아낸다 |
| **Debug** | Debug Modifier | 중간 결과를 본다 |

**순서가 중요하다.** 위에서 아래로 차례로 적용된다 —
`Create` 로 만들고, `Edit`·`Offset` 으로 다듬고, `Remove` 로 솎아낸다.
드래그로 순서를 바꿀 수 있다.

---

## 부록 B. Performance 섹션 전체

| 프로퍼티 | 기본값 | 뜻 |
|---|---|---|
| **Render Mode** | `Use Instancing` (0) | **0** MultiMesh · **1** 노드 복제 · **2** GPU 파티클 |
| **Keep Static Colliders** | `false` | 🛑 **콜리전. 켜야 한다** |
| **Use Chunks** | `true` | 결과를 **청크로 나눠** 만든다 |
| **Chunk Dimensions** | `(15, 15, 15)` | 청크 한 변 15m |
| **Force Rebuild On Load** | `true` | 씬을 열 때 다시 뿌린다. 끄면 **캐시된 배치를 복원**해 로딩이 빠르다 |
| **Enable Updates In Game** | `false` | 게임 실행 중 재생성. **꺼 두는 것이 맞다** |

> **`Use Chunks` 는 컬링에 직결된다.** MultiMesh 는 인스턴스를 하나씩 잘라내지 못해
> "맵 전체를 하나로 묶으면 전부 그린다" 는 문제가 있는데
> ([multimesh-3d.md §10](multimesh-3d.md)), ProtonScatter 는 **청크로 나눠** 그 문제를 줄인다.
> 라리엔 3D 의 청크는 **64m**(`scripts/world_metrics.gd:74`)이므로 맞춰 쓸지 판단이 필요하다.

| Render Mode 별 차이 | 렌더 | 콜리전 |
|---|---|---|
| **Use Instancing** (0) | MultiMesh · 드로우콜 1 | `Keep Static Colliders` 로 **물리 서버에 직접** |
| **Create Copies** (1) | 노드를 진짜로 N개 복제 | 🛑 `Keep Static Colliders` 가 **무시된다**(복제된 노드가 콜리전을 이미 갖는다) |
| **Use Particles** (2) | GPU 파티클 | `Keep Static Colliders` 동작 |

---

## 부록 C. 🛑 막히는 곳 모음

| 증상 | 원인과 해결 |
|---|---|
| **Create New Node 에 ProtonScatter 가 없다** | Step 2 의 플러그인 활성화를 안 했다 |
| **아무것도 안 뿌려진다** | ① `ScatterItem` 의 `Path` 가 비었다 ② `ScatterShape` 의 `Shape` 이 `<empty>` 다 ③ `Modifier Stack` 이 비었다(코드로 만든 경우) |
| **콘솔에 `Cannot open file … demos/assets/brick.tscn`** | 애드온을 `demos/` 없이 벤더링했다. **Step 5 에서 `Path` 를 바꾸면 사라진다** |
| **나무가 공중에 뜬다** | `Project On Colliders` 가 지면을 못 찾는다 → 바닥에 **콜리전**을 주고, `Collision Mask` 와 `Ray Length`(기본 5m)를 확인 |
| **나무가 눕거나 뒤집힌다** | `Randomize Transforms ▸ Rotation` 의 X·Z 를 **0** 으로. `Randomize Rotation` 을 썼다면 `(0, 360, 0)` |
| **나무끼리 겹친다** | `Relax Position ▸ Iterations` 를 올리거나 `Create Inside (Poisson)` 으로 바꾼다 |
| **충돌이 안 생긴다** | ① `Keep Static Colliders` ✅ ② `Render Mode = Use Instancing` ③ **원본에 `StaticBody3D ▸ CollisionShape3D` 가 있는가** |
| **콜리전이 안 보인다** | 🛑 **정상이다.** 노드를 만들지 않으므로 디버그 뷰에 안 나온다. 직접 부딪혀 확인한다 |
| **콜리전 크기가 메시와 다르다** | 부모 노드의 `scale` 이 버려졌다(제약 ②). 크기를 메시·shape 자체에 넣는다 |
| **게임 실행 중에 배치가 바뀐다** | `Enable Updates In Game` 을 끈다 |

---

## 부록 D. 코드로 만들 때

🛑 **`ProtonScatter.new()` 로 만들면 Modifier Stack 이 비어 있다.**
에디터의 자동 프리셋 적용은 인스펙터 UI 가 하는 일이라 코드 경로에는 없다.
**직접 채워야 인스턴스가 생긴다.**

```gdscript
const M := "res://addons/proton_scatter/src/modifiers/"

var scatter := ProtonScatter.new()
scatter.render_mode = 0                  # 0 = Use Instancing (MultiMesh)
scatter.keep_static_colliders = true     # ★ 콜리전
add_child(scatter)

# 무엇을 뿌릴까
var item := ProtonScatterItem.new()
item.source = 1                          # 0 = From current scene · 1 = From disk
scatter.add_child(item)
item.path = "res://scenes/demo/multimesh/mm_tree.tscn"   # 🛑 프로퍼티 이름은 path 다

# 어디에 뿌릴까
var shape := ProtonScatterShape.new()
var box := ProtonScatterBoxShape.new()
box.size = Vector3(16, 2, 16)
shape.shape = box
scatter.add_child(shape)

# 🛑 이것이 없으면 인스턴스가 0개다
var create = load(M + "create_inside_random.gd").new()
create.amount = 40
var rand_t = load(M + "randomize_transforms.gd").new()
rand_t.rotation = Vector3(0, 360, 0)     # 위 축만 돌린다
var stack := ProtonScatterModifierStack.new()
var mods: Array[ScatterBaseModifier] = [create, rand_t]
stack.stack = mods
scatter.modifier_stack = stack

scatter.rebuild(true)
```

| 코드 경로에서 다른 것 | |
|---|---|
| Modifier Stack | **비어 있다.** 직접 채운다 |
| `Project On Colliders` 의 `remove_points_on_miss` | 소스 기본값 **`true`** (프리셋은 `false`) → 바닥을 못 맞히면 **전부 사라진다** |
| `Randomize Rotation` 의 `rotation` | 소스 기본값 **`(360, 360, 360)`** → 그대로 쓰면 눕는다 |

---

## 언제 ProtonScatter 를 쓰고, 언제 쓰지 않나

| 상황 | 답 |
|---|---|
| **자유 배치 + 충돌**이 둘 다 필요 | ✅ **ProtonScatter** — 이것 말고 클릭으로 되는 방법이 없다 |
| 격자에 놓아도 되는 건물·울타리 | `GridMap` + `MeshLibrary` (**내장**, 콜리전 자동) |
| 충돌이 필요 없는 풀·꽃·자갈 | `MultiMeshInstance3D` + `Populate Surface` (**내장**) |
| 부딪힐 나무가 수십 그루뿐 | 그냥 **개별 노드**. 가장 단순하다 |

> 🛑 **라리엔 3D 에서는** 이동 차단의 권위가 **서버 walkable** 이라
> 일반 나무·바위에 클라 콜리전을 주지 않는다. 그리고
> `player.gd` 의 `_pick_ground()` 가 `collision_mask` 를 잠그지 않아,
> 기물 콜리전을 켜면 **나무를 클릭했을 때 나무 표면이 이동 목표**가 된다.
> → [multimesh-3d.md §13](multimesh-3d.md)

---

## 참고

| | |
|---|---|
| 애드온 | [HungryProton/scatter](https://github.com/HungryProton/scatter) · 미러 [Codeberg](https://codeberg.org/hungryproton/proton_scatter) |
| 소스 | `addons/proton_scatter/src/scatter.gd` · `src/common/scatter_util.gd` · `src/stack/inspector_plugin/ui/stack_panel.gd` |
| 기본 프리셋 | `addons/proton_scatter/presets/scatter_default.tscn` |
| 실측 | [protonscatter_collision_probe.gd](../../../../tests/protonscatter_collision_probe.gd) · [protonscatter_preset_probe.gd](../../../../tests/protonscatter_preset_probe.gd) · [autopilot_mm_walk_test.gd](../../../../tests/autopilot_mm_walk_test.gd) |
| 이어서 | [multimesh-3d.md](multimesh-3d.md) — MultiMesh 원리와 콜리전 여섯 방법 |
