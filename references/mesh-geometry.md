# 메시의 구조 — 정점·모서리·삼각형·면

> **이 문서로 오는 상황** — 3D 형상이 **무엇으로 이루어져 있는가** — 정점(vertex)·모서리(edge)·
> 삼각형(triangle)·면(face)·서피스(surface)·메시(mesh)가 서로 어떻게 이어지는지, 왜 상자의
> 꼭짓점은 8개인데 정점은 24개인지, 와이어프레임으로 그것을 어떻게 눈으로 확인하는지.
> 용어 하나의 뜻만 필요하면 [dictionary.md](dictionary.md), 성능 예산은 [lowend-3gb-60fps.md](lowend-3gb-60fps.md)

이 문서의 숫자는 전부 **엔진에서 직접 뽑은 것**이다. 기준은 `godot --version` 의
**4.7.2.stable.official** 이고, 측정 방법은 각 절에 코드로 함께 적었다.

---

## 목차

1. [한눈에 — 점 하나에서 화면까지](#1-한눈에--점-하나에서-화면까지)
2. [정점(vertex) — 위치 하나가 아니라 속성 묶음이다](#2-정점vertex--위치-하나가-아니라-속성-묶음이다)
3. [모서리(edge) — 저장되지 않는다. 계산될 뿐이다](#3-모서리edge--저장되지-않는다-계산될-뿐이다)
4. [삼각형(triangle) — GPU 가 아는 유일한 면](#4-삼각형triangle--gpu-가-아는-유일한-면)
5. [면(face) — 사람이 세는 단위, GPU 가 세는 단위](#5-face--사람이-세는-단위-gpu-가-세는-단위)
6. [인덱스(index) — 정점을 재사용하는 장치](#6-인덱스index--정점을-재사용하는-장치)
7. [사각형 하나를 끝까지 따라간다](#7-사각형-하나를-끝까지-따라간다-실측)
8. [🛑 상자의 꼭짓점은 8개인데 정점은 24개다](#8--상자의-꼭짓점은-8개인데-정점은-24개다-실측)
9. [서피스(surface)와 메시(Mesh) — 드로우콜이 갈리는 곳](#9-서피스surface와-메시mesh--드로우콜이-갈리는-곳)
10. [MeshInstance3D — 형상을 씬에 놓는 노드](#10-meshinstance3d--형상을-씬에-놓는-노드)
11. [눈으로 확인한다 — 와이어프레임·오버드로우·언셰이디드](#11-눈으로-확인한다--와이어프레임오버드로우언셰이디드)
12. [🛑 감김 방향(winding) — 삼각형이 안 보이면 여기부터](#12--감김-방향winding--삼각형이-안-보이면-여기부터)
13. [직접 만든다 — ArrayMesh 와 SurfaceTool](#13-직접-만든다--arraymesh-와-surfacetool)
14. [세는 법 — 무엇을 물었는지에 따라 답이 다르다](#14-세는-법--무엇을-물었는지에-따라-답이-다르다)
15. [라리엔 3D 에서 이것이 걸리는 곳](#15-라리엔-3d-에서-이것이-걸리는-곳)

---

## 1. 한눈에 — 점 하나에서 화면까지

**용어들이 따로 노는 것처럼 느껴지는 이유는 하나다 — 이들은 나열된 목록이 아니라 한 줄로
이어진 계보이기 때문이다.** 아래 화살표는 "무엇이 무엇을 만드는가"이지 분류가 아니다.

```
  정점 (vertex)            공간의 점 하나 + 그 점이 가진 속성들
      │                    ↓ 3개를 고른다
  삼각형 (triangle)        점 3개가 만드는 최소한의 면. 모서리 3개는 여기서 자동으로 생긴다
      │                    ↓ 여러 개를 잇는다
  면 (face) / 표면          삼각형들이 이어져 만든 "겉면"
      │                    ↓ 같은 재질끼리 묶는다
  서피스 (surface)          머티리얼 하나가 적용되는 삼각형 묶음 = 드로우콜 하나
      │                    ↓ 서피스를 모은다
  메시 (Mesh)              형상 데이터 전체. 파일·리소스이며 노드가 아니다
      │                    ↓ 씬에 놓는다
  MeshInstance3D           그 메시를 어느 위치에 놓고 그릴지 정하는 노드
      │
  화면
```

| 단계 | 한 줄 정의 | Godot 에서의 실체 |
|---|---|---|
| **정점** vertex | 공간의 점 + 그 점의 속성 묶음 | `PackedVector3Array` 한 칸 (+ 노멀·UV 배열의 같은 칸) |
| **모서리** edge | 두 정점을 잇는 선 | **저장되지 않는다.** 삼각형에서 파생될 뿐 |
| **삼각형** triangle | 정점 3개가 닫아 만든 최소 면 | 인덱스 배열의 3칸 묶음 |
| **면** face | 겉면 한 조각 | 렌더링에서는 삼각형과 같은 말 |
| **서피스** surface | 머티리얼 하나가 걸리는 삼각형 묶음 | `Mesh.get_surface_count()` 의 한 칸 = **드로우콜 1** |
| **메시** Mesh | 서피스를 모은 형상 데이터 | `Resource` — 여러 노드가 공유한다 |
| **MeshInstance3D** | 메시를 씬 좌표에 놓는 노드 | `Node3D` 의 자손 |

> 🛑 **가장 흔한 오해는 마지막 두 줄에서 나온다.** 메시는 **노드가 아니라 리소스**다.
> `MeshInstance3D` 를 만들자마자 화면에 아무것도 없는 이유는 **그릇만 있고 내용물(mesh)이
> 비어 있어서**다. 반대로 메시 하나를 **100개의 노드가 함께 쓸 수 있다** — 형상 데이터는
> 메모리에 한 벌만 있으면 되기 때문이다.

---

## 2. 정점(vertex) — 위치 하나가 아니라 속성 묶음이다

**"꼭짓점"이라는 번역 때문에 위치(x, y, z)만 떠올리게 되는데, 실제 정점은 그 점에 붙은
속성 여러 개의 묶음이다.** 이것을 모르면 8절의 "상자의 정점이 24개"가 영원히 이해되지 않는다.

Godot 은 정점의 속성을 **배열 13개**로 나눠 담는다. 배열마다 같은 번호 칸이 **같은 정점**이다.
(엔진에서 확인 — `Mesh.ArrayType` 열거값)

| 상수 | 값 | 담는 것 | 없어도 되나 |
|---|---|---|---|
| `ARRAY_VERTEX` | 0 | **위치** `Vector3` | 🛑 필수 |
| `ARRAY_NORMAL` | 1 | 이 점에서 면이 향하는 방향 | 없으면 조명이 계산되지 않는다 |
| `ARRAY_TANGENT` | 2 | 노멀맵을 위한 접선 | 노멀맵을 쓸 때 |
| `ARRAY_COLOR` | 3 | 정점 색 | 선택 |
| `ARRAY_TEX_UV` | 4 | **텍스처 좌표** | 텍스처를 붙일 때 필수 |
| `ARRAY_TEX_UV2` | 5 | 두 번째 UV (라이트맵) | 라이트맵을 구울 때 |
| `ARRAY_BONES` | 10 | 이 점을 움직이는 본 번호 | 스킨드 메시일 때 |
| `ARRAY_WEIGHTS` | 11 | 각 본의 영향 비율 | 스킨드 메시일 때 |
| `ARRAY_INDEX` | 12 | **정점을 잇는 순서** (→ 6절) | 없으면 정점을 그대로 3개씩 읽는다 |
| `ARRAY_MAX` | 13 | 배열의 총 개수 | — |

```gdscript
var arrays: Array = mesh.surface_get_arrays(0)          # 서피스 0의 모든 배열
var pos:  PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
var nrm:  PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
var uv:   PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
# pos[7] · nrm[7] · uv[7] 은 모두 "7번 정점"의 속성이다
```

**이 구조에서 나오는 규칙 하나 — 속성이 하나라도 다르면 다른 정점이다.**
위치가 완전히 같아도 노멀이 다르면 GPU 에게는 별개의 정점이다. 8절이 그 사례다.

> 정점 수가 성능에 어떻게 걸리는지는 [dictionary.md — 삼각형 수·폴리곤 수·정점 수](dictionary.md#삼각형-수--폴리곤-수--정점-수--모델의-무게를-세는-세-가지-단위) 와
> [lowend-3gb-60fps.md](lowend-3gb-60fps.md) 를 본다. 스킨드 캐릭터는 비용이 삼각형이 아니라
> **정점 수**에 비례한다.

---

## 3. 모서리(edge) — 저장되지 않는다. 계산될 뿐이다

**모서리는 정점과 삼각형 사이를 잇는 개념이지만, 렌더링 데이터에는 들어 있지 않다.**
`surface_get_arrays()` 어디를 뒤져도 "모서리 배열"은 없다. **삼각형이 정해지면 모서리는
저절로 정해지기 때문**이다 — 정점 3개를 순서대로 이으면 변 3개가 나온다.

```
정점 3개                      삼각형 1개                모서리 3개(자동)
   A                             A                         A
                        ⇒       ╱ ╲             ⇒         ╱ ╲   ← A-B, B-C, C-A
  B   C                        B───C                      B───C
```

| 어디서 모서리를 다루나 | 실제로 하는 일 |
|---|---|
| **Blender 의 Edit Mode** | 모서리를 선택·이동한다 → **모델링 도구가 따로 관리**하는 정보다 |
| **와이어프레임 표시** (→ 11절) | 삼각형에서 **그때 계산해** 선으로 그린다 |
| **Godot 의 메시 데이터** | 🛑 **없다.** 정점 배열 + 인덱스 배열뿐이다 |

> **첨부 강의에서 "vertices … connected by edges … these connections make triangles"
> 라고 말한 순서가 정확하다.** 다만 데이터로 저장되는 것은 **점(정점)과 이음 순서(인덱스)**
> 이고, 선(모서리)은 그 결과로 생긴다는 점만 덧붙이면 된다.

---

## 4. 삼각형(triangle) — GPU 가 아는 유일한 면

**GPU 는 삼각형만 그린다.** 사각형도, 오각형도, 원도 없다. 이유는 세 가지다.

| 이유 | 내용 |
|---|---|
| **항상 평면이다** | 점 3개는 반드시 한 평면 위에 있다. 점 4개는 꼬일 수 있어 "어느 쪽이 면인가"가 모호해진다 |
| **항상 볼록하다** | 래스터라이저가 안팎을 판정하는 계산이 단순해진다 |
| **보간이 유일하게 정해진다** | 세 꼭짓점의 색·UV·노멀을 면 안쪽으로 섞는 방법(무게중심 좌표)이 하나뿐이다 |

그래서 모델러가 사각형(quad)으로 만든 면도 **렌더링 직전에 삼각형 2개로 쪼개진다.**

```
사각형 면 1개 (폴리곤 1)          GPU 에서는 삼각형 2개
   0 ─────── 1                    0 ─────── 1
   │         │          ⇒         │ ＼   ①  │      ① = 0, 1, 2
   │         │                    │  ②  ＼  │      ② = 0, 2, 3
   3 ─────── 2                    3 ─────── 2
```

**와이어프레임을 켰을 때 상자의 각 면에 대각선이 그어져 보이는 것**(11절 스크린샷)이
바로 이 분할이다. 모델에 없던 선이 생긴 것이 아니라 **처음부터 그렇게 저장되어 있던 것**이다.

Godot 에서 프리미티브 종류는 `Mesh.PrimitiveType` 로 지정한다 (엔진에서 확인).

| 상수 | 값 | 뜻 |
|---|---|---|
| `PRIMITIVE_POINTS` | 0 | 정점을 점으로 |
| `PRIMITIVE_LINES` | 1 | 2개씩 선으로 |
| `PRIMITIVE_TRIANGLES` | **3** | **3개씩 삼각형으로 — 형상은 사실상 전부 이것** |

---

## 5. 면(face) — 사람이 세는 단위, GPU 가 세는 단위

**"face"는 문맥에 따라 두 가지를 가리킨다. 이 하나가 대화를 어긋나게 만든다.**

| | 무엇을 face 라 부르나 | 상자 하나의 face 수 | 누가 쓰나 |
|---|---|---|---|
| **① 모델링 관점** | 사각형이든 n각형이든 **면 한 장** | **6** | Blender·모델러·Decimate 옵션 |
| **② 렌더링 관점** | **삼각형 하나** | **12** | GPU·Godot `get_faces()`·성능 예산 |

Godot 의 API 이름은 ②를 따른다. `Mesh.get_faces()` 는 **삼각형마다 정점 3개**를
펼친 `PackedVector3Array` 를 준다.

```gdscript
var faces: PackedVector3Array = mesh.get_faces()
var triangle_count := faces.size() / 3          # 🛑 3으로 나눈다
```

**실측** — 기본 `BoxMesh`

```
get_faces() 길이 = 36  →  삼각형 12개  →  사각형 면 6장
```

> **정리 문장 하나** — **"상자의 face 는 6개(모델링) 또는 12개(렌더링)다. 그래서 성능을
> 이야기할 때는 face 라 하지 않고 삼각형(tris)이라고 말한다."** 이 습관 하나로
> 대부분의 혼동이 사라진다 → [dictionary.md](dictionary.md#삼각형-수--폴리곤-수--정점-수--모델의-무게를-세는-세-가지-단위)

---

## 6. 인덱스(index) — 정점을 재사용하는 장치

**삼각형 2개가 붙어 있으면 정점 2개를 공유한다. 그것을 두 번 저장하지 않기 위한 장치가
인덱스다.** 인덱스 배열은 "몇 번 정점을 어떤 순서로 읽어라"라는 **번호표의 나열**이다.

```
정점 배열 (4개)                    인덱스 배열 (6개)
  [0] (-0.5, 0, -0.5)                0, 1, 2,      ← 삼각형 ①
  [1] ( 0.5, 0, -0.5)                0, 2, 3       ← 삼각형 ②
  [2] ( 0.5, 0,  0.5)
  [3] (-0.5, 0,  0.5)              → 정점 0 과 2 를 두 삼각형이 함께 쓴다
```

**실측** — 같은 사각형을 인덱스 없이 만들면 정점이 6개가 된다.

```gdscript
var st := SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)
# 삼각형 2개 분량의 정점 6개를 그대로 넣는다
...
var m := st.commit()          # → 정점 6 · 인덱스 없음 · 삼각형 2

st.index()                    # 같은 위치의 정점을 합친다
var m2 := st.commit()         # → 정점 4 · 인덱스 6 · 삼각형 2
```

| | 인덱스 없이 | 인덱스 사용 |
|---|---|---|
| 정점 배열 | **6** | **4** |
| 인덱스 배열 | 없음 | 6 |
| 삼각형 | 2 | 2 |

정점 하나는 위치·노멀·UV 를 담고 다니는 반면 인덱스는 정수 하나(4바이트)다.
**면이 이어질수록 차이가 커진다** — 구는 정점 2,210개로 삼각형 4,224개를 만든다(8절 표).
인덱스가 없었다면 정점 배열이 **12,672칸**이어야 했다. 5.7배다.

> 🛑 **`SurfaceTool.index()` 는 "위치·노멀·UV 가 모두 같은" 정점만 합친다.**
> 각진 면끼리는 노멀이 달라 합쳐지지 않는다 — 그래서 다음 절의 결과가 나온다.

---

## 7. 사각형 하나를 끝까지 따라간다 (실측)

**첨부 강의가 상자로 보여준 것을 가장 작은 단위로 재현한 것이다.** 코드 20줄로
정점 4개부터 화면에 그려지는 면까지 전 과정이 나온다.

```gdscript
var arrays := []
arrays.resize(Mesh.ARRAY_MAX)                       # 13칸짜리 배열을 만든다

# ① 정점 — 위치 4개
arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
    Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5),
    Vector3( 0.5, 0,  0.5), Vector3(-0.5, 0, 0.5)])

# ② 각 정점이 향하는 방향 — 위로
arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([
    Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])

# ③ 텍스처 좌표
arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
    Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])

# ④ 삼각형 2개 — 번호 3개씩. 순서가 곧 감김 방향이다(→ 12절)
arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2,  0, 2, 3])

var mesh := ArrayMesh.new()
mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

var mi := MeshInstance3D.new()                      # ⑤ 씬에 놓는 노드
mi.mesh = mesh
add_child(mi)
```

**실측 결과** (`godot --headless -s` 로 실행)

```
surface 수 = 1
정점 4 · 인덱스 6 · 삼각형 2
AABB = [P: (-0.5, 0.0, -0.5), S: (1.0, 0.00001, 1.0)]
```

> 🛑 **인덱스 순서를 `[0,1,2, 0,2,3]` 로 쓴 것에 이유가 있다.** 이 순서라야 **위에서 내려다볼 때
> 보인다.** `[0,2,1, 0,3,2]` 로 뒤집으면 노멀이 `UP` 이어도 화면에서 사라진다 —
> 위에서 카메라로 내려다보며 중앙 픽셀을 읽어 확인했다(앞은 `(1,1,1)`, 뒤집으면 `(0,0,0)`).
> 왜 그런지는 → [12절 감김 방향](#12--감김-방향winding--삼각형이-안-보이면-여기부터)

| 강의에서 부른 이름 | 이 코드에서 | 개수 |
|---|---|---|
| vertices (the points) | `ARRAY_VERTEX` | 4 |
| edges (connections) | 인덱스가 만드는 변 | 5개 (겉 4 + 대각선 1) |
| triangles | `ARRAY_INDEX` 3칸씩 | 2 |
| face | 사각형 겉면 | 1장 = 삼각형 2 |
| mesh | `ArrayMesh` | 1 |
| **"mesh instance is drawing"** | `MeshInstance3D` | 1 |

---

## 8. 🛑 상자의 꼭짓점은 8개인데 정점은 24개다 (실측)

**이것이 이 문서에서 가장 중요한 사실이다.** 눈으로 세는 꼭짓점과 GPU 가 세는 정점은
같은 수가 아니다.

**기본 `BoxMesh` 실측**

```
ARRAY_VERTEX : 24        ← 정점 배열 길이
ARRAY_NORMAL : 24
ARRAY_TEX_UV : 24
ARRAY_INDEX  : 36        ← 삼각형 12개 × 3
get_faces()  : 36 (삼각형 12)
서로 다른 위치 좌표 = 8   ← 눈으로 보는 꼭짓점
```

**왜 8이 아니라 24인가 — 한 꼭짓점이 세 면에 걸쳐 있고, 세 면의 노멀이 서로 다르기 때문이다.**

```
정점 배열에서 실제로 뽑은 값 — 위치는 같고 노멀만 다른 세 칸

  [ 2] pos=(0.5, 0.5, 0.5)  normal=(0, 0, 1)     ← 앞면에 속할 때
  [ 8] pos=(0.5, 0.5, 0.5)  normal=(1, 0, 0)     ← 오른쪽 면에 속할 때
  [16] pos=(0.5, 0.5, 0.5)  normal=(0, 1, 0)     ← 윗면에 속할 때
```

**8개 꼭짓점 × 3면 = 24.** UV 도 면마다 달라 어차피 합칠 수 없다.
정점은 위치만이 아니라 **속성 묶음**이라는 2절의 정의가 여기서 그대로 확인된다.

> 🛑 **반대로, 구처럼 면이 매끄럽게 이어지는 형상은 노멀이 연속이라 정점이 공유된다.**
> 아래 표에서 구의 정점/삼각형 비율이 상자와 정반대인 이유가 이것이다.

**Godot 기본 프리미티브 실측표** (4.7.2 · 전부 기본값)

| 메시 | 기본 파라미터 | 정점 | 인덱스 | 삼각형 | 눈으로 세는 꼭짓점 |
|---|---|---|---|---|---|
| `QuadMesh` | size 1×1 | **4** | 6 | **2** | 4 |
| `PlaneMesh` | size 2×2, subdivide 0 | **4** | 6 | **2** | 4 |
| `PlaneMesh` | subdivide 1×1 | 9 | 24 | 8 | 9 |
| **`BoxMesh`** | size 1×1×1 | **24** | 36 | **12** | **8** |
| `CylinderMesh` | radial 64, rings 4 | 522 | 2,304 | 768 | — |
| `SphereMesh` | radial 64, rings 32 | 2,210 | 12,672 | 4,224 | — |

> ⚠️ **"BoxMesh 는 정점 36개"라는 서술을 보면 인덱스 수(36)와 정점 수(24)를 혼동한 것이다.**
> 이 스킬의 용어 툴팁에도 같은 오기가 있어 이번에 바로잡았다.

---

## 9. 서피스(surface)와 메시(Mesh) — 드로우콜이 갈리는 곳

**서피스는 "머티리얼 하나가 적용되는 삼각형 묶음"이다.** 메시 하나가 서피스를 여러 개
가질 수 있고, **서피스 하나가 곧 드로우콜 하나**다. 성능 이야기가 시작되는 지점이 여기다.

```
Mesh (캐릭터 1인분)
 ├─ surface 0 : 몸통 삼각형 3,200개  ← 머티리얼 A (피부)     → 드로우콜 1
 ├─ surface 1 : 옷   삼각형 1,400개  ← 머티리얼 B (천)       → 드로우콜 2
 └─ surface 2 : 검   삼각형   200개  ← 머티리얼 C (금속)     → 드로우콜 3
```

```gdscript
mesh.get_surface_count()                  # 서피스 개수
mesh.surface_get_arrays(i)                # i번 서피스의 정점·인덱스 배열
mesh.surface_get_material(i)              # i번 서피스의 머티리얼
mi.get_surface_override_material_count()  # 노드에서 덮어쓴 머티리얼 수
```

**실측 — 프레임 통계로 확인한다** (기본 `SphereMesh` 1개를 화면에 놓고 측정)

```
TOTAL_OBJECTS_IN_FRAME    = 1        ← 그린 오브젝트 수
TOTAL_PRIMITIVES_IN_FRAME = 4,224    ← 그린 삼각형 수 (= 메시의 삼각형 수와 일치)
TOTAL_DRAW_CALLS_IN_FRAME = 1        ← 서피스가 1개라 드로우콜도 1
```

```gdscript
# 어느 화면에서든 실제로 그려진 양을 재는 코드
var tris := RenderingServer.get_rendering_info(
        RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
var calls := RenderingServer.get_rendering_info(
        RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
```

> **"삼각형을 줄여야 하나, 드로우콜을 줄여야 하나"는 이 두 숫자를 재서 답한다.**
> 모바일에서 대개 먼저 무너지는 쪽은 삼각형이 아니라 **드로우콜**이다
> → [lowend-3gb-60fps.md](lowend-3gb-60fps.md) · [performance-mobile.md](performance-mobile.md)

**메시 클래스 계보** (엔진에서 확인)

```
Mesh < Resource < RefCounted < Object
 ├─ ArrayMesh          배열을 직접 넣어 만든다. glTF 임포트 결과도 이것이다
 ├─ ImmediateMesh      매 프레임 다시 쌓는다. 디버그 선·궤적용
 ├─ PlaceholderMesh    비어 있는 자리표시
 └─ PrimitiveMesh      코드가 형상을 생성하는 메시
     ├─ BoxMesh · SphereMesh · CylinderMesh · CapsuleMesh · PlaneMesh · QuadMesh
     ├─ PrismMesh · TorusMesh · PointMesh · TextMesh
     └─ TubeTrailMesh · RibbonTrailMesh
```

---

## 10. MeshInstance3D — 형상을 씬에 놓는 노드

```
MeshInstance3D < GeometryInstance3D < VisualInstance3D < Node3D < Node < Object
```

| 클래스 | 그 층이 더하는 것 |
|---|---|
| `Node3D` | 위치·회전·크기 (`Transform3D`) |
| `VisualInstance3D` | 렌더 레이어, AABB — **컬링의 단위** |
| `GeometryInstance3D` | 그림자 설정, LOD 거리, 머티리얼 오버라이드, 가시 범위 |
| **`MeshInstance3D`** | **`mesh` 칸** — 무엇을 그릴지 |

```gdscript
var mi := MeshInstance3D.new()
mi.mesh = load("res://models/rock.tres")   # 형상 (리소스 — 공유된다)
mi.position = Vector3(3, 0, -2)            # 위치  (노드 — 인스턴스마다 다르다)
mi.material_override = my_material         # 모든 서피스를 한 머티리얼로 덮는다
add_child(mi)
```

**형상과 배치가 분리되어 있다는 것이 핵심이다.** 바위 하나를 200군데 놓아도
메시는 메모리에 한 벌이다. 이 분리가 [MultiMesh](lowend-culling-lod.md) ·
[LOD](dictionary.md#lod-level-of-detail--멀면-단순한-모델로-바꿔-그린다) ·
임포스터 같은 최적화가 성립하는 토대다.

> 🛑 **`MeshInstance3D` 는 충돌을 만들지 않는다.** 보이는 것과 부딪히는 것은 별개다
> → [physics-3d.md](physics-3d.md)

---

## 11. 눈으로 확인한다 — 와이어프레임·오버드로우·언셰이디드

**메시가 삼각형으로 되어 있다는 것을 말로 이해하는 것과 눈으로 보는 것은 다르다.**
Godot 은 그것을 보여주는 표시 모드를 갖고 있다.

### 에디터에서 — 3D 뷰포트 왼쪽 위 `Perspective` 버튼

그 버튼을 누르면 나오는 메뉴에 아래 항목이 있다 (에디터 문자열에서 확인).

| 메뉴 항목 | 보이는 것 | 언제 쓰나 |
|---|---|---|
| **Display Normal** | 평소 화면 | 기본값 |
| **Display Wireframe** | **삼각형의 변만 선으로** | **형상이 어떻게 쪼개져 있는지 볼 때** |
| **Display Overdraw** | 겹쳐 그린 만큼 밝아진다 | 반투명·파티클이 몇 겹 쌓였는지 |
| **Display Unshaded** | 조명을 끄고 색만 | 어두운 것이 조명 탓인지 텍스처 탓인지 가를 때 |
| **Display Advanced...** | 그림자·SSAO·클러스터 등 세부 | 렌더 단계별 진단 |

### 실행 중인 게임에서 — 코드로 켠다

```gdscript
# 🛑 와이어프레임은 먼저 "선 데이터를 만들라"고 켜 줘야 나온다
RenderingServer.set_debug_generate_wireframes(true)
get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
```

**열거값** (엔진에서 확인)

| 상수 | 값 |
|---|---|
| `Viewport.DEBUG_DRAW_DISABLED` | 0 |
| `Viewport.DEBUG_DRAW_UNSHADED` | 1 |
| `Viewport.DEBUG_DRAW_OVERDRAW` | 3 |
| `Viewport.DEBUG_DRAW_WIREFRAME` | **4** |

### 실제로 찍어 본 화면

기본 `BoxMesh` 하나를 네 모드로 렌더한 것이다 (`--resolution 640x640`, 헤드리스 아님).

| 모드 | 보이는 것 |
|---|---|
| Normal | 주황색 상자. 면이 3개만 보인다 |
| **Wireframe** | **각 면에 대각선이 하나씩 — 면 6장 = 삼각형 12개가 그대로 보인다** |
| Overdraw | 상자가 균일한 밝기 — 겹쳐 그린 곳이 없다는 뜻 |
| Unshaded | 조명 없이 albedo 색만 — 면 3장이 같은 색으로 평평하게 |

> **그림으로 보려면** — 이 스킬의 문서 사이트에 스크린샷과 인터랙티브 도해를 올려 두었다:
> `mesh.html` (온라인: https://thruthesky.github.io/godot/mesh.html)

---

## 12. 🛑 감김 방향(winding) — 삼각형이 안 보이면 여기부터

**직접 만든 메시가 화면에 안 나오는 원인 1위다.** 삼각형에는 앞뒷면이 있고,
**뒷면은 기본적으로 그리지 않는다**(백페이스 컬링). 앞뒤를 가르는 것은 위치가 아니라
**정점을 나열한 순서**다.

**실측** — 같은 위치에 삼각형 2개를 놓고 순서만 반대로 해서 렌더한 결과

```
왼쪽  (화면에서 시계 방향으로 감김)  → 픽셀 (1,1,1) — 보인다
오른쪽(화면에서 반시계 방향으로 감김) → 픽셀 (0,0,0) — 안 보인다
```

> ✅ **Godot 은 카메라에서 봤을 때 시계 방향(clockwise)으로 감긴 삼각형을 앞면으로 본다.**
> OpenGL 계열 문서의 "반시계 방향이 앞면"과 반대라 혼동하기 쉽다 —
> **Godot 기준은 시계 방향**이다.

| 증상 | 원인 | 고치는 법 |
|---|---|---|
| 메시가 통째로 안 보인다 | 감김 방향이 반대 | 인덱스에서 **두 번째와 세 번째 번호를 맞바꾼다** (`0,1,2` → `0,2,1`) |
| 안쪽에서만 보인다 | 같은 원인 | 위와 같다 |
| 양쪽 다 보이게 하고 싶다 | — | 머티리얼 `cull_mode = CULL_DISABLED` (🛑 비용 2배 — 나뭇잎·천에만) |
| 면은 보이는데 새까맣다 | 노멀이 없거나 반대 | `ARRAY_NORMAL` 을 넣거나 `SurfaceTool.generate_normals()` |

---

## 13. 직접 만든다 — ArrayMesh 와 SurfaceTool

| 방법 | 언제 |
|---|---|
| **`ArrayMesh` + 배열** | 정점 수가 이미 정해져 있고 **빠르게** 만들 때 (지형 청크·격자) |
| **`SurfaceTool`** | 한 정점씩 쌓으며 만들 때. `index()`·`generate_normals()`·`generate_tangents()` 를 대신 해 준다 |
| **`ImmediateMesh`** | 매 프레임 바뀌는 선·디버그 표시 |

```gdscript
# SurfaceTool — 노멀·인덱스를 알아서 만들어 준다
var st := SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)
for t in triangles:
    st.set_uv(t.uv0); st.add_vertex(t.v0)
    st.set_uv(t.uv1); st.add_vertex(t.v1)
    st.set_uv(t.uv2); st.add_vertex(t.v2)
st.index()                 # 같은 정점을 합친다 (→ 6절 실측: 6개가 4개로)
st.generate_normals()      # 노멀을 계산해 넣는다
var mesh: ArrayMesh = st.commit()
```

**메시를 읽는 쪽** — 이미 있는 메시의 정점을 꺼내 변형하는 패턴은
[openworld-3d.md](openworld-3d.md) 의 바위 생성 코드가 실제 사례다.

```gdscript
var arrays := sphere.surface_get_arrays(0)
var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
for i in v.size():
    v[i] += v[i].normalized() * randf_range(-0.05, 0.05)   # 울퉁불퉁하게
arrays[Mesh.ARRAY_VERTEX] = v
```

> 🛑 **`.glb` 로 들어온 모델의 정점을 코드로 고쳐 형상을 바로잡지 않는다.**
> 크기·자세·축·원점이 틀렸다면 **Blender 에서 원본을 고친다** — 프로젝트 절대 규칙이다
> (`CLAUDE.md` — "에셋 문제는 에셋에서 고친다").

---

## 14. 세는 법 — 무엇을 물었는지에 따라 답이 다르다

**"이 모델 몇 개짜리야?"라는 질문에는 최소 다섯 가지 답이 있다.** 상자 하나로 전부 적어 둔다.

| 물음 | 코드 | 상자의 답 |
|---|---|---|
| 눈으로 보는 꼭짓점은? | 고유 위치 좌표 수 | **8** |
| GPU 가 세는 정점은? | `surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()` | **24** |
| 인덱스는? | `...[Mesh.ARRAY_INDEX].size()` | **36** |
| 삼각형은? | `get_faces().size() / 3` | **12** |
| 모델링에서의 면은? | (도구에서 센다) | **6** |
| 드로우콜은? | `get_surface_count()` | **1** |

```gdscript
# 어떤 메시든 한 번에 세는 함수
func count(mesh: Mesh) -> Dictionary:
    var out := {"surfaces": mesh.get_surface_count(), "vertices": 0, "indices": 0}
    for i in mesh.get_surface_count():
        var a := mesh.surface_get_arrays(i)
        out["vertices"] += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
        if a[Mesh.ARRAY_INDEX] != null:
            out["indices"] += (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size()
    out["triangles"] = mesh.get_faces().size() / 3
    return out
```

---

## 15. 라리엔 3D 에서 이것이 걸리는 곳

| 상황 | 이 문서의 어느 절이 답인가 |
|---|---|
| 캐릭터 삼각형 예산을 정한다 | 5절(무엇을 세나) + [dictionary.md](dictionary.md#삼각형-수--폴리곤-수--정점-수--모델의-무게를-세는-세-가지-단위) |
| 스킨드 캐릭터가 무겁다 | 2절 — 비용이 삼각형이 아니라 **정점 수**에 비례한다 |
| 드로우콜이 예산을 넘는다 | 9절 — 서피스(머티리얼) 수를 줄인다 |
| 코드로 만든 메시가 안 보인다 | 12절 — 감김 방향 |
| 지형 청크를 코드로 만든다 | 13절 + [openworld-3d.md](openworld-3d.md) |
| 임포스터가 왜 되는지 알고 싶다 | 10절 — 형상과 배치가 분리되어 있기 때문 |
| 모델이 누워 있다·크기가 이상하다 | 🛑 **이 문서가 아니다.** `.glb` 를 Blender 에서 고친다 |

---

## 공식 문서

| 문서 | 주소 |
|---|---|
| Mesh 클래스 | https://docs.godotengine.org/en/latest/classes/class_mesh.html |
| ArrayMesh 클래스 | https://docs.godotengine.org/en/latest/classes/class_arraymesh.html |
| SurfaceTool 클래스 | https://docs.godotengine.org/en/latest/classes/class_surfacetool.html |
| MeshInstance3D 클래스 | https://docs.godotengine.org/en/latest/classes/class_meshinstance3d.html |
| Using the SurfaceTool | https://docs.godotengine.org/en/latest/tutorials/3d/procedural_geometry/surfacetool.html |
| Using ArrayMesh | https://docs.godotengine.org/en/latest/tutorials/3d/procedural_geometry/arraymesh.html |
| Procedural geometry | https://docs.godotengine.org/en/latest/tutorials/3d/procedural_geometry/index.html |
