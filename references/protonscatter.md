# ProtonScatter — 처음부터 끝까지 따라 하기

> **이 문서로 오는 상황** — 나무·바위·풀을 **자유롭게 흩뿌리면서 충돌도 필요할 때**.
> 설치부터 `Keep Static Colliders` 로 콜리전을 얻기까지 **클릭 순서 그대로** 적었다(Step 0~10).
> **뿌린 것을 걸러내고 청크 경계 안에 가두면서 밀도를 지키는 법**은 Step 11~19 에 있다 —
> 모디파이어 스택이 도는 원리, `Remove Outside` 와 `Remove Outside (Model)`, `Footprint Multiplier`,
> `Keep Partial Overlap`, `Create Inside (Random)` 의 `Amount` 를 소스와 실측으로 설명한다.
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
- [Step 11. 모디파이어 스택은 어떻게 도는가](#step-11-모디파이어-스택은-어떻게-도는가)
- [Step 12. Remove Outside — 원점 한 점만 본다](#step-12-remove-outside--원점-한-점만-본다)
- [Step 13. Remove Outside (Model) — 모델 크기로 거른다](#step-13-remove-outside-model--모델-크기로-거른다)
- [Step 14. Footprint Multiplier — 발자국 배율](#step-14-footprint-multiplier--발자국-배율)
- [Step 15. Keep Partial Overlap — 모양을 살리는 스위치](#step-15-keep-partial-overlap--모양을-살리는-스위치)
- [Step 16. Amount 로 밀도를 되살린다](#step-16-amount-로-밀도를-되살린다)
- [Step 17. 🛑 걸러내기 함정 모음](#step-17--걸러내기-함정-모음)
- [Step 18. 확인하는 법](#step-18-확인하는-법)
- [Step 19. 목표별 설정표](#step-19-목표별-설정표)
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

## Step 11. 모디파이어 스택은 어떻게 도는가

> Step 11~19 는 **뿌린 것을 걸러내는 법**이다. 기준은 같다 — Godot 4.7.2 · ProtonScatter 4.2.0(`2ced25f`) ·
> 실측 2026-09-17 라리엔 3D 청크 씬. 줄 번호는 `addons/proton_scatter/src/` 아래 파일 기준이다.

**모디파이어는 "목록 하나"를 위에서 아래로 차례로 고친다.** 인스펙터 카드가 따로따로 보여도 실제로는 한 줄 파이프라인이다.

```
rebuild
  └ modifier_stack.start_update(scatter, domain)        # scatter.gd:395(스레드 없이) · :412(스레드)
        transforms = 빈 목록
        for modifier in stack:                          # stack/modifier_stack.gd:23-24
            await modifier.process_transforms(transforms, domain, global_seed)
  └ _on_transforms_ready(transforms)                    # scatter.gd:745
        목록이 비었으면 → clear_output() 하고 끝       # :762 — build_completed 를 보내지 않는다
        아니면 → 아이템마다 몫을 나눠 MultiMesh 를 채운다
        build_completed.emit()                          # :784
```

### 이 구조에서 바로 나오는 사실 다섯

| 사실 | 소스 | 그래서 |
|---|---|---|
| **Create 만 목록을 늘리고, Remove 는 줄이기만 한다** | `modifiers/create_inside_random.gd:56` · `remove_*.gd` | 지운 자리는 다시 채워지지 않는다. 밀도를 지키려면 `Amount` 를 올린다([Step 16](#step-16-amount-로-밀도를-되살린다)) |
| **아이템 배정은 목록 순서로 이어 붙인 구간이다** | `scatter.gd:436` `count = round(proportion / 합계 × 전체 수)` | 목록 가운데 하나를 지우면 **뒤 아이템들의 자리가 한 칸씩 밀린다** |
| **결과가 0개면 `build_completed` 가 오지 않는다** | `scatter.gd:762-765` | 화면에 아무것도 없고, 이 신호를 기다리는 코드는 멈춘다([Step 17](#step-17--걸러내기-함정-모음)) |
| **꺼 둔(`enabled = false`) 모디파이어도 게임에서는 돈다** | `modifiers/base_modifier.gd:52-61` — `enabled` 검사가 `Engine.is_editor_hint()` 안에만 있다 | 에디터에서는 꺼져 보이는데 실행하면 켜져 있다(Step 17 실측) |
| **같은 스택 리소스를 두 Scatter 가 쓰면 두 번째는 복사본을 받는다** | `scatter.gd:147-148` | 한쪽을 고쳐도 다른 쪽은 안 바뀐다. 연결해 쓰려면 `Proxy` 모디파이어 |

비율 배분 예 — 아이템 A(`Proportion` 15) · B(80) 에 목록 35개면
A = round(15/95×35) = **6개(0~5번)**, B = round(80/95×35) = **29개(6~34번)** 다. 어느 모델이 어느 자리에 가는지는
자리 자체가 아니라 **목록에서 몇 번째인가**로 정해진다.

### 영역 "안" 판정은 모양마다 다르다

Remove 계열과 Create Inside 는 모두 `domain.is_point_inside()` 로 묻는다. 그런데 **모양마다 재는 방법이 다르다.**

| 모양 | 판정 | 높이(Y) | 소스 |
|---|---|---|---|
| **BoxShape** | 상자의 3D AABB `has_point` | 🛑 **본다** — `size.y` 밖이면 밖이다 | `shapes/box_shape.gd:21-23` |
| **SphereShape** | 중심까지 3D 거리 < 반지름 | 본다 | `shapes/sphere_shape.gd:21-23` |
| **PathShape** (`closed` 켬 · 기본) | 곡선을 XZ 다각형으로 보고 점이 안에 있나 | **무시** | `shapes/path_shape.gd:36-52` |
| PathShape (`thickness` > 0) | 곡선에서 `thickness/2` 안이면 안 (띠) | 3D 거리 | `shapes/path_shape.gd:45-48` |
| 여러 모양 | **negative 를 먼저** 본다 — 하나라도 안이면 밖. 그다음 positive 하나라도 안이면 안 | | `common/domain.gd:80-89` |

> 🛑 **BoxShape 로 거를 때는 `Project On Colliders` 보다 앞에 둔다.** Project 가 높이를 지면으로 옮긴 뒤에
> 상자(특히 `size.y` 가 작은 상자)로 판정하면 **높이 때문에 밖**이 된다. PathShape 는 높이를 안 보므로 상관없다.

### Create Inside (Random) 의 `Amount` 가 정확히 하는 일

```gdscript
# modifiers/create_inside_random.gd:53-73 (요약)
var max_retries = amount * 10
while new_transforms.size() != amount:
    pos = 경계 상자 안 무작위 점
    if restrict_height: pos.y = 경계 상자 중심 높이
    if domain.is_point_inside(pos): 담는다
    else: 실패 수 + 1 → max_retries 를 넘으면 그만둔다
```

| | |
|---|---|
| **`Amount` 는 "영역 안에 놓인 자리 수"다** | 경계 상자에서 뽑아 영역 안인 것만 담는다 |
| 영역이 경계 상자에 비해 아주 가늘면 | 실패가 `Amount × 10` 번을 넘어 **`Amount` 보다 적게** 나올 수 있다 |
| 같은 `Global Seed` 면 같은 순서로 뽑는다 | 🔑 **`Amount` 를 늘리면 앞의 자리는 그대로 두고 뒤에 추가된다**(아래 실측) |

**실측 — `Amount` 를 늘렸을 때 기존 자리가 움직이나** (`Remove Outside (Model)` 은 빼고 잼)

| 청크 · 스택 | 비교 | 기존 자리 중 그대로 | 최대 이동 |
|---|---|---|---|
| `chunk_06_13` · Create → Remove Outside | 23 → 35 | **23 / 23** | **0.00m** |
| `chunk_10_06` · Create → Randomize → **Relax** | 15 → 20 | 9 / 15 | 0.52m |

→ **Relax Position 이 없으면 자리가 그대로다.** Relax 는 모든 점이 서로 밀어내는 계산이라 개수가 바뀌면 기존 자리도 조금 밀린다.

### 에디터에서 Modifier Stack 을 찾는 법

| 알아 둘 것 | 이유(소스) |
|---|---|
| **Modifier Stack 은 인스펙터 안의 "속성 하나"다** | `stack/inspector_plugin/modifier_stack_plugin.gd:14` 가 `modifier_stack` 속성의 편집기를 패널로 바꾼다 |
| 🛑 **인스펙터 검색칸에 글자가 있으면 패널이 통째로 사라진다** | 검색어가 `modifier_stack` 이라는 이름과 안 맞으면 그 속성을 숨긴다. 예: `force rebuild` 를 치면 `Force Rebuild On Load` 만 남는다 |
| **`Force rebuild` 는 패널 안 툴바의 새로고침 아이콘이다** | `stack_panel.tscn` — `Add modifier` 버튼 옆. 마우스를 올리면 `Force rebuild.` 툴팁 |
| 카드의 `▸` 를 눌러야 값이 보인다 | 속성 이름은 인스펙터처럼 단어마다 대문자(`footprint_multiplier` → `Footprint Multiplier`) |

---

## Step 12. Remove Outside — 원점 한 점만 본다

애드온에 들어 있는 `Remove Outside` 는 **자리의 원점(나무 밑동) 한 점**만 본다.

```gdscript
# modifiers/remove_outside_shapes.gd:33-38
point = transforms.list[i].origin
if negative_shapes_only:
    to_remove = domain.is_point_excluded(point)   # negative 영역 안이면 지운다
else:
    to_remove = not domain.is_point_inside(point) # 영역 밖이면 지운다
```

| 그래서 | |
|---|---|
| **밑동만 영역 안이면 남는다** | 나무 가지·건물 벽이 영역 밖으로 **몇 m 나가도** 지워지지 않는다 |
| **모델 크기를 모른다** | 작은 풀과 큰 나무를 같은 기준으로 판정한다 |
| **청크 경계를 모른다** | 영역이 청크 끝까지 그려져 있으면 가지가 옆 칸으로 넘어간다 |

라리엔 3D 는 SSOT §5.2 "기물은 **실제 모양 전체**가 자기 청크 64×64m 안" 을 지켜야 해서 이것으로는 부족했다.
그래서 모델 크기로 재는 모디파이어를 따로 만들었다 — Step 13.

---

## Step 13. Remove Outside (Model) — 모델 크기로 거른다

> 🔑 **라리엔 로컬 추가다. 원본 애드온에는 없다.**
> 파일 `addons/proton_scatter/src/modifiers/remove_outside_model.gd`(+ `.uid` `uid://deexism53r4e0`) ·
> 기록 `addons/proton_scatter/VENDORED_COMMIT.txt`. **애드온을 갱신하면 지워지므로 다시 넣는다.**
> 🛑 씬은 이 스크립트를 uid 로 참조한다 — **파일이 커밋되지 않으면 그 씬이 열리지 않는다.**

카테고리는 **Remove**. `Add modifier ▸ Remove ▸ Remove Outside (Model)` 로 넣는다.

### 무엇을 재나 — "발자국"

| 순서 | 하는 일 | 소스 |
|---|---|---|
| ① | 아이템(`ProtonScatterItem`)마다 원본 씬을 **한 번** 인스턴스해 `MeshInstance3D`(와 CSG 기본 도형)의 AABB 를 합친다 | `_measure()` :455 |
| ② | 그 AABB 의 **XZ 직사각형** 네 모서리 + 변마다 `Edge Samples` 개 점 = **윤곽점** | `_outline()` :492 |
| ③ | 아이템이 원래 입히는 변환(`Source Scale Multiplier`·원본 회전·위치 오프셋)을 함께 쓴다 | `item.process_transform(Transform3D())` |
| ④ | 자리마다 **표본점**을 만든다 — 원점 + 윤곽점 | `_sample_points()` :561 |

```gdscript
# _sample_points() :561-578 — 표본점 하나
점 = 자리 원점 + (아이템 basis × 자리 basis) × (윤곽점 × Footprint Multiplier) + 아이템 위치 오프셋
점.y = 자리 원점의 y        # 기울어진 나무가 납작한 상자에서 떨어지지 않게
# 🔑 자리 원점 자체도 표본점 목록의 첫 번째로 항상 들어간다
```

→ **나무는 수관 크기, 건물·벽은 돌아간 바닥 사각형**으로 판정된다. 좌우 비대칭 모델도 원점 기준 실제 도달 거리 그대로다.

### 무엇을 지우나 — 판정 규칙

**청크 경계를 먼저 보고, 그다음 영역을 본다.** 청크 경계는 모드와 상관없이 **항상** 지킨다.

| | 청크 경계 (`Clip To Chunk` 켬) | 영역(노란 선) 판정에서 지우는 경우 |
|---|---|---|
| **기본** (둘 다 꺼짐) | 표본점 하나라도 청크 밖 → 지움 | 표본점 **하나라도** 영역 밖 |
| **`Keep Partial Overlap` 켬** | 〃 | 표본점이 **전부** 영역 밖 (원점이 안이면 남는다) |
| **`Negative Shapes Only` 켬** | 〃 | 표본점 하나라도 **negative 영역 안** (positive 영역 밖은 안 지운다) |

- 청크 판정 — 표본점을 **청크 루트 좌표**로 옮겨 `|x|` 또는 `|z|` 가 `32 − Chunk Margin` 을 넘으면 넘은 것(`_crosses_chunk()` :527 · 32 = `WorldMetrics.CHUNK_SIZE_M × 0.5`)
- 🛑 `Negative Shapes Only` 가 켜지면 `Keep Partial Overlap` 은 **무시된다**(`_crosses_shape()` :541 이 먼저 돌려준다)

### 지우지 않고 "고른다" — Honor Proportion

그냥 지우면 비율 배분이 밀린다(Step 11). 그래서 기본값(`Honor Proportion` 켬)에서는 이렇게 한다.

```
1. fits[아이템][자리] — "이 자리에 이 모델이 들어가도 되나" 를 전부 판정한다
2. 전부 들어가면 → 목록을 손대지 않는다(순서도 그대로)                        :225
3. 아니면 → 개수 N 에 대해 아이템별 몫 round(p/P × N) 을 그 아이템이 들어갈 수 있는 자리에서 뽑는다
            (들어갈 자리가 가장 적은 아이템부터)                            _select() :255 · :265
4. 되는 최대 N 을 이분 탐색으로 찾고, 아이템 순서대로 구간을 이어 목록을 다시 쓴다       :241
```

| 결과 | |
|---|---|
| ① 모든 자리가 **실제로 그 자리에 놓일 모델 크기**로 검사된다 | |
| ② 비율이 정확히 지켜진다 | |
| ③ 남는 개수가 최대가 된다 | 실측 — `chunk_11_08` GreenTree(15) + PlaneTree(80) 30자리: PlaneTree 가 청크에 막힌 자리 **6곳**인데 실제로 빠진 것은 **1그루**(나머지는 다른 자리로 배정) |
| 🛑 **이 모디파이어는 스택 맨 끝에 둔다** | 목록 순서를 다시 쓰므로 **뒤에 자리를 지우거나 섞는 모디파이어가 있으면 배정이 깨진다** |

`Honor Proportion` 을 끄면 현재 목록 크기로 구간을 한 번 나눠 걸러낸다 — 빠르지만 다른 모델용으로 검사된 자리에 모델이 들어갈 수 있다.

### 파라미터 전체

| 인스펙터 이름 | 기본값 | 뜻 | 언제 바꾸나 |
|---|---|---|---|
| **Footprint Multiplier** | `1.0` | 잰 발자국의 배율 | 1 미만: 잎이 조금 걸쳐도 됨 · 1 초과: 여유 · 🛑 **0 금지**([Step 14](#step-14-footprint-multiplier--발자국-배율)) |
| **Edge Samples** | `1` | 윤곽 변마다 모서리 외에 더 찍는 점 수 | 0 이면 모서리만. 영역 경계가 모델보다 잘게 꺾이면 올린다 |
| **Fallback Radius** | `0.0` | 메시를 못 잰 아이템(빈 path · 메시 없음)에 쓸 반지름 | 0 이면 원점만 본다 |
| **Keep Partial Overlap** | `false` | 일부만 영역 안이어도 남긴다 | 🔑 **청크 경계만 지키고 영역 모양은 살릴 때**([Step 15](#step-15-keep-partial-overlap--모양을-살리는-스위치)) |
| **Negative Shapes Only** | `false` | negative 영역에 걸친 것만 지운다 | 길·건물 자리에 가지가 덮이지 않게 할 때 |
| **Honor Proportion** | `true` | 비율을 지키며 자리를 고른다 | 끄지 않는다 |
| **Clip To Chunk** | `true` | 청크 경계(±32m)도 함께 판정 | 라리엔은 **항상 켠다** |
| **Chunk Margin** | `0.0` | 청크 경계 안쪽 추가 여유(m) | `2.0` 이면 `verify_chunk_bounds.gd` 의 여유 기준과 같다 |
| **Debug Report** | `false` | 재빌드마다 Output 패널에 판정 내역 | 튜닝할 때 켠다 |

### Debug Report 읽는 법

```
[Remove Outside (Model)] 15 transforms in
  chunk clip: border at +-32.00 m, margin 0.00
  PlaneTree (proportion 20): reach 3.84 x 3.44 m — 1 blocked by chunk, 8 by shape
```

| 줄 | 뜻 |
|---|---|
| `15 transforms in` | 이 모디파이어에 들어온 자리 수 |
| `chunk clip: border at +-32.00 m` | 청크를 찾았다. 🛑 `NO CHUNK FOUND` 면 청크 씬 아래가 아니라서 **청크 판정이 꺼져 있다** |
| `reach 3.84 x 3.44 m` | 원점에서 가장 먼 X·Z 거리 × `Footprint Multiplier`. 🛑 **`Source Scale Multiplier` 는 빠진 값이다** — 실측 `chunk_06_10` 야자수는 `0.30 x 0.33` 으로 찍히지만 배율이 **6** 이다 |
| `1 blocked by chunk, 8 by shape` | 이 모델이 **들어갈 수 없는 자리** 수. **지워진 수가 아니다**(아이템이 하나면 거의 같다) |

### 다른 프로젝트로 옮길 때 바꿀 두 곳

| 곳 | 라리엔 값 |
|---|---|
| `_find_chunk_root()` :398-404 — 청크 루트를 찾는 씬 경로 | `res://maps/chunks/` · `res://maps/dungeons/` |
| `_resolve_chunk()` :394 — 청크 한 변 | `WorldMetrics.CHUNK_SIZE_M`(64) |

---

## Step 14. Footprint Multiplier — 발자국 배율

```
표본점 = 원점 + basis × (윤곽점 × Footprint Multiplier) + 오프셋
```

| 값 | 결과 |
|---|---|
| **1.0** (기본) | 잰 크기 그대로 |
| 0.8 | 발자국을 20% 줄인다 → 잎이 조금 걸쳐도 남는다(잎은 상자를 꽉 채우지 않는다) |
| 1.2 | 발자국을 20% 키운다 → 경계에서 여유를 둔다 |
| 🛑 **0.0** | `윤곽점 × 0 = 0` → **모든 표본점이 원점(+오프셋) 한 점으로 모인다** → Step 12 의 원점 검사와 같아진다 |

**실측 — `chunk_03_11` TreeScatter · pine_tree 70그루**

| `Footprint Multiplier` | 청크 위반 (`./doctor.sh chunk-props`) |
|---|---|
| `0.0` (파일에 이렇게 저장돼 있었다) | 🛑 **2그루** — 원점은 안인데 서쪽 가지가 0.46m · 1.18m 넘어 **청크 없는 칸**으로 |
| `1.0` | ✅ **0그루** |

> 🔑 모디파이어가 **붙어 있다고 막히는 것이 아니다.** 이 값이 0 이면 붙여 놓고도 원점만 본다.
> 파일에서 확인하려면 `.tscn` 에서 `footprint_multiplier = 0.0` 을 찾는다(기본값 1.0 이면 줄 자체가 없다).

---

## Step 15. Keep Partial Overlap — 모양을 살리는 스위치

**기본값(꺼짐)은 "가지 전체가 영역(노란 선) 안" 이어야 남긴다.** 그래서 청크 경계와 상관없이
**영역 가장자리에 걸친 나무까지** 지운다. 영역을 청크 끝까지 그려 둔 씬에서는 나무가 크게 준다.

**켜면** 표본점이 **하나라도** 영역 안이면 영역 판정을 통과한다. Create Inside 로 만든 자리는 원점이 영역 안이므로
사실상 **청크 경계를 넘는 것만** 지워진다.

### 실측 — 같은 씬, 스위치만 바꿔서

| 청크 · 노드 | 모델 (`reach`) | 모디파이어 없음 | 기본값 (꺼짐) | **켬** |
|---|---|---|---|---|
| `chunk_06_13` · TreeScatter | acacia_flat_top (7.10×7.04m) | 23 | 🛑 **6** | **15** |
| `chunk_10_06` · TreeScatter | plane_tree (3.84×3.44m) | 15 | 🛑 **6** | **14** |
| `chunk_04_11` · TreeScatter | plane_tree (3.84×3.44m) | 20 | 🛑 **0 (완료 신호 없음)** | **14** |
| `chunk_06_10` · TreeScatter | 야자 (0.30×0.33m × 배율 6) | 40 | 🛑 **0 (완료 신호 없음)** | **40** |
| `chunk_06_10` · MountainMeadowTrees | 소나무 (1.26×1.30m) | 26 | 🛑 **6** | **22** |

`chunk_10_06` 의 Debug Report — 기본값 `1 blocked by chunk, 8 by shape` → 켬 `1 blocked by chunk, 0 by shape`.
**경계를 넘는 나무는 1그루뿐인데 기본값은 9그루를 지웠다.**

### 실측 — 7개 청크에 `Keep Partial Overlap` 켬으로 붙였을 때

실제 검사기(`tests/verify_chunk_props.gd` · 메시 꼭짓점의 볼록 껍질로 잰다)로 판정했다.

| 청크 · 노드 | 남은 수 (전 → 후) | 청크 위반 |
|---|---|---|
| `chunk_06_13` · TreeScatter | 23 → 15 | 7 → **0** |
| `chunk_06_14` · DriftwoodScatter | 28 → 21 | 6 → **0** |
| `chunk_07_04` · BushFlowerScatter (11종) | 1999 → 1990 | 10 → **0** |
| `chunk_07_12` · TreeScatter | 75 → 57 | 14 → **0** |
| `chunk_10_06` · TreeScatter | 15 → 14 | 1 → **0** |
| `chunk_11_08` · TreeScatter | 30 → 29 | 1 → **0** |
| `chunk_12_09` · TreeScatter | 30 → 29 | 1 → **0** |

### `Keep Partial Overlap` 과 `Negative Shapes Only` 는 어떻게 다른가

| | positive 영역 **밖**인 자리 | negative 영역에 걸친 자리 | 청크 경계 |
|---|---|---|---|
| Keep Partial Overlap 켬 | 표본점이 **전부** 밖이면 지운다 | 지운다(negative 안의 점은 "안" 이 아니다) | 지킨다 |
| Negative Shapes Only 켬 | **지우지 않는다** | 표본점 하나라도 안이면 지운다 | 지킨다 |

negative 영역이 없는 스캐터에서 Create Inside 로 만든 자리만 다루면 둘의 결과가 같다
(실측 `chunk_06_13` Amount 23 — 둘 다 15그루).

---

## Step 16. Amount 로 밀도를 되살린다

**Remove 는 채우지 않는다**(Step 11). 경계 때문에 나무가 줄었다면 **`Create Inside (Random)` 의 `Amount` 를 올린다.**

### 실측 — `chunk_06_13` TreeScatter · `Keep Partial Overlap` 켬

| Amount | 남는 나무 |
|---|---|
| 23 (모디파이어 없음) | 23 — 🛑 그중 10그루가 청크 경계 근처 |
| 23 | 15 |
| 30 | 21 |
| **35** | **24** ✅ 검사기 위반 0 |
| 40 | 29 |
| 45 | 31 |
| 50 | 34 |

![chunk_06_13 나무 배치도 — 왼쪽 모디파이어 없음 23그루, 가운데 기본값 6그루, 오른쪽 Keep Partial Overlap 켬 + Amount 35 로 24그루](https://thruthesky.github.io/godot/site/img/protonscatter-keep-partial-amount.png)

*위에서 본 배치도(렌더링이 아니라 헤드리스로 뽑은 실제 자리) — 빨간 선 청크 경계 · 노란 선 흩뿌리는 영역 ·
초록 원 가지 범위(반지름 = 도달 거리 7.07m, 넉넉한 근사). **왼쪽** 모디파이어 없음(23 · 가지가 경계 밖) ·
**가운데** 기본값(6) · **오른쪽** `Keep Partial Overlap` 켬 + `Amount` 35(24 · 경계 안).*

| 알아 둘 것 | |
|---|---|
| **원래 모습과 똑같이는 안 된다** | 경계 밖으로 나가던 나무가 바로 위반이다. 그 자리는 비고 나무는 경계에서 **모델 반폭(acacia 약 7m)만큼 안쪽**에만 남는다 |
| **Amount 를 올려도 기존 자리는 그대로다** | Relax 가 없으면(Step 11 실측). 추가된 자리 중 경계에 걸린 것만 빠진다 |
| 배치가 마음에 안 들면 | `ProtonScatter` 의 `Global Seed` 를 바꿔 본다 — 자리 전체가 새로 뽑힌다. 바꾼 뒤 다시 검사한다 |
| 경계 바깥까지 나무로 덮고 싶다 | **옆 청크 씬에 따로 심는다.** 그 칸에 청크가 없으면 지면부터 깐다(SSOT §5.2) |

---

## Step 17. 🛑 걸러내기 함정 모음

| # | 증상 | 원인 | 해결 | 근거 |
|---|---|---|---|---|
| 1 | 모디파이어를 붙였는데 가지가 경계를 넘는다 | `Footprint Multiplier = 0` → 원점 검사로 퇴화 | `1.0` | Step 14 실측 `chunk_03_11` |
| 2 | 붙였더니 나무가 **너무 적다** | `Keep Partial Overlap` 꺼짐 → 영역 가장자리까지 지움 | 켜고 `Amount` 를 올린다 | Step 15 · 16 실측 |
| 3 | 나무가 **전부 사라졌다** · 검사기 `🛑 흩뿌리기 미완` | 전부 지워져 목록이 0 → **`build_completed` 를 보내지 않는다** | 2 와 같다 | `scatter.gd:762-765` · 실측 `chunk_04_11`·`chunk_06_10` |
| 4 | 에디터에서 끈 모디파이어가 **게임에서 돈다** | `enabled` 검사가 에디터 전용 | 끄려면 **스택에서 뺀다** | `base_modifier.gd:52-61` · 실측 아래 |
| 5 | 인스펙터에 **Modifier Stack 패널이 없다** | 인스펙터 **검색칸**에 글자가 있다 | 검색칸의 `X` | `modifier_stack_plugin.gd:14` |
| 6 | `Force rebuild` 버튼을 못 찾는다 | 인스펙터 맨 위가 아니라 **Modifier Stack 패널 툴바**의 새로고침 아이콘 | | `stack_panel.tscn` |
| 7 | 다른 PC·CI 에서 청크가 안 열린다 | 로컬 모디파이어 `.gd`·`.uid` 가 **커밋되지 않았다** | 두 파일과 `VENDORED_COMMIT.txt` 를 함께 커밋 | 씬이 uid 로 참조 · `VENDORED_COMMIT.txt` 기록 (미실측) |
| 8 | **청크가 통째로 사라졌다** · 로그 `Parse Error: Expected value, got ''=''.` | `.tscn` 에 병합 충돌 표시(`<<<<<<<` `=======` `>>>>>>>`)가 커밋됐다 | 한쪽 값만 남기고 표시 줄을 지운다 · `git grep -n '^<<<<<<< '` | 실측 `chunk_04_11.tscn:171` — `main.tscn` 도 `referenced non-existent resource` |
| 9 | 한 Scatter 의 스택을 고쳤는데 다른 Scatter 는 그대로 | 두 번째 Scatter 는 스택 **복사본**을 쓴다 | 규칙을 공유하려면 `Proxy` | `scatter.gd:147-148` |
| 10 | 모델 메시를 바꿨는데 판정이 옛 크기 | 발자국 캐시 키에 메시가 없다(path·배율·ignore 플래그·Edge Samples 만) | 에디터를 다시 연다 | `remove_outside_model.gd:438` (소스 근거 · 미실측) |
| 11 | BoxShape 영역에서 Project 뒤에 두었더니 전부 지워진다 | Box 판정이 높이를 본다 | Box 로 거를 때는 Project 앞에 | `box_shape.gd:23` · 모디파이어 주석 (미실측) |

**실측 — 4번** (`chunk_06_13` TreeScatter · Amount 23 · 헤드리스 = 게임과 같은 비에디터)

```
[enabled] 에디터 힌트=false
[enabled] 모디파이어 빼기 → 나무 23그루
[enabled] 모디파이어 켜기 → 나무 15그루
[enabled] 모디파이어 끄기 → 나무 15그루      ← 꺼도 켠 것과 같다
```

### 검사 코드를 짤 때의 함정

| 함정 | 해결 |
|---|---|
| 헤드리스는 MultiMesh 인스턴스 변환을 버린다 | MultiMesh 를 읽지 말고 **`scatter.transforms.list`** 를 읽는다 |
| 스레드로 돌면 끝나는 시점을 모른다 | `scatter.dbg_disable_thread = true` 로 두거나 `build_completed` 를 기다린다(0개면 안 온다 — 제한 시간을 둔다) |
| `modifier_stack.add()` 는 `stack_changed` 로 **재빌드를 한 번 더** 건다 | 읽는 순간과 겹칠 수 있다 → 검사에서는 `stack.push_back()`·`stack.assign()` |
| 캐시된 `PackedScene` 의 스택 리소스에 모디파이어를 붙인 경우, 월드 전체를 세우는 검사에서 **반영되지 않았다**(원인 미확인) | 노드가 트리에 들어오는 순간(`SceneTree.node_added`) **그 인스턴스의 스택**에 붙인다 |

---

## Step 18. 확인하는 법

### 에디터에서

1. `Remove Outside (Model)` 카드의 **`Debug Report`** 를 켠다
2. Modifier Stack 패널의 **새로고침 아이콘(Force rebuild)**
3. **Output 패널**의 `[Remove Outside (Model)]` 블록을 읽는다(Step 13) — `by shape` 가 크면 [Step 15](#step-15-keep-partial-overlap--모양을-살리는-스위치)

### 헤드리스로 개수 세기 — 파일을 바꾸지 않고 설정별로 비교

```gdscript
extends SceneTree
# godot --headless --path . -s <이 파일>

func _count(path: String, node: String, amount: int, keep_partial: bool) -> int:
    var ps: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
    var chunk: Node3D = ps.instantiate()
    var s = chunk.get_node(node)
    s.dbg_disable_thread = true                      # 스레드 없이 — 끝나는 시점이 분명하다
    for m in s.modifier_stack.stack:                 # 인스턴스의 스택만 고친다(파일 불변)
        var f: String = m.get_script().resource_path.get_file()
        if f == "create_inside_random.gd":
            m.amount = amount
        if f == "remove_outside_model.gd":
            m.keep_partial_overlap = keep_partial
            m.debug_report = true
    var done := [false]                              # 람다는 바깥 bool 을 값으로 잡는다 → 배열로 감싼다
    s.build_completed.connect(func(): done[0] = true, CONNECT_ONE_SHOT)
    root.add_child(chunk)
    var t0 := Time.get_ticks_msec()
    while not done[0] and Time.get_ticks_msec() - t0 < 60000:
        await process_frame
    var n: int = s.transforms.list.size() if done[0] else 0   # 신호가 안 오면 0개다(Step 17 #3)
    chunk.queue_free()
    await process_frame
    return n

func _initialize() -> void:
    for a in [23, 35]:
        var n := await _count("res://maps/chunks/chunk_06_13.tscn", "Props/TreeScatter", a, true)
        print("amount %d → %d그루" % [a, n])
    quit(0)
```

### 라리엔 3D — 청크 경계 검사

| 명령 | |
|---|---|
| `./doctor.sh chunk-props` | 메인 월드 + 던전 5 전부 · 약 3~5분 · 보고서 `build/reports/chunk_props.md` |
| `./doctor.sh --chunk maps/chunks/chunk_06_13.tscn chunk-props` | 그 청크만 **보고**한다. 🛑 주변 흩뿌리기 충돌을 보려고 **월드는 통째로 세우므로** 시간은 비슷하다 |

**검사기와 모디파이어는 재는 법이 다르다.** 검사기는 메시 꼭짓점의 **볼록 껍질**(실제 모양), 모디파이어는 **AABB 직사각형**이라
모디파이어가 **조금 더** 지운다 — 경계를 넘길 일은 없다.

| 청크 · 노드 | 모디파이어 `blocked by chunk` | 검사기 청크 위반 |
|---|---|---|
| `chunk_06_13` · TreeScatter | 8 | 7 |
| `chunk_06_14` · DriftwoodScatter | 7 | 6 |
| `chunk_07_12` · TreeScatter | 18 | 14 |
| `chunk_10_06` · TreeScatter | 1 | 1 |

> 라리엔 규칙에서 **나무 잎사귀가 2m 이내로 넘는 것은 검사기가 ⚠ 로 허용**한다(원점이 안 · 넘은 칸에 청크가 있을 때).
> 모디파이어는 이 예외를 모른다 — 청크 없는 칸 쪽 경계는 어차피 허용이 없다.

---

## Step 19. 목표별 설정표

| 하고 싶은 것 | 설정 |
|---|---|
| **청크 경계만 지키고 영역 모양은 그대로** | `Remove Outside (Model)` 을 **스택 맨 끝**에 · **`Keep Partial Overlap` 켬** |
| **경계 때문에 준 나무 수를 되살리기** | `Create Inside (Random) ▸ Amount` 를 올린다 — `chunk_06_13` 23 → **35** 로 24그루 |
| 가지까지 영역(노란 선) 안에 딱 맞게 | 기본값(둘 다 꺼짐). 많이 지워지므로 영역을 모델 반폭만큼 넓히거나 `Amount` 를 크게 |
| 길·건물 자리에 가지가 덮이지 않게 | 그 자리에 **negative** 영역 + `Negative Shapes Only` 켬 |
| 잎이 경계에 조금 걸쳐도 되게 | `Footprint Multiplier` 를 1 미만(예 0.8) — 🛑 **0 금지** |
| 경계에서 여유를 두기 | `Chunk Margin` `2.0` |
| 모디파이어를 잠깐 끄기 | 🛑 `enabled` 끄기는 **게임에서 안 꺼진다** → 스택에서 뺀다 |
| 배치만 바꾸고 싶다 | `Global Seed` 를 바꾼다 |
| 경계 밖까지 나무로 덮기 | 옆 청크 씬에 따로 심는다(청크가 없으면 지면부터) |
| BoxShape 영역으로 거르기 | Project On Colliders **앞**에 둔다 |

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
| **Offset** | Edit Position / Rotation / Scale | 전부에 같은 값을 더한다 |
| | Edit Transform | 🛑 폐기 예정 — 위 셋을 조합해 쓴다 |
| **Remove** | **Remove Outside** | 영역 밖을 지운다 — 🛑 **원점 한 점만** 본다([Step 12](#step-12-remove-outside--원점-한-점만-본다)) |
| | **Remove Outside (Model)** | 🔑 **라리엔 로컬 추가** — **모델 크기**와 **청크 경계**로 거르고 비율을 지킨다([Step 13](#step-13-remove-outside-model--모델-크기로-거른다)) |
| | Remove Random | 무작위로 솎아낸다 |
| **Misc** | Proxy | 다른 ProtonScatter 의 스택을 **연결 복사**해 쓴다(원본을 고치면 따라온다) |
| **Debug** | Debug Modifier | 중간 결과를 본다 |

**순서가 중요하다.** 위에서 아래로 차례로 적용된다 —
`Create` 로 만들고, `Edit`·`Offset` 으로 다듬고, `Remove` 로 솎아낸다.
드래그로 순서를 바꿀 수 있다. **Remove 는 지우기만 하고 다시 채우지 않는다**([Step 11](#step-11-모디파이어-스택은-어떻게-도는가)).

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
| **Remove Outside (Model) 을 붙였더니 나무가 너무 적다** | `Keep Partial Overlap` 을 켜고 `Amount` 를 올린다([Step 15](#step-15-keep-partial-overlap--모양을-살리는-스위치)·[16](#step-16-amount-로-밀도를-되살린다)) |
| **나무가 전부 사라졌다 · `build_completed` 가 안 온다** | 걸러내기로 0개가 됐다 — 0개면 신호를 보내지 않는다([Step 17](#step-17--걸러내기-함정-모음)) |
| **붙였는데도 가지가 청크 경계를 넘는다** | `Footprint Multiplier` 가 `0` 이다 → `1.0`([Step 14](#step-14-footprint-multiplier--발자국-배율)) |
| **에디터에서 끈 모디파이어가 게임에서 돈다** | `enabled` 는 에디터에서만 지켜진다 → 스택에서 뺀다 |
| **인스펙터에 Modifier Stack 패널이 없다** | 인스펙터 **검색칸**을 비운다 |
| **청크·씬이 통째로 안 열린다(`Parse Error`)** | `.tscn` 에 병합 충돌 표시가 남았거나, 로컬 모디파이어 스크립트가 커밋되지 않았다 |

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
| 소스 | `addons/proton_scatter/src/scatter.gd` · `src/common/scatter_util.gd` · `src/common/domain.gd` · `src/stack/modifier_stack.gd` · `src/stack/inspector_plugin/ui/stack_panel.gd` · `src/modifiers/base_modifier.gd` · `create_inside_random.gd` · `remove_outside_shapes.gd` · `src/shapes/box_shape.gd`·`path_shape.gd`·`sphere_shape.gd` |
| 라리엔 로컬 모디파이어 | `addons/proton_scatter/src/modifiers/remove_outside_model.gd` · 기록 `addons/proton_scatter/VENDORED_COMMIT.txt` |
| 청크 경계 규칙·검사 | SSOT §5.2 · `tests/verify_chunk_props.gd` · `./doctor.sh chunk-props` · [openworld-3d.md §4](openworld-3d.md) |
| 기본 프리셋 | `addons/proton_scatter/presets/scatter_default.tscn` |
| 실측 | [protonscatter_collision_probe.gd](../../../../tests/protonscatter_collision_probe.gd) · [protonscatter_preset_probe.gd](../../../../tests/protonscatter_preset_probe.gd) · [autopilot_mm_walk_test.gd](../../../../tests/autopilot_mm_walk_test.gd) · Step 11~18 은 2026-09-17 라리엔 3D 청크 씬을 헤드리스로 인스턴스해 설정별로 세었다(Step 18 코드) |
| 이어서 | [multimesh-3d.md](multimesh-3d.md) — MultiMesh 원리와 콜리전 여섯 방법 |
