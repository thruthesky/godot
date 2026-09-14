# 에디터 없이 작업하기 — 터미널만으로 도는 개발 루프

> **이 문서로 오는 상황** — 에디터 없이 터미널만으로 — 6가지 기본 명령, 🛑 `--headless` 로 되는 것·안 되는 것(스크린샷 null·입력 좌표·종료 조건)과 **사람 화면에 창을 띄우지 않는 규칙**, 화면에 안 보이게 실행해 스크린샷·녹화하는 **가상 모니터** 요약(정본 [virtual-monitor.md](virtual-monitor.md)), `install.sh` 로 빌드·설치·실행, iOS 실기기 preset, Remote Deploy 와의 관계

Godot 에디터 GUI 를 열지 않고 **코드 작성 → 검증 → 실행 → 실기기 확인**까지 끝내는 방법이다.
Claude 가 이 프로젝트에서 작업할 때의 **기본 작업 방식**이며, CI 에서도 같은 명령을 쓴다.

빌드 자체의 개념(export template·preset·서명)은 [export-build.md](export-build.md) 와
플랫폼별 문서에 있다. 이 문서는 **루프를 어떻게 도는가**를 다룬다.

## 목차

1. [개발 루프 한 장](#1-개발-루프-한-장)
2. [기본 명령 6가지](#2-기본-명령-6가지)
   - [2-A. 헤드리스가 하는 일과 못 하는 일](#2-a-헤드리스가-하는-일과-못-하는-일) — 실측 표 · 사람 화면에 무엇이 뜨나 · 함정 다섯
3. [실기기 설치 — `install.sh`](#3-빌드설치실행--installsh)
4. [iOS 실기기가 되게 하는 preset 설정](#4-ios-실기기가-되게-하는-preset-설정)
5. [에디터 Remote Deploy 와의 관계](#5-에디터-remote-deploy-와의-관계)
6. [자주 막히는 지점](#6-자주-막히는-지점)
7. [사람 화면 없이 그림을 얻는다 — 가상 모니터](#7-사람-화면-없이-그림을-얻는다--가상-모니터)

---

## 1. 개발 루프 한 장

```text
GDScript 작성·수정
        ↓
LSP 정적 검증          python3 scripts/gdscript_lsp.py diagnose --changed   ← 필수
        ↓
창 없이 짧게 실행       godot --headless --quit-after 2
        ↓
창 없이 검사            godot --headless -s res://tests/<검사>.gd       ← AI 자율 실행의 기본
        ↓
그림으로 확인(창 없음)  scripts/xvfb_run.sh -s res://tests/<촬영>.gd    ← 가상 모니터 (virtual-monitor.md)
        ↓
실기기에서 최종 확인    scripts/install.sh <device-id>
```

🛑 **사람이 같은 화면에서 일한다 — AI 가 스스로 돌리는 실행은 사람 화면에 창을 띄우지 않는다.**
창(`godot --path .`)은 사람이 직접 볼 때, 또는 컨테이너로 안 되는 이유(Metal 전용 결함·실제 macOS 창 입력 등)가
있을 때만 쓰고 그 이유를 보고에 적는다 → [§2-A](#2-a-헤드리스가-하는-일과-못-하는-일) · [§7](#7-사람-화면-없이-그림을-얻는다--가상-모니터)

**데스크톱 실행은 실기기 확인을 대체하지 못한다.** 터치·성능·GPU 드라이버·발열은
기기에서만 드러난다. 특히 렌더러가 `mobile`(Metal/Vulkan)이면 데스크톱과 기기의
드라이버 경로가 아예 다르다.

---

## 2. 기본 명령 6가지

`GODOT_BIN` 을 정해 두면 모든 명령이 짧아진다. Homebrew 설치면 `godot` 만으로도 된다.

```bash
GODOT_BIN="${GODOT_BIN:-$(command -v godot)}"      # 또는 /Applications/Godot.app/Contents/MacOS/Godot
```

| 목적 | 명령 |
|---|---|
| **문법·부팅 검사** (창 없음) | `godot --headless --path . --quit-after 2 --log-file artifacts/logs/check.log` |
| **임포트만 수행** | `godot --headless --path . --import --quit` |
| **실제 게임 창 실행** 🛑 창이 뜨고 전면 앱을 가져간다 — 사람이 볼 때만 | `godot --path .` (프로젝트 폴더 안이면 `godot`) · AI 의 그림 확인은 [§7](#7-사람-화면-없이-그림을-얻는다--가상-모니터) `xvfb_run.sh` |
| **정적 진단** (에디터 실행 중) | `python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose --changed` |
| **빌드** | `godot --headless --path . --export-debug "<preset>" <출력경로>` |
| **실기기 설치·실행** | `.claude/skills/godot/scripts/install.sh <device-id>` |

`--quit-after N` 은 **N 프레임 뒤 종료**다. 초가 아니다. 부팅 시 오류를 잡는 용도이며,
게임 로직을 검증하지는 못한다. (빈 프로젝트 300프레임에 2,058ms — 헤드리스도 실시간에 맞춰 돈다.
`--fixed-fps 60` 을 붙이면 7ms 로 끝나지만 벽시계가 멈춘다 → [§2-A](#2-a-헤드리스가-하는-일과-못-하는-일) 함정 ④)

화면 확인이 필요하면 게임 코드에서 직접 PNG 로 저장한다. `RenderingServer.frame_post_draw`
를 기다리지 않고 뷰포트를 읽으면 검은 화면이 저장된다.

```gdscript
func capture() -> void:
	# 🛑 헤드리스는 그리지 않는다 — 이미지가 null 이고 frame_post_draw 가 오지 않아 await 에서 영원히 멈춘다
	if DisplayServer.get_name() == "headless":
		print("[CAPTURE] 헤드리스라 건너뜀 — 그림은 scripts/xvfb_run.sh 로 찍는다")
		return
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png("user://shot.png")
	print("[CAPTURE] ", ProjectSettings.globalize_path("user://shot.png"))
```

저장 위치를 추측하지 말고 **로그에 절대 경로를 찍어 확인한다.** 컨테이너([§7](#7-사람-화면-없이-그림을-얻는다--가상-모니터))에서는 환경변수 `SHOT_DIR`(= `/out`)에 저장한다.

---

## 2-A. 헤드리스가 하는 일과 못 하는 일

`--headless` 는 **창을 만들지 않고, 소리를 내지 않고, 그리지도 않는** 실행 방식이다. 엔진 도움말이 뜻을 그대로 적어 두었다(4.7.2).

```text
$ godot --help
  --display-driver <driver>   Display driver (and rendering driver) ["macos" (…), "headless" ("dummy")].
  --headless                  Enable headless mode (--display-driver headless --audio-driver Dummy). Useful for servers and with --script.
```

`headless` 디스플레이 드라이버에 붙는 렌더링 드라이버는 `dummy` 하나뿐이다 — 그래서 그림이 없다.
**서버용 Godot 바이너리를 따로 받을 필요가 없다.** 평소 쓰는 `godot`(에디터 바이너리)에 옵션 하나를 붙인다.
"헤드리스(머리 없는)"는 모니터·키보드 없이 도는 서버를 부르던 말에서 왔다.

### 🛑 AI 가 스스로 돌리는 실행은 헤드리스가 기본이다

사람 개발자가 같은 컴퓨터에서 일한다. 검증을 돌릴 때마다 게임 창이 떴다 사라지고 전면 앱이 바뀌면 사람의 작업이 끊긴다.
**AI 가 자율적으로 개발·테스트·검증할 때는 꼭 필요한 경우를 빼고 `--headless` 로 돌리고, 그림이 필요하면
[§7](#7-사람-화면-없이-그림을-얻는다--가상-모니터) 의 컨테이너로 찍는다.** 창이 꼭 필요했다면 그 이유를 보고에 적는다.

### 기본 명령 — 실측 (2026-09-13 · Godot 4.7.2 · Apple M5 Max · 빈 프로젝트)

`--path` 에는 **`project.godot` 이 있는 폴더**를 준다.

| 명령 | 하는 일 | 실측 |
|---|---|---|
| `godot --headless --path <프로젝트>` | `main_scene` 실행 | 🛑 **스스로 끝나지 않는다.** 코드가 `quit()` 를 부르기 전까지 돈다 — 6초 뒤 강제 종료(142)했다. AI 가 이렇게 부르면 명령이 멈춘 것처럼 보인다 |
| `godot --headless --path <프로젝트> res://scenes/test.tscn --quit-after 10` | 그 씬만 실행 | 10프레임 · 57ms 뒤 종료 |
| `godot --headless --path <프로젝트> --quit-after 300` | 300번 반복 뒤 종료 | **300프레임 · 2,058ms** — 헤드리스도 실시간에 맞춰 돈다(초당 약 146회) |
| `godot --headless --path <프로젝트> --quit-after 300 --fixed-fps 60` | 실시간 동기화를 끄고 최대 속도 | **300프레임 · 7ms** · 3,000프레임도 8ms. 🛑 벽시계가 멈춘다(아래 ④) |
| `godot --headless --path <프로젝트> --import` | 리소스를 임포트하고 종료 | **`--quit` 없이도 스스로 끝난다** · 1.7초(빈 프로젝트) |
| `godot --headless --editor --path <프로젝트> --quit` | 에디터를 창 없이 띄웠다가 첫 반복에서 종료 | 1.7초 — `--import`·`--export-*` 도 이 에디터 경로로 돈다 |
| `godot --headless --path . -s res://tests/x.gd` | `extends SceneTree` 스크립트 실행 | 검사의 기본형 · 60프레임 검사 0.62초 |

`--quit-after N` 의 N 은 **메인 루프 반복 수(= 프레임)** 다. 초가 아니다.

### 되는 것 · 안 되는 것 — 실측

| 항목 | 헤드리스 결과 | 그래서 |
|---|---|---|
| `DisplayServer.get_name()` | `"headless"` | 제품·검사 코드에서 분기할 때 쓰는 값 |
| 오디오 | `AudioServer.get_driver_name()` = `Dummy` | 소리는 안 난다. 재생 API 는 오류 없이 돈다 |
| `_process` · 물리 틱 | 60프레임 동안 물리 27틱(실시간) | 로직·이동·충돌 판정은 그대로 된다 |
| 네트워크(UDP·HTTP·WebSocket) | 된다 | 서버 E2E 검사를 헤드리스로 돌린다 |
| Control 레이아웃·글자 크기 | 된다(버튼 최소 크기 96×31 계산) | 배치·넘침·겹침은 **숫자로** 판정한다 |
| 입력 주입 | 된다 — 🛑 좌표 함정(아래 ①) | 클릭·터치 흐름 판정 |
| `get_viewport().get_texture().get_image()` | 🛑 **`null`** + `ERROR: Parameter "t" is null.` | 스크린샷 불가 → §7 |
| `RenderingServer.frame_post_draw` | 🛑 **매 프레임 오지 않는다** — 60프레임 동안 0회 · 90프레임 동안 1회(맥·리눅스) | 기다리는 시점 뒤로는 안 올 수 있어 `await` 하면 멈춘다(아래 ②) |
| `RenderingServer.get_rendering_device()` | `null` | GPU·셰이더 확인 불가 |
| `--write-movie out.avi` | 🛑 **종료 코드 134**(비정상 종료) · AVI 헤더 332바이트만 | 녹화 불가 — `.png` 시퀀스도 PNG 0장 → §7 |
| 드로우콜·프레임 시간 | 의미 없음(더미 렌더러) | 성능은 실기기에서 잰다 |
| `Engine.get_frames_per_second()` | 부팅 직후 **`1.0`** | FPS 문턱 로직이 검사 초반에 켜진다(아래 ⑤) |

### 헤드리스에서 그림을 얻는 우회로는 없다 — 전부 시도했다 (2026-09-14)

"렌더링 드라이버를 지정하면?" · "창과 무관한 `SubViewport` 라면?" · "강제로 그리게 하면?" 을 모두 시험했다.
장면은 파란 배경 위 빨간 상자 하나이고, 가운데 픽셀이 빨강 · 모서리가 파랑이면 "그림" 으로 판정했다.

| 실행 (맥 Godot 4.7.2 · 리눅스 컨테이너 Godot 4.7.2) | 메인 뷰포트 `get_image()` | 오프스크린 `SubViewport` | `force_draw()` 뒤 두 곳 | `get_rendering_device()` · 로컬 장치 |
|---|---|---|---|---|
| `--headless` (맥 · 리눅스) | null | null | null | null · null |
| `--headless --rendering-driver` `metal`·`vulkan`·`opengl3`(맥) · `vulkan`·`opengl3`(리눅스) | null | null | null | null · null — 드라이버 **이름만** 바뀐다 |
| `--headless --rendering-method gl_compatibility` (맥) | null | null | null | null · null |
| `--display-driver headless --rendering-driver` `metal`(맥) · `vulkan`(리눅스) — `--headless` 없이 | null | null | null | null · null |
| 리눅스 `--display-driver x11` 인데 가상 디스플레이가 없다 | 🛑 실행 실패 | `X11 Display is not available` | → wayland 폴백 실패 | → `Unable to create DisplayServer` (종료 1) |
| **리눅스 Xvfb + `x11` · Compatibility** | ✅ 그림 | ✅ 그림 | ✅ 그림 | null · null (OpenGL 이라 없다) |
| **리눅스 Xvfb + `x11` · Mobile(Vulkan `lavapipe`)** | ✅ 그림 | ✅ 그림 | ✅ 그림 | 있음 · 있음 |

맥 헤드리스 6개 조합은 실행하는 동안 WindowServer 창 목록을 0.1초마다 조회했고, **새로 생긴 Godot 창은 0개**였다.

**엔진 소스와 공식 문서도 같은 말을 한다** (4.7.2-stable):

- `main/main.cpp` — `} else if (arg == "--headless") { // enable headless mode (no audio, no rendering).` 다음 줄에서 오디오·디스플레이 드라이버를 널 드라이버로 바꾼다
- `servers/display/display_server_headless.h` — 헤드리스 디스플레이 서버가 허용하는 렌더링 드라이버는 `drivers.push_back("dummy");` **하나뿐**이다
- 공식 문서 *Exporting for dedicated servers* — GPU 나 디스플레이 서버가 없는 기계에서는 "headless display server and Dummy audio driver" 로 돌리고, `--headless` 를 줘야 "no window spawns"

→ **`--headless` 는 "창이 안 보이는 실행" 이 아니라 "그리기 자체가 없는 실행" 이다.** 그림은 가상 디스플레이([§7](#7-사람-화면-없이-그림을-얻는다--가상-모니터))에서만 나온다.

### 사람 화면에 무엇이 뜨나 — macOS 에게 밖에서 물었다

Godot 이 스스로 보고하는 값이 아니라, 실행 중에 macOS WindowServer 의 창 목록(`CGWindowListCopyWindowInfo`)과
앱 목록(`NSRunningApplication`)을 **외부 프로세스에서** 조회했다(2026-09-13 · macOS 26.6 · 모니터 3대).

| 실행 방식 | 앱 등록(Dock) | 사람 화면의 창 | 전면 앱 | 스크린샷 |
|---|---|---|---|---|
| **`--headless`** | **없음** | **0개** | **바뀌지 않음** | ✗ `null` |
| 창 + `--position -30000,-30000` | 있음 | 🛑 **보이는 모니터에 뜸** — Godot 이 창을 (4112, 622)로 옮겼다 | Godot 으로 바뀜 | ✓ |
| 창 + `display/window/size/mode=1`(최소화) | 있음 | 🛑 최소화가 **적용되지 않고** 화면에 뜸(`mode=0` 보고) | (다른 창과 겹쳐 판정 못 함) | ✓ |
| 창 + `display/window/size/no_focus=true` + 화면 밖 좌표 | 있음 | 🛑 화면에 뜸 | 🛑 Godot 으로 바뀜 | ✓ |
| 리눅스 컨테이너 + Xvfb(§7) | 없음 | 0개(컨테이너 안의 가상 화면) | 바뀌지 않음 | ✓ |

**결론 — macOS 에서 Godot 창을 사람 눈에 안 보이게 띄우는 설정은 없다.** 그림이 필요하면 창을 숨기려 하지 말고 §7 로 간다.

### 헤드리스의 함정

#### ① 창이 64×64 라 입력 좌표가 빗나간다

헤드리스 창은 설정한 해상도가 아니라 **64×64** 같은 작은 크기다(`--resolution`·`root.size` 도 무시된다).
배치 검사는 논리 뷰포트를 폰 크기로 잡는데, 이때 **`Input.parse_input_event` 는 좌표를 창(64×64) 기준으로 읽는다.**

| 주입 방법 (논리 뷰포트 390×844 · 버튼 (40,600) 크기 120×60) | 좌표 | 버튼 |
|---|---|---|
| `Input.parse_input_event` 터치 | 논리 (100, 630) 그대로 | 🛑 **0건 도착** |
| `Input.parse_input_event` 터치 | 창 좌표로 환산 (16.4, 47.8) | 눌림 — 마우스 흉내 이벤트도 함께 온다 |
| **`root.push_input(e, true)`** 터치 | 논리 그대로 | ✅ 눌림 |
| **`root.push_input(e, true)`** 클릭 | 논리 그대로 | ✅ 눌림 |

```gdscript
# SceneTree 검사 스크립트 — 노드 안이라면 get_tree().root
root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
root.content_scale_size = Vector2i(390, 844)      # 창은 64×64 로 남고 논리 뷰포트만 폰 크기가 된다

var touch := InputEventScreenTouch.new()
touch.index = 0
touch.pressed = true
touch.position = Vector2(100, 630)                # 논리 좌표
root.push_input(touch, true)                      # true = 좌표가 이미 뷰포트(논리) 기준이다
```

#### ② `frame_post_draw` 를 기다리는 코드는 멈춘다

"첫 프레임이 그려진 뒤" 를 기다리는 제품 코드가 헤드리스 검사에서 조용히 멈추거나 값이 영영 안 채워진다. 헤드리스면 분기한다.

```gdscript
if DisplayServer.get_name() == "headless":
	await get_tree().process_frame        # 헤드리스에는 그리기가 없다
else:
	await RenderingServer.frame_post_draw
```

#### ③ 종료 조건이 없으면 명령이 돌아오지 않는다

`-s` 스크립트는 판정 끝에 `quit()` 를, 씬 실행은 `--quit-after N` 을 둔다. **GDScript 파싱 오류도 출력 0줄로 안 끝나는
멈춤처럼 보인다** — 출력은 파이프가 아니라 파일로 받아 확인한다.

#### ④ `--fixed-fps` 는 벽시계를 멈춘다

`--fixed-fps N` 은 매 프레임 `delta` 를 `1/N` 으로 고정하고 **실시간 동기화를 끈다.** 300프레임(게임 시간 5초)이 7ms 에 끝난다.
`delta` 로 흐르는 것(이동·`Timer`·애니메이션)은 그만큼 진행되지만 **`Time.get_ticks_msec()` 로 재는 대기·서버 응답·
벽시계 게이트는 거의 흐르지 않는다.** 네트워크가 끼는 검사에는 쓰지 않는다.

#### ⑤ 부팅 직후 FPS 는 `1.0` 이다

부팅·로드의 긴 프레임이 1초 창에 들어가 `Engine.get_frames_per_second()` 가 0 이 아니라 **1.0** 으로 잡힌다.
"FPS 가 낮으면 효과를 끈다" 같은 문턱은 검사에서 기본으로 끄고, 그 항목만 1초 이상 기다린 뒤 켠다.

---

## 3. 빌드·설치·실행 — `install.sh`

```bash
.claude/skills/godot/scripts/install.sh [선택] [옵션]
```

**그냥 실행하면 지금 쓸 수 있는 장치를 번호로 보여주고, 고른 번호가 플랫폼을 정한다.**
macOS·iOS·Android 가 한 입구로 들어온다. preset 이름·패키지 ID·산출물 경로는
`export_presets.cfg` 에서 직접 읽으므로 프로젝트마다 고쳐 쓸 필요가 없다.

```
$ .claude/skills/godot/scripts/install.sh

사용 가능한 장치:

  1)  macOS     이 맥에서 실행 (arm64)
  2)  iOS       JaeHo16 — iPhone 16 Pro Max (iPhone17,2)
                67BD02AA-6E29-53D7-A5CE-A1619F9CF934

  (Android 기기 없음 — USB 디버깅을 켜고 연결한다)

번호 선택 [1]:
```

### 목록에 오르는 기준

**플랫폼마다 다르다.** 여기서 안 보이면 설치도 안 된다.

| 플랫폼 | 조회 | 오르는 조건 |
|---|---|---|
| **macOS** | `uname` | 이 맥이라 **항상 1번**. 연결이라는 개념이 없다 |
| **iOS** | `xcrun devicectl list devices` | 상태가 **`available`** 인 것만. 신뢰하지 않았거나 잠긴 기기는 `unavailable` 이라 빠진다 |
| **Android** | `adb devices -l` | 상태가 **`device`** 인 것만. `unauthorized`·`offline` 은 빠진다 |

**연결이 없는 플랫폼은 목록에서 빠지는 대신 왜 없는지를 한 줄로 알려 준다.**
"기기가 안 보인다" 에서 "무엇을 하면 보이는가" 로 바로 넘어가기 위해서다.

이전 판은 `xctrace` 도 훑어 `Devices Offline` 기기까지 잡았지만, **설치가 안 되는 기기를
목록에 올리는 것은 도움이 안 되므로** `devicectl` 의 `available` 판정 하나로 좁혔다.

### 번호 대신 직접 지정

스크립트·CI 에서는 번호가 흔들린다(기기를 뽑으면 순서가 바뀐다). 그때는 ID 를 준다.

```bash
install.sh macos                                  # 이 맥
install.sh R58X609XXYV                            # Android — adb 시리얼
install.sh 67BD02AA-6E29-53D7-A5CE-A1619F9CF934   # iOS — CoreDevice UUID
install.sh 1                                      # 목록 1번
```

**stdin 이 터미널이 아니면 묻지 않는다.** 목록만 찍고 끝나므로 CI 에서 멈추지 않는다.

| 옵션 | 동작 |
|---|---|
| `--console` | 실행 후 게임 로그를 터미널에 붙인다. iOS 는 `devicectl --console`, Android 는 `adb logcat -s godot`, macOS 는 바이너리를 직접 실행 |
| `--skip-build` | 빌드를 건너뛰고 설치·실행만. 코드 변경이 없을 때 수 초 |
| `--release` | 릴리즈 빌드 (기본은 디버그) |
| `--no-launch` | 설치만 하고 실행하지 않는다 |
| `--path <dir>` | 프로젝트 경로 지정 (기본: 현재 폴더에서 위로 `project.godot` 탐색) |
| `--list` | 목록만 출력하고 끝 |

### 스크립트가 하는 일

```text
장치 수집 (macOS + devicectl + adb)
      ↓
번호·ID 로 하나 확정 → 플랫폼이 정해진다
      ↓
project.godot 을 위로 탐색해 프로젝트 루트 확정
      ↓
export_presets.cfg 파싱 — preset 이름 / 패키지 ID / export_path
      ↓
godot --headless --export-debug "<preset>" <출력경로>
      ↓
macOS:   (.zip 이면 풀어서) xattr 로 격리 해제 → open
Android: adb install -r → adb shell monkey 로 실행
iOS:     devicectl install app → devicectl process launch
```

**macOS 만 설치라는 단계가 없다.** `.app` 을 만들면 그게 곧 설치된 앱이라,
서명 없는 자기 빌드가 Gatekeeper 에 막히지 않도록 `com.apple.quarantine` 을
지우고 여는 것이 그 자리를 대신한다.

iOS preset 이 `export_project_only=true` 면 `.ipa` 가 만들어지지 않으므로
**빌드 전에 멈추고 그 사실을 알린다.**
---

## 4. iOS 실기기가 되게 하는 preset 설정

`.ipa` 까지 한 번에 나오게 하는 값은 다섯 개다.

```ini
[preset.1]

name="iOS"
platform="iOS"
runnable=true                                   ; ① 에디터 Remote Deploy 아이콘 조건
export_path="builds/ios/Laryen3D.zip"

[preset.1.options]

architectures/arm64=true
application/app_store_team_id="AX352BQR6K"      ; ② 인증서의 OU 값
application/bundle_identifier="com.회사명.laryen3d"
application/code_sign_identity_debug="Apple Development"   ; ③
application/export_method_debug=1               ; ④ 1 = Development
application/export_project_only=false           ; ⑤ true 면 Xcode 프로젝트만 만들고 멈춘다
application/min_ios_version="14.0"
application/targeted_device_family=2            ; 2 = iPhone + iPad
```

| 항목 | 틀렸을 때 |
|---|---|
| ① `runnable` | 에디터에 Remote Deploy 아이콘이 나타나지 않는다 |
| ② `app_store_team_id` | `requires a development team` 으로 Xcode 빌드가 멈춘다 |
| ③ `code_sign_identity_debug` | 서명 실패로 `.ipa` 가 안 나온다 |
| ④ `export_method_debug` | App Store 용(`0`)으로 서명되어 기기에 설치되지 않는다 |
| ⑤ `export_project_only` | **가장 흔한 원인.** 빌드도 설치도 일어나지 않는다 |

### 함정 — Team ID 는 인증서 이름의 괄호 안 값이 아니다

```bash
security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject
```

```text
subject=UID=…, CN=Apple Development: JAEHO SONG (A76BVJ94Y8), OU=AX352BQR6K, …
                                                  ↑ 개인 식별자      ↑ 이 OU 가 Team ID
```

`app_store_team_id` 에는 **`OU=` 뒤의 값**을 넣는다. 괄호 안 값을 넣으면 서명이 실패한다.

### `export_path` 에 `.zip` 을 써도 `.ipa` 가 나온다

`export_project_only=false` 일 때 Godot 은 지정 경로의 **폴더**를 작업 폴더로 삼아
Xcode 프로젝트·아카이브·`.ipa` 를 모두 그 안에 만든다.

```text
builds/ios/
├── Laryen3D.ipa            ← 설치에 쓰는 파일
├── Laryen3D.xcodeproj/
├── Laryen3D.xcarchive/
└── MoltenVK.xcframework/   ← mobile 렌더러(Vulkan)를 Metal 위에서 돌린다
```

---

## 5. 에디터 Remote Deploy 와의 관계

에디터를 함께 쓸 때 반드시 구분해야 한다.

| 조작 | 어디서 실행되나 |
|---|---|
| ▶ · `F5` · macOS `Cmd+B` (`Run Project`) | **에디터가 켜진 그 PC**. 기기와 무관하다 |
| `Cmd+R` (`Run Current Scene`) | 역시 그 PC |
| **Remote Deploy** (우측 상단 기기 아이콘) | 연결된 실기기 |

실행 버튼을 기기로 향하게 하는 설정은 **없다.** 아이콘이 안 보이면 조건이 안 맞은 것이다.

| 조건 | 확인 |
|---|---|
| preset `runnable=true` + 위 ②③④⑤ | `export_presets.cfg` |
| Xcode 설치·라이선스 | `xcodebuild -version` |
| Apple 계정 로그인 | Xcode `Settings > Accounts` |
| 기기 페어링 | `xcrun devicectl list devices` 에 `available (paired)` |
| 기기 개발자 모드 | iPhone `설정 > 개인정보 보호 및 보안 > 개발자 모드` |
| **화면 잠금 해제** | 잠기면 감지되지 않는다 |
| **에디터가 preset 을 읽은 상태** | preset 을 고쳤으면 **에디터 재시작** |

마지막 항목이 특히 잘 걸린다. 에디터가 켜진 채 `export_presets.cfg` 를 텍스트로 고치면
에디터는 옛 값을 쓰고, 종료할 때 파일을 덮어쓸 수도 있다.

Remote Deploy 와 `install.sh` 는 결과가 같다. 에디터를 띄우지 않는 작업에서는 `install.sh` 를 쓴다.

---

## 6. 자주 막히는 지점

| 증상 | 원인 | 해결 |
|---|---|---|
| 실행 버튼을 눌렀는데 데스크톱 창이 뜬다 | 정상 동작이다 | Remote Deploy 또는 `install.sh` 를 쓴다 |
| Remote Deploy 아이콘이 없다 | preset 또는 기기 조건 미충족 | §5 표를 위에서부터 점검. 고친 뒤 **에디터 재시작** |
| `kAMDMobileImageMounterDeviceLocked` | iPhone 화면이 잠김 | 잠금 해제 후 재실행 |
| iOS export 오류 본문이 비어 있다 | 헤드리스에서 iOS 검증이 메시지를 안 낸다(실측) | 아이콘 → Team ID → bundle id → `ios.zip` 순 점검 |
| `.ipa` 가 안 생긴다 | `export_project_only=true` | `false` 로 바꾼다 |
| `res://build/...` PNG 임포트 오류가 쏟아진다 | Xcode 가 만든 `CgBI` PNG 를 Godot 이 못 읽는다 | 빌드 폴더에 빈 `.gdignore` 를 둔다 |
| 빌드가 시뮬레이터용 패치본을 지운다 | `delete_old_export_files_unconditionally=true` | `false` 로 두고 출력 폴더를 분리한다 |
| Android APK 서명 실패 | Android SDK build-tools 의 `apksigner` 경로 미설정 | 에디터 설정 `Export > Android` 에서 SDK 경로 지정 |
| 헤드리스 검사가 출력 없이 돌아오지 않는다 | `quit()` 을 안 불렀거나 · `frame_post_draw` 를 `await` 했거나(헤드리스에는 안 온다) · 파싱 오류 | `--quit-after` 로 상한을 두고, 헤드리스면 `process_frame` 으로 분기 (§2-A ②③) |
| 헤드리스에서 PNG 가 안 생긴다 · `ERROR: Parameter "t" is null.` | 헤드리스는 그리지 않는다(이미지 `null`) | `scripts/xvfb_run.sh` 로 찍는다 (§7) |
| 헤드리스 `--write-movie` 가 종료 코드 134 | 같은 이유 | 같은 해결 (§7) |
| 헤드리스에서 버튼에 입력을 넣었는데 반응이 없다 | 창이 64×64 라 논리 좌표가 창 밖이다 | `root.push_input(이벤트, true)` (§2-A ①) |
| 창을 화면 밖·최소화·`no_focus` 로 띄워도 사람 화면에 뜬다 | macOS 에서는 숨길 수 없다(실측) | 컨테이너 (§7) |
| 컨테이너에서 `xvfb-run` 이 로그 한 줄 없이 멈춘다 | `xvfb-run` 이 컨테이너 PID 1 이 됐다 | `docker run --init` (§7) |

### `.gdignore` 와 `exclude_filter` 는 다른 문제다

| | 뜻 |
|---|---|
| `exclude_filter="builds/*"` | 게임 패키지에 **포함하지 않는다** |
| `builds/.gdignore` (빈 파일) | Godot 이 그 폴더를 **임포트조차 하지 않는다** |
| `.cowork/.gdignore` · `build/.gdignore` 같은 **사본·프로브 폴더** | **GDScript LSP** 가 그 안의 `.gd` 를 파싱하지 않는다 — 4.7 `gdscript_workspace.cpp` `list_script_files` 는 `.gdignore` 폴더를 건너뛰지만 **점(`.`) 폴더는 건너뛰지 않는다**(에디터 FileSystem 과 다르다). 사본의 `class_name` 이 정본과 충돌해 `LSP: Failed to parse script … hides a global script class` 가 쏟아지면 이것이다(실측 2026-09-09: 37건 → 0건). `-s res://…` 실행과 `FileAccess` 는 그대로 된다 |

빌드 산출물이 `res://` 안에 있으면 **둘 다** 해 둔다.

🛑 에디터 FileSystem 스캔은 `project.godot` 검사가 `.gdignore` 검사보다 **먼저**라, `.gdignore` 를 둔 하위 프로젝트 폴더도
`Detected another project.godot at …` 경고가 **첫 후보 하나만**(`WARN_PRINT_ONCE`) 남는다. 무해하다. 없애려면 그 폴더를
`.gdignore` 가 있는 **상위 폴더 안**으로 옮긴다.

🛑 **`.gdignore` 는 폴더 전용이고, 이름이 `.godotignore` 가 아니며, 내용을 적는 파일도 아니다.** 숨길 폴더 **안에 빈 파일**로 넣는다. 개별 파일을 독에서 치우는 법(확장자 화이트리스트)까지 포함한 전체 설명은 → [basics/06-editor-screen.md](basics/06-editor-screen.md) 의 "FileSystem 독에서 파일·폴더를 숨긴다"

---

## 7. 사람 화면 없이 그림을 얻는다 — 가상 모니터

> 🖥 **정본은 [virtual-monitor.md](virtual-monitor.md) 로 옮겼다** — 실행 → 스크린샷 → 검증 절차 · 복사해 쓰는 촬영 검사 뼈대 · `xvfb_run.sh` · 증명 · 속도 · 함정.

헤드리스는 그리지 않고([§2-A](#2-a-헤드리스가-하는-일과-못-하는-일)), macOS 의 Godot 창은 숨길 수 없다. 남는 길은
**메모리 속 화면(가상 모니터)을 만들고 거기에 창을 띄우는 것**이다 — 리눅스 컨테이너 안의 Xvfb 에서 그리므로 사람 화면에는 아무것도 뜨지 않는다.

```bash
bash .claude/skills/godot/scripts/xvfb_run.sh -s res://tests/login_screen_shot.gd   # ① 실행 → ② 검사가 SHOT_DIR 에 PNG 저장
```

③ **판정 숫자를 보고, 저장된 PNG 를 직접 열어 확인한다.** 🛑 소프트웨어 렌더링이라 fps 측정에는 쓰지 않는다.

---

## 관련 문서

- [export-build.md](export-build.md) — 템플릿 개념, 필요 파일 판정표, CLI 전체
- [export-build-ios.md](export-build-ios.md) — iOS 서명·Xcode·TestFlight
- [export-build-android.md](export-build-android.md) — Android APK·AAB·adb
- [lsp.md](lsp.md) — LSP 정적 검증 (코드 작성 직후 필수)
- [virtual-monitor.md](virtual-monitor.md) — 🖥 가상 모니터: 화면에 안 보이게 실행해 스크린샷·녹화·검증 (정본)
- [../scripts/xvfb_run.sh](../scripts/xvfb_run.sh) — 가상 모니터 도구 (이미지 정의는 [../scripts/xvfb/Dockerfile](../scripts/xvfb/Dockerfile))
- `docs/godot/에디터 없이 작업.md` §13 — 사람이 읽는 전 과정 예제

## 공식 문서

- Command line tutorial: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- Using an external text editor: https://docs.godotengine.org/en/stable/tutorials/editor/external_editor.html
- One-click deploy: https://docs.godotengine.org/en/stable/tutorials/export/one-click_deploy.html
- Overview of debugging tools: https://docs.godotengine.org/en/stable/tutorials/scripting/debug/overview_of_debugging_tools.html
- Exporting for dedicated servers(헤드리스 서버 실행): https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html
- Creating movies(Movie Maker · `--write-movie`): https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html
- Xvfb: https://manpages.debian.org/unstable/xvfb/Xvfb.1.en.html · Mesa 환경변수(`LIBGL_ALWAYS_SOFTWARE`): https://docs.mesa3d.org/envvars.html
