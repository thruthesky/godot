# 가상 모니터 — 화면에 안 보이게 실행해 스크린샷·녹화하고 검증한다

> **이 문서로 오는 상황** — 🖥 사람이 쓰는 화면에 게임 창을 띄우지 않고 실행해 **스크린샷·녹화를 얻고 검증**해야 할 때 · AI 가 자율적으로 화면을 검증할 때 · "헤드리스로 스크린샷이 되나?"(→ 안 된다. 이 문서의 방법을 쓴다) · `scripts/xvfb_run.sh` 사용법·증명·속도·함정

**가상 모니터**는 실제 모니터 대신 **메모리 속에만 있는 화면**이다. Godot 은 거기에 창을 띄우고 **실제로 그리므로**
스크린샷·녹화가 나오지만, 사람이 보는 모니터에는 **창도 Dock 아이콘도 포커스 변화도 생기지 않는다.**
이 스킬은 Docker 리눅스 컨테이너 안에서 **Xvfb** 로 가상 모니터를 만들고, 한 줄 도구 `scripts/xvfb_run.sh` 로 쓴다.

## 목차

1. [왜 가상 모니터인가 — 헤드리스·macOS 창으로는 안 된다](#1-왜-가상-모니터인가--헤드리스macos-창으로는-안-된다)
2. [AI 자율 개발의 화면 검증 — 실행 → 스크린샷 → 검증](#2-ai-자율-개발의-화면-검증--실행--스크린샷--검증)
3. [촬영 검사 뼈대 — 복사해 쓰는 GDScript](#3-촬영-검사-뼈대--복사해-쓰는-gdscript)
4. [`scripts/xvfb_run.sh` — 한 줄로 실행](#4-scriptsxvfb_runsh--한-줄로-실행)
5. [증명 — 사람 화면에 안 뜨고, 그림은 나온다](#5-증명--사람-화면에-안-뜨고-그림은-나온다)
6. [속도](#6-속도)
7. [함정](#7-함정)

---

## 1. 왜 가상 모니터인가 — 헤드리스·macOS 창으로는 안 된다

| 방법 | 사람 화면 | 스크린샷·녹화 | 쓰임 |
|---|---|---|---|
| `godot --headless` | 창 0개 · 포커스 그대로 | 🛑 **안 된다** — 이미지 `null` · `--write-movie` 종료 코드 134. 렌더링 드라이버 지정 · `SubViewport` · `force_draw()` 로 우회해도 **맥 6 · 리눅스 4 조합 모두 `null`** | 로직·배치(숫자)·입력 검사 |
| macOS 창 (`--headless` 없이) | 🛑 **창이 뜨고 전면 앱을 가져간다** — 화면 밖 좌표 · 최소화 · `no_focus` 로도 못 숨긴다 | 된다 | 사람이 직접 볼 때만 |
| **가상 모니터** (`xvfb_run.sh`) | **창 0개 · 포커스 그대로** | ✅ **된다** — 메인 뷰포트 · `SubViewport` · 녹화 모두 | **AI 의 화면 검증** |

헤드리스가 그리지 못하는 이유는 엔진 소스에 적혀 있다(4.7.2-stable) — `main/main.cpp` 가 `--headless` 에
`// enable headless mode (no audio, no rendering).` 라고 달고, `servers/display/display_server_headless.h` 가 허용하는
렌더링 드라이버는 `dummy` 하나뿐이다. 조합별 실측표는 [headless-workflow.md §2-A](headless-workflow.md#2-a-헤드리스가-하는-일과-못-하는-일).

| 가상 모니터의 부품 | 하는 일 |
|---|---|
| **Xvfb**(X virtual framebuffer) | 리눅스에서 메모리 속에만 있는 화면을 만든다. 모니터가 없어도 창이 "뜬다" |
| **Mesa** 소프트웨어 렌더러 | GPU 없이 CPU 로 그린다 — OpenGL 은 `llvmpipe`, Vulkan 은 `lavapipe` |
| **Docker** 컨테이너 | 맥에서 리눅스를 돌린다. 컨테이너는 macOS 창을 만들 수 없으므로 **사람 화면과 완전히 분리된다** |

---

## 2. AI 자율 개발의 화면 검증 — 실행 → 스크린샷 → 검증

> 🛑 사람 개발자가 같은 컴퓨터에서 일한다. **AI 가 화면을 확인해야 하면 사람 화면이 아니라 가상 모니터에서 한다.**
> 그림이 필요 없는 검사(로직·네트워크·배치 숫자)는 그냥 `--headless` 로 돌린다 — 가상 모니터보다 빠르다.

| 단계 | 하는 일 | 명령·코드 |
|---|---|---|
| **① 실행** | 촬영 검사 스크립트를 가상 모니터에서 돌린다 | `bash .claude/skills/godot/scripts/xvfb_run.sh --out .cowork/<작업>/artifacts -s res://tests/<이름>_shot.gd` |
| **② 스크린샷** | 화면이 자리 잡으면 `RenderingServer.force_draw()` 뒤 뷰포트 이미지를 `SHOT_DIR` 에 PNG 로 저장한다 | [§3 뼈대](#3-촬영-검사-뼈대--복사해-쓰는-gdscript) |
| **③ 검증** | 아래 네 가지를 **모두** 한다 | |

**③ 검증에서 하는 것**

| # | 무엇을 | 어떻게 | 왜 |
|---|---|---|---|
| 1 | 종료 코드 · 판정 줄 | `xvfb_run.sh` 종료 코드 `0` · `✅ N/N 통과` | 기계가 판정한 결과 |
| 2 | 🛑 **PNG 를 직접 연다** | 저장된 PNG 를 이미지로 열어 본다(Claude 는 Read) | 노드·숫자 검사는 통과했는데 **완성 화면은 비어 있거나 겹쳐 있던** 사례가 여러 번 있었다. **열어 보지 않은 스크린샷은 검증이 아니다** |
| 3 | 색·위치를 숫자로 | `python3 .claude/skills/godot/scripts/png_pixel.py <png> [x y]` — 좌표를 빼면 9곳 자동 샘플 | 눈대중은 어긋난다. 단색(빈 화면)도 숫자로 잡힌다 |
| 4 | 녹화라면 프레임을 뽑아 본다 | `ffprobe -count_frames …` 로 프레임 수 · `ffmpeg -ss 2.5 -i <avi> -frames:v 1 frame.png` 로 한 장 뽑아 연다 | 영상 파일이 생긴 것과 그림이 맞는 것은 다르다 |

보고에는 **명령 · 판정 숫자 · PNG 경로 · "가상 모니터에서 확인했다"** 를 적는다.
🛑 가상 모니터는 **소프트웨어 렌더링**이다 — 그림이 맞는지만 본다. **fps·프레임 시간은 여기서 재지 않는다**(실기기에서 잰다).

---

## 3. 촬영 검사 뼈대 — 복사해 쓰는 GDScript

`tests/<이름>_shot.gd` 로 복사하고 `SCENE` 과 판정만 바꾼다.

**실측(2026-09-14)** — 가상 모니터에서 **2/2 통과 · 3.8초 · 사람 화면에 새로 생긴 창 0개**(WindowServer 16회 조회).
같은 파일을 `--headless` 로 돌리면 **종료 코드 2** 와 "헤드리스에는 그림이 없다" 를 찍고 멈춘다.

```gdscript
extends SceneTree
## 🖥 가상 모니터 촬영 검사의 뼈대 — 씬을 열고 · 자리 잡을 때까지 기다리고 · 찍고 · 숫자로 판정하고 · 끝낸다.
## 실행: bash .claude/skills/godot/scripts/xvfb_run.sh -s res://tests/virtual_monitor_shot.gd
## 종료 코드: 0 통과 · 1 판정 실패 · 2 헤드리스로 잘못 실행(그림이 없다)

const SCENE := "res://scene.tscn"      # 찍을 씬 — 바꿔 쓴다
const SETTLE_FRAMES := 30              # 씬 전환·비동기 로드·레이아웃이 자리 잡을 프레임 수

var _frames := 0
var _checks := 0
var _failures := 0


func _initialize() -> void:
	change_scene_to_file(SCENE)


func _process(_delta: float) -> bool:
	# 🛑 _process 안에서 await 하지 않는다 — 판정 없이 끝난다. 프레임 수로 기다린다
	_frames += 1
	if _frames == SETTLE_FRAMES:
		_shoot_and_judge()
	return false


func _shoot_and_judge() -> void:
	# 🛑 --headless 에는 그림이 없다(이미지 null). 조용히 통과시키지 말고 실패로 알린다
	if DisplayServer.get_name() == "headless":
		printerr("❌ 헤드리스에는 그림이 없다 — xvfb_run.sh(가상 모니터)로 실행한다")
		quit(2)
		return
	RenderingServer.force_draw()                        # 이 프레임을 확실히 그린 뒤 읽는다
	var img := root.get_texture().get_image()
	var dir := OS.get_environment("SHOT_DIR")           # xvfb_run.sh 는 /out 을 넣어 준다
	if dir.is_empty():
		dir = OS.get_user_data_dir()
	var path := dir.path_join("shot_%dx%d.png" % [img.get_width(), img.get_height()])
	img.save_png(path)
	print("[SHOT] ", path)

	# 판정은 눈대중이 아니라 숫자로 — 아래는 "화면이 비지 않았다" 는 최소 판정의 예
	var colors := {}
	for gy in 4:
		for gx in 4:
			var p := Vector2i(int((gx + 0.5) * img.get_width() / 4.0), int((gy + 0.5) * img.get_height() / 4.0))
			colors[img.get_pixelv(p).to_html(false)] = true
	_check(colors.size() >= 2, "화면이 단색이 아니다", "격자 16점 색 %d종" % colors.size())
	_check(img.get_width() > 0 and img.get_height() > 0, "이미지 크기가 있다", "%dx%d" % [img.get_width(), img.get_height()])

	print("%s virtual_monitor_shot: %d/%d 통과" % ["✅" if _failures == 0 else "❌", _checks - _failures, _checks])
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, label: String, detail := "") -> void:
	_checks += 1
	if ok:
		print("   ✅ %s  %s" % [label, detail])
	else:
		_failures += 1
		printerr("   ❌ %s  %s" % [label, detail])
```

| 이 코드가 이렇게 쓴 이유 | |
|---|---|
| `SETTLE_FRAMES` 로 기다린다 | `SceneTree` 스크립트의 `_process` 안에서 `await` 하면 판정 없이 끝난다. 비동기로 읽어 붙이는 화면(키 아트·스트리밍 에셋)은 **다 붙었다는 신호를 확인한 뒤** 찍는다 — 프레임 수만 기다리면 빈 칸이 찍힌다 |
| `RenderingServer.force_draw()` | 이 프레임을 확실히 그린 뒤 읽는다. `await RenderingServer.frame_post_draw` 는 창이 가려지거나 헤드리스면 오지 않아 멈출 수 있다 |
| 헤드리스면 `quit(2)` | 헤드리스에서는 이미지가 `null` 이다 — 조용히 통과시키면 "검증했다" 는 착각이 남는다 |
| `SHOT_DIR` | `xvfb_run.sh` 가 컨테이너 `/out` 을 넣어 준다. 🛑 인자에 호스트 경로를 쓰지 않는다 |
| 입력이 필요하면 | 찍기 전에 `Input.parse_input_event()` 나 `root.push_input(이벤트, true)` 로 터치·클릭을 넣고 몇 프레임 기다린다 |
| 판정을 늘릴 때 | 노드 위치·크기(`get_global_rect()`)와 픽셀 색(`img.get_pixelv()`)을 **둘 다** 본다 — 노드는 있는데 안 그려진 경우를 픽셀이 잡는다 |

---

## 4. `scripts/xvfb_run.sh` — 한 줄로 실행

```bash
bash .claude/skills/godot/scripts/xvfb_run.sh -s res://tests/login_screen_shot.gd        # 검사 스크립트 — SHOT_DIR=/out
bash .claude/skills/godot/scripts/xvfb_run.sh --size 1280x720 res://scenes/x.tscn --quit-after 120
bash .claude/skills/godot/scripts/xvfb_run.sh --movie login.avi --frames 300 --fps 30    # main_scene 녹화
bash .claude/skills/godot/scripts/xvfb_run.sh --mobile -s res://tests/x.gd               # Mobile 렌더러(느리다)
bash .claude/skills/godot/scripts/xvfb_run.sh --out .cowork/<작업>/artifacts -s res://tests/x.gd
bash .claude/skills/godot/scripts/xvfb_run.sh --help                                     # 옵션 전체
```

| 단계 | 하는 일 |
|---|---|
| 이미지 | [`scripts/xvfb/Dockerfile`](../scripts/xvfb/Dockerfile) 로 `godot-xvfb:<버전>-<arch>` 를 처음 한 번 만든다. 버전은 호스트 `godot --version` 을 따른다(사본의 임포트 캐시와 맞추려고) |
| 사본 | `~/Library/Caches/godot-xvfb/<프로젝트>-<cksum>/proj` 로 rsync. 첫 사본만 호스트 `.godot` 을 가져가고 이후엔 컨테이너의 것을 지킨다. 뺄 경로는 프로젝트 루트 **`.xvfbignore`**(rsync 패턴) |
| 임포트 | 첫 사본 · `--import` · 또는 **임포트가 필요한 변경**이 있을 때만 — 새 에셋 · 크기가 바뀐 에셋(`.import` 포함) · 새 `.gd`(class_name 캐시). 시간만 바뀐 파일 · `.tscn`·`.tres`·`.md`·`.translation`·`.uid`·`.cfg`·`.json` · 기존 `.gd` 수정 · `.gdignore` 폴더 안은 보지 않는다. 임포트할 때는 이유가 된 파일을 찍는다. 🛑 크기가 같은 에셋 수정은 놓치므로 그림이 옛것이면 `--import` |
| 실행 | `docker run --init` · 호스트 사용자 권한 · `xvfb-run` · `--display-driver x11 --audio-driver Dummy` · 기본 렌더러 `gl_compatibility`(라리엔 3D 는 `rendering_method.mobile="gl_compatibility"` 라 **폰과 같은 렌더러**다) |
| 산출물 | 컨테이너 `/out`(= `SHOT_DIR`) → 호스트 `<캐시>/<프로젝트>/out` 또는 `--out` |
| 종료 코드 | godot 의 종료 코드를 그대로 돌려준다 · 제한 시간(`--timeout`, 기본 600초) 초과는 124 · 도구 오류(Docker 꺼짐 등)는 2 |

- 🛑 godot 인자에 **호스트 경로를 쓰지 않는다** — 컨테이너 안에는 `/work/proj`(= `res://`)와 `/out` 뿐이다.
- 🛑 컨테이너마다 `user://` 가 비어 있다 — 로그인 세션·설정이 남지 않는다(검사 재현성에는 오히려 좋다).
- 🛑 Docker Desktop 이 켜져 있어야 한다. 첫 실행은 이미지 빌드·프로젝트 사본(라리엔 3D 약 14GB)·임포트가 붙는다.

---

## 5. 증명 — 사람 화면에 안 뜨고, 그림은 나온다

### 사람 화면 — 실행하는 동안 WindowServer 창 목록을 계속 조회했다

Godot 이 스스로 보고하는 값이 아니라, 실행 중에 macOS 의 화면 전체 창 목록(`CGWindowListCopyWindowInfo`)을
외부 프로세스에서 반복 조회해 **실행 전에 없던 창**을 소유 앱 이름과 함께 뽑았다(2026-09-13~14 · macOS 26.6 · 모니터 3대).

| 실행 | 조회 | 실행 중 새로 생긴 창 |
|---|---|---|
| 가상 모니터 — 촬영 검사 뼈대(§3) | 0.2초마다 16회 | **0개** |
| 가상 모니터 — 라리엔 3D 로그인 화면(첫 사본·임포트 포함 72초) | 0.5초마다 131회 | **Godot·Docker 창 0개** — 잡힌 7개는 그 사이 사람이 쓴 Finder 6개·ChatGPT 1개 |
| `--headless` 6개 조합(맥) | 0.1초마다 | **Godot 창 0개** |
| macOS 창 + 화면 밖 좌표·최소화·`no_focus` (대조군) | — | 🛑 3개 방식 모두 **보이는 모니터에 창이 떴다** |

### 그림 — 캡처 경로마다 실제로 그려졌다

장면은 파란 배경 위 빨간 상자 하나. 가운데 픽셀 `(1,0,0)` · 모서리 `(0.098,0.2,0.8)` 이면 "그림" 으로 판정했다.

| 실행 | 메인 뷰포트 | `SubViewport` | `force_draw()` 뒤 | `frame_post_draw` |
|---|---|---|---|---|
| `--headless` (맥 6 · 리눅스 4 조합) | null | null | null | 90프레임에 1회 |
| 가상 모니터 없이 `--display-driver x11` | 🛑 실행 실패 | `X11 Display is not available` | → `Unable to create DisplayServer` | 종료 코드 1 |
| **가상 모니터 · Compatibility** | ✅ 1152×648 | ✅ 160×120 | ✅ | 90프레임에 90회 |
| **가상 모니터 · Mobile(Vulkan `lavapipe`)** | ✅ 1152×648 | ✅ 160×120 | ✅ | 90프레임에 90회 |
| **라리엔 3D 로그인 화면** | ✅ 720×1600 · 판정 25/25 · 픽셀 9곳이 서로 다른 색 · PNG 를 열어 키 아트·3D 캐릭터·버튼 확인 | | | |

### 다른 팀이 제시한 방식을 그대로 재현했다

2026-09-13 · Docker 29.3(linux/aarch64) · Ubuntu 22.04 · Mesa 23.2 · 공식 `Godot_v4.7.2-stable_linux.arm64`.

```bash
xvfb-run -a -s "-screen 0 1280x720x24" \
  env LIBGL_ALWAYS_SOFTWARE=true \
  godot --path "/path/to/project" --display-driver x11 --rendering-method gl_compatibility \
  --resolution 1280x720 --write-movie "/tmp/game-test.avi" --fixed-fps 30 --quit-after 300
```

| 주장 | 실측 |
|---|---|
| `--headless` 로는 캡처·녹화를 못 한다 | ✅ **맞다** — 맥·컨테이너 둘 다 이미지 `null`, 녹화는 종료 코드 134 |
| 가상 디스플레이에서는 렌더링·스크린샷·녹화가 된다 | ✅ **맞다** — MJPEG 30fps AVI 5.7MB, `ffprobe` 로 300프레임 확인 · 스크린샷 픽셀 판정 통과 |
| 1280×720 영상이 나온다 | ⚠️ **아니다 — 1152×648 로 녹화됐다.** 녹화 크기는 `--resolution` 이 아니라 **`display/window/size/viewport_width`·`viewport_height`** 를 따른다. 뷰포트를 1280×720 으로 설정하자 1280×720, `--resolution 640x360` 만 준 것은 기본값 1152×648 |
| 약 10초 분량이고 처리 시간은 그와 다를 수 있다 | ✅ 300프레임(10초 분량) 녹화에 **3.8초** — `--fixed-fps` 가 실시간 동기화를 끈다 |
| `LIBGL_ALWAYS_SOFTWARE=true` 를 준다 | 컨테이너에는 GPU 가 없어 **빼도 `llvmpipe` 로 그렸다** |
| Compatibility 렌더러로 실행 가능한 프로젝트라면 | **Mobile 렌더러(Vulkan)도 `lavapipe` 로 그려진다** — 대신 첫 프레임까지 3.8초(셰이더 컴파일) |
| 녹화 명령만으로 게임이 자동 플레이되지는 않는다 | ✅ 맞다 — 입력은 `-s` 검사 스크립트가 넣는다 |
| AI 가 스크린샷을 보고 판단한다 | ✅ 라리엔 3D 로그인 화면을 가상 모니터에서 찍어 판정 전부 통과 · PNG 와 녹화 프레임을 열어 확인 |

---

## 6. 속도

Apple M5 Max · Docker 18 CPU.

| 작업 | 시간 |
|---|---|
| 맥 헤드리스 검사(빈 프로젝트 · 60프레임) — 비교용 | 0.6초 |
| 가상 모니터 — 촬영 검사 뼈대(빈 프로젝트 · 첫 사본·임포트 포함) | 3.8초 |
| 가상 모니터 — 녹화 300프레임(빈 프로젝트 · Compatibility) | 4.1초 |
| 가상 모니터 — 스크린샷(빈 프로젝트 · Mobile·Vulkan `lavapipe`) | 7.1초 |
| **`xvfb_run.sh` 라리엔 3D 로그인 화면 — 임포트 생략**(25개 판정 · 다른 세션 변경 634건 동기화 포함) | **11.6초** (컨테이너 안 4초) |
| `xvfb_run.sh` 같은 촬영 — 임포트함 | 약 25초 |
| `xvfb_run.sh --mobile` 같은 촬영(임포트 생략) | 14.1초 |
| 라리엔 3D 첫 촬영(사본 14GB 53초 + 임포트 약 24초 포함) | 72초 |
| 이미지 빌드(처음 한 번 · 695MB) | 52.8초 (apt 층이 캐시에 있으면 약 11초) |

재임포트(라리엔 3D 사본 약 20초)가 촬영보다 비싸므로 도구는 **임포트를 필요할 때만** 한다. 같은 작업 트리를 다른 세션이
계속 고치는 곳에서는 "무엇이든 바뀌면 임포트" 가 거의 매번 임포트가 된다(실측: 촬영 사이 668건 — 대부분 `.gdignore` 폴더 안의 빌드 산출물).

---

## 7. 함정

| 증상 | 원인 | 해결 |
|---|---|---|
| `--headless` 로 찍었는데 PNG 가 없다 · `ERROR: Parameter "t" is null.` | 헤드리스는 그리지 않는다 — 드라이버를 바꿔도 우회되지 않는다 | 가상 모니터(`xvfb_run.sh`) |
| 컨테이너가 로그 한 줄 없이 영원히 멈춘다(6분) — 안에 godot 프로세스조차 없다 | `docker run … bash -c 'cd … && xvfb-run …'` 은 bash 가 마지막 명령을 `exec` 해 **`xvfb-run` 이 PID 1** 이 된다. Xvfb 가 보내는 준비 신호를 받지 못하고 기다리기만 한다 | **`docker run --init`** — 같은 명령이 곧바로 끝났다(도구가 이미 붙인다) |
| `ERROR: X11 Display is not available` → `Unable to create DisplayServer` | 가상 모니터 없이 `--display-driver x11` 로 띄웠다 | `xvfb-run` 으로 감싼다 |
| `ERROR: … ERR_CANT_OPEN` `at: init_output_device (drivers/alsa/audio_driver_alsa.cpp)` | 컨테이너에 사운드 장치가 없어 더미로 넘어간다(무해) | `--audio-driver Dummy` |
| `ERROR: No GDExtension library found for current OS and architecture (linux.arm64)` | 프로젝트의 GDExtension 에 리눅스 바이너리가 없다(라리엔 3D: `godot_iap`·`laryen_social_auth`) | 그 확장 없이 뜨는 화면만 찍는다. **ERROR 줄 수로 실패를 세는 검사는 이 줄을 거른다** |
| 영상 크기가 기대와 다르다 | 녹화는 뷰포트 설정 크기를 따른다 | `viewport_width/height` 를 맞추거나 스크린샷을 쓴다 |
| 코드를 고쳤는데 PNG 가 옛 그림이다 | 크기가 같은 에셋 수정은 임포트 판정이 놓친다 | `--import` 로 다시 돈다 |
| 찍은 화면에 키 아트·에셋이 비어 있다 | 비동기 로드가 끝나기 전에 찍었다(제품은 정상인데 사진만 빈다) | 로드 완료를 확인한 뒤 찍는다(§3) |
| 원본 프로젝트를 마운트하면 사람 에디터의 임포트 캐시가 흔들린다 | 리눅스 Godot 이 `.godot/` 를 고쳐 쓴다 | **사본**을 마운트한다 — 도구가 한다 |
| 가상 모니터에서 fps 가 낮다 | GPU 없는 소프트웨어 렌더링이다 | 🛑 성능은 여기서 판단하지 않는다 → 실기기 · [perf-tuning-playbook.md](perf-tuning-playbook.md) |

---

## 관련 문서

- [headless-workflow.md §2-A](headless-workflow.md#2-a-헤드리스가-하는-일과-못-하는-일) — 헤드리스로 되는 것·안 되는 것 · 우회 시도 전체 표 · 입력 좌표 함정(`push_input`)
- [../scripts/xvfb_run.sh](../scripts/xvfb_run.sh) — 가상 모니터 도구 · 이미지 정의 [../scripts/xvfb/Dockerfile](../scripts/xvfb/Dockerfile)
- [../scripts/png_pixel.py](../scripts/png_pixel.py) — PNG 픽셀 색을 숫자로 잰다
- [perf-tuning-playbook.md](perf-tuning-playbook.md) — 성능은 실기기에서

## 공식 문서

- Exporting for dedicated servers(헤드리스): https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html
- Creating movies(Movie Maker · `--write-movie`): https://docs.godotengine.org/en/stable/tutorials/animation/creating_movies.html
- Command line tutorial: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- Xvfb: https://manpages.debian.org/unstable/xvfb/Xvfb.1.en.html · Mesa 환경변수(`LIBGL_ALWAYS_SOFTWARE`): https://docs.mesa3d.org/envvars.html
