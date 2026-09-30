# `/godot install-godotty` — Godotty 터미널 애드온 설치

> **이 문서로 오는 상황** — 사용자가 **`/godot install-godotty`** 라고 지시했을 때 ·
> "Godotty 설치해 줘"·"에디터 안에 터미널 애드온 넣어 줘" 처럼 **Godotty 설치를 요청**했을 때 ·
> Godotty 를 설치했는데 하단 **Terminal** 버튼이 안 보일 때

**Godotty** 는 Godot 에디터 안에 진짜 터미널(셸)을 띄우는 애드온이다([thruthesky/godotty](https://github.com/thruthesky/godotty) — 원본
[ingur/godotty](https://github.com/ingur/godotty) 에 여러 터미널을 격자로 동시에 보이는 기능을 더한 판).
Rust 로 만든 **GDExtension** 이라 GDScript 애드온과 달리 운영체제별 **실행 바이너리**(`.dylib`·`.dll`·`.so`)가 함께 들어 있다.

## 목차

1. [한 줄 실행](#1-한-줄-실행)
2. [절차 — 사용자가 준 설치 요청문 7단계](#2-절차--사용자가-준-설치-요청문-7단계)
3. [설치 결과 — 무엇이 어디에 생기나](#3-설치-결과--무엇이-어디에-생기나)
4. [검증 — 파일 · 헤드리스 · 화면](#4-검증--파일--헤드리스--화면)
5. [🛑 실측 함정](#5--실측-함정)
6. [보고 형식](#6-보고-형식)
7. [설치한 뒤 — git · export](#7-설치한-뒤--git--export)
8. [Windows 에서 스크립트 없이](#8-windows-에서-스크립트-없이)

---

## 1. 한 줄 실행

```bash
bash .claude/skills/godot/scripts/install_godotty.sh --dry-run          # 먼저 무엇을 할지 본다
bash .claude/skills/godot/scripts/install_godotty.sh                    # 현재 폴더의 프로젝트에 v0.9.7
bash .claude/skills/godot/scripts/install_godotty.sh --project ~/game   # 대상 지정
```

| 옵션 | 뜻 |
|---|---|
| `--project <경로>` | `project.godot` 이 있는 폴더. 없으면 현재 폴더에서 **위로** 찾고, 없으면 **아래로 3단계** 찾는다 |
| `--version <태그>` | 릴리스 태그 (기본 `v0.9.7`) |
| `--zip <파일>` | 이미 받은 설치 ZIP 을 쓴다. 해시 대조는 그대로 한다 |
| `--godot <실행 파일>` | Godot 에디터 (기본 `$GODOT` → PATH 의 `godot` → `/Applications/Godot.app`) |
| `--skip-verify` | 헤드리스 확장 로드 검사를 건너뛴다 (큰 프로젝트의 첫 스캔이 몇 분 걸릴 때) |
| `--dry-run` | 대상·버전·에디터 실행 여부까지만 보고 파일은 바꾸지 않는다 |

| 종료 코드 | 뜻 | 할 일 |
|---|---|---|
| 0 | 설치·검증 통과 | 보고 (§6) |
| 2 | 대상 프로젝트가 없거나 여러 개 | **사용자에게 대상 경로를 묻는다** — 추측해 고르지 않는다 |
| 3 | 대상 프로젝트를 연 Godot 이 실행 중 | **저장하고 그 에디터를 닫아 달라고 안내**하고 멈춘다. 대신 종료하지 않는다 |
| 4 | Godot 없음 · 4.7 미만 | 알린다. 에디터를 받거나 올리지 않는다 |
| 5 | 다운로드·해시·ZIP 구성 실패 | 원인을 보고한다. Source code ZIP 으로 대신하지 않는다 |
| 6 | 설치 뒤 파일·헤드리스 검사 실패 | 출력의 ❌ 항목으로 진단한다(§5) |

스크립트는 **설명으로 끝내지 않고 실제로 받고 복사한다.** 스크립트를 쓸 수 없는 환경이면 §2 를 손으로 그대로 따른다.

## 2. 절차 — 사용자가 준 설치 요청문 7단계

아래가 정본이다(2026-09-30 사용자 지시 · 원문은 [godotty README](https://github.com/thruthesky/godotty/blob/main/README.md) 의 "AI 에이전트에 그대로 복사할 설치 요청문").
오른쪽 열은 `install_godotty.sh` 가 그 단계를 어떻게 하는지다.

| # | 요청문 | 스크립트가 하는 것 |
|---|---|---|
| 0 | Godot 엔진·에디터는 이미 설치돼 있다. **다운로드·재설치하지 않는다.** Rust·Zig·Git 설치나 소스 빌드 없이 **완성된 설치 ZIP 만** 쓴다 | 에디터는 찾기만 한다. 받는 것은 `godotty-v0.9.7.zip` 하나 |
| 1 | `project.godot` 이 있는 **프로젝트 루트**를 확인한다. 없거나 여러 개라 불명확하면 **대상 경로를 묻는다.** 설치된 에디터가 **4.7 이상**인지 확인하고, 아니면 알린다 | 위로 → 아래로 탐색, 0개·여러 개면 종료 2 · `godot --version` 이 4.7 미만이면 종료 4 |
| 2 | 대상 프로젝트의 에디터가 실행 중이면 **저장하고 종료하도록 안내한 뒤** 설치한다. **로드 중인 라이브러리를 덮어쓰거나, 다른 프로젝트를 임의로 종료하지 않는다** | `ps` 의 `--path` · 프로세스 cwd · 기존 바이너리를 연 프로세스(`lsof`)로 판정 → 종료 3. 다른 프로젝트의 에디터는 무시 |
| 3 | ZIP 을 **프로젝트 바깥 임시 폴더**로 받아 푼다. GitHub **Code → Download ZIP·Source code ZIP 으로 대신하지 않는다** | `mktemp -d` (프로젝트 안이면 중단) · 릴리스 digest 와 **sha256 대조** · 안에 `addons/godotty/godotty.gdextension` 이 없으면 종료 5 |
| 4 | 압축을 푼 `addons/godotty` **폴더 전체**를 루트의 `addons/godotty` 로 복사한다. `addons` 가 없으면 만든다. **기존 Godotty 는 프로젝트 바깥에 백업하고 교체**한다. 다른 애드온과 `project.godot` 설정은 보존한다 | 기존 것은 `~/.godotty-backups/<프로젝트>-<시각>/godotty` 로 **옮긴다** → 새 폴더 복사 · `project.godot` 은 cksum 전후 대조 |
| 5 | `godotty.gdextension` 과 `bin` 안의 **현재 OS 용 바이너리**가 실제로 있는지 확인한다. **`addons/addons/godotty` 처럼 중첩하지 않는다. `plugin.cfg` 를 만들지 않는다** | 파일 검사 6개(§4-1) |
| 6 | 가능하면 에디터로 다시 열어 **하단 Terminal 버튼과 + 로 터미널 두 개가 동시에 보이는지** 확인한다. UI 검증이 불가능하면 **파일 검사 결과와 남은 수동 확인을 구분해서** 알린다 | 헤드리스 확장 로드 검사까지(§4-2). 화면 확인은 §4-3 |
| 7 | **실제 설치한 프로젝트 경로 · 바이너리 경로 · 검증 결과**를 알린다. 설명에서 끝내지 말고 다운로드·복사까지 한다 | 마지막 "완료" 블록 → §6 형식으로 보고 |

<details>
<summary>설치 요청문 원문 (사용자가 준 그대로)</summary>

```text
현재 작업 중인 Godot 프로젝트에 Godotty 터미널 애드온 v0.9.7을 실제로 설치해 주세요.
Godot 엔진/에디터는 이미 설치되어 있습니다. Godot 에디터를 다운로드하거나 재설치하지 마세요.
Rust, Zig, Git 설치나 소스 빌드 없이, 아래 완성된 설치 ZIP만 사용하세요.

설치 ZIP 다운로드 주소:
https://github.com/thruthesky/godotty/releases/download/v0.9.7/godotty-v0.9.7.zip
설치 방법 README:
https://github.com/thruthesky/godotty/blob/main/README.md

1. 현재 작업 폴더에서 project.godot가 있는 프로젝트 루트를 확인하세요.
   대상이 없거나 여러 프로젝트 중 어느 것인지 불명확하면 대상 경로를 물어보세요.
   이미 설치된 Godot 에디터가 4.7 이상인지 확인하세요. 버전이 맞지 않으면 알려 주세요.
2. 대상 프로젝트의 에디터가 실행 중이면 작업을 저장하고 종료하도록 안내한 뒤 설치하세요.
   로드 중인 라이브러리를 덮어쓰거나, 사용자의 다른 프로젝트를 임의로 종료하지 마세요.
3. 위 ZIP을 프로젝트 바깥의 임시 폴더로 다운로드하고 압축을 푸세요.
   GitHub Code → Download ZIP이나 Source code ZIP으로 대신 설치하지 마세요.
4. 압축을 푼 위치의 addons/godotty 폴더 전체를 대상 프로젝트 루트의
   addons/godotty로 복사하세요. 대상 addons 폴더가 없으면 만드세요.
   기존 Godotty가 있으면 프로젝트 바깥에 백업하고 교체하세요.
   다른 애드온과 project.godot의 기존 설정은 보존하세요.
5. addons/godotty/godotty.gdextension과 bin 안의 현재 OS용 바이너리가
   실제로 있는지 확인하세요. macOS는 libgodotty.macos.dylib,
   Windows는 libgodotty.windows.x86_64.dll, Linux는 libgodotty.linux.x86_64.so입니다.
   addons/addons/godotty처럼 중첩해서 설치하지 마세요. plugin.cfg도 만들지 마세요.
6. 가능하면 기존 Godot 에디터로 대상 프로젝트를 다시 열고,
   하단 Terminal 버튼과 +로 터미널 두 개가 동시에 표시되는지 확인하세요.
   UI 검증이 불가능하면 파일 검사 결과와 남은 수동 확인을 구분해서 알려 주세요.
7. 실제 설치한 프로젝트 경로, 바이너리 경로, 검증 결과를 알려 주세요.
   설치 방법을 설명하는 것에서 끝내지 말고 파일 다운로드와 복사까지 수행하세요.
```

</details>

| OS | 바이너리 (`addons/godotty/bin/`) |
|---|---|
| macOS (Intel·Apple Silicon 공용) | `libgodotty.macos.dylib` |
| Windows 10+ x86_64 | `libgodotty.windows.x86_64.dll` |
| Linux x86_64 | `libgodotty.linux.x86_64.so` |

## 3. 설치 결과 — 무엇이 어디에 생기나

```text
<프로젝트 루트>/
├── project.godot                 ← 손대지 않는다
└── addons/
    └── godotty/
        ├── godotty.gdextension   ← 엔진이 이 파일을 보고 바이너리를 읽는다
        ├── bin/
        │   ├── libgodotty.macos.dylib          (54 MB)
        │   ├── libgodotty.windows.x86_64.dll   (28 MB)
        │   └── libgodotty.linux.x86_64.so      (28 MB)
        ├── LICENSE · OFL.txt · FONTS.md
```

v0.9.7 설치 ZIP 실측(2026-09-30): 69 MB · 풀면 110 MB · sha256 `3860c9f9cad735757ae9b6f2485e8974fbd41f4456485c9e7d46169424ef7e9b`(GitHub 릴리스 digest 와 일치).

`godotty.gdextension` 의 내용 — 왜 `plugin.cfg` 가 필요 없는지가 여기 있다:

```ini
[configuration]
entry_symbol = "gdext_rust_init"
compatibility_minimum = 4.7      # ← 4.7 미만 에디터는 이 확장을 거부한다
reloadable = false               # ← 핫 리로드하면 에디터가 죽는다 → 바꾼 뒤엔 에디터를 재시작

[libraries]
linux.editor.x86_64 = "res://addons/godotty/bin/libgodotty.linux.x86_64.so"
macos.editor = "res://addons/godotty/bin/libgodotty.macos.dylib"
windows.editor.x86_64 = "res://addons/godotty/bin/libgodotty.windows.x86_64.dll"
```

- **GDExtension 은 스스로 에디터 플러그인을 등록한다.** 그래서 `Project Settings → Plugins` 에 켤 항목이 없고 `plugin.cfg` 도 없다.
  `plugin.cfg` 를 만들면 존재하지 않는 GDScript 플러그인을 찾다 오류가 난다.
- 라이브러리 키가 모두 **`.editor`** 태그다 → **에디터에서만** 읽힌다. 내보낸 게임에는 기본적으로 실리지 않는다(§7).
- 엔진은 `res://.godot/extension_list.cfg` 에 적힌 확장만 읽는다. 이 목록은 **에디터의 파일 시스템 스캔**이 채운다 —
  그래서 폴더만 복사한 직후 게임 모드(`-s`)로 돌리면 확장이 **안 읽힌다**(§5 함정 2).

## 4. 검증 — 파일 · 헤드리스 · 화면

### 4-1. 파일 검사 (스크립트가 자동으로)

| 검사 | 기대 |
|---|---|
| `addons/godotty/godotty.gdextension` | 있음 |
| `addons/godotty/bin/<현재 OS 바이너리>` | 있고 크기 > 0 |
| ZIP 원본과 `diff -rq` | 같음 |
| `addons/addons/godotty` · `addons/godotty/addons` | 없음 (중첩 설치 아님) |
| `addons/godotty/plugin.cfg` | 없음 |
| `project.godot` cksum | 설치 전과 같음 |

### 4-2. 헤드리스 확장 로드 검사 — 창을 띄우지 않는다

```bash
godot --headless --editor --path <루트> --quit-after 300      # 첫 스캔 → extension_list.cfg 에 등록
godot --headless --path <루트> -s /tmp/…/check_godotty.gd     # 프로젝트 바깥 검사 스크립트
```

검사 스크립트(스크립트가 임시 폴더에 만들고 지운다 — 🛑 대상 프로젝트에 검증 코드를 만들지 않는다):

```gdscript
extends SceneTree
func _initialize() -> void:
	var names := []
	for c in ["Terminal", "TerminalPanel", "TerminalTabs"]:
		if ClassDB.class_exists(c):
			names.append(c)
	print("GODOTTY_CLASSES=", ",".join(names))
	print("GODOTTY_LOADED=", "res://addons/godotty/godotty.gdextension" in GDExtensionManager.get_loaded_extensions())
	quit()
```

| 판정 | 기대 (4.7.2 실측) |
|---|---|
| `.godot/extension_list.cfg` | `res://addons/godotty/godotty.gdextension` 한 줄 |
| `GODOTTY_LOADED` | `true` |
| `GODOTTY_CLASSES` | `Terminal,TerminalPanel,TerminalTabs` (그 밖에 `GodottyExportPlugin` 도 등록된다) |

- 게임 모드(`-s`, `--editor` 없음)에서도 `.editor` 라이브러리가 읽히는 이유 — 공식 `godot` 실행 파일은 에디터 빌드라 `editor` 기능 태그를 늘 갖는다.
- 큰 프로젝트는 첫 스캔이 임포트까지 하느라 몇 분 걸린다. 급하면 `--skip-verify` 로 넘기고 그 사실을 보고에 적는다.

### 4-3. 화면 확인 — 하단 Terminal · 터미널 두 개

요청문 6단계의 "하단 **Terminal** 버튼 → **+** 로 터미널 두 개가 동시에 보이는지" 는 **에디터 창을 띄워야** 한다.

| 환경 | 하는 법 |
|---|---|
| 사람 화면에 창을 띄워도 되는 프로젝트 | 에디터로 프로젝트를 다시 연다 → 하단 패널 **Terminal**(단축키 `` Ctrl+` ``) → **+** → 두 칸이 나란히 보이는지. 화면이 좁으면 한 칼럼으로 줄어든다 |
| 🛑 **AI 가 창을 띄우면 안 되는 프로젝트**(라리엔 3D — 헤드리스·가상 모니터 규칙) | 창을 띄우지 않는다. **§4-1·§4-2 결과를 "확인함" 으로, 화면 확인을 "사람이 할 남은 수동 확인" 으로 나눠** 보고한다 |
| 대상 프로젝트 에디터가 이미 떠 있던 경우 | 설치 전에 닫아 달라고 했으므로 여기 오지 않는다. 사람이 다시 열 때 확인해 달라고 한다 |

## 5. 🛑 실측 함정

| # | 증상 | 원인 · 대응 (Godot 4.7.2 + Godotty v0.9.7 · macOS · 2026-09-30) |
|---|---|---|
| 1 | 설치 직후 `godot --headless --path <루트> --import` 가 **종료 코드 134**, 로그에 `handle_crash: Program crashed with signal 11` | 확장이 **처음 등록되는 그 실행**에서 `loading_editor_layout` 직후 SIGSEGV. 4/4 재현(`.godot` 없는 새 프로젝트 2회 · 있는 프로젝트 2회). 같은 조건의 애드온 없는 프로젝트는 정상(1/1). **두 번째 `--import` 부터는 정상.** → 검사는 `--headless --editor --quit-after 300` 으로 한다(4/4 정상). `--import` 를 쓰는 빌드·검사 파이프라인은 설치 뒤 한 번 크래시할 수 있으니, 설치 직후 위 명령을 한 번 돌려 둔다 |
| 2 | 복사했는데 `-s` 검사에서 `Terminal` 클래스가 없다 | `extension_list.cfg` 가 아직 없다 — 에디터 스캔이 한 번도 안 돌았다. §4-2 첫 줄을 먼저 돌린다 |
| 3 | 에디터에 Terminal 버튼이 없다 | ① `addons/godotty/godotty.gdextension` 경로(중첩 설치 아닌지) ② `bin/` 에 현재 OS 바이너리 ③ 파일만 복사하고 **에디터를 재시작하지 않았다**(`reloadable = false`) |
| 4 | "라이브러리를 찾을 수 없음" | Source code ZIP 을 받았다 — `bin/` 이 없다. 설치 ZIP 으로 다시 |
| 5 | macOS 에서 라이브러리가 차단된다 | 브라우저로 받은 ZIP 은 `com.apple.quarantine` 이 붙는다. 스크립트는 `addons/godotty` 안에서만 지운다(`xattr -dr com.apple.quarantine addons/godotty`). `curl` 로 받은 것은 `com.apple.provenance` 뿐이라 해당 없음(실측) |
| 6 | 실행 중인 에디터 위에 덮어쓰면 에디터가 죽거나 옛 바이너리가 남는다 | 로드 중인 `.dylib` 은 교체·핫 리로드가 안 된다. 그래서 종료 3 으로 멈추고 **사람에게 닫아 달라고 한다** |

## 6. 보고 형식

요청문 7단계대로 **실제 값**을 적는다. 확인한 것과 못 한 것을 섞지 않는다.

```text
Godotty v0.9.7 설치 완료
- 프로젝트    : /Users/…/MyGame
- 설치 위치   : /Users/…/MyGame/addons/godotty
- 바이너리    : /Users/…/MyGame/addons/godotty/bin/libgodotty.macos.dylib (54 MB)
- ZIP         : sha256 3860c9f9… — 릴리스 digest 와 일치
- 백업        : ~/.godotty-backups/MyGame-20260930-172957/godotty  (또는 "없음 — 새 설치")
✅ 확인함     : 파일 검사 6/6 · extension_list.cfg 등록 · 헤드리스 로드 true · 클래스 Terminal,TerminalPanel,TerminalTabs
⬜ 남은 수동 확인 (사람): 에디터로 다시 열기 → 하단 Terminal → + 로 두 터미널 동시 표시
- git         : addons/godotty 110 MB — 커밋하지 않음(§7)
```

## 7. 설치한 뒤 — git · export

| 항목 | 사실 | 누가 |
|---|---|---|
| **git** | `addons/godotty` 는 **110 MB**(가장 큰 파일 54 MB — GitHub 100 MB 한도 아래지만 저장소가 커진다). 스크립트는 **커밋하지 않는다** | 커밋할지 · `.gitignore` 에 넣을지 · LFS 로 둘지 **사람이 정한다** |
| **export** | 라이브러리가 `.editor` 태그뿐이라 **내보낸 게임에는 바이너리가 실리지 않는다.** 다만 `.gdextension` 파일이 실려 시작할 때 "확장이 없다" 는 무해한 로그가 남는다 | 없애려면 export preset 의 **제외 필터**에 `addons/godotty/*` — `export_presets.cfg` 수정이므로 **사람 확인 뒤** |
| **게임 안에서 `Terminal` 노드를 쓰기** | `godotty.gdextension` 의 `.editor` 태그를 지워야 한다 → 바이너리가 앱에 실린다(용량 · 보안 검토) | 사람 결정 |
| **업데이트** | 같은 스크립트에 `--version <새 태그>` — 기존 것은 백업되고 교체된다 | AI |

## 8. Windows 에서 스크립트 없이

Git Bash 가 있으면 `install_godotty.sh` 가 그대로 돈다(`MINGW*` 판정 → `.dll`). PowerShell 만 있으면 같은 순서를 손으로 한다:

```powershell
$root = "C:\path\to\MyGame"                                   # project.godot 이 있는 폴더
$tmp  = Join-Path $env:TEMP ("godotty-" + [guid]::NewGuid())  # 프로젝트 바깥
New-Item -ItemType Directory $tmp | Out-Null
Invoke-WebRequest https://github.com/thruthesky/godotty/releases/download/v0.9.7/godotty-v0.9.7.zip -OutFile "$tmp\g.zip"
(Get-FileHash "$tmp\g.zip" -Algorithm SHA256).Hash             # 3860C9F9… 와 대조
Expand-Archive "$tmp\g.zip" "$tmp\unz"
if (Test-Path "$root\addons\godotty") { Move-Item "$root\addons\godotty" "$HOME\godotty-backup-$(Get-Date -f yyyyMMdd-HHmmss)" }
New-Item -ItemType Directory -Force "$root\addons" | Out-Null
Copy-Item -Recurse "$tmp\unz\addons\godotty" "$root\addons\godotty"
Test-Path "$root\addons\godotty\bin\libgodotty.windows.x86_64.dll"
```

그 뒤 §4-2 헤드리스 검사를 `godot` 대신 콘솔 실행 파일(`Godot_v4.7.2-stable_win64_console.exe`)로 돌린다.
