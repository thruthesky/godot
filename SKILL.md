---
name: godot
description: Godot 4.7 로 3D 게임(모바일 MMORPG 라리엔 3D)을 만들 때의 개발 규범·검증 도구이자 Godot 을 처음 배우는 사람의 학습 자료. 설치·프로젝트 매니저·노드·씬·인스턴싱·리소스·생명주기·시그널·에디터 사용법 같은 기본 개념부터 GDScript, Node3D 좌표계, Jolt Physics, CharacterBody3D, 머티리얼·조명·셰이더, AnimationTree, 내비게이션, 입력·UI(HUD·메뉴·Theme·한글 폰트), glTF 임포트, 오디오, 저수준 네트워킹(UDP·HTTP·WebSocket), 디버깅, 저사양 Android(3GB RAM) 60fps 최적화, LSP 정적 검증, EditorPlugin, Asset Store, CSG·GridMap 레벨 디자인, 헤드리스 워크플로우, Android·iOS·macOS·Windows 빌드와 실기기 설치까지 다룬다. 다음 때 반드시 사용한다 — GDScript 작성·수정(작성 후 LSP 진단 필수), 씬·노드·.tscn 편집, 이동·충돌·물리, 조명·셰이더, 애니메이션, 길찾기·적 AI, 성능·드로우콜·프레임 문제, HUD·버튼·인벤토리 UI, 맵·블록아웃, 빌드·설치·실기기 실행, project.godot 설정, 에디터 도구·플러그인, 애드온, Godot 용어·기본 개념 학습, "노드가 뭔가요" 같은 입문 질문, 오류·크래시 진단. 성능·조명·저사양 질문이면 references/performance-mobile.md §0 을 먼저 읽는다. 키워드 — Godot, 고도, GDScript, tscn, Node3D, CharacterBody3D, Jolt, AnimationTree, NavigationAgent3D, MultiMesh, LOD, 드로우콜, 60fps, 3GB, 저사양, CSG, 블록아웃, GridMap, HUD, Theme, LSP, export, APK, Xcode, 헤드리스, 라리엔, godot init, 예제, 튜토리얼, 입문, 메시, mesh, 정점, vertex, 꼭짓점, 모서리, edge, 삼각형, triangle, 면, face, 폴리곤, 서피스, surface, 인덱스, 와이어프레임, wireframe, ArrayMesh, SurfaceTool, MeshInstance3D.
---

# Godot — 3D 게임 개발·학습 스킬

## 🧭 왕초보는 여기부터 — 이 파일은 길다. 지금 읽을 것은 셋뿐이다

| 순서 | 무엇 | 어디 |
|---|---|---|
| 0 | **Godot 을 받고 첫 프로젝트를 만든다** (🛑 렌더러 Mobile) · 공식 문서 읽는 법 | [references/getting-started.md](references/getting-started.md) |
| 1 | **개념** — 노드·씬·인스턴싱·스크립트·시그널·에디터 | [basics/00-study-list.md](references/basics/00-study-list.md) → [01-world](references/basics/01-world.md) · [02-scene](references/basics/02-scene.md) · [03-instancing](references/basics/03-instancing.md) · [04-script](references/basics/04-script.md) · [05-signal](references/basics/05-signal.md) · [06-editor-screen](references/basics/06-editor-screen.md) · [07-editor-input](references/basics/07-editor-input.md) · [08-video](references/basics/08-video.md) · [09-controller](references/basics/09-controller.md) · [10-animation](references/basics/10-animation.md) (색인: [basics.md](references/basics.md)) |
| 2 | **손** — 빈 프로젝트에서 캐릭터가 움직이기까지 (맨 앞 "빠른 길" 8개 조작) | [references/example.md](references/example.md) |

- 용어가 안 보이면 [dictionary.md](references/dictionary.md) · 코드를 쓰기 시작하면 [gdscript.md](references/gdscript.md) + LSP · 실행이 이상하면 [debugging.md](references/debugging.md)
- 🛑 공식 튜토리얼의 **태양 추가·원근 카메라·거리 줌**은 따르지 않는다 — 이 프로젝트는 **광원 0개·직교 −45° 고정·`size` 줌**이다([example.md §0-B](references/example.md))
- 아래의 절대 규칙·저사양 실측·`/godot init` 은 **게임을 만들 때** 지킨다. 처음 배우는 동안은 위 셋으로 충분하다.

## 다루지 않는 것 — 물어보면 공식 문서로 안내한다

| 범위 밖 | 이유 | 공식 |
|---|---|---|
| **2D 게임**(`Node2D`·`TileMapLayer`·2D 물리) | 라리엔 3D 는 3D. **2D 는 UI(`Control`)뿐** — [hud-menu.md](references/hud-menu.md) | https://docs.godotengine.org/en/stable/tutorials/2d/index.html |
| **C#/.NET · GDExtension 제작** | GDScript 만 쓴다([gdscript.md](references/gdscript.md) 범위) | https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html |
| **XR** | 대상 아님. 제안하지 않는다 | https://docs.godotengine.org/en/stable/tutorials/xr/index.html |
| **Web 내보내기** | Android·iOS·Steam 만 | https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html |
| **Godot 고수준 멀티플레이어로 서버 통신** | 서버가 Godot 이 아니다 — [networking-lowlevel.md](references/networking-lowlevel.md) | — |

**최신 Godot 기준**으로 3D 게임을 개발하기 위한 전체 개발 정보와 검증 도구를 제공한다.

## 이 스킬의 두 가지 성격

이 스킬은 **개발 규범이자 학습 자료**다. 둘 다이며, 어느 한쪽이 아니다.

| 성격 | 뜻 |
|---|---|
| **개발 규범** | 라리엔 3D 코드는 여기 적힌 방식을 따른다. "절대 규칙" 절은 예외 없이 지킨다 |
| **학습 자료** | 사용자는 **Godot 을 배우면서 게임을 만들고 있다.** 엔진 사용법·기본 개념도 이 스킬이 설명한다 |

### 그래서 답할 때 지킬 것

**결과만 주지 말고 왜 그런지를 함께 설명한다.** 사용자는 코드를 받는 것이 아니라
**Godot 을 이해하려 하고 있다.**

| 하지 않는다 | 한다 |
|---|---|
| "이 코드를 쓰세요" 하고 끝 | 그 노드가 무엇이고, 왜 그 노드인지, 대안은 무엇인지 한 줄이라도 붙인다 |
| 에디터 조작을 말로만 | **어느 독에서 · 어떤 버튼·단축키로** 하는지 경로를 준다 |
| 용어를 설명 없이 사용 | 처음 나오는 용어는 뜻을 밝히거나 [dictionary.md](references/dictionary.md) 로 보낸다 |
| 값을 추측해서 단언 | 엔진에서 확인하고, 확인했다는 사실과 값을 함께 보인다 |
| 스킬 문서에 없어서 **"모른다"·"다루지 않는다"** | 🛑 **밖에서 찾아 확인하고 답한다** — 공식 문서·엔진 소스·웹 검색·헤드리스 실행 (→ 아래 **이 스킬 문서만 보고 답하지 않는다**) |

### 🛑 소스 코드를 요청받으면 — **주석을 단 전체 파일**로 준다

사용자가 *"소스 코드를 보여 달라"* · *"설명을 달아 달라"* 고 하면
**조각이 아니라 파일 전체**를, **그 자리에서 읽고 이해할 수 있는 주석과 함께** 준다.

**표준 형식은 [example.md](references/example.md) §7 의 "📜 주석 완전판"** 이다.
새로 코드를 설명할 때도 그 형식을 따른다.

| 반드시 담을 것 | 예 |
|---|---|
| **파일 머리 블록** | 이 스크립트가 **붙는 자리**, **기대하는 씬 구조**, 좌표 규약 |
| **함수마다** | **누가 부르는가**(내가? 엔진이?) · **언제 부르는가** · 이름을 틀리면 어떻게 되는가 |
| **줄·블록마다** | 무엇을 하는가 → **왜 그렇게 하는가** → **바꾸면 어떻게 되는가** |
| **함정 표시** | 🛑 로 표시하고 **틀렸을 때 나오는 실제 오류 메시지**를 적는다 |
| **이름의 출처** | 엔진이 정한 이름인지, 내가 지은 이름인지 (바꿔도 되는지) |
| 🛑 **선언 없이 쓰는 이름** | `extends` 로 물려받아 그냥 쓰는 것(`velocity`·`is_on_floor()`·`global_position` …)은 **처음 나오는 자리에서** 정체·타입·단위·이름을 바꿀 수 있는지까지 밝힌다 |

**주석은 실행에 영향이 없으므로 그대로 복사해 써도 된다는 것**을 함께 알린다.

> 🛑 **다 쓴 뒤 반드시 점검한다** — **파일 안에 `var`·`func` 로 선언되지 않았는데
> 설명 없이 등장하는 이름이 있는지** 훑는다. 독자는 그 이름이 어디서 왔는지 알 방법이
> 없고, "왜 이건 설명이 없나" 로 막힌다. 실제로 `velocity` 를 빠뜨려 지적받았다.

**설명이 문서에 없으면 먼저 문서에 채우고 나서 답한다.** 답변만 하고 끝내면
같은 질문이 반복되고, 문서와 답이 갈라진다.


**Godot 을 처음 접하는 질문이면 [basics.md](references/basics.md) 를 먼저 읽는다.**
그 문서는 색인이고, 본문은 [`references/basics/`](references/basics/) 아래 11개 파트에 있다.
노드·씬·인스턴싱·리소스·생명주기·에디터 화면 구성이 거기 있다.

### 새 내용을 어느 문서에 넣을 것인가

**기본은 [`basics/`](references/basics/) 의 해당 파트로 모은다**(색인은 [basics.md](references/basics.md)). 문서가 늘어날수록 "기본 개념을
찾으려면 어디를 봐야 하는가"가 흐려지므로, 아래 기준으로 갈라 놓는다.

| 성격 | 넣을 곳 |
|---|---|
| **기본 개념·기본 문법·기본 사용법** — Godot 을 배우는 사람이 알아야 할 것 | **[basics/](references/basics/) 의 해당 파트** (00 공부 목록 · 01 세계관 · 02 씬 · 03 인스턴싱 · 04 스크립트 · 05 시그널 · 06 에디터 화면 · 07 에디터 조작 · 08 강좌 · 09 컨트롤러 · 10 애니메이션) — 색인 [basics.md](references/basics.md) 의 줄 수·요약도 함께 갱신한다 |
| **저사양(3GB RAM) 60fps 실측·노하우** — 베이킹·병목 진단·본 수·크래시 회피 | **[lowend-3gb-60fps.md](references/lowend-3gb-60fps.md)** |
| **저사양에서 LOD·컬링·해상도 스케일링·VRS 를 쓸지 말지** — 엔진 기능별 판정 | **[lowend-culling-lod.md](references/lowend-culling-lod.md)** |
| 용어의 뜻 한 가지 | [dictionary.md](references/dictionary.md) |
| 특정 영역의 **테크닉·심화·실전 패턴** | 그 영역 문서 (physics-3d, rendering-3d, animation-3d …) |
| 문법의 **전수 목록·상세 레퍼런스** | [gdscript.md](references/gdscript.md) |

판단이 애매하면 이렇게 가른다 — **"Godot 을 처음 배우는 사람이 이걸 몰라서 막히는가?"**
그렇다면 `basics/` 의 해당 파트다. **"이미 아는 사람이 더 잘하려고 찾는 것인가?"** 그렇다면 영역 문서다.

같은 주제를 양쪽에 쓸 때는 **`basics/` 파트에 개념을, 영역 문서에 실전을** 두고 서로 링크한다.
인스턴싱이 그 예다 — 개념과 4단계는 [basics/03-instancing.md](references/basics/03-instancing.md), 스포너·풀링 같은 패턴은
[nodes-scenes.md](references/nodes-scenes.md) §4 에 있다.

특정 패치 버전에 묶인 문서가 아니다. 새 기능은 **도입 버전을 표기**해
(`(4.5+)`, `(4.6 신규)`, `(4.7 신규)`) 쓸 수 있는지 바로 판단하게 한다.
버전별 신기능과 업그레이드 절차는 [references/whats-new.md](references/whats-new.md)에 모아 둔다.

> **검증 기준**: 문서의 API·기본값·설정 키는 **엔진에서 직접 추출·실행해 확인한 것**이며,
> 현재 확인 기준 버전은 `godot --version` 기준 **4.7.2.stable**이다.
> 엔진을 올렸다면 값이 달라질 수 있으므로, 의심스러우면 그 자리에서 다시 확인한다.
>
> ```bash
> godot --version                          # 현재 엔진 버전
> godot --headless --doctool /tmp/gddoc     # 클래스 정의 XML 전체 추출
> ```

## `/godot init` 과 `./install.sh` — 절차는 [references/godot-init.md](references/godot-init.md)

사용자가 **`/godot init`** 이라고 지시하면 세 가지를 한다 — ① 이 스킬의 `commands/godot-example.md` 를 대상
프로젝트의 `.claude/commands/` 로 **복사**한다(그 뒤로는 `/godot-example` 처럼 짧게 부른다). ② 프로젝트 루트에
`install.sh` → `.claude/skills/godot/scripts/install.sh` 를 가리키는 **상대경로 심볼릭 링크**를 건다 — 복사가
아니다. ③ `scripts/triangles.sh` → `../.claude/skills/godot/scripts/triangles.sh` 링크를 건다(🛑 `scripts/` 안에
있으므로 `..` 이 하나 더 붙는다). 복사하면 스킬을 고쳐도 사본은 옛날 그대로 남지만, 링크는 모든 프로젝트에 즉시 반영된다.
🛑 같은 이름의 파일이 이미 있으면 덮어쓰지 않고 차이를 보여주며, `ln -sf` 를 쓰지 않고(진짜 `install.sh` 를
말없이 지운다), 원본 존재를 먼저 확인하고, 만든 뒤 `./install.sh --list` 로 검증한다. 인자로 경로가 오면
(`/godot init ~/apps/ex2`) 그 프로젝트에, 없으면 현재 프로젝트에 설치한다. 표에 없는 파일은 설치하지 않는다.
**설치 명령 전문·지킬 것 8가지·Windows 대안·`project.godot` 탐색 규칙은 위 문서에 있다.**

---

## 🛑 이 스킬 문서만 보고 답하지 않는다 — **밖에서 찾아 확인한다**

**이 스킬은 출발점이지 울타리가 아니다.**
여기에 적힌 것은 이 프로젝트가 내린 **결정과 실측 기록**이지 Godot 의 전부가 아니다.
**스킬에 없다고 해서 "없다"·"모른다"·"안 된다"고 답하지 않는다.**

### 근거의 우선순위 — 위쪽이 항상 이긴다

| 순위 | 근거 | 무엇을 물을 때 |
|---|---|---|
| **1** | **엔진에서 직접 확인** (doctool · 헤드리스 실행 · 소스) | 값·기본값·실제 동작 |
| **2** | **이 스킬의 references** | 이 프로젝트의 규범·결정·이미 잰 실측 |
| **3** | **공식 문서 · 엔진 소스코드** | 스킬에 없는 API·시그니처·에디터 동작 |
| **4** | **웹 검색** | 최신 이슈·버전별 변경·서드파티 애드온·남들이 겪은 함정 |
| — | **기억(사전학습 지식)** | 🛑 **출발점일 뿐 근거가 아니다.** 어디를 확인할지 정하는 데만 쓴다 |

**충돌하면 1번이 이긴다.** 이 스킬 문서가 엔진 실측과 다르면 **문서가 틀린 것**이므로
고친다. 기억이 문서와 다르면 **둘 다 의심하고 엔진에서 확인**한다.

### 사전학습 지식을 어떻게 쓰나

**답으로 쓰지 말고 가설로 쓴다.**

| 🛑 이렇게 하지 않는다 | ✅ 이렇게 한다 |
|---|---|
| "제 기억으로는 기본값이 1.0 입니다" | doctool 로 뽑아 **"확인했더니 `0.7853982` 였습니다"** |
| "아마 이 메서드가 있을 겁니다" | 클래스 XML 을 grep 해 **시그니처를 그대로 인용** |
| 스킬에 없어서 "다루지 않습니다" | **공식 문서·소스를 찾아보고** 답한다 |

Godot 은 버전마다 API 가 바뀐다. **기억은 어느 버전 것인지 알 수 없으므로**
그 자체로는 근거가 되지 못한다.

### 실제로 쓰는 확인 수단

```bash
# ① 클래스 정의 전체 추출 — 기본값·시그니처·enum 값의 1차 출처
godot --headless --doctool /tmp/gddoc
grep -oE '<member name="floor_max_angle"[^>]*default="[^"]*"' /tmp/gddoc/doc/classes/CharacterBody3D.xml

# ② 엔진 소스에서 확인 — 에디터 동작·단축키·내부 규칙은 문서에 없다
curl -sfL -o /tmp/x.cpp https://raw.githubusercontent.com/godotengine/godot/4.7/<경로>
grep -n 'ED_SHORTCUT("spatial_editor/snap"' /tmp/x.cpp

# ③ 헤드리스로 실제 실행 — "정말 그런가"를 재는 가장 확실한 방법
godot --headless --path <스크래치패드 프로젝트> --script res://check.gd

# ④ 문법만 검사 — 실행하지 않고 파싱 결과만
godot --headless --path . --check-only --script res://x.gd

# ⑤ 에디터가 떠 있으면 LSP
python3 .claude/skills/godot/scripts/gdscript_lsp.py hover res://a.gd 42 10
```

**웹은 이렇게 쓴다** — 공식 문서(`docs.godotengine.org/en/4.7/`), 클래스 레퍼런스,
GitHub 이슈·PR, Asset Store. **다만 웹에서 본 것도 그대로 옮기지 않고
엔진에서 다시 확인한다.** 블로그·강좌는 대개 옛 버전 기준이다.

### 검증용 코드는 사용자 프로젝트에 만들지 않는다

확인하려고 만든 임시 씬·스크립트는 **스크래치패드에** 두고, 끝나면 지운다.
사용자의 프로젝트를 실험장으로 쓰지 않는다.

### 알아낸 것은 문서에 남긴다

밖에서 찾아 확인한 값·동작·함정은 **그 자리에서 답하고 끝내지 말고
해당 reference 에 적는다.** 그러지 않으면 같은 것을 매번 다시 찾게 되고,
답과 문서가 갈라진다.

**"엔진에서 확인했다"는 사실과 확인한 값을 함께 적는다.** 나중에 버전이 올라
값이 달라졌을 때 무엇을 다시 재야 하는지 알 수 있다.

---

## 🛑 게임 규칙은 `game` 스킬의 SSOT 가 최종 권위다

이 스킬은 **엔진 사용법**을 담는다. **"라리엔이 어떤 규칙으로 만들어지는가"** 는
[`game` 스킬의 SSOT.md](../game/references/SSOT.md) 에 있고 **그쪽이 최종 권위다.**

| 이 스킬에서 다루는 것 | SSOT 가 정하는 것 |
|---|---|
| `Camera3D` 의 `fov`·투영·`SpringArm3D` 사용법 | **카메라 각도는 회전 3축 전부 고정**(피치 −45°·yaw 0°·roll 0°), 줌만 0.5~2배 |
| `LightmapGI` 굽는 방법·설정 | **동적 조명은 존재하지 않는다** — 낮/밤·날씨·동적 그림자 전면 금지 |
| glTF 임포트 옵션(`root_scale`·축 변환)이 무엇을 하는가 | 🛑 **보정 용도로는 쓰지 않는다.** `.glb` 가 정본이고, 값이 틀렸으면 Blender 로 돌아간다 |
| 드로우콜을 줄이는 기법 | **예산은 300** (텍스처 200MB · 메모리 1,120MB) |
| `visibility_range`·`MultiMesh` API | **거리 3구간 배분**(AOI 82개 → 8/20/54) |

**엔진이 할 수 있는 것과 이 게임이 하기로 한 것은 다르다.**
예: Godot 은 실시간 그림자를 지원하지만 **라리엔 3D 는 쓰지 않는다.**
기능을 제안하기 전에 SSOT 를 확인한다.

## 현재 프로젝트 컨텍스트

[`project.godot`](../../../project.godot)에 고정된 값이며, 모든 코드는 이 전제 위에서 작성한다.

| 항목 | 값 | 개발상 의미 |
|------|-----|------------|
| `config/name` | `Laryen 3D` | 프로젝트 이름 |
| `config/features` | `4.7`, `Mobile` | Godot 4.7 API, Mobile 렌더러 |
| `renderer/rendering_method` | `mobile` | **SDFGI·VoxelGI·SSR·SSAO·SSIL·볼류메트릭 포그·TAA 사용 불가** |
| `3d/physics_engine` | `Jolt Physics` | Godot Physics 전용 조인트 속성 사용 불가 |
| `rendering_device/driver.windows` | `d3d12` | Windows는 Direct3D 12, 그 외는 Vulkan/Metal |
| `window/stretch/mode` | `canvas_items` | UI 스케일링 방식 |

**🛑 최소 지원 사양 — 3GB RAM Android (Galaxy A12 급) 에서 60fps**

> ### **모바일 3D MMORPG 의 최소 지원 RAM 은 3GB 다.**
>
> "요즘 폰은 8GB 니까" 로 기준을 올리지 않는다. **MMORPG 는 수명이 길고,
> 그 기간 내내 구형 기기가 접속한다.** 기준을 올리는 순간 실사용자의 상당수가 잘려 나간다.
> **FPS 와 메모리가 그래픽 품질보다 우선한다.**

**🛑 저사양 60fps 작업을 시작하기 전에 반드시 읽는다 →
[references/lowend-3gb-60fps.md](references/lowend-3gb-60fps.md)**

프로시저럴 생성 → **빌드 타임 베이킹** 파이프라인, 병목을 실험으로 가려내는 절차,
조명을 정점 컬러에 굽는 법, 스킨드 캐릭터 30명 이상을 60fps 로 돌리는 법,
저사양 기기의 크래시 회피까지 **A12 실측 기록**으로 정리되어 있다.

기준 기기·실측값·규범은
[references/performance-mobile.md §0](references/performance-mobile.md#0--최소-지원-사양--3gb-ram-android-가-기준이다) 에도 있고,
성능 판단을 하기 전에 **반드시 그 절을 먼저 읽는다.**

| 실측 요약 (SM-A125N · PowerVR GE8320 · Mobile 렌더러) | |
|---|---|
| 🛑 **조명을 쓰지 않는다** — 실시간도, 라이트맵도 | 라이트맵 **1.0fps** / 실시간 22.3fps / **조명 없음 60fps**. ⚠️ **엔진이 못 하는 것이 아니다** — Mobile 렌더러는 `LightmapGI` 렌더링을 지원한다(공식 *Overview of renderers*). **A12 에서 너무 느려 우리가 쓰지 않기로 한 것**이다 |
| 반복 배치는 **무조건 `MultiMeshInstance3D`** | Mobile 렌더러엔 자동 인스턴싱이 없다 (실기기 DC 300 vs 1) |
| 🛑 **메모리도 예산이다** | 반복물을 병합하면 정점이 복제되어 **메모리 400배**. 나무 1,000그루 = MultiMesh 81KB vs 병합 33MB → [lowend-3gb-60fps.md §5.3](references/lowend-3gb-60fps.md#53--multimesh-vs-병합--메모리를-400배-내는-거래) |
| 폴리곤은 아끼지 않아도 된다 | 지형 삼각형 20만까지 실질 무해 |
| 진짜 병목은 **픽셀당 셰이딩** | 삼각형 2개짜리 면 하나가 60→22fps |
| **스킨드 캐릭터는 본 수가 곧 프레임** | 30명 기준 본 25 → **40.3fps** / 본 16 → **60.0fps** |
| **병목은 하나가 아니다 — 순서대로 드러난다** | 메모리 → 드로우콜 → 정점 → VRAM → 스켈레톤 → 로딩 |
| 🛑 **캐릭터 삼각형은 픽셀로 정한다** | 직교 고정이라 얼굴이 화면에서 **최대 38×36 px**(실측). 머리 삼각형 **2,304개를 넘으면 화면이 한 픽셀도 안 달라진다** → NPC **5,000** · 플레이어 **15,000** 이 상한이고 **2만은 화면에 나타나지 않는다**. "2만 이하면 얼굴이 뭉개진다"는 **원근 클로즈업 게임의 이야기**다 → [§7.5](references/lowend-3gb-60fps.md) |
| 🛑 **얼굴이 뭉개지면 총량이 아니라 배분을 본다** | `male.glb` 는 4,798 중 **95%가 검 한 자루**, 몸통 234 · 얼굴 **0개**였다(2026-09-02). 총량을 올려도 비율이 같으면 그대로다 |
| 드로우콜 한계는 **650~900** | 병합 전 1,291 → 병합 후 **6**. DC 83 은 문제가 아니었다 |
| 🛑 **VRS 는 A12 에서 켜도 아무 일도 안 일어난다** | Snapdragon 888+ / Dimensity 9000+ / Mali-G615+ 만 지원. 경고 없이 무시된다 → [lowend-culling-lod.md §7](references/lowend-culling-lod.md) |
| 🛑 **FSR 은 Mobile 렌더러에서 못 쓴다** | 해상도 스케일링은 **Bilinear** 만. 2D UI 는 안 상한다 → [lowend-culling-lod.md §6](references/lowend-culling-lod.md) |
| 프로시저럴은 **빌드 타임에 굽는다** | 배치 6,227개를 3.4초에 bake → 런타임 생성 코드 **0줄** · DC 9~23 |
| 리소스를 한꺼번에 로드하면 **드라이버가 죽는다** | `SIGSEGV in WorkerThread` — 프레임에 나눠 읽으면 5/5 성공 |

**Mobile 렌더러 전제로 반드시 지킬 것**

- 🛑 **같은 모양이 대량 반복되는 것(나무·풀·바위)은 `MultiMeshInstance3D` 로 묶는다.**
  병합하면 정점이 개수만큼 복제되어 **메모리를 400배** 쓴다. 병합은 **꼭짓점 단위로
  밝기가 달라야 할 때만** 지불하는 대가다 (→ lowend-3gb-60fps.md §5.3).
- 🛑 **광원 노드를 씬에 두지 않는다.** 조명은 **빌드 타임에 정점 컬러로 굽고**
  런타임 머티리얼은 `SHADING_MODE_UNSHADED` + `vertex_color_use_as_albedo` 를 쓴다.
  `LightmapGI` 는 저사양에서 **오히려 가장 느리다** (→ performance-mobile.md §8).
- `SDFGI`/`VoxelGI`는 Mobile 렌더러에 없다. 제안하지 않는다.
- 안티에일리어싱은 `MSAA 3D` 또는 `FXAA`/`SMAA`를 쓴다. `TAA`/`FSR2`는 없다.
- 후처리는 `Glow`, `Adjustments`, 기본 `Fog`까지만 가능하다.
- `SubsurfaceScattering`은 Forward+ 전용이므로 머티리얼에서 쓰지 않는다.
- AO는 화면공간 대신 **정점 컬러에 구운 AO** 또는 베이킹된 AO 텍스처를 쓴다.

렌더러별 지원/미지원 전체 표는 [references/rendering-3d.md](references/rendering-3d.md)에 있다.

## 작업 흐름 — 이 순서를 지킨다

### 1. 시작 전

- **버전 확인**: `godot --version`으로 현재 엔진 버전을 본다. 쓰려는 기능의 도입 버전이
  그보다 높으면 안 된다. 버전별 신기능과 업그레이드 시 확인할 것은
  [references/whats-new.md](references/whats-new.md)에 정리되어 있다.
- **관련 reference를 먼저 읽는다.** 아래 목록에서 해당 영역 문서를 읽고,
  Mobile 렌더러 / Jolt 제약에 맞는 방법을 고른다.
- **`.tscn`/`.tres`를 직접 편집하기 전에** [references/project-config.md](references/project-config.md)의
  포맷 규칙을 읽는다. `load_steps`나 리소스 ID를 잘못 쓰면 씬이 깨진다.

### 2. 구현 중

- 씬 구조를 먼저 정한다 — 재사용 단위마다 `.tscn`으로 분리하고 루트 노드 타입을 신중히 고른다.
- **스크립트는 씬 옆에 둔다** — `scenes/player/player.tscn` + `scenes/player/player.gd`.
  아래 "파일 배치 규범" 참고.
- 스크립트는 **정적 타입**으로 작성한다. 노드 참조는 `@onready` + 고유 이름(`%`)을 쓴다.
- 물리·이동은 `_physics_process`, 시각·입력 폴링은 `_process`에 둔다.
- 노드 간 결합은 직접 참조 대신 시그널로 푼다.

#### 파일 배치 규범 — 스크립트는 씬 옆에

**씬에 붙는 스크립트는 그 씬과 같은 폴더에 둔다** — `scenes/player/player.tscn` + `scenes/player/player.gd`.
타입별 `scripts/` 폴더는 Unity 관습이고, Godot 에서는 **Attach Script 의 기본 경로가 현재 씬 폴더**이며
스크립트가 `extends`·`$Child` 로 씬에 1:1 로 묶이고, 폴더를 나누면 파일명이 충돌해 관리가 어려워진다.
**예외** — 씬에 붙지 않는 코드는 모아 둔다: 오토로드 싱글턴(`GameState`·`AudioManager`) → `autoload/`,
`class_name` 공용 클래스(상태 머신 베이스·수학 유틸)와 커스텀 `Resource` 정의(`ItemData`·`SkillData`) → `scripts/`.
`scripts/` 를 없애는 게 아니라 용도를 바꾸는 것이다. 근거 3가지·예외 표·권장 폴더 트리(`res://` 아래 `scenes/`·
`autoload/`·`scripts/`)는 [references/nodes-scenes.md](references/nodes-scenes.md) §11 에 그대로 있다.

### 3. GDScript를 작성·수정한 직후 — 필수

**LSP로 진단한다. 이 단계를 건너뛰지 않는다.**

```bash
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose res://수정한파일.gd

# 여러 파일을 건드렸으면 git 변경분 전체
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose --changed
```

오류가 하나라도 남아 있으면 작업이 끝난 것이 아니다.
**"코드를 작성했다"고 보고하기 전에 이 명령이 오류 0개를 반환해야 한다.**

종료 코드: `0`=오류 없음, `1`=오류 있음, `2`=LSP 연결 실패.

Godot 에디터가 실행 중이어야 동작한다. 자세한 사용법·경고 종류·문제 해결은
[references/lsp.md](references/lsp.md)를 읽는다.

### 4. 기존 코드를 수정할 때

1. 해당 기능의 reference에 기록된 **핵심 로직과 소스코드를 먼저 확인**한다.
2. 문서에 기록된 패턴을 유지한 채 최소 범위로 수정한다. 기존 로직을 임의로 재작성하지 않는다.
3. 로직이 실제로 바뀌었다면 reference 문서도 함께 갱신한다.

### 5. 문제를 진단할 때

**채널을 순서대로 올라간다. 위쪽이 싸고 빠르다.**

| 알고 싶은 것 | 방법 |
|-------------|------|
| 문법·타입 오류, 경고 | `gdscript_lsp.py diagnose` |
| 파일 구조 (클래스·함수 목록) | `gdscript_lsp.py symbols` — 파일 전체를 읽지 않고 파악 |
| 변수의 타입, 심볼 정의 | `gdscript_lsp.py hover` / `definition` |
| 씬 구조, 프로젝트 설정 | `.tscn` / `project.godot` 직접 읽기 |
| 런타임 오류, 실제 노드 값, 화면 | MCP 도구 ([references/ai-tooling.md](references/ai-tooling.md)) |
| 특정 시점의 지역 변수 | DAP 브레이크포인트 |
| 성능 병목 | [references/performance-mobile.md](references/performance-mobile.md)의 CPU/GPU 구분 절차 |

**LSP로 잡을 수 있는 문제를 게임 실행으로 찾지 않는다.**
**코드만 읽고 런타임 동작을 단정하지 않는다** — 값을 확인해야 하면 MCP로 관찰한다.
**원인 파악 전에 최적화하지 않는다.**

## 절대 규칙

Godot에서 실제로 버그를 만들어내는 지점이다. 예외 없이 지킨다.

| 규칙 | 이유 |
|------|------|
| 🛑🛑 **임포트한 에셋(`.glb`·`.fbx`)을 Godot 에서 보정하지 않는다** | 모델의 **크기·자세·축 방향·원점·본 구조**가 틀렸으면 **파일 자체가 틀린 것**이다. Godot 은 파일에 적힌 것을 그대로 믿고 쓴다. `.import` 의 `root_scale`·노드 `scale`/`rotation`/`position`·`_ready()` 보정·`EditorScenePostImport` 보정·역스케일 래퍼 **전부 금지** — 전부 가능하지만 전부 부채다. **DCC(Blender)로 돌아가 고친 뒤 재익스포트한다.** 보정은 쓰는 곳마다 반복되고 콜리전·본 길이·애니 이동량·부착점·임포스터 굽기가 그 값을 전제로 쌓여 **되돌릴 수 없게 된다** |
| 물리 관련 코드는 `_physics_process(delta)`에만 쓴다 | 물리 서버는 고정 틱(기본 60Hz)으로 돈다. `_process`에서 바디를 움직이면 지터·터널링이 생긴다 |
| 3D 회전은 `rotation`(오일러) 대신 `Transform3D`/`Basis`/`Quaternion`으로 다룬다 | 오일러는 짐벌락·회전 순서 의존·보간 왜곡을 일으킨다 |
| 전방 벡터는 `-transform.basis.z`다 | Godot 3D는 **-Z가 forward**, +Y가 up, +X가 right |
| `:=`는 우변 타입이 확실할 때만 쓴다 | `Object.get()`, 딕셔너리 값, 빈 `[]`/`{}`, 불확실한 노드 경로에서 추론하면 Variant가 되어 이후 모든 접근이 unsafe가 된다 |
| `name`·`position`·`rotation`·`scale`·`visible`·`seed`를 변수명으로 쓰지 않는다 | 엔진 멤버를 가려 예측 불가능한 동작을 만든다 |
| `@export`와 `@onready`를 함께 쓰지 않는다 | 인스펙터 값이 `_init()` 시점에 신뢰할 수 없다 |
| 필수 노드는 `@onready var n := $Path as Type` 대신 명시적 타입을 쓴다 | `as`는 실패 시 조용히 `null`이 된다 |
| `await` 뒤에 `is_instance_valid(self)`와 `is_inside_tree()`를 확인한다 | 대기 중 노드가 제거될 수 있다 |
| 물리·접촉 콜백에서 씬 트리·콜리전 셰이프·monitoring 변경은 `call_deferred`로 미룬다 | 물리 쿼리 중 상태 변경은 오류를 낸다 |
| `free()` 대신 `queue_free()`를 쓴다 | 프레임 중간 `free()`는 순회 중인 트리를 깨뜨린다 |
| 씬 첫 프레임에 NavigationServer 결과를 읽지 않는다 | 첫 물리 프레임 전까지 맵이 동기화되지 않는다. `await get_tree().physics_frame` 필요 |
| 누적 회전 후 `transform = transform.orthonormalized()` | 부동소수점 오차로 basis가 찌그러진다 |
| 리소스를 인스턴스 간 공유할 때 주의한다 | 머티리얼·AnimationTree 등은 기본 공유. 개별화는 `duplicate()` 또는 `Local to Scene` |
| 씬에 붙는 스크립트는 씬과 같은 폴더에 둔다 | 엔진의 Attach Script 기본 경로가 그 구조를 전제한다. 씬과 1:1로 묶인 코드를 분리하면 이동·삭제 때마다 두 폴더를 손으로 동기화해야 하고 파일명이 충돌한다 |

## 참조 문서

**상세 소개는 [references/catalog.md](references/catalog.md)** 에 있다(예전에 이 자리에 있던 약 800줄을 그대로 옮겼다). 여기는 **어디로 갈지 고르는 표**다.

| 문서 | 무엇 | 언제 |
|---|---|---|
| [lowend-3gb-60fps.md](references/lowend-3gb-60fps.md) | 🛑 3GB RAM 폰에서 60fps ★ 저사양 작업 전 필독 | [상세](references/catalog.md#lowend-3gb-60fpsmd---3gb-ram-폰에서-60fps--저사양-작업-전-필독) |
| [lowend-culling-lod.md](references/lowend-culling-lod.md) | 저사양에서 "그리는 양"을 줄이는 6가지 엔진 기능 | [상세](references/catalog.md#lowend-culling-lodmd--저사양에서-그리는-양을-줄이는-6가지-엔진-기능) |
| [basics.md](references/basics.md) | Godot 기본 **색인** ★ 처음 배울 때 먼저 · 본문은 [`basics/`](references/basics/) 11파트 · 기본은 거기 모은다 | [상세](references/catalog.md#basicsmd--godot-기본--처음-배울-때-먼저--기본은-여기-모은다) |
| [example.md](references/example.md) | 예제: 빈 프로젝트에서 캐릭터가 움직이기까지 ★ 손으로 한 번 만들어 본다 | [상세](references/catalog.md#examplemd--예제-빈-프로젝트에서-캐릭터가-움직이기까지--손으로-한-번-만들어-본다) |
| [lsp.md](references/lsp.md) | Godot LSP 정적 검증 ★ 코드 작성 시 필수 | [상세](references/catalog.md#lspmd--godot-lsp-정적-검증--코드-작성-시-필수) |
| [gdscript.md](references/gdscript.md) | GDScript 2.0 언어 전체 | [상세](references/catalog.md#gdscriptmd--gdscript-20-언어-전체) |
| [nodes-scenes.md](references/nodes-scenes.md) | 노드·씬·SceneTree 아키텍처 | [상세](references/catalog.md#nodes-scenesmd--노드씬scenetree-아키텍처) |
| [3d-core.md](references/3d-core.md) | Node3D·Transform3D·카메라 | [상세](references/catalog.md#3d-coremd--node3dtransform3d카메라) |
| [mesh-geometry.md](references/mesh-geometry.md) | 메시의 구조 — 정점·모서리·삼각형·면 | [상세](references/catalog.md#mesh-geometrymd--메시의-구조--정점모서리삼각형면) |
| [multimesh-3d.md](references/multimesh-3d.md) | MultiMeshInstance3D — 대량 배치와 🛑 콜리전이 복제되지 않는 문제 | 나무·바위·풀을 수백~수천 개 놓을 때 |
| [physics-3d.md](references/physics-3d.md) | Jolt Physics와 3D 물리 | [상세](references/catalog.md#physics-3dmd--jolt-physics와-3d-물리) |
| [rendering-3d.md](references/rendering-3d.md) | 렌더러·머티리얼·조명·환경 | [상세](references/catalog.md#rendering-3dmd--렌더러머티리얼조명환경) |
| [animation-3d.md](references/animation-3d.md) | 애니메이션 시스템 | [상세](references/catalog.md#animation-3dmd--애니메이션-시스템) |
| [navigation-3d.md](references/navigation-3d.md) | 길찾기와 적 AI | [상세](references/catalog.md#navigation-3dmd--길찾기와-적-ai) |
| [input-ui.md](references/input-ui.md) | 입력 처리와 Control UI | [상세](references/catalog.md#input-uimd--입력-처리와-control-ui) |
| [hud-menu.md](references/hud-menu.md) | HUD·메뉴·버튼 만들기 (화면 UI 조립) | [상세](references/catalog.md#hud-menumd--hud메뉴버튼-만들기-화면-ui-조립) |
| [i18n.md](references/i18n.md) | 다국어 — 번역·언어 전환·폰트 폴백·RTL | [상세](references/catalog.md#i18nmd--다국어-i18n) |
| [resources-assets.md](references/resources-assets.md) | 리소스와 에셋 임포트 | [상세](references/catalog.md#resources-assetsmd--리소스와-에셋-임포트) |
| [audio.md](references/audio.md) | 3D 오디오 | [상세](references/catalog.md#audiomd--3d-오디오) |
| [shaders-3d.md](references/shaders-3d.md) | 셰이더 | [상세](references/catalog.md#shaders-3dmd--셰이더) |
| [performance-mobile.md](references/performance-mobile.md) | 최적화와 내보내기 ★ §0 먼저 | [상세](references/catalog.md#performance-mobilemd--최적화와-내보내기--0-먼저) |
| [headless-workflow.md](references/headless-workflow.md) | 에디터 없이 작업하기 ★ 기본 작업 방식 | [상세](references/catalog.md#headless-workflowmd--에디터-없이-작업하기--기본-작업-방식) |
| [export-build.md](references/export-build.md) | 빌드와 내보내기 (플랫폼 공통) | [상세](references/catalog.md#export-buildmd--빌드와-내보내기-플랫폼-공통) |
| [export-build-android.md](references/export-build-android.md) | Android 빌드 | [상세](references/catalog.md#export-build-androidmd--android-빌드) |
| [export-build-ios.md](references/export-build-ios.md) | iOS 빌드 | [상세](references/catalog.md#export-build-iosmd--ios-빌드) |
| [export-build-desktop.md](references/export-build-desktop.md) | macOS·Windows·Linux | [상세](references/catalog.md#export-build-desktopmd--macoswindowslinux) |
| [multiplayer.md](references/multiplayer.md) | 멀티플레이어 | [상세](references/catalog.md#multiplayermd--멀티플레이어) |
| [project-config.md](references/project-config.md) | 설정 파일 포맷과 CLI | [상세](references/catalog.md#project-configmd--설정-파일-포맷과-cli) |
| [ai-tooling.md](references/ai-tooling.md) | LSP·MCP·Codex 연동 | [상세](references/catalog.md#ai-toolingmd--lspmcpcodex-연동) |
| [editor-plugin.md](references/editor-plugin.md) | @tool과 EditorPlugin 개발 | [상세](references/catalog.md#editor-pluginmd--tool과-editorplugin-개발) |
| [whats-new.md](references/whats-new.md) | 최신 버전 신기능과 마이그레이션 | [상세](references/catalog.md#whats-newmd--최신-버전-신기능과-마이그레이션) |
| [asset-store.md](references/asset-store.md) | Asset Store와 애드온 | [상세](references/catalog.md#asset-storemd--asset-store와-애드온) |
| [level-design.md](references/level-design.md) | 맵 만들기 | [상세](references/catalog.md#level-designmd--맵-만들기) |
| [openworld-3d.md](references/openworld-3d.md) | 오픈월드 만들기 ★ 넓은 야외 맵 | [상세](references/catalog.md#openworld-3dmd--오픈월드-만들기--넓은-야외-맵) |
| [dictionary.md](references/dictionary.md) | 용어집 | [상세](references/catalog.md#dictionarymd--용어집) |
| [getting-started.md](references/getting-started.md) | ★ 0단계 — 내려받기·프로젝트 매니저·New Project(Mobile)·핵심 개념 4·공식 문서·API 읽는 법 | Godot 을 처음 설치하거나 공식 문서·클래스 레퍼런스를 읽는 법을 물을 때 |
| [networking-lowlevel.md](references/networking-lowlevel.md) | 🛑 외부 서버(Zone UDP·Nakama)에 붙는 엔진 API — PacketPeerUDP·StreamPeerBuffer 엔디안·HTTPRequest·WebSocketPeer·TLS | 서버 통신 코드를 쓸 때. 프로토콜 값은 `game` 스킬 |
| [best-practices.md](references/best-practices.md) | 공식 Best practices 12편 + GDScript 스타일 가이드(명명·코드 순서) + 공식과 이 스킬이 다른 곳 | "왜 이렇게 하라고 하나"·씬 vs 스크립트·오토로드 남용·명명 규칙 |
| [debugging.md](references/debugging.md) | 실행 뒤 문제 — Output·Debugger·Remote 씬 트리·오류 읽기·프로파일러·ObjectDB·원격 디버그·Android 심볼화·Troubleshooting·내비 디버그 | 오류 메시지·안 보임·느림·폰에서만 죽음 |
| [keywords.md](references/keywords.md) | 예전 `description` 의 트리거 키워드 전량(9,319자) — 검색 색인 | 어떤 질문이 어느 문서로 가야 하는지 찾을 때 |
| [godot-init.md](references/godot-init.md) | `/godot init` 설치 절차 전문 + `install.sh` 옵션·장치 목록 기준 (SKILL.md 에서 이동) | `/godot init` 지시를 받았을 때 · 실기기 빌드·설치 |

## 번들 스크립트

### scripts/gdscript_lsp.py

Godot LSP 클라이언트. **Python 표준 라이브러리만 사용**하므로 설치가 필요 없다.

```bash
python3 .claude/skills/godot/scripts/gdscript_lsp.py ping                      # 연결 확인
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose res://a.gd       # 진단
python3 .claude/skills/godot/scripts/gdscript_lsp.py diagnose --changed        # git 변경분 전체
python3 .claude/skills/godot/scripts/gdscript_lsp.py --json diagnose --changed # JSON 출력
python3 .claude/skills/godot/scripts/gdscript_lsp.py symbols res://a.gd        # 파일 구조
python3 .claude/skills/godot/scripts/gdscript_lsp.py hover res://a.gd 42 10    # 타입 정보
python3 .claude/skills/godot/scripts/gdscript_lsp.py definition res://a.gd 42 10
python3 .claude/skills/godot/scripts/gdscript_lsp.py complete res://a.gd 42 10
```

Godot 에디터가 실행 중이어야 한다. 상세 사용법은 [references/lsp.md](references/lsp.md).

### scripts/install.sh — 상세는 [references/godot-init.md §2](references/godot-init.md)

**빌드·설치·실행 스크립트.** 그냥 실행하면 지금 쓸 수 있는 장치(macOS·iOS·Android)를 번호로 보여주고,
번호·기기 ID·`macos` 를 고르면 그 플랫폼으로 빌드·설치·실행까지 한다. preset 이름·패키지 ID·산출물 경로는
`export_presets.cfg` 에서 직접 읽으므로 프로젝트마다 고칠 것이 없다. `--list`·`--console`·`--skip-build`·`--release`·
`--no-launch`·`--path` 옵션, 장치가 목록에 오르는 기준(iOS 는 `devicectl` 이 `available` 로 판정한 것만, Android 는
`adb devices` 의 `device` 상태만), stdin 이 터미널이 아닐 때 묻지 않고 목록만 찍는 동작, macOS `.zip` 풀기와
`com.apple.quarantine` 제거는 위 문서에 있다. 에디터 Remote Deploy 와 결과가 같으므로 에디터를 띄우지 않는
작업에서는 이 스크립트를 쓴다 → [references/headless-workflow.md](references/headless-workflow.md) §3.

### scripts/triangles.sh — 삼각형·드로우콜 세기

**씬에 삼각형이 몇 개인지 센다.** 엔진에는 "씬 전체 삼각형" API 가 없어 노드를 순회해야 하는데,
그 순회를 대신한다. `/godot init` 이 프로젝트의 `scripts/triangles.sh` 로 링크를 걸어 준다.

```bash
scripts/triangles.sh                        # main_scene 총량
scripts/triangles.sh scenes/main/main.tscn  # 씬 하나 — 무거운 노드 순위·종류별 집계
scripts/triangles.sh --all --budget 150000  # 전 씬. 초과가 있으면 종료 코드 1 (CI)
scripts/triangles.sh --frame                # 실제로 띄워 "그린" 삼각형 (VISIBLE·SHADOW·CANVAS 분리)
scripts/triangles.sh --glb assets           # Godot 없이 .glb 를 파이썬으로 직접 읽는다
```

🛑 **기본 모드와 `--frame` 은 다른 것을 센다** — 전자는 씬에 **존재하는** 총량(컬링 무관, 예산용),
후자는 그 프레임에 **그린** 양(컬링·LOD·그림자 반영, 병목용). 런타임에 `add_child()` 로 만드는
메시는 기본 모드가 못 세므로 그런 씬은 `--frame` 으로 잰다.
`MultiMesh`·`GridMap`·`CSG`·파티클·`Sprite3D`·`Label3D` 는 세는 법이 각각 다르다 →
[references/mesh-geometry.md §15](references/mesh-geometry.md)

## 프로젝트 내 학습 문서

`docs/godot/` 에는 사람이 읽는 입문 문서가 따로 있다(`에디터 없이 작업.md`, `기본 개념.md`,
`GDScript.md` 등). 이 스킬이 **라리엔 3D 기준 규범**이고 그쪽은 일반 학습용이므로,
**두 곳이 어긋나면 이 스킬이 맞다.**

`에디터 없이 작업.md` §13 은 에디터 없이 4개 플랫폼을 테스트 빌드·설치·릴리즈까지 가져가는
전 과정을 예제(`./app`)로 다룬다. 템플릿 필요 파일 판정은 이 스킬
([export-build.md](references/export-build.md) §2)과 같은 실측 결과로 맞춰져 있다.

## 공식 참조

- 공식 문서(stable = 현재 4.7 브랜치): https://docs.godotengine.org/en/stable/ — 버전 고정이 필요하면 https://docs.godotengine.org/en/4.7/
- 클래스 레퍼런스: https://docs.godotengine.org/en/4.7/classes/
- 엔진 소스: https://github.com/godotengine/godot
- 릴리스: https://github.com/godotengine/godot-builds/releases
- Asset Store: https://store.godotengine.org/

클래스의 정확한 시그니처가 필요하면 추측하지 말고 `hover`로 확인하거나
`https://docs.godotengine.org/en/4.7/classes/class_<소문자클래스명>.html`을 조회한다.

### 이 폴더의 나머지 파일들

- `index.html`·`doc.html`·`isometric.html`·`node-structure.html`·`site/`·`.nojekyll` — **사람이 브라우저로 보는 문서 사이트**(GitHub Pages 용)다. 스킬 동작에는 관여하지 않으며 에이전트는 `SKILL.md`·`references/` 를 읽는다.
- `.claude-plugin/plugin.json` + `commands/godot-example.md` — 이 폴더가 **스킬이면서 플러그인**으로도 등록되어 세션 스킬 목록에 `godot-example` 과 `godot:godot-example` 이 둘 다 보인다. **정본은 `commands/godot-example.md` 하나**이고 둘은 같은 파일이다. 구조는 사람이 정한다.
- 이 스킬은 **git 서브모듈**(`github.com/thruthesky/godot`)이다 — 문서를 고치면 서브모듈 안에서 커밋하고, 부모 저장소의 포인터도 함께 갱신한다.
