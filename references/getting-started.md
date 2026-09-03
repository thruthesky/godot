# 시작하기 — 내려받기부터 첫 프로젝트, 그리고 공식 문서 읽는 법

**이 문서는 0단계다.** [example.md](example.md) 는 "빈 3D 프로젝트" 에서 시작하고,
[basics/](basics.md) 는 프로젝트가 이미 열려 있다고 전제한다. **그 앞** — Godot 을 어디서
받고, 무엇을 눌러 그 빈 프로젝트에 도달하는지, 그리고 이 스킬 밖의 정보를 어디서 어떻게
찾는지 — 를 여기서 다룬다.

공식 문서의 **Getting started → Introduction** 6편(Introduction to Godot · Learn to code with
GDScript · Overview of Godot's key concepts · First look at Godot's interface · Learning new
features · Godot's design philosophy)과 **Manual → Editor → Using the Project Manager**,
**Scripting → How to read the Godot API** 에 대응한다. 값과 메뉴 이름은 **4.7.2.stable** 에서
확인한 것이다.

## 목차

| 절 | 내용 |
|---|---|
| [§1](#1-내려받기와-첫-실행) | 내려받기와 첫 실행 — 어떤 빌드를 받나, 실행 파일이 곧 에디터다 |
| [§2](#2-프로젝트-매니저--처음-보는-창) | 프로젝트 매니저 — 처음 보는 창 |
| [§3](#3-새-프로젝트-만들기--렌더러는-mobile) | 새 프로젝트 만들기 — 🛑 렌더러는 **Mobile** |
| [§4](#4-에디터-첫-화면--다섯-화면과-독) | 에디터 첫 화면 — 다섯 화면과 독 |
| [§5](#5-godot-의-핵심-개념-4가지) | Godot 의 핵심 개념 4가지 — 씬·노드·씬 트리·시그널 |
| [§6](#6-godot-의-설계-철학--왜-이렇게-생겼나) | Godot 의 설계 철학 — 왜 이렇게 생겼나 |
| [§7](#7-공식-문서-지도--getting-started-와-이-스킬의-대응) | 공식 문서 지도 — Getting started 와 이 스킬의 대응 |
| [§8](#8-클래스-레퍼런스-읽는-법--api-문서-한-페이지의-구조) | ★ 클래스 레퍼런스 읽는 법 — API 문서 한 페이지의 구조 |
| [§9](#9-새-기능을-배우는-법과-질문하는-법) | 새 기능을 배우는 법과 질문하는 법 |
| [§10](#10-시스템-요구-사양--공식-최소치와-이-프로젝트의-기준) | 시스템 요구 사양 — 공식 최소치와 이 프로젝트의 기준 |
| [§11](#11-자주-막히는-곳) | 자주 막히는 곳 |
| [공식 문서](#공식-문서) | 이 문서가 근거로 삼은 공식 페이지 |

---

## 1. 내려받기와 첫 실행

### 어디서 받나

**https://godotengine.org/download** 에서 운영체제에 맞는 것을 받는다. 두 가지 빌드가 있다.

| 빌드 | 정체 | 이 프로젝트 |
|---|---|---|
| **Godot Engine** (Standard) | GDScript 전용. 용량이 작고 설치가 없다 | ✅ **이것을 받는다** |
| Godot Engine – .NET | C# 을 쓰려는 사람용. .NET SDK 를 따로 깔아야 한다 | 🛑 받지 않는다 — 이 스킬과 라리엔 3D 는 **GDScript 만 쓴다** |

**"설치" 가 없다.** 압축을 풀면 실행 파일 하나가 나오고, **그 파일이 곧 에디터**다.
어디에 두든 동작하며, 지워도 프로젝트는 남는다(프로젝트는 별도 폴더에 있다).

| OS | 받는 것 | 실행 |
|---|---|---|
| macOS | `Godot.app` (universal) | Applications 로 옮기거나 그 자리에서 더블클릭. 처음 열 때 Gatekeeper 가 막으면 **우클릭 → 열기** |
| Windows | `Godot_v4.7.2-stable_win64.exe` + 콘솔용 `_console.exe` | 아무 폴더에 두고 더블클릭. `_console.exe` 는 터미널 출력이 함께 뜨는 버전 — 오류를 볼 때 편하다 |
| Linux | `Godot_v4.7.2-stable_linux.x86_64` | 실행 권한(`chmod +x`)을 주고 실행 |

**터미널에서도 부른다.** 이 스킬의 [headless-workflow.md](headless-workflow.md) 와 검증 명령들은
`godot` 이 PATH 에 있다고 전제한다. macOS 는 Homebrew 로 두는 것이 가장 간단하다.

```bash
brew install --cask godot        # macOS — /opt/homebrew/bin/godot 에 링크가 생긴다 (이 스킬을 쓰는 환경에서 확인)
godot --version                  # 4.7.2.stable.official.ed1daf0bf  ← 이 스킬의 기준 버전
```

> 🔑 **버전을 먼저 확인한다.** 이 스킬의 값·메뉴 이름은 4.7.2 기준이다. 다른 버전이면
> [whats-new.md](whats-new.md) 에서 무엇이 달라졌는지 본다.

### 처음 실행하면

에디터가 아니라 **프로젝트 매니저**(§2)가 뜬다. 프로젝트를 하나 만들거나 열어야 에디터로 들어간다.

---

## 2. 프로젝트 매니저 — 처음 보는 창

Godot 을 실행하면 가장 먼저 보는 창이다. 프로젝트를 **만들고·가져오고·지우고·실행**하는 곳이다.

| 위치 | 무엇 |
|---|---|
| 위쪽 탭 **Projects** | 내 프로젝트 목록. 더블클릭하면 에디터가 열린다 |
| 위쪽 탭 **Asset Library** | 공식 데모·템플릿·애드온을 받는 곳. **처음엔 "Go Online" 버튼만 보인다** — 개인정보 보호를 위해 기본은 오프라인이다. 눌러야 목록이 뜬다 |
| 왼쪽 위 **Create** | 새 프로젝트(§3) |
| **Import** | 이미 있는 프로젝트 폴더(`project.godot` 이 있는 폴더)나 zip 을 목록에 추가 |
| **Scan** | 폴더를 지정하면 그 아래 프로젝트를 전부 찾아 목록에 넣는다 |
| 오른쪽 위 **Settings** | 에디터 언어(기본은 시스템 언어)·테마·화면 배율·**Network Mode**(Online/Offline)·폴더 이름 규칙 |

**태그** — 프로젝트가 많아지면 프로젝트를 고른 뒤 **Manage Tags** 로 태그를 붙이고, 필터 칸에
`tag:이름` 으로 거른다. 태그는 프로젝트에 붙어 다니므로 다른 컴퓨터로 옮겨도 남는다.

**Recovery Mode** — 프로젝트가 열자마자 죽거나 자주 죽으면, 목록에서 프로젝트를 고르고
Edit 버튼 옆 드롭다운에서 **Edit in recovery mode** 를 고른다. `@tool` 스크립트·에디터
플러그인·GDExtension·씬 자동 복원·실행이 전부 꺼진 채 열리므로 원인을 찾을 수 있다.
(대개는 죽은 뒤 다시 열면 자동으로 이 모드가 제안된다.)

---

## 3. 새 프로젝트 만들기 — 렌더러는 Mobile

**Create** 를 누르면 **Create New Project** 창이 뜬다. 칸은 넷이다.

| 칸 | 넣는 값 | 이유 |
|---|---|---|
| **Project Name** | 프로젝트 이름 | 폴더 이름과 `project.godot` 의 `config/name` 이 된다 |
| **Project Path** | **빈 폴더**. **Browse** 로 고르거나 직접 입력. **Create Folder** 를 켜 두면 이름으로 하위 폴더를 자동으로 만든다 | 빈 폴더여야 오른쪽에 **초록 체크**가 뜬다. 이미 파일이 있는 폴더는 거부된다 |
| **Renderer** | 🛑 **Mobile** | 아래 참조. 나중에 바꿀 수는 있지만 **처음부터 맞춰야** 실측이 어긋나지 않는다 |
| **Version Control** | Git (선택) | 켜면 `.gitignore`·`.gitattributes` 를 함께 만들어 준다. Godot Git Plugin 은 별개다 |

### 🛑 렌더러는 Mobile 이다 — 학습 프로젝트도 같다

| 렌더러 | 정체 | 이 프로젝트 |
|---|---|---|
| Forward+ | 데스크톱 고사양. SDFGI·VoxelGI·SSR·SSAO·볼류메트릭 포그·TAA·FSR 이 **여기만** 있다 | 🛑 쓰지 않는다 — 여기서 만든 화면은 **저사양 폰에서 재현되지 않는다** |
| **Mobile** | 모바일·저사양 데스크톱. 위 기능이 **없다** | ✅ **라리엔 3D 의 규범** (`project.godot` 의 `renderer/rendering_method="mobile"`) |
| Compatibility | OpenGL. 가장 낮은 사양·웹 | 쓰지 않는다 — Mobile 보다 기능이 더 적고 라리엔의 실측이 Mobile 기준이다 |

**학습용 프로젝트도 Mobile 로 만든다.** Forward+ 로 배우면 "된다" 고 알게 된 기능이
라리엔에서는 없다. 무엇이 있고 없는지는 [rendering-3d.md §1](rendering-3d.md) 의 렌더러 비교표에 있다.

**Create** 를 누르면 폴더가 만들어지고 에디터가 열린다. 그때 폴더에 무엇이 생겨 있는지는
[basics/06-editor-screen.md — "새 프로젝트를 만들면 이미 들어 있는 파일들"](basics/06-editor-screen.md) 에 있다.

> **여기까지가 [example.md](example.md) 가 전제하는 "빈 3D 프로젝트" 다.** 예제는 이 다음 단계부터 시작한다.

---

## 4. 에디터 첫 화면 — 다섯 화면과 독

에디터가 열리면 화면은 세 층이다. **자세한 것은 [basics/06-editor-screen.md](basics/06-editor-screen.md)** 에
있고 여기서는 이름만 맞춘다.

| 위치 | 이름 | 무엇 |
|---|---|---|
| 맨 위 왼쪽 | **메인 메뉴** | Scene · Project · Debug · Editor · Help |
| 맨 위 가운데 | **워크스페이스 버튼 5개** | **2D · 3D · Script · Game · AssetLib** — 아래 표 |
| 맨 위 오른쪽 | **실행 버튼**과 Movie Maker 토글 | ▶ 프로젝트 실행(F5) · 현재 씬 실행(F6) |
| 그 아래 | **씬 탭** | 열려 있는 씬들. `+` 로 새 씬 |
| 가운데 | **뷰포트**와 그 위 **툴바** | 선택·이동·회전·크기 도구. 2D/3D 에 따라 툴바가 바뀐다 |
| 양옆 | **독(dock)** | 왼쪽 **FileSystem**(파일) · **Scene**(노드 트리) / 오른쪽 **Inspector**(속성) · **Node**(시그널·그룹) |
| 맨 아래 | **하단 패널** | Output · Debugger · Audio · Animation … 접혀 있다가 누르면 펼쳐진다 |

| 워크스페이스 | 언제 |
|---|---|
| **2D** | UI(HUD·메뉴)를 만들 때. 3D 게임이어도 UI 는 여기서 만든다 |
| **3D** | 맵·캐릭터·카메라 — 이 스킬의 대부분 |
| **Script** | 코드 편집기. 디버거·자동완성·**내장 클래스 레퍼런스**(§8) |
| **Game** | 실행 중인 게임이 나타나는 곳(4.6+). 일시정지하고 값을 바꿔 볼 수 있지만 **여기서 바꾼 값은 저장되지 않는다** |
| **AssetLib** | 무료 애드온·에셋 → [asset-store.md](asset-store.md) |

**독은 옮길 수 있다.** 독 제목 옆 ⋮ 로 왼쪽·오른쪽·위·아래 어디든 보낸다.
왼손잡이·매직 마우스 환경에서 조작을 바꾸는 법은 [basics/07-editor-input.md](basics/07-editor-input.md).

---

## 5. Godot 의 핵심 개념 4가지

공식 문서가 "이 넷만 알면 시작할 수 있다" 고 고른 개념이다. 한 줄씩만 맞추고,
**본문은 [basics/01-world.md](basics/01-world.md) 부터 순서대로** 읽는다.

| 개념 | 한 줄 | 자세히 |
|---|---|---|
| **노드(Node)** | 게임을 이루는 **가장 작은 부품**. 카메라·메시·충돌체·소리가 전부 노드다. 노드는 **트리**로 묶인다 | [basics/01-world.md](basics/01-world.md) |
| **씬(Scene)** | 노드를 묶어 저장한 **재사용 단위**(`.tscn`). 캐릭터도 씬, 맵도 씬, 메뉴도 씬. **다른 엔진의 프리팹과 레벨 둘 다**에 해당한다 | [basics/02-scene.md](basics/02-scene.md) · [basics/03-instancing.md](basics/03-instancing.md) |
| **씬 트리(SceneTree)** | 실행 중인 게임 전체 — **씬들의 트리**. 씬이 노드 트리이므로 결국 하나의 큰 노드 트리다 | [nodes-scenes.md](nodes-scenes.md) |
| **시그널(Signal)** | 노드가 "무슨 일이 일어났다" 고 알리는 방법. 노드끼리 **직접 부르지 않고** 연결한다(옵저버 패턴) | [basics/05-signal.md](basics/05-signal.md) |

> 🔑 **이름 끝의 `3D`** — `CharacterBody3D`·`Camera3D`·`CollisionShape3D` 처럼 3D 노드는
> 이름이 `3D` 로 끝나고, 2D 는 `2D` 로 끝난다. Godot 3 의 `Spatial` 은 4 에서 `Node3D` 가 됐다.
> 옛 강좌에서 `Spatial` 을 보면 `Node3D` 로 읽는다.

---

## 6. Godot 의 설계 철학 — 왜 이렇게 생겼나

공식 문서 *Godot's design philosophy* 의 요지다. **"왜 이렇게 하라고 하는가"** 가 궁금할 때 돌아온다.

| 기둥 | 뜻 | 이 스킬에서 |
|---|---|---|
| **객체 지향과 합성** | 씬을 **합성**(씬 안에 씬)하고 **상속**(씬을 확장)한다. `BlinkingLight` 씬을 고치면 그것을 쓰는 모든 `BrokenLantern` 이 함께 바뀐다 | [basics/03-instancing.md](basics/03-instancing.md) · [best-practices.md](best-practices.md) |
| **노드는 컴포넌트가 아니다** | 다른 엔진의 "컴포넌트를 붙인다" 와 다르다. 노드는 **부모를 상속해 스스로 동작**하고, 대부분 서로 독립이다. 예외가 `CollisionShape3D` 처럼 부모가 쓰는 노드 | [basics/01-world.md](basics/01-world.md) "몸·모양·그림" |
| **올인원** | 스크립트 편집기·애니메이션·셰이더 편집기·디버거·프로파일러가 다 들어 있다. **단, 3D 작업 공간은 2D 보다 도구가 적다** — 지형·복잡한 캐릭터 애니는 외부 도구(Blender)가 필요하다 | [resources-assets.md](resources-assets.md) · `model` 스킬 |
| **GDScript** | 게임 코드를 위해 만든 언어. 들여쓰기 문법·정적 타입·자동완성. C# 도 되지만 이 프로젝트는 쓰지 않는다 | [gdscript.md](gdscript.md) |
| **오픈소스(MIT)** | 엔진 소스를 읽고 고칠 수 있다. 오류가 엔진 안에서 나도 스택 트레이스가 보인다. **만든 게임에는 아무 조건이 붙지 않는다** | SKILL.md "근거의 우선순위" — 엔진 소스가 근거가 된다 |
| **에디터도 Godot 게임이다** | 에디터가 엔진의 UI 시스템으로 만들어졌다. `@tool` 을 붙이면 **게임 코드가 에디터 안에서 돈다** | [editor-plugin.md](editor-plugin.md) |
| **2D 와 3D 엔진이 따로 있다** | 2D 의 단위는 **픽셀**, 3D 의 단위는 **미터**. 3D 위에 2D(UI)를 얹을 수 있다 | [hud-menu.md](hud-menu.md) — UI 는 2D 좌표계다 |

---

## 7. 공식 문서 지도 — Getting started 와 이 스킬의 대응

공식 문서(https://docs.godotengine.org/en/stable/)는 네 덩어리다. **처음 배우는 사람은
Getting started 를 순서대로 읽는 것이 공식 권장**이고, 이 스킬은 그것을 라리엔 3D 기준으로 다시 쓴 것이다.

| 공식 | 무엇 | 이 스킬의 대응 |
|---|---|---|
| **About** | 소개·기능 목록·시스템 요구 사양·FAQ·라이선스 | §10, [asset-store.md](asset-store.md) |
| **Getting started** | Introduction(6편) → **Step by step**(6편) → Your first 2D game(7편) → **Your first 3D game**(10편) | 아래 표 |
| **Manual**(Tutorials) | 주제별 — 2D·3D·Scripting·Physics·Rendering·Shaders·Animation·Navigation·Audio·Export·UI·Best practices·Performance·Networking·… | 각 references 문서 |
| **Class reference** | 클래스마다 한 페이지 — **API 의 정본** | §8 |

**Getting started 의 각 편이 이 스킬 어디에 있나**

| 공식 페이지 | 이 스킬 |
|---|---|
| Introduction to Godot · Learn to code with GDScript | 이 문서 §1·§9 |
| Overview of Godot's key concepts | 이 문서 §5 → [basics/01-world.md](basics/01-world.md) |
| First look at Godot's interface | 이 문서 §4 → [basics/06-editor-screen.md](basics/06-editor-screen.md) |
| Learning new features · Godot's design philosophy | 이 문서 §9 · §6 |
| Step by step — Nodes and Scenes / Creating instances | [basics/01-world.md](basics/01-world.md) · [basics/02-scene.md](basics/02-scene.md) · [basics/03-instancing.md](basics/03-instancing.md) |
| Step by step — Scripting languages / Creating your first script | [basics/04-script.md](basics/04-script.md) |
| Step by step — Listening to player input | [basics/09-controller.md](basics/09-controller.md) · [input-ui.md](input-ui.md) |
| Step by step — Using signals | [basics/05-signal.md](basics/05-signal.md) |
| Your first 2D game | 🛑 **범위 밖** — 이 프로젝트는 3D 다. UI 만 2D 를 쓴다([hud-menu.md](hud-menu.md)) |
| **Your first 3D game**("Squash the Creeps") | [example.md](example.md) — 🛑 **다른 점**: 공식은 `DirectionalLight3D`(태양)를 놓지만 **라리엔은 광원 0개**이고, 공식은 원근 카메라지만 **라리엔은 직교·−45° 고정**이다. 공식 튜토리얼을 따라 하려면 그 두 가지만 이 스킬 규범으로 바꾼다 |

---

## 8. 클래스 레퍼런스 읽는 법 — API 문서 한 페이지의 구조

**"이 노드에 무슨 속성이 있나·이 함수가 뭘 돌려주나" 는 전부 클래스 레퍼런스에 있다.**
이 스킬은 자주 쓰는 것만 옮겨 적었으므로, 없는 것은 여기서 찾는다. 페이지 구조는 **모든 클래스가 같다.**

### 여는 법 — 에디터 안에서 여는 것이 가장 빠르다

| 방법 | 어디서 |
|---|---|
| **F1** (macOS 는 **Opt+Space**, F 키가 미디어 키인 키보드는 **fn+F1**) | 에디터 어디서나 → **Search Help** 창 |
| Script 화면 오른쪽 위 **Search Help** 버튼 | Script 워크스페이스 |
| **Help 메뉴 → Search Help** | 메인 메뉴 |
| 코드에서 클래스·함수·변수 이름을 **Cmd+클릭**(Windows·Linux 는 Ctrl+클릭) | Script 화면 — 그 항목의 페이지로 바로 간다 |
| Scene 독에서 노드 **우클릭 → Open Documentation** | Scene 독 |
| 웹 | `https://docs.godotengine.org/en/stable/classes/class_<소문자클래스명>.html` — 예 `class_characterbody3d.html` |

**에디터 안의 것과 웹의 것은 같은 내용**이고, 에디터 안의 것은 **지금 쓰는 버전과 정확히 같다.**
웹은 stable 이 4.7 이지만 다른 버전을 보고 있을 수 있으므로 왼쪽 아래 버전 표시를 확인한다.

### 한 페이지의 구조 — 위에서 아래로

`CharacterBody3D` 페이지를 예로 든다(값은 4.7.2 doctool 에서 확인).

| 절 | 무엇이 있나 | 예 |
|---|---|---|
| **클래스 이름** | 맨 위 | `CharacterBody3D` |
| **Inherits** | 이 클래스가 **물려받는** 조상 사슬. 클릭하면 그 클래스로 간다. **여기 없는 속성은 조상에 있다** | `PhysicsBody3D < CollisionObject3D < Node3D < Node < Object` — `position` 은 `Node3D` 에, `name` 은 `Node` 에 있다 |
| **Inherited By** | 이 클래스를 물려받는 자식들 | (없음) |
| **Brief Description** | 한 줄 요약. **노드 추가 창(Create New Node)에 뜨는 그 문장** | |
| **Description** | 본문. 동작 원리·코드 예·경고·관련 링크 | `move_and_slide()` 가 무엇을 하는지 |
| **Tutorials** | 이 클래스를 다루는 매뉴얼 페이지 링크 | *Using CharacterBody2D/3D* |
| **Properties** 표 | 왼쪽 **타입** · 가운데 **이름**(클릭하면 상세로) · 오른쪽 **기본값** | `float` · `floor_max_angle` · `0.7853982`(= 45°) |
| **Methods** 표 | 왼쪽 **반환 타입** · 오른쪽 **이름(인자: 타입 = 기본값) 한정자** | `bool` · `move_and_slide()` |
| **Signals** | 이 노드가 **알리는** 이벤트와 그 인자. 언제 나가는지 설명이 붙어 있다 | `Area3D` 의 `body_entered(body: Node3D)` |
| **Enumerations** | 이 클래스의 열거형 — 이름·정수값·뜻 | `MotionMode` … `MOTION_MODE_GROUNDED = 0` |
| **Constants** | 이름 붙은 상수. `NOTIFICATION_*` 이면 **어느 엔진 이벤트에 오는지**가 적혀 있다 | `Node` 의 `NOTIFICATION_READY = 13` |
| **Property Descriptions** | 속성마다 상세 + **setter/getter 이름** | `floor_max_angle` → `set_floor_max_angle()` / `get_floor_max_angle()` |
| **Method Descriptions** | 메서드마다 상세·예제 | |

**Methods 표의 한정자 세 가지**

| 한정자 | 뜻 |
|---|---|
| `const` | 인스턴스의 데이터를 바꾸지 않는다 — 읽기만 |
| `virtual` | **엔진은 아무것도 하지 않고 내 스크립트가 덮어쓰기를 기다린다** — `_ready()`·`_process()` 가 이것이다. 이름 앞의 `_` 가 그 표시다 |
| `vararg` | 인자를 몇 개든 받는다 — `print()` |

> 🔑 **속성은 전부 setter/getter 한 쌍이다.** `body.floor_max_angle = 0.5` 와
> `body.set_floor_max_angle(0.5)` 는 같다. **`Callable` 로 함수 이름을 넘겨야 할 때**
> (시그널 연결·트윈) setter 이름이 필요해지므로 Property Descriptions 에서 확인한다.

> 🛑 **기본값은 "설정하지 않았을 때의 값" 이다.** 인스펙터에서 바꾼 값은 `.tscn` 에 저장되고,
> 코드에서 바꾼 값은 그때부터다. 문서의 기본값과 내 씬의 값이 다르면 **어딘가에서 바꾼 것**이다.
> 인스펙터에서 값 옆의 ↺ 아이콘이 "기본값과 다르다" 는 표시다.

### 이 스킬이 클래스 레퍼런스를 다루는 규칙

SKILL.md "근거의 우선순위" 대로 — **값이 궁금하면 문서보다 먼저 엔진에서 뽑는다.**

```bash
godot --headless --doctool /tmp/gddoc                       # 클래스 XML 전체 추출 (한 번만)
grep -o '<member name="floor_max_angle"[^>]*>' /tmp/gddoc/doc/classes/CharacterBody3D.xml
# → default="0.7853982"   ← 이 값이 문서·기억·스킬보다 우선한다
```

---

## 9. 새 기능을 배우는 법과 질문하는 법

공식 *Learning new features* 의 요지다. **이 스킬에 없는 것을 만났을 때** 의 순서이기도 하다.

### 배우는 순서

| 순서 | 어디 | 무엇 |
|---|---|---|
| 1 | **매뉴얼**(왼쪽 메뉴로 넓게, 검색으로 좁게) | 개념·에디터 사용법. 페이지 끝의 관련 링크를 따라간다 |
| 2 | **클래스 레퍼런스**(§8) | 속성·메서드·시그널의 정확한 이름과 기본값 |
| 3 | **엔진에서 확인** | `doctool`·헤드리스 실행 — SKILL.md "실제로 쓰는 확인 수단" |
| 4 | **공식 데모** | 프로젝트 매니저 **Asset Library** 탭의 *Godot demo projects* — 실제로 돌아가는 예제 |
| 5 | **커뮤니티** | 공식 포럼 https://forum.godotengine.org/ — 답이 검색에 남는다 |

**프로그래밍이 처음이면** — 공식 문서가 권하는 무료 강좌 **Learn GDScript From Zero**(GDQuest,
브라우저에서 바로 실행: https://gdquest.github.io/learn-gdscript). 이 스킬의 [basics/04-script.md](basics/04-script.md) 는
"Godot 에서 코드가 어떻게 붙는가" 를 다루지 프로그래밍 자체를 가르치지는 않는다.

**동영상으로 손을 먼저 움직이고 싶으면** — [basics/08-video.md](basics/08-video.md).

### 질문하는 법 — 답을 빨리 받는 6가지

공식 문서가 정리한 것이고, **AI 에게 물을 때도 똑같이 적용된다.**

1. **목표를 말한다** — "이렇게 하고 싶다". 방법이 아니라 목적을 말하면 더 쉬운 길이 있을 수 있다
2. **오류 메시지를 그대로 붙인다** — Debugger 패널의 **Copy Error** 아이콘으로 복사한다. 요약하지 않는다
3. **코드를 텍스트로 붙인다** — 스크린샷이 아니라 텍스트
4. **Scene 독 스크린샷을 붙인다** — 코드의 대부분은 씬 구조에 묶여 있다. **씬도 소스 코드다.** 폰 카메라로 찍지 않는다
5. 움직임 문제면 **화면 녹화**
6. **버전을 밝힌다** — stable 이 아니면 특히

---

## 10. 시스템 요구 사양 — 공식 최소치와 이 프로젝트의 기준

공식 *System requirements* 페이지의 **모바일 실행(native export) 최소치**는 이렇다.

| 항목 | 공식 최소 (실행 기기) |
|---|---|
| GPU | **Vulkan 1.0** 을 완전히 지원하는 SoC — 예: Adreno 505 · Mali-G71 MP2 · Apple A12 (Forward+·Mobile) / OpenGL ES 3.0 (Compatibility) |
| RAM | **1GB** |
| OS | Android 9.0 (Forward+·Mobile) / iOS 12.0 |

**이 프로젝트의 기준은 이것보다 훨씬 높다 — 그런데도 "최소 사양" 이다.**

| | 공식 최소 | 라리엔 3D 규범 | 왜 다른가 |
|---|---|---|---|
| RAM | 1GB | **3GB** (Galaxy A12 급) | 공식 최소는 "엔진이 뜬다" 의 기준이고, 라리엔은 **MMORPG 를 60fps 로** 돌리는 기준이다 |
| 렌더러 | 셋 다 가능 | **Mobile** | 실측이 Mobile 기준이다 |
| 성능 | — | 드로우콜 300 · 광원 0 · 본 16 | [performance-mobile.md §0](performance-mobile.md) · [lowend-3gb-60fps.md](lowend-3gb-60fps.md) |

> 🛑 **"공식 최소가 1GB 니까 더 낮춰도 된다" 로 읽지 않는다.** 그 값은 빈 씬이 뜨는 기준이다.
> 라리엔의 3GB 는 실기기 실측으로 정한 값이고 SSOT 가 못 박았다.

에디터를 돌리는 **개발 PC** 의 공식 권장은 8GB RAM·Vulkan 1.2 전용 GPU 다. 이 스킬의
헤드리스·실기기 워크플로우([headless-workflow.md](headless-workflow.md))는 macOS 를 전제로 실측했다.

---

## 11. 자주 막히는 곳

| 증상 | 원인 | 해결 |
|---|---|---|
| macOS 에서 "확인되지 않은 개발자" 로 열리지 않는다 | Gatekeeper | 우클릭 → **열기**. 또는 Homebrew cask 로 설치 |
| Asset Library 탭이 비어 있다 | 기본이 오프라인 | **Go Online** 을 누른다. Settings 의 **Network Mode** 에서 되돌릴 수 있다 |
| Create 창에서 폴더에 초록 체크가 안 뜬다 | 빈 폴더가 아니다 | 빈 폴더를 만들거나 **Create Folder** 를 켠다 |
| 프로젝트를 열자마자 죽는다 | 플러그인·`@tool` 스크립트·GDExtension | **Edit in recovery mode**(§2) |
| 에디터가 느리고 팬이 돈다(맥 Retina) | 고해상도 뷰포트 | 3D 뷰포트 **Perspective ▾ → Half Resolution**, Editor Settings **Low Processor Mode Sleep** 을 `33000` 으로 → [debugging.md](debugging.md) 문제 해결 절 |
| 처음 실행이 오래 걸린다 | 셰이더 컴파일·캐시 | 정상. 두 번째부터 빠르다. 엔진·드라이버를 올리면 다시 한 번 느리다 |
| `godot` 명령이 없다 | PATH 에 없다 | §1 — Homebrew 또는 실행 파일 경로를 PATH 에 |
| 공식 튜토리얼대로 태양을 넣었더니 폰에서 느리다 | 라리엔은 광원 0개 | §7 표 — 공식 First 3D game 과 다른 점 |

---

## 관련 문서

- [basics.md](basics.md) — 다음 단계. 색인 → [basics/00-study-list.md](basics/00-study-list.md) 부터
- [example.md](example.md) — 이 문서 §3 이 끝난 곳에서 시작하는 실습
- [basics/06-editor-screen.md](basics/06-editor-screen.md) — 에디터 화면 상세
- [debugging.md](debugging.md) — 실행이 안 되거나 오류가 날 때
- [best-practices.md](best-practices.md) — 공식 Best practices 와 스타일 가이드
- [whats-new.md](whats-new.md) — 버전이 다를 때

## 공식 문서

- Introduction: https://docs.godotengine.org/en/stable/getting_started/introduction/index.html
- Overview of Godot's key concepts: https://docs.godotengine.org/en/stable/getting_started/introduction/key_concepts_overview.html
- First look at Godot's interface: https://docs.godotengine.org/en/stable/getting_started/introduction/first_look_at_the_editor.html
- Learning new features: https://docs.godotengine.org/en/stable/getting_started/introduction/learning_new_features.html
- Godot's design philosophy: https://docs.godotengine.org/en/stable/getting_started/introduction/godot_design_philosophy.html
- Using the Project Manager: https://docs.godotengine.org/en/stable/tutorials/editor/project_manager.html
- How to read the Godot API: https://docs.godotengine.org/en/stable/tutorials/scripting/how_to_read_the_godot_api.html
- System requirements: https://docs.godotengine.org/en/stable/about/system_requirements.html
- Your first 3D game: https://docs.godotengine.org/en/stable/getting_started/first_3d_game/index.html
- Learn GDScript From Zero: https://gdquest.github.io/learn-gdscript
