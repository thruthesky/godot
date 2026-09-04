# `/godot init` 과 `install.sh` — 슬래시 명령 설치 · 빌드·설치·실행 도구

> **이 문서로 오는 상황** — 사용자가 **`/godot init`** 이라고 지시했을 때 · **`./install.sh`** 로 실기기(macOS·iOS·Android)에 빌드·설치·실행할 때 · 심볼릭 링크가 깨졌거나 장치가 목록에 안 보일 때

> 2026-09-03 에 `SKILL.md` 의 두 절(「`/godot init`」·「번들 스크립트 › scripts/install.sh」)을 **한 글자도 지우지 않고** 여기로 옮겼다.
> Agent Skills 규격은 `SKILL.md` 본문을 500줄 미만으로 두라 하고, 아래 절차·옵션 표는 스킬이 트리거된 뒤 그 작업을 할 때만 필요하기 때문이다.
> `SKILL.md` 에는 100단어 안팎의 요약만 남겼다.

## 목차

1. [`/godot init` — 프로젝트에 슬래시 명령과 `./install.sh` 를 설치한다](#1-godot-init--프로젝트에-슬래시-명령과-installsh-를-설치한다)
   - 설치하는 것 ① 슬래시 명령 — 복사한다 · ② `./install.sh` — 심볼릭 링크 · 절차 · 지킬 것
2. [`scripts/install.sh` — 빌드·설치·실행](#2-scriptsinstallsh--빌드설치실행-원문은-skillmd-번들-스크립트에-있던-것)
   - 장치 목록 · 번호/기기 ID 선택 · 옵션(`--console`·`--skip-build`·`--release`·`--no-launch`·`--path`) · 비대화형 동작 · macOS `.zip`·quarantine
3. [공식 문서](#공식-문서)

---

## 1. `/godot init` — 프로젝트에 슬래시 명령과 `./install.sh` 를 설치한다

사용자가 **`/godot init`** 이라고 지시하면 세 가지를 한다.

1. 이 스킬이 들고 있는 **명령 파일들을 대상 프로젝트의 `.claude/commands/` 로 복사**한다 —
   그 뒤로는 `/godot-example` 처럼 짧게 부를 수 있다
2. 대상 프로젝트 **루트에 `./install.sh` 심볼릭 링크**를 건다 —
   `.claude/skills/godot/scripts/install.sh` 를 가리키며, 긴 경로 없이 `./install.sh` 로 부른다
3. 대상 프로젝트 **`scripts/triangles.sh` 심볼릭 링크**를 건다 —
   `.claude/skills/godot/scripts/triangles.sh` 를 가리키며, 씬·에셋의 삼각형과 드로우콜을 센다

### 설치하는 것 ① 슬래시 명령 — **복사한다**

| 원본 (이 스킬 안) | 설치 위치 | 무엇을 하는 명령인가 |
|---|---|---|
| `commands/godot-example.md` | `.claude/commands/godot-example.md` | **기본 예제 생성** — 빈 프로젝트에 바닥·벽·플레이어를 세우고 화살표 키로 걸어다니게 한다 (→ [example.md](example.md) 1~8단계) |

새 명령을 늘릴 때는 `commands/` 에 파일을 추가하고 이 표에 한 줄을 더한다.
**표에 없는 파일은 설치하지 않는다.**

### 설치하는 것 ② `./install.sh` — **심볼릭 링크를 건다. 복사하지 않는다**

| 원본 (이 스킬 안) | 설치 위치 | 형태 |
|---|---|---|
| `scripts/install.sh` | `<대상>/install.sh` | 🛑 **심볼릭 링크** — `.claude/skills/godot/scripts/install.sh` 를 가리킨다 |

**왜 복사가 아니라 링크인가** — 복사하면 스킬을 고쳐도 프로젝트의 사본은 옛날 그대로 남고,
프로젝트마다 갈라진 사본이 쌓인다. 링크는 **스킬을 고치면 모든 프로젝트에 즉시 반영**된다.
스크립트는 preset 이름·패키지 ID·산출물 경로를 `export_presets.cfg` 에서 직접 읽으므로
**프로젝트별로 고칠 것이 없다** — 그래서 링크로 충분하다.

```bash
./install.sh            # 장치 목록을 보여주고 골라서 빌드·설치·실행
./install.sh --list     # 목록만
./install.sh 1 --console  # 1번 장치에 설치하고 로그를 터미널에 붙인다
```

### 설치하는 것 ③ `scripts/triangles.sh` — **심볼릭 링크를 건다**

| 원본 (이 스킬 안) | 설치 위치 | 형태 |
|---|---|---|
| `scripts/triangles.sh` | `<대상>/scripts/triangles.sh` | 🛑 **심볼릭 링크** — `../.claude/skills/godot/scripts/triangles.sh` 를 가리킨다 |

🛑 **링크의 상대경로는 "링크 파일이 있는 폴더" 기준이다.** `scripts/` 안에 두므로
`.claude/…` 가 아니라 **`../.claude/…`** 로 건다. `install.sh` 는 루트에 있어 `..` 이 없다.

```bash
scripts/triangles.sh                        # main_scene 의 삼각형 총량
scripts/triangles.sh scenes/main/main.tscn  # 씬 하나 — 무거운 노드 순위까지
scripts/triangles.sh --all --budget 150000  # 전 씬. 예산 초과가 있으면 종료 코드 1 (CI)
scripts/triangles.sh --frame                # 실제로 띄워 "그린" 삼각형 (VISIBLE·SHADOW·CANVAS 분리)
scripts/triangles.sh --glb assets           # Godot 없이 .glb 를 파이썬으로 직접 읽는다
```

**왜 `scripts/` 아래인가** — 루트를 어지럽히지 않기 위해서다. `install.sh` 는 가장 자주 쓰고
프로젝트의 얼굴이라 루트에 두지만, 나머지 도구는 `scripts/` 로 모은다.

**동작 원리** — 셸이 `project.godot` 을 위로 탐색해 루트를 잡고, 스킬의 GDScript 를
**`res://.claude/skills/godot/scripts/…`** 로 실행한다. 🛑 `.claude/` 는 Godot 의 리소스
스캔에서 빠지지만 **`-s res://…` 로 직접 실행하는 것은 된다**(4.7.2 실측). 그래서 프로젝트
안으로 복사할 필요가 없다.

### 절차

```bash
# ── ① 슬래시 명령 ────────────────────────────────────────────
ls .claude/skills/godot/commands/          # 원본 확인
mkdir -p <대상>/.claude/commands           # 없으면 만든다
cp .claude/skills/godot/commands/godot-example.md <대상>/.claude/commands/

# ── ② ./install.sh 심볼릭 링크 ───────────────────────────────
cd <대상>

# 원본이 실제로 있는지 먼저 확인한다 — 없으면 깨진 링크가 된다
[ -f .claude/skills/godot/scripts/install.sh ] || echo "스킬이 없다. 링크를 걸지 않는다"

# 이미 있으면 손대지 않는다
if [ -e install.sh ] || [ -L install.sh ]; then
  ls -l install.sh                          # 무엇이 있는지 보여주고 사람에게 물어본다
else
  ln -s .claude/skills/godot/scripts/install.sh install.sh
fi

./install.sh --list                          # 검증 — 장치 목록이 나오면 성공

# ── ③ scripts/triangles.sh 심볼릭 링크 ───────────────────────
mkdir -p scripts
if [ -e scripts/triangles.sh ] || [ -L scripts/triangles.sh ]; then
  ls -l scripts/triangles.sh                 # 이미 있으면 손대지 않고 사람에게 물어본다
else
  ln -s ../.claude/skills/godot/scripts/triangles.sh scripts/triangles.sh
fi

scripts/triangles.sh --glb                   # 검증 — 표가 나오면 성공 (Godot 없이도 도는 모드다)
```

인자로 경로가 오면(`/godot init ~/apps/ex2`) 그 프로젝트에, 없으면 **현재 프로젝트**에 설치한다.

### 지킬 것

| 규칙 | 이유 |
|---|---|
| **같은 이름의 파일이 이미 있으면 덮어쓰지 않는다** | 사용자가 고쳐 둔 명령·스크립트를 날린다. 차이를 보여주고 물어본다 |
| 🛑 **`ln -sf` 를 쓰지 않는다** | 루트에 있던 **진짜 `install.sh` 파일을 말없이 지운다.** 존재를 먼저 확인하고 없을 때만 건다 |
| 🛑 **링크는 반드시 상대경로로 건다** (`ln -s .claude/skills/...`) | 절대경로(`/Users/…`)로 걸면 **폴더를 옮기거나 다른 사람이 클론하면 깨진다** |
| **`.claude/skills/godot/scripts/install.sh` 가 실제로 있는지 먼저 확인한다** | 스킬이 없는 프로젝트에 걸면 **깨진 링크**만 남는다 |
| 링크를 만든 뒤 **`./install.sh --list` 로 검증한다** | 링크가 걸렸다는 것과 동작한다는 것은 다르다 |
| 설치 후 **무엇이 생겼고 어떻게 부르는지** 알린다 | 파일만 복사하고 끝내면 쓸 줄 모른다 |
| 새 명령은 **`commands/` 에 원본을 두고** 복사한다 | 내용이 두 곳으로 갈라지지 않게 한다 |
| 슬래시 명령은 **재시작 후 인식**될 수 있다 | 목록에 안 보이면 세션을 다시 열라고 안내한다 |

**심볼릭 링크는 git 에 그대로 커밋된다.** 스킬을 서브모듈로 같은 경로에 두는 저장소라면
클론한 쪽에서도 그대로 동작한다. 스킬이 없는 환경(또는 심링크를 못 쓰는 Windows)에서는
링크 대신 `bash .claude/skills/godot/scripts/install.sh` 를 직접 부른다.

**`install.sh` 는 실행 위치에서 위로 올라가며 `project.godot` 을 찾는다.**
링크로 실행해도 프로젝트 루트를 정확히 잡으며, `export_presets.cfg` 가 없으면 거기서 멈춘다.

---

## 2. `scripts/install.sh` — 빌드·설치·실행 (원문은 SKILL.md 「번들 스크립트」에 있던 것)

**빌드·설치·실행 스크립트.** 그냥 실행하면 **지금 쓸 수 있는 장치를 번호로 보여주고**,
번호를 고르면 그 플랫폼으로 빌드·설치·실행까지 한다. macOS·iOS·Android 를 한 입구에서
다룬다. preset 이름·패키지 ID·산출물 경로는 `export_presets.cfg` 에서 직접 읽으므로
프로젝트마다 고쳐 쓸 필요가 없다.

```bash
.claude/skills/godot/scripts/install.sh          # 장치 목록 → 번호 입력
.claude/skills/godot/scripts/install.sh --list   # 목록만 보고 끝
.claude/skills/godot/scripts/install.sh 1        # 1번을 바로 선택
```

```
사용 가능한 장치:

  1)  macOS     이 맥에서 실행 (arm64)
  2)  iOS       JaeHo16 — iPhone 16 Pro Max (iPhone17,2)
                67BD02AA-6E29-53D7-A5CE-A1619F9CF934

  (Android 기기 없음 — USB 디버깅을 켜고 연결한다)
```

**목록에 오르는 기준이 플랫폼마다 다르다.** macOS 는 이 맥이라 항상 1번에 있고,
iOS 는 `devicectl` 이 `available` 로 판정한 것만(신뢰하지 않은 기기는 `unavailable`
이라 뜨지 않는다), Android 는 `adb devices` 의 `device` 상태만 오른다. 연결이 없는
플랫폼은 목록에서 빠지는 대신 **왜 없는지**를 한 줄로 알려 준다.

번호 대신 기기 ID 나 `macos` 를 직접 줘도 된다 — 스크립트나 CI 에서 쓸 때 편하다.

```bash
install.sh macos                     # 이 맥에서 빌드·실행
install.sh R58X609XXYV               # Android (adb 시리얼)
install.sh 00008140-001C24C9…        # iOS (UDID·UUID 모두 가능)
install.sh <선택> --console          # 실행 로그를 터미널에 붙인다
install.sh <선택> --skip-build       # 설치·실행만 (수 초)
install.sh <선택> --release          # 릴리즈 빌드
install.sh <선택> --no-launch        # 설치만
install.sh <선택> --path ~/game      # 프로젝트 경로 지정
```

**stdin 이 터미널이 아니면 묻지 않는다** — 목록만 찍고 끝나므로 CI 나 스크립트에서
멈추지 않는다. 이때는 번호를 인자로 준다.

macOS 는 `export_path` 가 `.zip` 이면 풀어서 `.app` 을 꺼내고, `com.apple.quarantine`
속성을 지운 뒤 `open` 한다 — 서명 없는 자기 빌드가 Gatekeeper 에 막히는 것을 피한다.

**에디터 Remote Deploy 와 결과가 같으므로, 에디터를 띄우지 않는 작업에서는 이 스크립트를
쓴다.** 상세는 [references/headless-workflow.md](headless-workflow.md) §3.

---

## 공식 문서

- 커맨드라인 튜토리얼(`--export-debug`·`--export-release`·`--headless`): https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- 내보내기 전반(프리셋·템플릿·원클릭 배포): https://docs.godotengine.org/en/stable/tutorials/export/index.html
- 플랫폼별 절차·서명·실기기 설치는 이 스킬의 [export-build.md](export-build.md) · [export-build-android.md](export-build-android.md) · [export-build-ios.md](export-build-ios.md) · [export-build-desktop.md](export-build-desktop.md) 를 본다.
