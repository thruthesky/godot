# 성능 튜닝 플레이북 — 프레임이 떨어졌을 때 무엇을 어떤 순서로 하는가

> **이 문서는 절차서입니다.** "무엇이 느린가"를 **추측 대신 실험으로 특정하고**, 고치고, 다시 재는
> 전 과정을 담습니다. 어느 Godot 3D 프로젝트에서나 그대로 쓸 수 있게 썼고, 실측값은 사례로 표시했습니다.
>
> | | |
> |---|---|
> | **대상** | 저사양 Android(**3GB RAM**) 3D 게임. 다른 플랫폼에도 절차는 그대로 통합니다 |
> | **검증 기기 예** | SM-A125N(Galaxy A12 · PowerVR Rogue GE8320 · 720×1600 · 60Hz · Vulkan Forward Mobile) |
> | **목표** | 실기기에서 **60fps** = 프레임 하나를 **16.7ms** 안에 |
> | **판정 기준** | 개발 PC 의 숫자는 근거가 아닙니다. **실기기 · 릴리즈 빌드 · 실제 게임 흐름**의 값만 씁니다 |
>
> **역할 분담** — 왜 3GB 가 기준인지와 조명·MultiMesh·굽기 노하우는 [lowend-3gb-60fps.md](lowend-3gb-60fps.md),
> 컬링·LOD·해상도 스케일의 기능별 판정은 [lowend-culling-lod.md](lowend-culling-lod.md),
> `Performance` 모니터 API·내보내기 설정은 [performance-mobile.md](performance-mobile.md).
> **"지금 느린데 어디서부터 볼까"는 이 문서입니다.**

## 목차

- [§1. 먼저 읽을 세 가지 — 모르면 엉뚱한 곳을 고칩니다](#1)
- [§2. 진단 5단계](#2)
- [§3. 측정 장비 만들기 — 릴리즈에서 자동으로 재는 법](#3)
- [§4. 원인별 처방](#4)
- [§5. 로딩이 느릴 때](#5)
- [§6. 함정 14가지](#6)
- [§7. 체크리스트](#7)
- [§8. 실측 사례 — 20fps → 60fps, 로딩 49.5초 → 15초](#8)
- [§9. 부록 — 복사해서 쓰는 전체 코드](#9)

---

<a id="1"></a>

## §1. 🛑 먼저 읽을 세 가지 — 모르면 엉뚱한 곳을 고칩니다

### 1.1 `TIME_PROCESS`(HUD 의 `process ○○ms`)는 스크립트 시간이 **아닙니다**

**가장 많이 속는 지점입니다.** 이름과 달리 `_process()` 만 재지 않습니다.

엔진 소스 `main/main.cpp` 가 한 프레임에서 하는 일(4.7.2 기준 5059~5138행):

```
process_begin
   → main_loop->process()        ← 여기가 진짜 _process() 들
   → RenderingServer::sync()     ← "이전 프레임을 아직 그리는 중이면 기다린다"
   → RenderingServer::draw()     ← 스왑체인 획득 + 펜스 대기 = GPU 를 기다리는 구간
   → process_ticks               ← 여기까지를 합산
그리고 1초마다 그 구간의 **최댓값**을 performance->set_process_time() 으로 게시
```

`draw()` 안에서 `vkAcquireNextImageKHR(..., UINT64_MAX)` 와 `vkWaitForFences(..., UINT64_MAX)` 로
**GPU 를 무한정 기다립니다** (`servers/rendering/rendering_device.cpp:5399·8048·8219`,
`drivers/vulkan/rendering_device_driver_vulkan.cpp:4026·3054`).

| 그래서 | |
|---|---|
| **GPU 가 밀리면 그 대기가 `TIME_PROCESS` 에 찍힙니다** | 47ms 가 나와도 스크립트는 0.5ms 일 수 있습니다 |
| 이 값은 **1초 구간의 최댓값**입니다 | 평균이 아니라서 스파이크 하나에 크게 튑니다 |
| 🛑 "`TIME_PROCESS` 가 크다 → CPU 병목" 은 **틀린 추론** | 실제로 이 함정에 빠질 뻔했습니다(§8) |

**CPU 냐 GPU 냐는 §2 의 2단계(해상도 절반)로 가릅니다.** 모니터 이름으로 판단하지 마세요.

### 1.2 저사양 폰의 진짜 병목은 거의 항상 **픽셀당 셰이딩**입니다

드로우콜 21, 삼각형 4천, 메모리 여유 — 이 상태로도 **19fps** 가 나옵니다.

| 흔한 오해 | 사실 |
|---|---|
| "드로우콜이 적으니 렌더는 문제 없다" | 드로우콜은 **호출 횟수**일 뿐입니다. 삼각형 2개짜리 바닥이 화면을 덮으면 **픽셀 115만 개**(720×1600)를 셰이딩합니다 |
| "삼각형이 4천밖에 안 되는데" | 정점 비용과 픽셀 비용은 **다른 예산**입니다. 지형 20만 삼각형은 무해했지만 바닥 1장이 60→22fps 를 만들었습니다 |
| "메모리가 남으니 여유롭다" | 메모리는 **크래시**를 막는 예산이지 프레임 예산이 아닙니다 |
| "GPU 가 요즘 폰은 다 괜찮다" | PowerVR GE8320 급에서 per-pixel PBR + 하늘 라디언스 큐브맵 샘플링은 **화면을 덮는 면 하나로 예산을 다 씁니다** |

**픽셀 비용을 만드는 3대 요소** — ① 화면을 덮는 면적 ② 그 면의 셰이딩 모드(lit/unshaded)
③ 환경에서 오는 앰비언트·반사 샘플링. 셋 중 하나만 꺼도 크게 달라집니다.

### 1.3 어디서 재느냐로 숫자가 달라집니다

| 무엇 | 실측 차이 | 결론 |
|---|---|---|
| **디버그 vs 릴리즈** | 릴리즈가 빠릅니다(엔진이 최적화 빌드) | fps 판정은 **반드시 릴리즈** |
| **측정 전용 씬 vs 실제 게임 흐름** | 측정 전용 씬이 **6fps 높게** 나왔습니다(26.4 vs 19.6) | 로그인·오토로드·UI·폰트가 빠지기 때문. **실제 흐름**을 탑니다 |
| **`adb screencap` 중 vs 아닐 때** | 캡처가 그 순간 fps 를 **60→1** 로 떨어뜨립니다 | 스크린샷으로 fps 를 읽지 마세요. 숫자는 **logcat** 이 정본 |
| **셰이더 캐시 있음 vs 없음** | 로딩이 15초 vs 22초 | 사용자가 겪는 건 대개 **캐시 없는 첫 실행** |

**그래서 표준 측정 조건은 이것입니다** — *릴리즈 빌드 + 자동 로그인으로 실제 화면까지 진입 + logcat 숫자 + 충분한 예열*.
장비 만드는 법은 §3.

---

<a id="2"></a>

## §2. ★ 진단 5단계 — 이 순서를 지킵니다

> **대원칙 둘**
> ① **변수를 하나만 바꾼다** — 두 개를 동시에 바꾸면 어느 쪽이 효과였는지 영원히 모릅니다.
> ② **조건은 누적이 아니라 독립** — 매 조건 전에 기준 상태로 되돌린 뒤 그 조건만 켭니다.

### 1단계 — 실기기·릴리즈·실제 흐름에서 **재현**한다

증상을 내 손으로 재현하지 못하면, 고친 뒤에도 고쳐졌는지 알 수 없습니다.

**기록할 것** — 기준 fps · 평균 프레임 ms · p95 · `TIME_PROCESS` 최댓값 · 드로우콜 · 삼각형 · VRAM.
**2회 이상** 재서 편차를 봅니다(정상이면 ±0.3fps 안에 듭니다).

### 2단계 — 해상도를 절반으로 낮춰 **CPU/GPU 를 가른다**

가장 값싸고 확실한 갈림길입니다. 3D 렌더 해상도만 바뀌고 UI 는 그대로입니다.

```gdscript
get_viewport().scaling_3d_scale = 0.5     # 픽셀 수 1/4
```

| 결과 | 뜻 | 다음 |
|---|---|---|
| **fps 가 크게 오른다** | **GPU · 픽셀 병목** | 3단계로 — 무엇이 픽셀을 먹는지 가릅니다 |
| 거의 그대로다 | **CPU 병목** | 스크립트·물리·드로우콜 제출·본 수를 봅니다 ([lowend-3gb-60fps.md §2](lowend-3gb-60fps.md)) |

> 🛑 **이건 진단 도구이지 해결책이 아닙니다.** 해상도를 낮춰 넘기면 근본 원인이 그대로 남고,
> 콘텐츠가 늘면 다시 무너집니다. 원인을 찾아 고치면 스케일 1.0 에서 60 이 납니다.
>
> **보조 확인** — 카메라를 아무것도 없는 방향으로 돌려도 느리면 화면을 덮는 것(바닥·하늘)이 범인입니다.

### 3단계 — 조건을 하나씩 켜고 끄며 **범인을 특정한다**

**화면을 많이 덮는 것부터** 의심합니다. 권장 순서:

| 순서 | 조건 | 무엇을 확인하나 |
|---|---|---|
| 1 | 해상도 0.5배 | GPU/CPU 갈림 (2단계) |
| 2 | **바닥·지형 머티리얼만 `UNSHADED`** | 화면을 덮는 면의 셰이딩 비용 |
| 3 | 환경의 `ambient_light_source`·`reflected_light_source` 만 `DISABLED` | 하늘 라디언스 큐브맵 샘플링 비용 |
| 4 | 배경을 `BG_COLOR` 로 (하늘 리소스 제거) | `Sky` 의 매 프레임 라디언스 갱신 비용 |
| 5 | 2+4 (권고안 조합) | 실제 적용했을 때의 값 |
| 6 | 5 + 기물·캐릭터 머티리얼 `UNSHADED` | glTF PBR·양면 렌더 비용 |
| 7 | 5 + HUD/디버그 오버레이 숨김 | UI 갱신 비용 |
| 8 | 5 + 애니메이션 정지 | 스켈레톤·믹서 비용 |
| 9 | 5 재측정 | **재현성 확인** (같은 값이 나와야 신뢰할 수 있습니다) |

각 조건은 **예열 4초 + 측정 6초**, 첫 조건 전에는 **12초 예열**(셰이더 컴파일).
자동화 코드는 §9.2 에 전체가 있습니다.

### 4단계 — **원인을 확정하고 표로 남긴다**

"켜면 60, 끄면 20" 이 나오면 그것이 원인입니다. 추측을 남기지 말고 숫자로 적습니다.

```
| 조건                     | fps  | 평균 ms | 판정                     |
| 00 현재 상태             | 19.6 |  51.1  | 재현                     |
| 01 해상도 0.5배          | 44.0 |  22.7  | GPU 픽셀 병목 확정        |
| 02 바닥만 UNSHADED       | 60.0 |  16.7  | ✅ 단독으로 60 달성       |
| 03 환경 앰비언트만 끔     | 59.0 |  17.0  | ✅ 단독으로도 거의 60     |
```

**두 조건이 각각 단독으로 효과를 낼 수 있습니다.** 같은 비용(하늘 라디언스 샘플링)을 서로 다른 쪽에서
제거하기 때문입니다. 그래도 **규범대로 둘 다 고칩니다** — 하나만 고치면 나중에 다른 쪽이 되살아납니다.

### 5단계 — 고치고, **다시 재고, 화면을 눈으로 본다**

- 고친 뒤 1~3단계를 **다시 돌려** 숫자로 확인합니다.
- **스크린샷으로 화면을 봅니다.** 성능만 보다가 외관이 망가진 것을 놓치기 쉽습니다(§4.4 — 색 변화, 검게 변함).
- 수정 내역·수치·스크린샷 경로를 문서에 남깁니다.

---

<a id="3"></a>

## §3. 측정 장비 만들기 — 릴리즈에서 자동으로 재는 법

### 3.1 문제 — 릴리즈 APK 는 CLI 스크립트를 무시합니다

`godot --path . -s res://tests/x.gd` 는 **에디터·데스크톱에서만** 통합니다.
export 된 앱은 없는 경로를 줘도 오류 없이 `main_scene` 을 띄웁니다(실측).
그래서 **검증 훅을 제품 코드에 넣고 기능 태그로 켭니다.**

### 3.2 스위치 — `Autotest` 하나로 켜고 끕니다

```gdscript
## scripts/autotest.gd — class_name Autotest
## 검증 모드인가? 릴리즈는 기능 태그로, 디버그는 파일 하나로 켠다.
class_name Autotest
extends RefCounted

const CONFIG_PATH := "user://autotest.cfg"

static func enabled() -> bool:
    if OS.has_feature("autotest"):        # 릴리즈: 빌드에 박은 기능 태그
        return true
    return OS.is_debug_build() and FileAccess.file_exists(CONFIG_PATH)   # 디버그: 파일로
```

로그인 화면에서:

```gdscript
func _ready() -> void:
    ...
    if Autotest.enabled():
        _on_guest_pressed()      # 사람이 버튼을 누른 것과 같은 경로를 탄다
```

| 켜는 법 | |
|---|---|
| 릴리즈 | `export_presets.cfg` 의 `custom_features="autotest"` 로 빌드 |
| 디버그 | `adb shell "run-as <패키지> sh -c 'echo 1 > files/autotest.cfg'"` (앱 권한 필요 — §6-7) |
| 끄는 법 | 파일 삭제 / 기능 태그 없이 빌드 |

🛑 **기능 태그를 손으로 넣고 원복을 잊으면 스토어 빌드에 자동 로그인이 들어갑니다.**
아래 스크립트를 쓰면 원복까지 검증합니다.

### 3.3 빌드 — `scripts/build_autotest_release.sh` (이 스킬에 포함)

```bash
bash .claude/skills/godot/scripts/build_autotest_release.sh              # 자동 로그인 + 성능 로그
bash .claude/skills/godot/scripts/build_autotest_release.sh --sweep      # + 조건 순회 측정
bash .claude/skills/godot/scripts/build_autotest_release.sh --groundfix  # 첫 프레임 전에 바닥만 수정(로딩 A/B)
bash .claude/skills/godot/scripts/build_autotest_release.sh --fullfix    # 첫 프레임 전에 전부 수정(로딩 A/B)
```

`custom_features` 를 잠깐 바꿔 내보내고 **반드시 원복하며 원복을 검증**합니다. 산출물 이름도 따로 둡니다.

### 3.4 조건 순회 측정 노드

실제 게임 화면 안에서 조건을 독립 적용하며 fps·프레임 ms·p95·드로우콜을 `print` 로 냅니다.
**전체 코드는 §9.2** — 프로젝트에 그대로 복사해 쓰면 됩니다.

```
[PerfSweep] 02_ground_unshaded   fps= 60.0  frame avg= 16.67 p95= 16.67 max= 16.67 ms  processMax= 16.73  dc3d=8
```

붙이는 법 — HUD 나 디버그 패널의 `_ready()` 에서 조건부로 만들어 붙이면 `.tscn` 을 건드리지 않습니다:

```gdscript
if Autotest.enabled() and PerfSweep.wanted():
    var sweep := PerfSweep.new()
    sweep.name = "PerfSweep"
    add_sibling.call_deferred(sweep)
```

### 3.5 결과 회수 — 릴리즈에서는 **logcat 이 유일한 창구**입니다

```bash
adb logcat -c && adb shell am start -n <패키지>/com.godot.game.GodotAppLauncher
adb logcat -s 'godot:*' -v time | grep -E "\[PerfSweep\]|\[Login\]"
```

🛑 릴리즈 APK 는 debuggable 이 아니라 `adb shell run-as` 로 `user://` 파일을 꺼낼 수 없습니다.
JSON 저장은 디버그 빌드에서만 쓸 수 있습니다.

### 3.6 화면 확인 — 스크린샷 자동화

```bash
godot --path . --resolution 720x1600 -s res://tests/autopilot_shot.gd -- /경로/shot.png
```

전체 코드는 §9.3. **고친 뒤 반드시 눈으로 확인**하세요.

### 3.7 빌드·설치 — `scripts/install.sh` (이 스킬에 포함)

```bash
./install.sh                      # 장치 목록 → 번호 선택 → Debug/Release 선택
./install.sh <시리얼> --release   # 묻지 않고 릴리즈로
```

**성능·로딩 측정은 Release 입니다.**

---

<a id="4"></a>

## §4. 원인별 처방

### 4.1 처방표 — 위에서부터 의심합니다

| 순위 | 원인 | 증상 | 처방 | 실측 효과 |
|---|---|---|---|---|
| 1 | **화면을 덮는 면에 머티리얼이 없다** | 드로우콜·삼각형이 적은데 느리다 | 공유 `UNSHADED` 머티리얼을 물린다 (§4.3) | **19.6 → 60.0fps** |
| 2 | **환경이 하늘에서 앰비언트·반사를 가져온다** | 위와 같음 | `ambient_light_source`·`reflected_light_source` = `DISABLED`, 배경 `BG_COLOR` | **19.6 → 59.0fps** |
| 3 | **glTF 머티리얼을 그대로 쓴다** (`shading=1 cull=2`) | 로딩이 수십 초 · fps 도 낮음 | 임포트 매핑으로 `UNSHADED`+`CULL_BACK` (§4.5) | **맵 로딩 48.7 → 15.3초** |
| 4 | 광원 노드가 있다 | 전반적으로 느림 | 광원 0개. 조명은 정점 컬러에 굽는다 | 22.3 → 60fps |
| 5 | 같은 모양을 여러 노드로 반복 배치 | 드로우콜 수백~수천 | `MultiMeshInstance3D` | DC 300 → 1 |
| 6 | 스킨드 캐릭터의 본이 많다 | 캐릭터가 늘면 급락 | 본 25 → 16 | 40.3 → 60fps |
| 7 | 디버그 HUD·오버레이 | 60fps 인데 주기적 스파이크 | 측정 시 숨긴다 / 배포 시 뺀다 | processMax 27 → 16ms |
| 8 | 한 프레임에 리소스를 몰아서 로드 | 로딩 중 크래시(`SIGSEGV`) | 프레임에 나눠 읽는다 | 크래시 해소 |

4~8의 상세는 [lowend-3gb-60fps.md](lowend-3gb-60fps.md) 에 있습니다. 이 문서는 1~3을 다룹니다.

### 4.2 "머티리얼 없음"은 "가벼움"이 아닙니다

머티리얼이 없는 메시는 **엔진 기본 셰이더**로 그려집니다
(`servers/rendering/renderer_rd/forward_mobile/scene_shader_forward_mobile.cpp:860-873`):

```
ALBEDO = vec3(0.6) · ROUGHNESS = 0.8 · METALLIC = 0.2 · unshaded 아님
```

**per-pixel PBR 경로를 전부 돕니다.** 게다가 환경이 기본값이면 픽셀마다 하늘 라디언스를 샘플링합니다
(`scene_forward_mobile.glsl` 의 `!MODE_UNSHADED && !AMBIENT_LIGHT_DISABLED` 블록).
`UNSHADED` 면 그 블록이 **컴파일 단계에서 통째로 빠집니다** — 실행 시 분기가 아니라 셰이더 자체가 작아집니다.

### 4.3 머티리얼 규범 — 이 네 값이 전부입니다

```gdscript
mat.shading_mode   = BaseMaterial3D.SHADING_MODE_UNSHADED               # 0 — 픽셀 조명 계산 안 함
mat.transparency   = BaseMaterial3D.TRANSPARENCY_DISABLED               # 0 — 알파 프리패스 제거(렌더 패스 2배 방지)
mat.cull_mode      = BaseMaterial3D.CULL_BACK                           # 0 — 양면(2)이면 픽셀 2배
mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS  # 3
```

*(enum 값은 `godot --headless --doctool` 로 확인한 실제 값입니다.)*

씬 파일에서 메시에 물리는 법:

```ini
[ext_resource type="Material" path="res://materials/ground_unshaded.tres" id="1_ground"]

[sub_resource type="BoxMesh" id="BoxMesh_xxx"]
size = Vector3(64, 1, 64)
material = ExtResource("1_ground")
```

**여러 씬이 같은 `.tres` 를 참조하게 하세요** — 관리가 한 곳으로 모이고 배칭에도 유리합니다.

### 4.4 🛑 조명 관련 수정은 **한 묶음**입니다 — 하나만 하면 화면이 깨집니다

**앰비언트를 끄면 광원이 0개이므로 `lit` 머티리얼은 새까맣게 됩니다.**
바닥·기물·캐릭터가 **모두** `UNSHADED` 여야 화면이 정상입니다.

**그리고 색이 변합니다.** `lit` 일 때 보이던 색은 `albedo × 앰비언트` 의 결과이고, `UNSHADED` 는 곱하는 것이 없습니다.

| | 사례 |
|---|---|
| 수정 전 화면의 바닥 픽셀 | sRGB **(80, 92, 110)** ← `ALBEDO 0.6` 에 하늘 앰비언트가 곱해진 값 |
| `albedo_color = 0.6` 회색으로 만들면 | sRGB **(153,153,153)** — 훨씬 밝아집니다 |
| ✅ 올바른 값 | **수정 전 화면색을 그대로 albedo 에 넣습니다** → `Color(0.313725, 0.360784, 0.431373)` |

**방법** — 수정 전 스크린샷의 픽셀 색을 재고, 그 값을 `albedo_color` 에 넣습니다(눈대중 금지).
텍스처가 있는 머티리얼은 원본을 `duplicate()` 하면 색이 유지됩니다(§4.5).

### 4.5 ★ glTF 머티리얼을 고치는 **정석 경로** — 임포트 매핑

glTF 임포트 직후 실측값은 보통 `shading_mode=1(PER_PIXEL)`, `cull_mode=2(DISABLED)` 입니다.

**세 가지 방법이 있고, 아래로 갈수록 좋습니다.**

| 방법 | 장점 | 단점 |
|---|---|---|
| 런타임에 코드로 고침 | 즉시 | 매 실행 비용 · 메시당 1회 관리 필요 · 에디터에서 안 보임 |
| 씬에서 `material_override` | 간단 | **인스턴스마다** 걸어야 함 — 새로 놓을 때 빠뜨림 |
| ✅ **`.glb.import` 외부 머티리얼 매핑** | 그 모델의 **모든 인스턴스에 자동 적용** · 런타임 코드 0 · 에디터에도 반영 | 절차가 두 단계 |

**1) 원본을 복제해 네 값만 바꾼 `.tres` 를 만듭니다** (텍스처·UV·색이 유지됩니다)

```gdscript
## 헤드리스로 실행: godot --headless --path . -s res://tools/make_unshaded.gd
extends SceneTree
func _init() -> void:
    var ps: PackedScene = load("res://path/model.glb")
    var root := ps.instantiate()
    for n in root.find_children("*", "MeshInstance3D", true, false):
        var mesh: Mesh = (n as MeshInstance3D).mesh
        var src := mesh.surface_get_material(0) as BaseMaterial3D
        if src == null: continue
        print("머티리얼 이름: ", src.resource_name)     # ← 2)에서 이 이름을 씁니다
        var m := src.duplicate() as BaseMaterial3D      # 🛑 새로 만들지 말고 복제 — 텍스처를 잃지 않는다
        m.shading_mode   = BaseMaterial3D.SHADING_MODE_UNSHADED
        m.transparency   = BaseMaterial3D.TRANSPARENCY_DISABLED
        m.cull_mode      = BaseMaterial3D.CULL_BACK
        m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        ResourceSaver.save(m, "res://path/model_unshaded.tres")
        break
    root.free()
    quit()
```

**2) `.glb.import` 의 `_subresources={}` 를 이 블록으로 바꿉니다**

```ini
_subresources={
"materials": {
"<위에서 출력된 머티리얼 이름>": {
"use_external/enabled": true,
"use_external/path": "res://path/model_unshaded.tres"
}
}
}
```

> **키 이름 근거** — 엔진 소스 `editor/import/3d/resource_importer_scene.cpp:1627·1637·2302`.
> 머티리얼 이름은 `mat->get_meta("import_id", mat->get_name())` 이므로 **glb 안의 이름 그대로**여야 합니다.
> 에디터에서 하려면 Advanced Import Settings → Materials → 해당 머티리얼 → *Use External* 입니다.

**3) 재임포트하고 값이 바뀌었는지 검증합니다**

```bash
godot --headless --path . --import --quit
godot --headless --path . -s res://tools/verify_materials.gd   # §9.4
```

> ✅ **이 경로는 "`.glb` 를 Godot 에서 보정하지 않는다" 규칙과 충돌하지 않습니다.**
> 그 규칙은 **크기·자세·축·원점·본 구조**에 대한 것입니다. 셰이딩 모드는 "저사양에서 어떻게 그릴 것인가"라는
> **렌더 정책**이고, [lowend-3gb-60fps.md §7.8](lowend-3gb-60fps.md) 이 프로젝트 쪽에서 정하도록 규정합니다.
> 더 나은 정본은 `.glb` 를 `KHR_materials_unlit` 으로 재익스포트하는 것입니다(그러면 매핑도 필요 없습니다).

### 4.6 환경(Environment) 설정

```ini
[sub_resource type="Environment" id="Environment_x"]
background_mode = 1                                          # BG_COLOR
background_color = Color(0.313725, 0.360784, 0.431373, 1)    # 수정 전 화면색
ambient_light_source = 1                                     # AMBIENT_SOURCE_DISABLED
reflected_light_source = 1                                   # REFLECTION_SOURCE_DISABLED
```

`Sky`·`ProceduralSkyMaterial` 서브리소스도 **삭제**합니다. `ProceduralSky` 는
셰이더가 `LIGHT_*` 를 쓰면 `PROCESS_MODE_INCREMENTAL` 로 **매 프레임 라디언스 맵을 조금씩 갱신**하므로,
배경으로 보이지 않아도 비용이 남습니다.

*(enum: `BG_COLOR=1` · `AMBIENT_SOURCE_DISABLED=1` · `REFLECTION_SOURCE_DISABLED=1` — doctool 확인)*

---

<a id="5"></a>

## §5. 로딩이 느릴 때

**fps 와 원인이 다를 수 있습니다.** 구간을 나눠 재는 것이 먼저입니다.

### 5.1 구간을 나눕니다

| 구간 | 재는 법 |
|---|---|
| 엔진 배너 → 첫 화면 준비 | 첫 씬 `_ready()` 끝에서 `Time.get_ticks_msec()` 를 `print` |
| → 다음 씬이 트리에 들어옴 | 그 씬의 노드 `_ready()` **앞부분**에서 `print` |
| **→ 첫 프레임이 실제로 그려짐** | `_ready()` 에서 `await get_tree().process_frame` **뒤**에 `print` ← **이 값이 정본** |

두 값의 차이가 크면 **씬 로드가 아니라 렌더 준비(셰이더 컴파일)** 가 원인입니다.

### 5.2 셰이더 컴파일인지 가르는 법

**첫 프레임이 그려지기 전에** 머티리얼을 `UNSHADED` 로 바꾼 빌드와 비교합니다
(`--groundfix` / `--fullfix`). 그 구간이 짧아지면 lit 셰이더 변형 컴파일이 원인입니다.

> **실측 사례** — 맵 첫 프레임까지:
> 현재 상태 **49.5초** / 바닥만 미리 수정 **48.7초**(거의 그대로) / **바닥+기물·캐릭터+하늘까지 15.3초**.
> → 바닥만으로는 안 줄었고, **나무·캐릭터의 lit 셰이더와 `ProceduralSky` 가 33초를 먹고 있었습니다.**
> fps 는 바닥만 고쳐도 60 이 나왔지만 **로딩은 전부 고쳐야 줄었습니다.**

🛑 조건 순회(`_ready()` 의 `await` 뒤)로는 이미 늦습니다. **`await` 전에** 적용해야 그 셰이더가 컴파일되지 않습니다.

### 5.3 셰이더 캐시를 지운 첫 실행도 재세요

```bash
adb shell pm clear <패키지>     # 앱 데이터 + 셰이더 캐시 삭제 = "설치 직후 첫 실행" 재현
```

사용자가 겪는 것은 대개 이쪽입니다. (실측: 캐시 있음 15.3초 / 없음 22.2초)

### 5.4 그 밖의 로딩 비용

| 후보 | 확인 |
|---|---|
| 폰트(CJK·인도계는 수 MB) | `.tres` 폰트 폴백 목록과 파일 크기 |
| 국제화 데이터(`icudt_godot.dat`) | 약 4.8MB — TextServer Advanced 가 시작 시 로드 |
| 번역 파일 수 | `project.godot` 의 `locale/translations` |
| 오토로드 | 개수와 각각의 `_ready()` 비용 |
| 한 프레임 몰아 로드 | 프레임에 나눠 읽기([lowend §8](lowend-3gb-60fps.md)) |

---

<a id="6"></a>

## §6. 🛑 함정 14가지 — 전부 실제로 겪은 것입니다

| # | 함정 | 어떻게 피하나 |
|---|---|---|
| 1 | `TIME_PROCESS` 를 CPU 시간으로 읽는다 | §1.1 — 해상도 절반 테스트로 가릅니다 |
| 2 | `adb screencap` 으로 fps 를 읽는다 | 캡처가 fps 를 60→1 로 떨어뜨립니다. 숫자는 **logcat** |
| 3 | 로그인을 건너뛴 측정 전용 씬에서 잰다 | 실제보다 6fps 높습니다. **자동 로그인으로 실제 흐름**을 탑니다 |
| 4 | 디버그 빌드로 fps 를 판정한다 | 릴리즈로 잽니다 |
| 5 | 예열 없이 첫 구간을 잰다 | PowerVR 셰이더 컴파일로 1fps 가 찍힙니다. 시작 12초 + 조건마다 4초 |
| 6 | 조건을 누적해서 켠다 | 무엇이 효과였는지 모릅니다. **독립 적용** |
| 7 | `adb shell run-as <pkg> ... files/x` 가 "No such file" | **셸 인용 문제**입니다. `adb shell "run-as <pkg> sh -c 'echo 1 > files/x'"` 처럼 **바깥을 큰따옴표로** 묶습니다. 릴리즈(non-debuggable)에서는 아예 불가능합니다 |
| 8 | 릴리즈에서 `MEMORY_STATIC` 등이 0 | 일부 모니터는 릴리즈에서 0 입니다. fps 는 `delta` 로 직접 세세요 |
| 9 | 기능 태그를 손으로 넣고 원복을 잊는다 | `build_autotest_release.sh` 가 원복까지 검증합니다 |
| 10 | 여러 세션·사람이 한 실기기를 같이 쓴다 | 패키지명이 같아 서로의 APK 를 덮어씁니다. **점유 잠금 파일**을 두고 알립니다 |
| 11 | 인스턴스마다 머티리얼을 `duplicate()` 한다 | 셰이더가 재컴파일되어 드라이버가 죽습니다. **메시(RID)당 1회** |
| 12 | 성능만 보고 화면을 안 본다 | 앰비언트를 끄면 lit 머티리얼이 새까맣게 됩니다. **스크린샷 필수** |
| 13 | 색이 변한 것을 눈치채지 못한다 | `lit` 색 = `albedo × 앰비언트`. **수정 전 픽셀 색을 재서** albedo 에 넣습니다(§4.4) |
| 14 | 해상도 스케일로 맞추고 끝낸다 | 증상 완화입니다. 근본을 고치면 스케일 1.0 에서 60 이 납니다 |

---

<a id="7"></a>

## §7. 체크리스트 — 튜닝을 끝내기 전에

- [ ] **실기기 · 릴리즈 · 실제 게임 흐름**에서 60fps 인가 (개발 PC 아님)
- [ ] 같은 조건으로 **2회 이상 재현**했는가
- [ ] 조건을 **독립 적용**해 원인을 하나로 특정했는가
- [ ] 광원 노드가 0개인가
- [ ] 화면을 덮는 모든 면에 **머티리얼이 있고** `UNSHADED` 인가
- [ ] 환경의 `ambient_light_source`·`reflected_light_source` 가 `DISABLED` 이고 `Sky` 가 없는가
- [ ] 모든 glTF 머티리얼이 `UNSHADED` + `CULL_BACK` + `TRANSPARENCY_DISABLED` 인가
- [ ] **스크린샷으로 화면이 정상인지 눈으로 봤는가** (텍스처·색·검게 변한 곳)
- [ ] 수정 전후 **색이 달라지지 않았는가**
- [ ] 첫 프레임까지의 시간을 쟀는가 (셰이더 캐시 있음/없음 둘 다)
- [ ] 드로우콜·VRAM 이 예산 안인가
- [ ] 측정용 APK·기능 태그·검증 훅을 정리하고 `export_presets.cfg` 원복을 확인했는가
- [ ] 수치·스크린샷 경로를 문서에 남겼는가

---

<a id="8"></a>

## §8. 실측 사례 — 20fps → 60fps · 로딩 49.5초 → 15초

**환경** — 라리엔 3D · SM-A125N(3GB) · 릴리즈 빌드 · 실제 손님 로그인 → 맵 진입 · 2026-09-04

**증상** — 기물 몇 개, 캐릭터 1명, 드로우콜 21, 삼각형 4,104, 메모리 여유인데 **fps 27**(사람 관측) / **19.6**(릴리즈 측정).
HUD 의 `process 47.04ms` 때문에 CPU 병목으로 오해하기 쉬웠습니다.

| 조건 (독립 적용) | fps | 평균 ms | 판정 |
|---|---|---|---|
| 00 현재 상태 | 19.4 / 19.5 / 19.6 | 51.5 | 재현 (3회, 편차 ±0.1) |
| 01 해상도 0.5배 | 44.0 | 22.7 | **GPU 픽셀 병목 확정** |
| **02 바닥 6장만 UNSHADED** | **59.7 / 59.9 / 60.0** | 16.7 | ✅ 단독으로 60 |
| 03 환경 앰비언트·반사만 끔 | 59.0 | 17.0 | ✅ 단독으로도 거의 60 |
| 04 배경색(하늘 제거) | 59.3 | 16.9 | ✅ |
| 06 바닥 + 배경색 | 59.0~59.2 | 16.9 | 권고안 |
| 07 06 + 기물·캐릭터 UNSHADED | 59.0 | 16.9 | fps 기여 없음 · **로딩엔 결정적** |
| 08 06 + HUD 숨김 | **60.0** | 16.67 | processMax 16.0ms — 스파이크 0 |
| 09 06 + 애니 정지 | 59.2 | 16.9 | 무관 |
| 11 06 + HUD 숨김 + 해상도 0.75 | 59.3 | 16.9 | 스케일 불필요 |

**로딩(첫 프레임까지)** — 현재 49.5초 / 바닥만 미리 수정 48.7초 / **전부 수정 15.3초**(캐시 없이 22.2초).

**적용 후** — fps **57~60**(HUD 숨기면 60.0) · 드로우콜 **21 → 16** · VRAM **54.9 → 40.1MB** · 맵 로딩 **49.5 → 15초**.

**고친 것 세 가지**
1. 바닥(`BoxMesh`) 4개 씬에 공유 `UNSHADED` 머티리얼
2. `Environment` → 배경색 + 앰비언트·반사 `DISABLED`, `Sky` 삭제
3. 나무 2종·캐릭터 glTF → 임포트 매핑으로 `UNSHADED`+`CULL_BACK`

---

<a id="9"></a>

## §9. 부록 — 복사해서 쓰는 전체 코드

### 9.1 성능 HUD 에 넣을 로그 (릴리즈에서도 나오는 형태)

```gdscript
## 1초마다 성능 지표를 print 한다. 릴리즈에서 값을 회수하는 유일한 창구는 logcat 이다.
## 🛑 화면 캡처(adb screencap)는 그 순간 fps 를 떨어뜨리므로 숫자의 정본은 이 로그다.
var _log_accum := 0.0

func _process(delta: float) -> void:
    if not Autotest.enabled():
        return
    _log_accum += delta
    if _log_accum < 1.0:
        return
    _log_accum = 0.0
    print("[PerfHUD] fps=%.0f draw=%d tris=%d vram=%.1fMB process=%.2fms physics=%.2fms nodes=%d" % [
        Engine.get_frames_per_second(),
        int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
        int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
        Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
        Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,        # ← 렌더 대기 포함(§1.1)
        Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
        int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
```

### 9.2 조건 순회 측정 노드 — `perf_sweep.gd`

```gdscript
## 실제 게임 화면 안에서 조건을 하나씩 바꿔 재고 로그로 남긴다.
##
## 붙이는 법: HUD 등의 _ready() 에서
##     if Autotest.enabled() and PerfSweep.wanted():
##         var s := PerfSweep.new(); s.name = "PerfSweep"; add_sibling.call_deferred(s)
##
## 🛑 조건은 누적이 아니라 독립이다 — 매 조건 전에 기준으로 되돌린 뒤 그 변수만 켠다.
## 🛑 결과는 print 로만 낸다 — 릴리즈는 debuggable 이 아니라 user:// 파일을 회수할 수 없다.
class_name PerfSweep
extends Node

const SWEEP_FEATURE := "perfsweep"      ## 조건 순회를 켜는 기능 태그
const GROUNDFIX_FEATURE := "groundfix"  ## 첫 프레임 전에 바닥만 UNSHADED (로딩 A/B)
const FULLFIX_FEATURE := "fullfix"      ## 첫 프레임 전에 전부 수정 (로딩 A/B)

const STARTUP_WARMUP_SEC := 12.0   ## 첫 조건 전 예열 — 셰이더가 "처음 보일 때" 컴파일되므로 필수
const WARMUP_SEC := 4.0            ## 조건 전환 뒤 예열
const MEASURE_SEC := 6.0           ## 측정

const PLAN: Array[Dictionary] = [
    {"name": "00_baseline"},
    {"name": "01_scale_0.5", "scale": 0.5},
    {"name": "02_ground_unshaded", "ground": true},
    {"name": "03_env_ambient_off", "env": "amb_off"},
    {"name": "04_env_color_no_sky", "env": "color"},
    {"name": "05_ground+env_color", "ground": true, "env": "color"},
    {"name": "06_fix+props_unshaded", "ground": true, "env": "color", "props": true},
    {"name": "07_fix+hud_hidden", "ground": true, "env": "color", "hud": false},
    {"name": "08_fix+anim_off", "ground": true, "env": "color", "anim": false},
    {"name": "09_fix_again", "ground": true, "env": "color"},
]

static func wanted() -> bool:
    return OS.has_feature(SWEEP_FEATURE) or OS.has_feature(GROUNDFIX_FEATURE) or OS.has_feature(FULLFIX_FEATURE)

var _grounds: Array[MeshInstance3D] = []
var _props: Array[MeshInstance3D] = []
var _anims: Array[AnimationPlayer] = []
var _huds: Array[CanvasLayer] = []
var _world_env: WorldEnvironment
var _env_original: Environment
var _ground_mat: StandardMaterial3D
var _prop_mats := {}          ## 원 머티리얼 RID → UNSHADED 사본. 메시당 1회만 만든다(재컴파일 폭주 방지)

enum Phase { STARTUP, WARMUP, MEASURE, DONE }
var _phase := Phase.STARTUP
var _t := 0.0
var _idx := -1
var _frames := 0
var _sum := 0.0
var _deltas: PackedFloat64Array = []
var _proc_max := 0.0

func _ready() -> void:
    _ground_mat = _make_ground_material()
    var full := OS.has_feature(FULLFIX_FEATURE)
    if full or OS.has_feature(GROUNDFIX_FEATURE):
        # 🛑 await 보다 먼저 — 첫 프레임 전에 바꿔야 그 lit 셰이더가 컴파일되지 않는다
        _collect(get_tree().current_scene)
        for g in _grounds:
            g.material_override = _ground_mat
        if full:
            for p in _props:
                p.material_override = _unshaded_copy(p)
            _apply_env("color")
        print("[PerfSweep] 사전 수정 적용 (부팅 후 %dms)" % Time.get_ticks_msec())
        await get_tree().process_frame
        print("[PerfSweep] 첫 프레임 완료 — 부팅 후 %dms" % Time.get_ticks_msec())
        if not OS.has_feature(SWEEP_FEATURE):
            set_process(false)
            return
    await get_tree().process_frame
    if _grounds.is_empty():
        _collect(get_tree().current_scene)
    print("[PerfSweep] 시작 — 부팅 후 %dms · grounds=%d props=%d · 화면 %s · %s" % [
        Time.get_ticks_msec(), _grounds.size(), _props.size(),
        DisplayServer.window_get_size(), RenderingServer.get_video_adapter_name()])

func _make_ground_material() -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode = BaseMaterial3D.CULL_BACK
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    m.albedo_color = Color(0.6, 0.6, 0.6)     ## 프로젝트의 실제 바닥색으로 바꿔 쓰세요(§4.4)
    return m

## 무엇이 바닥이고 무엇이 기물인지는 프로젝트마다 다르다 — 여기 판정 규칙만 고치면 된다.
func _collect(root: Node) -> void:
    if root == null:
        return
    for n in root.find_children("*", "MeshInstance3D", true, false):
        var mi := n as MeshInstance3D
        if mi.mesh is BoxMesh or mi.mesh is PlaneMesh:
            _grounds.append(mi)
        elif mi.mesh is ArrayMesh:
            _props.append(mi)
    for n in root.find_children("*", "AnimationPlayer", true, false):
        _anims.append(n as AnimationPlayer)
    for n in root.find_children("*", "WorldEnvironment", true, false):
        _world_env = n as WorldEnvironment
        _env_original = _world_env.environment
    for n in root.find_children("*", "CanvasLayer", true, false):
        _huds.append(n as CanvasLayer)

func _process(delta: float) -> void:
    _t += delta
    match _phase:
        Phase.STARTUP:
            if _t >= STARTUP_WARMUP_SEC: _next()
        Phase.WARMUP:
            if _t >= WARMUP_SEC:
                _phase = Phase.MEASURE
                _t = 0.0; _frames = 0; _sum = 0.0; _deltas.clear(); _proc_max = 0.0
        Phase.MEASURE:
            _frames += 1
            _sum += delta
            _deltas.append(delta)
            # 🛑 릴리즈에서는 일부 모니터가 0 이다. fps 는 delta 로 직접 센다.
            _proc_max = maxf(_proc_max, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
            if _t >= MEASURE_SEC:
                _record(); _next()
        Phase.DONE:
            set_process(false)

func _next() -> void:
    _idx += 1
    if _idx >= PLAN.size():
        _phase = Phase.DONE
        _apply({"ground": true, "env": "color"})     ## 권고안 상태로 남긴다
        print("[PerfSweep] DONE")
        return
    _apply(PLAN[_idx])
    _phase = Phase.WARMUP
    _t = 0.0

## 기준 상태로 되돌린 뒤 이 조건의 변수만 켠다.
func _apply(c: Dictionary) -> void:
    get_viewport().scaling_3d_scale = float(c.get("scale", 1.0))
    for g in _grounds:
        g.material_override = _ground_mat if c.get("ground", false) else null
    for p in _props:
        p.material_override = _unshaded_copy(p) if c.get("props", false) else null
    for a in _anims:
        a.active = bool(c.get("anim", true))
    for h in _huds:
        h.visible = bool(c.get("hud", true))
    _apply_env(String(c.get("env", "")))

func _apply_env(mode: String) -> void:
    if _world_env == null or _env_original == null:
        return
    match mode:
        "amb_off":      ## 하늘은 두고 앰비언트·반사 샘플링만 끈다
            var e := _env_original.duplicate() as Environment
            e.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
            e.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
            _world_env.environment = e
        "color":        ## 배경색만 칠하고 하늘 리소스를 뗀다
            var e2 := _env_original.duplicate() as Environment
            e2.background_mode = Environment.BG_COLOR
            e2.background_color = Color(0.31, 0.36, 0.43)   ## 프로젝트 색으로
            e2.sky = null
            e2.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
            e2.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
            _world_env.environment = e2
        _:
            _world_env.environment = _env_original

## 원 머티리얼의 텍스처를 살린 UNSHADED 사본. 같은 원본이면 같은 사본을 준다(메시당 1회).
func _unshaded_copy(mi: MeshInstance3D) -> Material:
    var src := mi.get_active_material(0)
    if src == null or not (src is BaseMaterial3D):
        return _ground_mat
    var key := src.get_rid()
    if not _prop_mats.has(key):
        var m := (src as BaseMaterial3D).duplicate() as BaseMaterial3D
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
        m.cull_mode = BaseMaterial3D.CULL_BACK
        _prop_mats[key] = m
    return _prop_mats[key]

func _record() -> void:
    var sorted := _deltas.duplicate()
    sorted.sort()
    var p95 := 0.0
    var dmax := 0.0
    if sorted.size() > 0:
        p95 = sorted[mini(int(floor(sorted.size() * 0.95)), sorted.size() - 1)]
        dmax = sorted[sorted.size() - 1]
    var vp := get_viewport().get_viewport_rid()
    print("[PerfSweep] %-28s fps=%5.1f  frame avg=%6.2f p95=%6.2f max=%6.2f ms  processMax=%6.2f  dc3d=%d" % [
        PLAN[_idx]["name"], float(_frames) / maxf(_sum, 0.0001),
        _sum / maxf(_frames, 1) * 1000.0, p95 * 1000.0, dmax * 1000.0, _proc_max,
        RenderingServer.viewport_get_render_info(vp,
            RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
            RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)])
```

### 9.3 스크린샷 자동화 — `autopilot_shot.gd`

```gdscript
## 씬을 창으로 열어 스크린샷을 저장한다. 성능을 고친 뒤 화면이 깨지지 않았는지 눈으로 확인하는 용도.
##   godot --path . --resolution 720x1600 -s res://tests/autopilot_shot.gd -- /경로/shot.png
extends SceneTree

func _init() -> void:
    var out := "res://.godot/shot.png"
    var args := OS.get_cmdline_user_args()
    if args.size() > 0:
        out = args[0]
    await change_scene_to_file("res://scenes/main/main.tscn")   ## 프로젝트 씬 경로로
    for i in 180:                       ## 셰이더 컴파일·리소스 로드가 끝날 때까지 넉넉히
        await process_frame
    await RenderingServer.frame_post_draw
    var img := root.get_texture().get_image()
    print("[Shot] ", error_string(img.save_png(out)), " → ", out)
    quit()
```

### 9.4 머티리얼 전수 검사 — `verify_materials.gd`

```gdscript
## 씬 안의 모든 메시가 규범(UNSHADED · CULL_BACK · TRANSPARENCY_DISABLED)을 지키는지 숫자로 판정한다.
## 눈으로 확인하지 않고 종료 코드로 판정하므로 CI 에도 넣을 수 있다.
extends SceneTree

func _init() -> void:
    var root := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
    var bad := 0
    for n in root.find_children("*", "MeshInstance3D", true, false):
        var mesh: Mesh = (n as MeshInstance3D).mesh
        for s in mesh.get_surface_count():
            var mat := mesh.surface_get_material(s) as BaseMaterial3D
            if mat == null:
                print("[X] 머티리얼 없음 — ", n.get_path(), " (엔진 기본 lit 셰이더로 그려진다)")
                bad += 1
                continue
            var ok: bool = mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED \
                and mat.cull_mode == BaseMaterial3D.CULL_BACK \
                and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
            if not ok:
                bad += 1
            print("[%s] '%s' shading=%d cull=%d transp=%d" % [
                "OK" if ok else "X ", mat.resource_name, mat.shading_mode, mat.cull_mode, mat.transparency])
    var we: WorldEnvironment = root.find_child("WorldEnvironment", true, false)
    if we != null:
        var e := we.environment
        print("환경: bg=%d sky=%s ambient=%d reflected=%d" % [
            e.background_mode, "있음" if e.sky else "없음",
            e.ambient_light_source, e.reflected_light_source])
    print("위반 ", bad, "건")
    root.free()
    quit(1 if bad > 0 else 0)
```

### 9.5 스크린샷의 픽셀 색 재기 (수정 전후 비교용)

수정 전 화면색을 알아야 `albedo_color` 를 정확히 맞출 수 있습니다(§4.4).
Python 표준 라이브러리만으로 PNG 픽셀을 읽는 스크립트가
[`scripts/png_pixel.py`](../scripts/png_pixel.py) 에 있습니다.

```bash
python3 .claude/skills/godot/scripts/png_pixel.py before.png 360 1000 120 900
#   before.png (360,1000) RGB (80, 92, 110)  → Godot Color(0.313725, 0.360784, 0.431373)
```
