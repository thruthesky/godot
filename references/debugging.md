# 디버깅 — 실행 중인 게임 안을 들여다보는 법

**코드가 "돌긴 도는데 이상하다" 일 때 무엇을 열어 보는가**를 담는다. 공식 문서 Scripting → **Debug**
6편(Overview of debugging tools · Output panel · Debugger panel · The Profiler · Using the ObjectDB
profiler · Custom performance monitors), **Troubleshooting**, Platform → Android → **Resolving crashes on
Android**, Navigation → **Navigation debug tools** 에 대응한다.

이 스킬의 다른 문서와 역할이 나뉜다.

| 문서 | 언제 |
|---|---|
| [lsp.md](lsp.md) | **실행하기 전** — 문법·타입 오류를 LSP 로 잡는다. 이 스킬의 필수 단계 |
| **이 문서** | **실행한 뒤** — 오류 메시지·실행 중 노드 상태·흐름·성능·실기기 |
| [ai-tooling.md](ai-tooling.md) | AI 가 에디터·게임을 관찰하는 채널(MCP·DAP) |
| [performance-mobile.md §1~3](performance-mobile.md) | 성능 병목을 **측정으로** 가르는 절차와 디버그 오버레이 — 여기서는 프로파일러 **UI** 만 |

값·메뉴 이름은 **4.7.2.stable** 에서 확인한 것이다.

## 목차

| 절 | 내용 |
|---|---|
| [§1](#1-핵심-개념--문제를-찾는-순서) | 핵심 개념 — 문제를 찾는 순서 |
| [§2](#2-output-패널--print-가-가는-곳) | Output 패널 — `print()` 가 가는 곳 |
| [§3](#3-debugger-패널--탭-하나하나) | Debugger 패널 — 탭 하나하나 |
| [§4](#4-remote-씬-트리--실행-중인-노드를-본다) | ★ Remote 씬 트리 — 실행 중인 노드를 본다 |
| [§5](#5-오류-메시지-읽는-법) | ★ 오류 메시지 읽는 법 — 진짜 원인은 대개 한 줄 위에 있다 |
| [§6](#6-debug-메뉴--실행-옵션) | Debug 메뉴 — 실행 옵션 |
| [§7](#7-프로파일러--어느-함수가-느린가) | 프로파일러 — 어느 함수가 느린가 |
| [§8](#8-objectdb-프로파일러--메모리-누수46) | ObjectDB 프로파일러 — 메모리 누수(4.6+) |
| [§9](#9-커스텀-모니터--내-숫자를-그래프로) | 커스텀 모니터 — 내 숫자를 그래프로 |
| [§10](#10-실기기-원격-디버그와-android-크래시-심볼화) | 실기기 원격 디버그와 Android 크래시 심볼화 |
| [§11](#11-공식-troubleshooting--에디터가-이상할-때) | 공식 Troubleshooting — 에디터가 이상할 때 |
| [§12](#12-내비게이션-디버그) | 내비게이션 디버그 |
| [§13](#13-자주-하는-실수) | 자주 하는 실수 |
| [공식 문서](#공식-문서) | |

---

## 1. 핵심 개념 — 문제를 찾는 순서

**싼 것부터 연다.** 위쪽이 빠르고 아래로 갈수록 무겁다. SKILL.md "문제를 진단할 때" 표의 상세판이다.

| 순서 | 증상 | 어디 | 절 |
|---|---|---|---|
| 0 | 코드를 고쳤다 | **LSP 진단** — 실행 전에 문법·타입·경고 | [lsp.md](lsp.md) |
| 1 | 실행했더니 빨간 글자 | **Output** / **Debugger › Errors** | §2 · §5 |
| 2 | 오류는 없는데 화면이 다르다 (안 보인다·안 움직인다) | **Remote 씬 트리** — 노드가 있나·`visible`·`position` | §4 |
| 3 | 값이 어디서 바뀌는지 모르겠다 | **브레이크포인트** + Stack Trace + Evaluator | §3 |
| 4 | 느리다 | **Profiler / Visual Profiler / Monitors** | §7 · [performance-mobile.md](performance-mobile.md) |
| 5 | 메모리가 는다 | **ObjectDB 프로파일러** · 고아 노드 | §8 |
| 6 | 에디터에서는 되는데 폰에서만 안 된다 | **원격 디버그** · `logcat` · 크래시 심볼화 | §10 |
| 7 | 에디터 자체가 이상하다 | 공식 Troubleshooting | §11 |

> 🛑 **코드만 읽고 런타임을 단정하지 않는다.** "이럴 리가 없는데" 는 대개 Remote 씬 트리 한 번이면 끝난다.

---

## 2. Output 패널 — `print()` 가 가는 곳

하단 패널 **Output**. 프로젝트를 실행하면 자동으로 열린다(Editor Settings › Run › Bottom Panel › Action on Play).

| 색 | 종류 | 무엇 |
|---|---|---|
| 흰/검 | **Log** | `print()` |
| 🔴 빨강 | **Error** | 프로젝트·에디터 오류 |
| 🟡 노랑 | **Warning** | 경고 — 실패는 아니지만 봐야 한다 |
| 회색 | **Editor** | 에디터 자신의 메시지(undo/redo 등) |

오른쪽 버튼으로 종류를 끄고 켜고, 아래 **Filter Messages** 로 글자를 거른다. 실행할 때마다 지워지는 것이
기본이다(Run › Output › Always Clear Output on Play).

### 무엇으로 찍나

| 함수 | 언제 |
|---|---|
| `print(a, b)` | 기본. 인자를 붙여 찍는다. `prints()` 는 공백, `printt()` 는 탭으로 |
| `print_rich("[color=red]x[/color]")` | BBCode 색·굵기 — 터미널에서도 ANSI 로 나온다 |
| **`push_error("…")`** | 🛑 **오류로 기록** — 실행 중에는 Output 이 아니라 **Debugger › Errors 탭**에 뜬다. 스택도 남는다 |
| `push_warning("…")` | 경고로 기록 — 마찬가지로 Errors 탭 |
| `print_debug("…")` | `print` + **호출 위치**(파일:줄). 디버그 빌드에서만 |
| `print_stack()` | 여기까지의 **스택 트레이스** — "누가 이 함수를 불렀나" |
| `print_tree()` / `print_tree_pretty()` | 이 노드 아래 **씬 트리**를 찍는다 — 코드로 만든 구조 확인 |
| `print_verbose()` | `--verbose` 로 실행했을 때만 |
| `printerr()` / `printraw()` | stderr 로 / 줄바꿈 없이(Output 에는 안 뜬다). 대개 `push_error` 가 낫다 |

> 🔑 **`push_error` 를 쓴다.** `print("오류!")` 는 로그에 묻히지만 `push_error` 는 빨갛게 Errors 탭에 모이고,
> **[lsp.md](lsp.md) 의 진단과 같은 자리**에서 본다. 이 스킬의 코드 예제가 전부 `push_error` 인 이유다.

---

## 3. Debugger 패널 — 탭 하나하나

하단 패널 **Debugger**. 탭이 아홉이다.

| 탭 | 무엇 | 언제 |
|---|---|---|
| **Stack Trace** | 브레이크포인트·오류에서 멈췄을 때 **호출 사슬**과 변수 값. 스크립트 편집기에 초록 화살표가 멈춘 줄을 가리킨다 | §5 |
| **Errors** | `push_error`·엔진 오류·경고가 쌓이는 곳. **Copy Error** 로 복사해 질문에 붙인다 | §5 |
| **Evaluator** | 🔑 멈춘 상태에서 **식을 입력해 값을 본다**(REPL). `counter * 2`, `text.to_upper()`, `sqrt(delta)`. 멤버·지역 변수 다 된다. 실행 중에는 입력이 잠긴다 — 먼저 멈춰야 한다 | §5 |
| **Profiler** | 함수별 시간 | §7 |
| **Visual Profiler** | 렌더링의 CPU/GPU 시간 (스크립트·물리는 **안 잡힌다** — Profiler 로) | §7 |
| **Network Profiler** | 🛑 **고수준 멀티플레이어 API 전용** — 라리엔의 UDP 는 여기 안 잡힌다 | [networking-lowlevel.md](networking-lowlevel.md) |
| **Monitors** | FPS·메모리·노드 수·드로우콜 그래프. 안 열어 놔도 기록되다가 열면 보인다 | §9 · [performance-mobile.md](performance-mobile.md) |
| **Video RAM** | 리소스별 VRAM — 어느 텍스처가 큰가 | [lowend-3gb-60fps.md §6](lowend-3gb-60fps.md) |
| **Misc** | **Clicked Control** — 실행 중 클릭한 UI 노드가 트리 어디인지 | 🛑 "화면을 눌렀는데 캐릭터가 안 움직인다" → 어느 `Control` 이 입력을 먹었나 → [hud-menu.md](hud-menu.md) `mouse_filter` |

### 브레이크포인트 — 흐름을 멈춰 세운다

| 방법 | |
|---|---|
| 스크립트 편집기 **줄 번호 왼쪽 여백 클릭** → 빨간 점 | 에디터를 껐다 켜도 남는다 |
| 코드에 **`breakpoint`** 키워드 한 줄 | 파일에 저장되므로 **버전 관리로 다른 컴퓨터에도 간다** |
| 위 버튼 **Break** | 지금 당장 멈춘다 |

멈추면 — **Step Into**(한 줄, 함수 안으로) · **Step Over**(한 줄, 함수는 통째로) · **Continue**(계속) · **Skip Breakpoints**(전부 무시).

> 🛑 **`@tool` 스크립트에서는 브레이크포인트가 안 된다**(에디터 안에서 도는 코드). `print` 로 본다 — [editor-plugin.md](editor-plugin.md).

---

## 4. Remote 씬 트리 — 실행 중인 노드를 본다

**게임을 실행하면 Scene 독 위에 `Remote` / `Local` 버튼이 생긴다.**

| | 보는 것 | 값을 바꾸면 |
|---|---|---|
| **Local** | 디스크의 `.tscn`(설계도) | 다음 실행부터 |
| **Remote** | **지금 메모리에서 도는 실제 노드** | 🔑 **즉시 게임에 반영**되지만 **저장되지 않는다** |

인스펙터도 Remote 노드의 값을 보여 준다 — `position`·`visible`·`velocity` 가 **지금** 얼마인지.

### "스폰한 몹이 안 보여요" — 3분 절차

1. 실행 → Scene 독 **Remote** → 트리에서 몹 노드를 찾는다
2. **트리에 없다** → `add_child()` 가 안 불렸거나 다른 부모 아래다. 코드로 만든 노드는 `print_tree_pretty()` 로도 확인
3. **트리에 있다** → 인스펙터에서 `visible` · `global_position` · `scale` 을 본다. 카메라 뒤·땅속·크기 0 이 대부분이다
4. `MeshInstance3D` 인데 `mesh` 가 `<empty>` → [basics/01-world.md](basics/01-world.md) "`MeshInstance3D` 를 추가해도 안 보이는 이유"
5. 값을 **Remote 에서 직접 고쳐** 보이면 → 원인은 그 값. 고친 값은 코드·씬에 다시 적는다

### 값 튜닝

실행한 채 Remote 에서 `speed`·`jump_velocity`(`@export` 변수)를 바꾸면 **그 즉시** 조작감이 바뀐다.
마음에 드는 값을 찾으면 **Local 로 돌아가 인스펙터에 적는다** — Remote 값은 게임을 끄면 사라진다.

---

## 5. 오류 메시지 읽는 법

### 형식

```
E 0:00:01:0234   player.gd:12 @ _physics_process(): Invalid access to property or key 'global_position' on a base object of type 'Nil'.
  <C++ Error>    Method/function failed.
  <C++ Source>   scene/main/node.cpp:1234 @ get_node()
  <Stack Trace>  player.gd:12 @ _physics_process()
```

| 부분 | 뜻 |
|---|---|
| `E` / `W` | 오류 / 경고 |
| `0:00:01:0234` | 실행 후 경과 시간 |
| **`player.gd:12 @ _physics_process()`** | 🔑 **내 코드의 어디** — 파일:줄 @ 함수. 클릭하면 그 줄로 간다 |
| 메시지 | 무엇이 잘못됐나 |
| `<Stack Trace>` | 호출 사슬 — 위가 최근. 내 파일이 나올 때까지 내려간다 |

### 자주 보는 메시지와 진짜 원인

| 메시지 | 진짜 원인 | 어디를 본다 |
|---|---|---|
| `Invalid access to property or key 'x' on a base object of type 'Nil'` | 🛑 **그 줄이 아니라 그 앞** — `$Path` 나 `get_node()` 가 `null` 을 돌려줬다. 노드 이름·위치가 다르다 | [example.md §11 증상별 진단표](example.md) · [basics/01-world.md](basics/01-world.md) "이름이나 위치를 바꾸면 조용히 null" |
| `Node not found: "Player" (relative to "/root/Main")` | `$Player` 가 그 위치에 없다 | Remote 트리에서 실제 경로 확인 |
| `Attempt to call function 'x' in base 'null instance' on a null instance` | 위와 같음 — 변수가 `null` | `@onready` 가 `_ready` 전에 쓰였거나 `@export` 를 인스펙터에서 안 채웠다 |
| `Invalid call. Nonexistent function 'x' in base 'Node3D'` | 타입이 다르다 — `Node3D` 에는 그 함수가 없다 | `as CharacterBody3D` 가 실패해 `null`… 이 아니라 **잘못된 노드를 잡았다.** 클래스 레퍼런스 Inherits 확인 |
| `Parser Error: Expected indented block …` | 빈 함수 | `pass` — [basics/04-script.md](basics/04-script.md) |
| `Used space character for indentation instead of tab` | 탭·스페이스 혼용 | Edit › Indentation › Convert Indent to Tabs |
| `Cannot assign a value of type "String" as "int"` | `:=` 로 고정된 타입 | [basics/04-script.md](basics/04-script.md) `:=` |
| `Condition "!is_inside_tree()" is true` | 트리에 붙기 전에 `global_position` 등을 썼다 | `add_child()` 뒤로 옮긴다 — [basics/03-instancing.md](basics/03-instancing.md) |
| `Function "move_and_slide()" not found in base self` | `extends` 가 `CharacterBody3D` 가 아니다 | 루트 노드 타입 — [example.md §7](example.md) "스크립트를 어느 노드에 붙이는가" |
| 오류 없이 **T-포즈로 서 있다** | 애니 이름 불일치 | [basics/10-animation.md](basics/10-animation.md) |

> 🔑 **Evaluator 로 확인한다.** 멈춘 자리에서 `$Path` 를 입력하면 `null` 인지 노드인지 바로 나온다.

---

## 6. Debug 메뉴 — 실행 옵션

메인 메뉴 **Debug**. 실행할 때 켜고 끄는 것들이다.

| 옵션 | 무엇 | 이 프로젝트 |
|---|---|---|
| **Deploy with Remote Debug** | 원클릭 배포 시 **폰이 이 컴퓨터의 디버거에 접속**한다 | 실기기 디버그 — §10 |
| **Small Deploy with Network Filesystem** | 폰에 최소 실행 파일만 보내고 **파일은 네트워크로** 준다. 큰 프로젝트 반복 테스트가 빠르다 | 에셋이 커지면 |
| **Visible Collision Shapes** | 실행 중 콜리전 셰이프·레이캐스트를 그린다 | 🔑 "뚫고 떨어진다" 의 첫 확인 — [physics-3d.md](physics-3d.md) |
| **Visible Paths** | `Path3D` 커브 표시 | |
| **Visible Navigation** | 내비메시·연결 표시 | §12 |
| **Visible Avoidance** | 회피 반경·속도 표시 | [navigation-3d.md §5](navigation-3d.md) |
| **Synchronize Scene Changes** / **Script Changes** | 에디터에서 고친 씬·스크립트를 **실행 중인 게임에 반영** | 값 튜닝 |
| **Keep Debug Server Open** | 에디터 밖에서 시작한 세션도 받는다 | `install.sh --console` 과 조합 |
| **Customize Run Instances…** | **여러 인스턴스**를 각자 다른 인자·feature tag 로 실행 | 멀티플레이 테스트 · `--perf-log` 같은 인자 ([performance-mobile.md](performance-mobile.md)) |

사용자 인자는 `-- one two` 처럼 **`--` 뒤에 공백을 두고** 적고 `OS.get_cmdline_user_args()` 로 읽는다.

---

## 7. 프로파일러 — 어느 함수가 느린가

**Debugger › Profiler › Start**(또는 **Autostart** — 다음 실행부터 자동. 에디터를 끄면 풀린다).
꺼져 있는 것이 기본이다 — 켜 두면 그 자체가 느리다.

| 항목 | 뜻 |
|---|---|
| **Frame Time** | 한 프레임 전체(물리+렌더링). **렌더링이 포함**되므로 스크립트가 빠른데 여기만 튀면 파티클·이펙트다 |
| **Physics Frame** | 물리 틱에 배정된 시간(60Hz = 16.66ms) |
| **Idle Time** | `_process`·타이머·카메라 |
| **Physics Time** | `_physics_process`·물리 |
| **Script Functions** | 🔑 **내 함수들** — 체크해 그래프에 올린다 |

**Measure** — 시간(ms) / Frame %(프레임 대비) / Physics % · **Inclusive**(안에서 부른 함수 포함) / **Self**(그 함수 몸통만).
`get_neighbors` 가 Inclusive 로 크고 Self 로 작으면 **그 안에서 부른 다른 함수**가 느린 것이다.

그래프를 클릭하면 그 프레임의 값이 왼쪽에 나온다. 튀는 프레임을 잡아 **Frame #** 을 앞뒤로 옮기며 원인을 찾는다.

**함수 안의 어느 줄인가** — 손으로 잰다.

```gdscript
var t0 := Time.get_ticks_usec()
_expensive()
print("걸린 시간: %.3f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
```

> 🛑 **프로파일러는 C# 을 지원하지 않는다** — 이 프로젝트는 GDScript 라 무관.
> **Visual Profiler 는 렌더링만** 잰다(드로우콜·패스). 스크립트·물리는 Profiler 로. macOS 의 Compatibility 렌더러에서는 Visual Profiler 가 안 된다.
> 저사양 실기기 측정 절차는 [performance-mobile.md §2](performance-mobile.md) · [lowend-3gb-60fps.md §3](lowend-3gb-60fps.md).

---

## 8. ObjectDB 프로파일러 — 메모리 누수(4.6+)

**Debugger › ObjectDB Profiler › Take ObjectDB Snapshot**. 지금 메모리에 있는 **모든 `Object`** 를 찍는다.
두 장을 찍고 **Diff Against** 로 비교하면 **무엇이 늘었는지**가 나온다.

| 탭 | 무엇 |
|---|---|
| Summary | 총 개수와 diff |
| Classes | 클래스별 인스턴스 수 (A / B / Delta) |
| Objects | 인스턴스 하나하나 — **Outbound / Inbound References**로 "누가 나를 붙잡고 있나" |
| Nodes | 스냅샷 시점의 씬 트리 — **Combined Diff** 로 추가(초록)·제거(빨강). 맨 아래 **고아 노드**(트리 밖 노드) 목록 |
| RefCounted | 참조 수 — `ObjectDB Cycles` 가 0 이 아니면 **순환 참조** |

**전형적인 사용** — 맵 입장 전 한 장, 맵 나온 뒤 한 장. `Delta` 가 0 이 아닌 클래스가 **안 지운 것**이다.
고아 노드는 `queue_free()` 를 안 부른 것 — [performance-mobile.md](performance-mobile.md) 의 `OBJECT_ORPHAN_NODE_COUNT` 모니터가 같은 것을 숫자로 보여 준다.

스냅샷 파일은 `user://objectdb_snapshots/*.odb_snapshot` — 이름을 바꿔 두면(`before_fix`) 나중에 비교할 수 있다.
엔진 내부(스크립트에 노출되지 않은) 메모리는 안 잡힌다.

---

## 9. 커스텀 모니터 — 내 숫자를 그래프로

**Monitors 탭에 내 값을 추가한다.** 적 수·활성 청크 수·SNAP 수신 빈도처럼 성능은 아니지만 그래프로 봐야 하는 것.

```gdscript
func _ready() -> void:
	# "카테고리/이름" — 슬래시 앞이 Monitors 의 그룹이 된다. 없으면 "Custom"
	Performance.add_custom_monitor("game/enemies", _count_enemies)

func _count_enemies() -> int:      # 0 이상의 int 또는 float 를 돌려준다. 에디터가 초당 1회 부른다
	return get_tree().get_nodes_in_group("enemies").size()
```

실행 → Debugger › **Monitors** → 아래로 내려 **Game › Enemies** 체크.
게임 화면에도 띄우려면 `Performance.get_custom_monitor("game/enemies")` — 릴리스 빌드에서도 된다.
[performance-mobile.md](performance-mobile.md) 의 디버그 오버레이가 이 방식으로 SSOT 예산과 나란히 보여 준다.

---

## 10. 실기기 원격 디버그와 Android 크래시 심볼화

### 원격 디버그

| 단계 | |
|---|---|
| 1 | **Debug › Deploy with Remote Debug** 켜기 |
| 2 | 원클릭 배포(에디터 오른쪽 위 폰 아이콘) 또는 `./install.sh <기기> --console` — [headless-workflow.md §3](headless-workflow.md) |
| 3 | 폰이 **이 컴퓨터의 IP:6007** 로 접속한다 — 같은 Wi-Fi 여야 한다. 포트는 Editor Settings › Network › Debug › Remote Port |
| 4 | 이후는 로컬과 같다 — Output·Errors·Remote 씬 트리·Profiler 전부 |

로그만 필요하면 — Android `adb logcat -s godot`([export-build-android.md §4](export-build-android.md)),
iOS 는 [export-build-ios.md §7](export-build-ios.md).

### Android 크래시가 난독화돼 온다 — 심볼화

Play Console·Crashlytics 의 스택이 주소만 나올 때, **내보낸 템플릿과 같은 빌드의 심볼**이 필요하다.

| | |
|---|---|
| **공식 템플릿을 썼으면** | GitHub 릴리스에서 `Godot_native_debug_symbols.4.7.2.stable.template_release.android.zip` 을 받는다 |
| 직접 빌드한 템플릿이면 | `scons … debug_symbols=yes separate_debug_symbols=yes` — 🛑 **템플릿과 심볼은 같은 빌드**여야 한다 |
| **Play Console 에 올리기** | Test and release › Latest releases and bundles › 번들 › **Downloads › Assets › Native debug symbols** ↑ (또는 릴리스 생성 시 ⋮ › Upload native debug symbols) |
| **직접 풀기** | `ndk-stack -sym <심볼폴더>/arm64-v8a/ -dump crash.txt` — 🛑 `crash.txt` 첫 줄이 `*** *** *** …` 별표 줄이어야 파싱한다 |

`ndk-stack` 은 Android SDK 의 `ndk/` 안에 있다. 결과에 Godot 소스의 파일:줄이 나온다 — 엔진 안에서 죽은 것인지 내 코드 때문인지 갈린다.
저사양 기기의 `SIGSEGV in WorkerThread`(리소스 일괄 로드) 사례는 [lowend-3gb-60fps.md](lowend-3gb-60fps.md).

---

## 11. 공식 Troubleshooting — 에디터가 이상할 때

| 증상 | 원인 | 해결 |
|---|---|---|
| **에디터가 느리고 팬이 돈다** (맥 Retina) | 고해상도 렌더 | 3D 뷰포트 **Perspective ▾ › Half Resolution**(최대 4배 빠름) · Editor Settings **Low Processor Mode Sleep (µsec)** 을 `33000`(30fps) · 계속 다시 그리는 노드(파티클)는 에디터에서 숨기고 `_ready()` 에서 켠다 |
| **첫 실행이 아주 오래 걸린다** | 셰이더 컴파일·캐시 | 정상. 엔진·그래픽 드라이버·GPU 를 바꾸면 다시 한 번. 계속 그러면 USB 장치(iCUE)·방화벽(Portmaster)이 디버그 포트 6007 을 막는 알려진 문제 — 포트를 `7007` 등으로 |
| **에디터에서는 되는데 내보내면 파일을 못 찾는다** | 🛑 ① **비리소스 파일**(`.json` 등)은 PCK 에 안 들어간다 → Export › Resources › **Filters to export non-resource files** 에 `*.json` ② **점으로 시작하는 파일·폴더는 절대 안 들어간다** ③ **PCK 는 대소문자를 구분한다** — Windows·macOS 에서만 되던 `Player.tscn`/`player.tscn` | [export-build.md](export-build.md) · [best-practices.md §9](best-practices.md) |
| **프로젝트가 열자마자 죽는다** | 플러그인·`@tool`·GDExtension | **Recovery Mode** — [getting-started.md §2](getting-started.md) |
| 가변 주사율 모니터에서 깜빡인다 | 에디터가 필요할 때만 다시 그림 | Editor Settings **Interface › Editor › Update Continuously** + Low Processor Mode Sleep `33000` |
| 화면이 너무 선명하거나 흐리다 | 그래픽 드라이버가 샤프닝·FXAA 를 강제 | 드라이버 제어판에서 앱별로 끈다 |
| 콘솔 창을 클릭했더니 에디터가 멈춤 (Windows) | 콘솔 선택 모드 | 콘솔에서 Enter |
| 좌상단에 "NO DC"·마이크 아이콘 | NVIDIA 오버레이 | 드라이버 설정 |

---

## 12. 내비게이션 디버그

> 🛑 디버그 기능·설정·함수는 **디버그 빌드에서만** 있다. 릴리스에 남기지 않는다.

| 무엇 | 어디 |
|---|---|
| 에디터 안에서는 **기본으로 보인다** — 내비메시·연결 | 3D 뷰포트 |
| 실행 중에도 보려면 | **Debug › Visible Navigation** |
| 코드로 | `NavigationServer3D.set_debug_enabled(true)` (doctool 확인) |
| 모양·색 | Project Settings **`debug/shapes/navigation`** — `enable_edge_lines`(폴리곤 테두리) · `enable_edge_lines_xray`(벽 너머로) · `enable_geometry_face_random_color`(폴리곤마다 색) · `edge_connection_color`(메시 연결) |
| 성능 | Debugger › **Monitors › Navigation Process** — 서버가 맵·리전·에이전트·회피를 갱신하는 ms. **경로 탐색은 안 들어간다**(별도). 물리 틱 안에서 돌므로 이 값이 크면 Physics Process 도 같이 커진다 |

`NavigationServer3D` API 만 써서 만든 것은 디버그 그리기에 안 나온다(노드 기반만).
느릴 때의 원인 다섯(소스 지오메트리 파싱·베이킹·에이전트 쿼리·경로 탐색·맵 동기화)과 처방은 [navigation-3d.md](navigation-3d.md) 의 최적화 절.

---

## 13. 자주 하는 실수

| 실수 | 결과 | 고침 |
|---|---|---|
| 오류 줄만 보고 그 줄을 고친다 | `Nil` 오류는 원인이 앞줄 | §5 — `$` 경로·`@export` 미설정 |
| `print` 로 오류를 찍는다 | 로그에 묻힌다 | `push_error` — Errors 탭에 모인다 |
| Remote 에서 고친 값을 저장한 줄 안다 | 게임을 끄면 사라진다 | Local 인스펙터에 옮겨 적는다 |
| 프로파일러를 켜 둔 채 성능을 잰다 | 켜는 것 자체가 느리다 | 필요할 때만 Start |
| Visual Profiler 로 스크립트 병목을 찾는다 | 렌더링만 잰다 | Profiler 탭 |
| Network Profiler 에 UDP 가 안 나온다고 당황한다 | 고수준 API 전용 | [networking-lowlevel.md](networking-lowlevel.md) — 직접 카운터를 커스텀 모니터로 |
| `@tool` 스크립트에 브레이크포인트 | 무시된다 | `print` |
| 폰에서만 죽는데 에디터 로그만 본다 | 폰 로그는 폰에 있다 | §10 — 원격 디버그·`logcat`·심볼화 |
| 릴리스 빌드에서 `assert()` 에 의존 | 릴리스에서는 실행되지 않는다 | `push_error` + 조기 `return` |
| 내보낸 뒤 `.json` 을 못 읽는다 | 비리소스 필터 누락 | §11 |

---

## 관련 문서

- [lsp.md](lsp.md) — 실행 전 진단 (필수 단계)
- [ai-tooling.md](ai-tooling.md) — DAP·MCP 로 AI 가 관찰하기
- [performance-mobile.md](performance-mobile.md) — 병목 가르기·디버그 오버레이
- [lowend-3gb-60fps.md](lowend-3gb-60fps.md) — 저사양 실기기 측정 규칙
- [example.md §11](example.md) — 첫 씬의 증상별 진단표
- [headless-workflow.md](headless-workflow.md) · [export-build-android.md](export-build-android.md) · [export-build-ios.md](export-build-ios.md) — 실기기 설치·로그
- [navigation-3d.md](navigation-3d.md) — 내비게이션

## 공식 문서

- Overview of debugging tools: https://docs.godotengine.org/en/stable/tutorials/scripting/debug/overview_of_debugging_tools.html
- Output panel: https://docs.godotengine.org/en/stable/tutorials/scripting/debug/output_panel.html
- Debugger panel: https://docs.godotengine.org/en/stable/tutorials/scripting/debug/debugger_panel.html
- The Profiler: https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html
- Using the ObjectDB profiler: https://docs.godotengine.org/en/stable/tutorials/scripting/debug/objectdb_profiler.html
- Custom performance monitors: https://docs.godotengine.org/en/stable/tutorials/scripting/debug/custom_performance_monitors.html
- Troubleshooting: https://docs.godotengine.org/en/stable/tutorials/troubleshooting.html
- Resolving crashes on Android: https://docs.godotengine.org/en/stable/tutorials/platform/android/resolving_crashes_on_android.html
- Navigation debug tools: https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_debug_tools.html
- Logging: https://docs.godotengine.org/en/stable/tutorials/scripting/logging.html
