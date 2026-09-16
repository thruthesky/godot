# 렌더러 CPU 최적화 — 고도 엔진 팀이 실제로 하는 법

> **출처** — Godot 공식 블로그 [Optimizing CPU-side Rendering Code](https://godotengine.org/article/rendering-cpu-optimizations/)
> (Clay John · 2026-09-15 · Progress Report). **이 문서는 그 글의 번역·정리에 라리엔 3D 실측을 덧붙인 것이다.**
> 원문에 없는 내용은 절마다 **[라리엔]** 으로 표시했다 — 섞어 읽지 않는다.
>
> | | |
> |---|---|
> | **이 문서로 오는 상황** | "프로파일러 화면을 어떻게 읽나" · "최적화를 어떤 순서로 하나" · "매 프레임 메시를 다시 만드는데 괜찮나" · "CPU 를 줄여야 하나 GPU 를 줄여야 하나" |
> | **원문이 말하는 것** | 엔진 개발자가 **렌더러의 CPU 코드**를 최적화하는 과정. 방법론 5단계 + 실제 사례 2건 |
> | **원문이 말하지 않는 것** | GPU·셰이더 최적화, 게임 코드(GDScript) 최적화 |
>
> **역할 분담** — **"우리 게임 프레임이 떨어졌다"** 는 [perf-tuning-playbook.md](perf-tuning-playbook.md)(진단 5단계·측정 장비·원인별 처방)가 정본이다.
> 이 문서는 그 위층 — **"최적화라는 작업 자체를 어떤 사고로 하는가"** 와 **엔진 쪽 사례**를 담는다.
> 저사양 판정은 [lowend-3gb-60fps.md](lowend-3gb-60fps.md) · 기능별 컬링/LOD 는 [lowend-culling-lod.md](lowend-culling-lod.md).

## 목차

- [§1. CPU 와 GPU — 느린 쪽이 프레임을 정한다](#1)
- [§2. 최적화 5단계 — 원문의 방법론](#2)
- [§3. 프로파일러 고르기 — 내장 2종 · Tracy · 외부 샘플링](#3)
- [§4. 프로파일 화면을 읽는 법](#4)
- [§5. 사례 1 — Polygon2D 가 매 프레임 메시를 새로 만들고 있었다](#5)
- [§6. 사례 2 — 셰이더 트랜스파일에서 로딩 11초를 되찾다](#6)
- [§7. 가져갈 규칙 7가지](#7)

---

<a id="1"></a>

## §1. CPU 와 GPU — 느린 쪽이 프레임을 정한다

원문의 전제. **최종 성능은 두 프로세서 중 느린 쪽이 결정한다.**

> "No amount of CPU optimization will save you from inefficient shaders."
> — 셰이더가 비효율이면 CPU 를 아무리 깎아도 소용없다.

그래서 렌더러를 쓸 때는 **늘 한쪽을 주고 한쪽을 얻는 거래**를 한다.

| 기법 | GPU | CPU | 왜 이득인가 |
|---|---|---|---|
| **2D 배칭** | 조금 손해 | **크게 이득** | 2D 게임은 GPU 보다 **CPU 병목이 먼저** 온다 → 대체로 순이득 |
| **오클루전 컬링(3D)** | **이득** | 손해(CPU 에서 계산) | 3D 게임은 **GPU 병목이 잦다** → CPU 를 써서 GPU 부담을 던다 |

그리고 어느 쪽으로 기울든 **엔진을 최적화하는 것은 언제나 이득**이다 — 게임 개발자가 쓸 CPU·GPU 여유가 그만큼 늘고,
전력이 제한된 기기에서는 **배터리**가 절약된다.

**[라리엔]** 우리 실측도 같은 자리에 닿는다 — A12(PowerVR GE8320)에서 드로우콜 21·삼각형 4,104·메모리 여유인데 fps 19.6 이었고,
**범인은 3D 장면이 아니라 HUD 였다**(HUD 를 숨기면 60.0) — [perf-tuning-playbook.md §8](perf-tuning-playbook.md).
**병목이 아닌 축을 줄이면 프레임은 1도 오르지 않는다** — [lowend-culling-lod.md §1](lowend-culling-lod.md).

🛑 **`TIME_PROCESS` 가 크다고 CPU 병목이라고 단정하지 않는다.** Godot 의 `TIME_PROCESS` 는
`RenderingServer::draw()` 안의 **GPU 대기(펜스·스왑체인)까지 합산**한 1초 구간 최댓값이다 —
근거와 엔진 소스 줄 번호는 [perf-tuning-playbook.md §1.1](perf-tuning-playbook.md).

---

<a id="2"></a>

## §2. 최적화 5단계 — 원문의 방법론

```
① 병목/핫스팟을 찾는다  →  ② 왜 거기가 병목인지 이해한다  →  ③ 해법을 조사한다
                        →  ④ 다시 측정한다              →  ⑤ 반복한다
```

| 단계 | 원문이 말하는 핵심 |
|---|---|
| **① 찾기** | **가장 어려운 단계.** 어디가 느린지 보이는 순간 이유까지 바로 아는 경우가 많다 — 뜨거운 루프에서 비싼 API 를 부르거나, 디버그 코드를 지우지 않았거나 |
| **② 이해** | 최적화는 결국 **"할 필요 없는 일을 하지 않는다"** 로 귀결된다. 주변 코드와 시스템을 알아야 무엇이 불필요한지 가려진다 |
| **③ 조사** | 해법은 대개 자명하지만 늘 그렇지는 않다. 무거운 루프를 보면 "계산을 줄이자" 싶지만, 진짜 원인이 **메모리 대역폭**이면 **자료 구조를 바꾸는 쪽**이 더 크게 이긴다 |
| **④ 재측정** | 🛑 **반드시 다시 잰다.** 빠를 거라 생각한 변경이 느려지는 일이 흔하다 |
| **⑤ 반복** | 한 병목을 없애면 다음 병목이 드러난다 |

### 🛑 ④ 가 왜 절대 규칙인가 — 직관이 틀리는 두 예 (원문)

| 직관 | 실제 |
|---|---|
| "for 루프에 분기를 넣어 계산을 건너뛰면 항상 빨라진다" | 많은 경우 **컴파일러의 벡터화가 막혀** 더 느려진다 |
| "값을 캐시해 두 번 계산하지 않으면 빨라진다" | 그 경로의 병목이 **메모리 읽기**라면 캐시가 더 느리다 — **두 번 계산하는 편이 나았다** |

> "Unless you are an absolute C++ compiler genius, you likely can't guess the exact result of your code change on performance."

**[라리엔]** 이 5단계는 우리 [perf-tuning-playbook.md §2 진단 5단계](perf-tuning-playbook.md)와 층이 다르다.

| | 원문 5단계 | 라리엔 진단 5단계 |
|---|---|---|
| 대상 | **엔진 C++ 코드** | **게임 씬·스크립트·에셋** |
| 도구 | 외부 샘플링 프로파일러 | 실기기 릴리스 빌드 + 자체 계측 로그 |
| 관계 | **사고 절차** | **그 절차를 우리 기기에 맞춰 구체화한 것** |

---

<a id="3"></a>

## §3. 프로파일러 고르기 — 내장 2종 · Tracy · 외부 샘플링

| 도구 | 무엇을 재나 | 언제 |
|---|---|---|
| **에디터 내장 — GDScript 프로파일러** | 게임 스크립트 함수별 시간 | **게임 코드**가 느릴 때 |
| **에디터 내장 — 렌더러 프로파일러** | 렌더링 전용 통계 | 그리는 쪽이 의심될 때 |
| **Tracy** (엔진을 Tracy 지원으로 빌드) | **추적(tracing)** — 표시해 둔 구간을 빠짐없이 기록 | 엔진 코드를 직접 건드릴 때. [공식 문서](https://docs.godotengine.org/en/stable/engine_details/development/profiling/tracy.html) |
| **외부 샘플링 프로파일러** — 원문 필자는 [Superluminal](https://superluminal.eu/) | 실행 중인 Godot 프로세스에 **붙어서** 주기적으로 스택을 샘플링 | **엔진 코드 자체**를 최적화할 때. Superluminal 은 [Linux 도 지원](https://superluminal.eu/applications/linux/) |

🛑 **엔진 코드를 최적화하려면 외부 프로파일러가 필요하다** — 내장 프로파일러 두 개로는 엔진 내부가 보이지 않는다.

**[라리엔]** 우리는 실기기 릴리스 빌드가 판정 기준이라 외부 프로파일러를 붙이지 않는다.
대신 **자체 계측**을 쓴다 — `BootProfile` 의 `[Boot] … [fNN]` 프레임 번호 로그,
`Performance` 모니터 수집, `adb logcat -d` 버퍼 폴링. 절차와 복사용 코드는
[perf-tuning-playbook.md §3](perf-tuning-playbook.md), 모니터 API 는 [performance-mobile.md](performance-mobile.md).
🛑 `BootProfile` 은 **디버그 빌드에서만** 찍힌다 — 릴리스에서 `[Boot]` 0줄은 정상이다.

---

<a id="4"></a>

## §4. 프로파일 화면을 읽는 법

원문이 스크린샷으로 보여 주는 네 가지 화면. **어떤 프로파일러를 쓰든 이 네 가지는 같다.**

| 화면 | 무엇을 알려 주나 | 어떻게 쓰나 |
|---|---|---|
| **타임라인** | 프레임 하나 안에서 **언제 무엇이 도는가** | 한 프레임을 확대해 시간을 큰 덩어리로 쪼갠다 |
| **콜 그래프** | 고른 함수 안의 호출을 **비싼 순서로** 정렬 | 덩어리 안에서 범인 함수를 찍는다 |
| **소스·디스어셈블** | **어느 줄**이 시간을 먹는가 | 함수 안에서 줄 단위로 확정한다 |
| **스레드 뷰** | 🟩 초록 = 일하는 중(막대 높이 = 얼마나 열심히) · 🟥 빨강 = **무언가를 기다리며 멈춘 중** | **갭(빈 구간)** 을 찾는다 — 갭은 "이론상 걸릴 시간보다 오래 걸리고 있다"는 신호 |

> **갭이 왜 중요한가** — 로딩처럼 멀티스레드로 도는 구간의 이상적인 모습은 **모든 코어가 꽉 찬 상태**다.
> 스레드가 비어 있다면 그만큼이 순수한 낭비다(§6).

---

<a id="5"></a>

## §5. 사례 1 — Polygon2D 가 매 프레임 메시를 새로 만들고 있었다

### 5.1 어디서 시작했나

게임 [Heidi's Legacy: Mountains Calling](https://store.steampowered.com/app/3589430/Heidis_Legacy_Mountains_Calling/) 개발자가
**"애니메이션 캐릭터 20개쯤부터 프레임이 무너진다"** 고 제보. 구조는 이랬다.

```
AnimationPlayer → Polygon2D 의 정점을 애니메이션 → Viewport 에 그리고 → Sprite3D 로 3D 안에 표시
```

특이하긴 해도 그 자체가 문제될 구조는 아니다. **그래서 프로파일러를 켰다.**

### 5.2 프레임 하나를 쪼개 보니 (Ryzen 5 9600X · 최적화 전)

| 구간 | 시간 | 판정 |
|---|---|---|
| `AnimationMixer` | **4.6 ms** | 바라던 것보다는 느리지만, 정점마다 트랙이 있으니 아주 뜻밖은 아니다 |
| **`Polygon2D::_notification()`** | **15.7 ms** | 🛑 **여기가 이상하다** |
| 씬 그리기 | **11.7 ms** | 이 중 정점 배열 **생성 3.3 ms · 해제 5.0 ms** → 실제 렌더링은 **3.4 ms 뿐** |

고수준 개요만으로 두 가지가 확정된다.

1. **Polygon2D 가 예상 밖의 일을 하고 있다**
2. 그 일 때문에 **정점 배열이 매 프레임 만들어지고 버려진다**

콜 그래프로 내려가니 대부분의 시간이 **새 서피스 추가 + 이전 서피스 해제**였고,
소스 패널이 가리킨 곳은 **Polygon2D 의 내부 메시를 만드는 코드**였다.
정점이 매 프레임 CPU 에서 바뀌니 **메시를 매 프레임 다시 만들고 있었던 것**이다.

### 5.3 해법 — 정점 수가 그대로면 버퍼만 덮어쓴다

Godot 은 **정점 데이터를 직접 갱신하는 저수준 API** 를 노출한다.
**"이전 메시 해제 → 새로 할당 → 업로드"** 대신 **"기존 메시에 업로드"** 만 하면 된다.

실제 [PR #117334](https://github.com/godotengine/godot/pull/117334)(머지됨 · 34줄 추가 · 파일 2개)의 핵심:

```cpp
// 이전: 매 프레임 지우고 다시 만든다
RS::get_singleton()->mesh_clear(mesh);
...
RS::get_singleton()->mesh_add_surface(mesh, sd);

// 이후: "모양이 바뀌었을 때"만 다시 만들고, 아니면 버퍼만 덮어쓴다
bool needs_clear  = len != last_len;                       // 정점 수가 바뀜
     needs_clear |= index_array.size() != last_index_count; // 인덱스 수가 바뀜
     needs_clear |= has_uv != last_has_uv;                  // UV 유무가 바뀜
     needs_clear |= has_color != last_has_color;            // 색 유무가 바뀜
     needs_clear |= has_bones || has_bones != last_has_bones; // 본이 붙음

if (needs_clear) {
    RS::get_singleton()->mesh_clear(mesh);
    RS::get_singleton()->mesh_add_surface(mesh, sd);
} else {
    RS::get_singleton()->mesh_surface_update_vertex_region(mesh, 0, 0, sd.vertex_data);
    if (has_uv || has_color) {
        RS::get_singleton()->mesh_surface_update_attribute_region(mesh, 0, 0, sd.attribute_data);
    }
    RS::get_singleton()->mesh_surface_update_index_region(mesh, 0, 0, sd.index_data);
}
```

**PR 작업의 대부분은 "어느 경우에 갱신으로 되고 어느 경우에 재생성이 필요한가"를 가려내는 일**이었다.

### 5.4 결과

| | 전 | 후 |
|---|---|---|
| 프레임 | **35 ms** | **13 ms** |
| 필자 기기 FPS | **28** | **83** |
| PR 본문의 재현 프로젝트 ①([#115476](https://github.com/godotengine/godot/issues/115476)) | 33 FPS | **101 FPS** |
| PR 본문의 재현 프로젝트 ②([#74540](https://github.com/godotengine/godot/issues/74540)) | 80 오브젝트 | **220 오브젝트** |

최적화 후 프레임 구성은 렌더링 50% · 애니메이션 30% · Polygon2D 갱신 20%.

### 5.5 🛑 여기서 **멈춘** 이유 — 원문이 강조하는 절제

더 깎을 여지는 있다. 지금은 정점 하나만 움직여도 **버퍼 전체**를 다시 올린다 → **바뀐 구간만** 올리면 된다.
그런데 하지 않았다.

> "to properly optimize something you need to be able to test your optimization!
> If you don't have a test case, you can't do an optimization properly."

- 이 게임은 **매 프레임 모든 정점**이 움직인다 → 부분 갱신에 필요한 추적 비용이 **순손해**가 될 가능성이 크다
- 부분 갱신으로 이득을 볼 **실제 씬이 있어야** 그 최적화를 제대로 검증할 수 있다

**작고 안전한 최적화로 28 → 83 FPS 를 얻었으니 지금은 충분하다** — 이것이 원문의 결론이다.

### 5.6 **[라리엔]** 이 API 가 GDScript 에서 되는가 — 4.7.2 실측

`RenderingServer` 는 GDScript 에 그대로 열려 있다. `--headless` 로 `has_method()` 를 확인한 결과:

| API | `RenderingServer` | `ArrayMesh` |
|---|---|---|
| `mesh_surface_update_vertex_region` / `surface_update_vertex_region` | ✅ | ✅ |
| `mesh_surface_update_attribute_region` / `surface_update_attribute_region` | ✅ | ✅ |
| `mesh_surface_update_index_region` / `surface_update_index_region` | ✅ | 🛑 **없다** |

> 실측: `Godot 4.7.2-stable` · `godot --headless -s` 로 `RenderingServer.has_method(...)` · `ArrayMesh.new().has_method(...)`.
> **인덱스 구간 갱신은 `RenderingServer` 쪽에만 있다** — `ArrayMesh` 만 보고 "없는 기능" 이라고 판단하지 않는다.

**우리 코드에 이 사례가 그대로 있지는 않다.** 라리엔 3D 에는 `Polygon2D` 가 없고,
매 프레임 메시를 다시 만드는 경로도 쓰지 않는다. 가져갈 것은 **원리 쪽**이다.

| 라리엔 규칙 | 같은 원리 |
|---|---|
| **기물의 움직임은 구운 프레임 메시로 한다**(분수 방식 · 기물 `vertex()` 셰이더 금지) | 매 프레임 지오메트리를 만들지 않는다 |
| **MultiMesh 는 `buffer` 에 직접 대입**한다 — 헤드리스 검사에서 `set_instance_transform` 의 변환이 버려지는 것을 실측했다 | 인스턴스마다 API 를 부르는 대신 **버퍼 한 번** |
| 캔버스는 **`draw_line` 만** 쓴다 — `draw_polyline`·`draw_colored_polygon` 은 **도형마다 1 드로우콜** | 명령 종류가 섞이면 배칭이 끊긴다(§1 의 2D 배칭) |

---

<a id="6"></a>

## §6. 사례 2 — 셰이더 트랜스파일에서 로딩 11초를 되찾다

### 6.1 배경 — D3D12 에서 셰이더가 거치는 4단계

Godot 이 Direct3D 12 백엔드에서 셰이더를 컴파일하는 경로([관련 글](https://godotengine.org/article/d3d12-adventures-in-shaderland/)):

```
GDShader ──(내장 컴파일러)──▶ GLSL ──(GLSLang)──▶ SPIR-V ──(Mesa NIR 변환기)──▶ DXIL ──▶ GPU 드라이버
                                                        ▲
                                              🛑 여기가 압도적으로 느리다
```

Vulkan 은 SPIR-V 를 **그대로** 쓰므로 이 단계가 없다 → 그래서 **Vulkan 과 D3D12 의 로딩 시간 차이**가 체감될 만큼 났다.

### 6.2 프로파일이 보여 준 것 — "빨간 구간"

Asilkan 이 Superluminal 로 추적을 뜨자, 멀티스레드로 도는데도 **몇 개 스레드만 일하는 큰 갭**이 보였다.
확대해 보니 갭의 정체는 —

> **모든 스레드가 OS 에 힙 메모리를 더 달라고 요청하며 서로를 기다리고 있었다.**

작업 자체는 잘 병렬화돼 있었지만, **전역 힙 하나**에서 자주 할당을 받느라 스레드들이 줄을 섰다.

### 6.3 해법과 결과

**스레드마다 자기 힙을 준다** — OS 에 자주 손 벌리지 않고 자기 힙에서 할당한다.

| | 결과 |
|---|---|
| 스레드 뷰 | 갭이 크게 줄고 코어가 채워졌다 |
| TPS 데모 로딩 | **11초 단축** — 그 11초는 CPU 가 **아무 일도 못 하고 멈춰 있던 순수한 낭비**였다 |

### 6.4 **[라리엔]** 같은 모양의 함정을 우리도 만났다

"일은 병렬로 나눴는데 서로를 기다린다" 는 패턴은 엔진 밖에서도 그대로 나온다.

| 우리 사례 | 무엇이 기다리게 했나 |
|---|---|
| **A12 는 스레드 로드가 메인 스레드를 굶긴다** — 선행 로드를 넣어도 지연이 옮겨갈 뿐이었다 | 코어가 적은 기기에서 워커가 메인의 몫을 가져간다 |
| **86MB 팩의 SHA-256 검증이 한 프레임을 1초 잡아먹었다** → 워커로 옮겼다 | `PackedData` 에 락이 없고 해시가 소프트웨어 구현 |
| **헤드리스/스레드 메시 로드에서 RID 손상** — 30회 중 4회 크래시 | 스레드 로드 자체가 안전하지 않은 경로였다 |

🛑 **결론은 원문과 같다** — 스레드를 늘리기 전에 **"지금 스레드들이 무엇을 기다리는가"** 를 먼저 본다.

---

<a id="7"></a>

## §7. 가져갈 규칙 7가지

| # | 규칙 | 근거 |
|---|---|---|
| 1 | **느린 쪽이 프레임을 정한다** — 셰이더가 비효율이면 CPU 최적화로 구할 수 없다 | §1 |
| 2 | **병목을 찾기 전에 고치지 않는다** — 찾기가 가장 어려운 단계다 | §2 ① |
| 3 | **최적화 = 할 필요 없는 일을 안 하는 것** — 매 프레임 재생성·재할당부터 의심한다 | §2 ②, §5 |
| 4 | 🛑 **반드시 재측정한다** — 분기 추가가 벡터화를 막고, 캐시가 메모리 병목을 악화시킨다 | §2 ④ |
| 5 | **테스트 케이스 없는 최적화는 하지 않는다** — 검증할 씬이 없으면 제대로 못 한다 | §5.5 |
| 6 | **작고 안전한 이득으로 충분하면 거기서 멈춘다** — 28 → 83 FPS 면 됐다 | §5.5 |
| 7 | **스레드 갭(빨간 구간)은 순수한 낭비다** — 병렬화보다 대기 원인을 먼저 본다 | §6 |

> **[라리엔] 우리 판정 기준은 그대로다** — 개발 PC 의 숫자는 근거가 아니다.
> **실기기 · 릴리스 빌드 · 실제 게임 흐름**의 값만 쓴다([perf-tuning-playbook.md](perf-tuning-playbook.md)).
> 실기기 확인 순서는 **SM-A17 → SM-A15 → SM-A12**.
