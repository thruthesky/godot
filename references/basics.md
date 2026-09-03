# Godot 기본 — 엔진을 이해하는 첫 문서

> **이 문서로 오는 상황** — Godot 을 처음 배울 때의 **색인** — 본문은 `basics/00~10`. 설치·프로젝트 생성이 아직이면 [getting-started.md](getting-started.md)

**Godot 을 처음 배울 때 알아야 할 구조**를 다룬다. 다른 참조 문서가 "어떻게 하는가"를
담는다면 이 문서는 **"Godot 이 왜 이렇게 생겼는가"**를 담는다.

문법은 [gdscript.md](gdscript.md), 노드 API 상세는 [nodes-scenes.md](nodes-scenes.md),
용어 뜻은 [dictionary.md](dictionary.md) 로 간다. 여기서는 **개념의 뼈대**만 세운다.

동작은 **엔진에서 직접 실행해 확인한 것**이며 기준은 **4.7.2.stable** 이다.

---

## 🗂 이 문서는 색인이다 — 내용은 `basics/` 아래 11개 파트에 있다

한 파일이 5,000줄에 가까워져 **파트별로 나눴다.** 이 문서에는 **어디에 무엇이 있는지**만
있고, **본문은 전부 [`basics/`](basics/) 폴더의 파트 파일에 있다.**

**순서대로 읽어도 되고, 필요한 파트만 열어도 된다.** 각 파트 맨 위에 이전·다음 파트
링크가 있다.

**분리 규칙** — 메인 문서(이 색인)는 서브 문서(파트)마다 100~120단어 요약을 담는다(skill-creator 의
 reference 분리 규칙). 파트 본문을 고치면 아래 요약·줄 수·소제목 목록도 함께 갱신한다.

(줄 수는 표시 줄 기준 — 마지막 줄에 개행이 없으면 `wc -l` 이 1 작게 나온다)

| # | 파트 | 다루는 것 | 줄 |
|---|---|---|---|
| **0** | **[무엇부터 공부해야 하나](basics/00-study-list.md)** | 6단계 체크리스트 — 엔진 구조부터 캐릭터 애니메이션까지 | 91 |
| **1** | **[Godot 의 세계관](basics/01-world.md)** | 노드 → 씬 → 씬 속의 씬. 씬 트리·충돌·인스펙터 상속 사슬·리소스 | 1,011 |
| **2** | **[씬 — 파일인가 객체인가](basics/02-scene.md)** | 같은 "씬"이 가리키는 세 가지와 루트 노드 · 새 씬의 루트 타입 고르기 | 230 |
| **3** | **[인스턴싱](basics/03-instancing.md)** | 설계도로 실체를 찍어낸다. load → instantiate → add_child 4단계 | 322 |
| **4** | **[스크립트](basics/04-script.md)** | 노드에 붙는 것. GDScript 기초 문법·들여쓰기·`:=`·어노테이션·`@tool` | 701 |
| **5** | **[시그널](basics/05-signal.md)** | 노드끼리 대화하는 방법. 연결이 `.tscn` 에 저장되는 함정 | 307 |
| **6** | **[에디터 화면](basics/06-editor-screen.md)** | 4개 독의 역할·단축키·`res://`·FileSystem 에서 파일 숨기기 | 274 |
| **7** | **[에디터 조작을 손에 맞춘다](basics/07-editor-input.md)** | 궤도 회전과 프리룩·3버튼 없는 마우스·왼손 사용자 리바인딩 | 210 |
| **8** | **[동영상 강좌](basics/08-video.md)** | 손으로 한 번 따라 만들어 보는 강좌 4개 | 147 |
| **9** | **[실전 — 캐릭터 컨트롤러](basics/09-controller.md)** | 3D 컨트롤러 전체 코드를 한 줄씩. 좌표 규약·중력·`transform.basis` | 1,097 |
| **10** | **[캐릭터 애니메이션](basics/10-animation.md)** | `.glb` 애니메이션이 도는 원리. 화살표 키만 눌렀는데 왜 걷는가 | 893 |
| | | **합계** | **5,215** |

> 💡 **처음 배우는 사람은 0 → 1 → 2 → 3 → 4 순서로 읽는다.**
> 5~8 은 필요할 때 찾아보면 되고, **9·10 은 앞을 읽은 뒤에 본다** —
> 앞 파트의 개념을 전제로 코드를 한 줄씩 뜯는 실전 파트다.

---

## 📑 파트별 요약과 상세 목차

파트마다 **100~120단어 요약**(누가·무엇을·어떻게·왜)과 소제목 목록을 둔다 — 파트를 열기 전에 **그 파트에 답이 있는지** 여기서 판단한다.
(요약은 파트 본문에 적힌 것만 담았고, 실측값은 파트의 표기를 그대로 옮겼다. 2026-09-03)

### 0. [무엇부터 공부해야 하나](basics/00-study-list.md)

`references/basics/00-study-list.md` · **91줄** · 소제목 6개

6단계 체크리스트 — 엔진 구조부터 캐릭터 애니메이션까지.

Godot 으로 게임을 만들려는 초보 독자에게 최소한 알아야 할 항목을 체크리스트로 준 파트다. 각 항목은 코드를 베껴 쓸 수 있는가가 아니라 "설명할 수 있는가"로 판단한다. 1단계 엔진 구조는 노드·씬·루트 노드·리소스·몸·모양·그림 세트·인스턴싱·`preload` 와 `load`·`Save Branch as Scene...`·생명주기·`pass`·시그널·에디터 4개 독을 묶고, 2단계 GDScript 문법, 3단계 3D 기초, 4단계 움직임과 충돌, 5단계 CSG 로 만들어 보기, 6단계 `.glb` 애니메이션(자동 재생되지 않는다)으로 이어진다. 각 단계는 `gdscript.md`·`3d-core.md`·`physics-3d.md`·`level-design.md` 등 해당 문서로 연결된다. 순서대로 다 읽고 시작할 필요는 없으며 1단계만 이해하면 만들기 시작해도 되고, 막히는 곳에서 해당 단계를 펴 보는 편이 실제로는 더 빠르다고 적는다. Magic Mouse 나 왼손 마우스라면 [파트 7](basics/07-editor-input.md) 을, 손으로 먼저 익히려면 [파트 8](basics/08-video.md) 동영상 강좌를 먼저 보라고 안내한다.

> - 1단계 — 엔진 구조 (파트 1~5 — 01-world · 02-scene · 03-instancing · 04-script · 05-signal)
> - 2단계 — GDScript 문법 (gdscript.md)
> - 3단계 — 3D 기초 (3d-core.md)
> - 4단계 — 움직임과 충돌 (physics-3d.md)
> - 5단계 — 만들어 보기 (level-design.md)
> - 6단계 — 캐릭터를 살아 움직이게 (파트 10)

### 1. [Godot 의 세계관](basics/01-world.md)

`references/basics/01-world.md` · **1,011줄** · 소제목 8개

노드 → 씬 → 씬 속의 씬. 씬 트리·충돌·인스펙터 상속 사슬·리소스.

왕초보에게 "모든 것은 노드, 노드 묶음이 씬, 씬은 다른 씬의 부품" 세 문장으로 엔진 구조를 설명하는 파트다. 씬 트리는 좌표 상속·삭제·`_ready()` 순서를 정하지만 충돌은 정하지 않고 물리 공간과 `collision_layer`·`collision_mask` 가 정한다는 것을, 트리 세 위치에서 낙하시킨 실측(낙하 후 `y` 가 모두 `1.00`, `is_on_floor()` `true`)으로 보인다. 반면 `CollisionShape3D` 는 직속 부모에만 붙어, 중간에 `Node3D` 가 끼면 등록 shape 이 0개라 `-18.09` 까지 뚫고 떨어진다. 인스펙터는 상속 사슬을 세로로 펼친 것이고(`Node3D` 자손 120개), 노드 참조는 `@export` 로 해야 이름·위치 변경에 버티며, 바닥 위 평면은 z-fighting 때문에 `0.05` 띄우고, 노드와 리소스는 다르다는 것을 다룬다. 끝으로 몸·모양·그림이 한 세트임을 설명하고, `CharacterBody3D` 에 `MeshInstance3D`·`CollisionShape3D`·`Camera3D` 를 붙여 플레이어를 조립하되 캡슐 원점이 중앙이라 `position.y = 1` 로 올린다는 함정을 짚는다.

> - 노드란 무엇인가
> - 씬 트리가 정하는 것과 정하지 않는 것
> - 인스펙터는 상속 사슬을 그대로 세로로 펼친 것이다
> - 다른 노드를 가리키는 세 가지 방법 — @export 를 쓴다
> - 같은 높이에 두 면을 겹치지 않는다 — z-fighting
> - 노드와 리소스는 다르다
> - 3D 게임에서 실제로 만나는 노드들 — 몸 · 모양 · 그림
> - 해 보기 — 플레이어 캐릭터를 만든다 (노드 4개)

### 2. [씬 — 파일인가 객체인가](basics/02-scene.md)

`references/basics/02-scene.md` · **230줄** · 소제목 1개

같은 "씬"이 가리키는 세 가지와 루트 노드.

같은 "씬"이라는 말이 셋을 가리켜 계속 막히는 초보에게 씬 파일(`.tscn` 텍스트 설계도)·씬 인스턴스(메모리의 실체)·`SceneTree`(실행 중인 활성 트리)를 갈라 주는 파트다. Scene 독 맨 위의 `Demo` 는 씬이 아니라 루트 노드 하나이고, 씬은 `Demo` 와 그 아래 전부를 묶은 것이라는 점을 4.7.2 바이너리의 UI 문자열(`Create Root Node:`·`Make Scene Root`)로 뒷받침한다. 진짜 함정은 `root` 라는 말이 둘이라는 것으로, `get_tree().root` 는 엔진이 얹은 `Window` 이고 내 씬의 루트 노드는 `get_tree().current_scene` 이다. 루트 노드만 `owner` 가 `null` 이고 `.tscn` 에 `parent=` 가 없으며 `scene_file_path` 가 `res://demo.tscn` 이라는 실측을 표로 보이고, `instantiate()` 가 돌려주는 것도 루트 노드라 씬의 타입은 루트 노드 타입이 정하므로 씬을 만들 때 루트 타입을 먼저 정해야 한다고 결론짓는다. 마지막 절은 **그래서 새 씬을 만들 때 실제로 무엇을 누르는가** — `Scene > New Scene` 이 띄우는 **`Create Root Node:`** 패널의 네 항목(`2D Scene`·`3D Scene`·`User Interface`·**`Other Node`**, 4.7.2 실측)에서 **앞의 셋은 한 타입 고정 바로가기이고 `Other Node` 만 `Create Node` 대화상자를 열어 모든 노드 타입을 검색하게 한다**(`Favorites:`·`Recent:`·`Matches:`). 🛑 **3D 게임이라고 늘 `3D Scene` 이 답은 아니다** — `Node3D` 에는 이동 기능이 없어 **움직이는 캐릭터는 `Other Node` 로 `CharacterBody3D` 를 골라야** `velocity`·`move_and_slide()`·`is_on_floor()` 를 물려받는다. 흔히 듣는 *"루트 타입은 나중에 못 바꾼다"* 는 **사실이 아니다** — 우클릭 **`Change Type...`** 이 있다(에디터 액션 `scene_tree/change_node_type`, 4.7.2 확인). 다만 새 타입에 없는 속성이 버려지고 스크립트 `extends`·그 씬을 쓰던 곳을 직접 확인해야 하므로 **"못 바꾼다"가 아니라 "바꾸면 손이 간다"** 가 정확한 이유다.

> - 트리 맨 위의 그것은 "씬"이 아니라 루트 노드다
> - 　새 씬을 만들 때 무엇을 고르나 — `Create Root Node:` 패널

### 3. [인스턴싱](basics/03-instancing.md)

`references/basics/03-instancing.md` · **322줄** · 소제목 8개

설계도로 실체를 찍어낸다. load → instantiate → add_child 4단계.

씬 하나를 만들어 두고 총알처럼 반복해서 찍어내려는 초보에게 인스턴싱을 설명하는 파트다. 에디터에서는 `Instantiate Child Scene`(Cmd+Shift+A)으로, 코드에서는 `load()` 로 `PackedScene` 을 얻고 `instantiate()` 로 노드를 만든 뒤 `add_child()` 로 트리에 넣는 4단계로 나누어 "메모리에 올린다"가 단계마다 다른 뜻임을 짚는다. 4.7.2 실측으로 `instantiate` 직후 `is_inside_tree = false`, `add_child` 안에서 `_ready` 가 즉시 불리고, `preload` 와 `load` 가 같은 캐시 객체를 준다는 것을 보이므로 `global_position` 은 `add_child()` 뒤에 준다. 후반은 반대 방향인 `Save Branch as Scene...` 으로, 실행 후 `.tscn` 에서 자식 정의가 사라지고 `instance=ExtResource(...)` 한 줄만 남는 것, `Reset Position` 이 기본 켜짐인 것, 루트 노드나 이미 인스턴스인 노드를 고르면 거부되는 메시지, 여러 노드를 떼려면 부모 `Node` 를 먼저 만들어야 한다는 실무 함정을 다룬다.

> - 왜 필요한가
> - 방법 1 — 에디터에서
> - 방법 2 — 코드에서
> - "메모리에 올린다"가 무슨 뜻인가 — 4단계
> - 한 장으로 보는 4단계
> - 엔진에서 확인한 실제 동작 (4.7.2)
> - preload 와 load 의 차이
> - 반대 방향 — Save Branch as Scene... (만들어 놓은 묶음을 씬으로 떼어낸다)

### 4. [스크립트](basics/04-script.md)

`references/basics/04-script.md` · **701줄** · 소제목 5개

노드에 붙는 것. GDScript 기초 문법·들여쓰기·:=·어노테이션·@tool.

스크립트를 처음 붙이는 왕초보에게, 스크립트는 노드에 붙어야 돌고 `extends` 가 물려받을 기능을 정한다고 시작하는 파트다. 문법은 엔진에 넣어 돌려 본 결과로 보인다 — 블록은 들여쓰기로만 정해지고 탭과 스페이스를 섞으면 오류가 나며, `:=` 는 타입을 고정해 `Parse Error: Cannot assign a value of type "String" as "int".` 처럼 실행 전에 잡고, 어노테이션은 엔진이 준 37개 중 고르기만 하며, `@tool` 은 `Engine.is_editor_hint()` 로 갈라야 한다. `velocity` 는 속도일 뿐이고 `move_and_slide()` 가 없으면 `position.z` 가 `0.000` 그대로라는 실측으로 값을 바꾸는 것과 실제로 일어나는 것을 가른다. 생명주기 순서, 인스턴싱되지 않은 씬은 `_ready()` 가 불리지 않는다는 것, macOS 실행 단축키 Cmd+B·Cmd+R, `pass` 는 `return` 과 달리 함수를 끝내지 않는다는 것으로 마친다.

> - GDScript 문법의 기초 — 왕초보가 가장 먼저 막히는 것들
> - 값을 바꾸는 것과 실제로 일어나는 것은 다르다
> - 생명주기 — 언제 불리는가
> - _ready() 가 실행되지 않는다 — 파일이 있다고 실행되는 게 아니다
> - pass 는 무엇인가 — 스크립트를 붙이면 처음 보게 되는 것

### 5. [시그널](basics/05-signal.md)

`references/basics/05-signal.md` · **307줄** · 소제목 11개

노드끼리 대화하는 방법. 연결이 .tscn 에 저장되는 함정.

적이 죽을 때 UI·사운드·스포너를 직접 호출하다 씬 구조에 묶인 초보에게, 알리는 쪽이 받는 쪽을 모르는 시그널(관찰자 패턴)을 설명하는 파트다. 내장 시그널과 `signal` 로 선언한 커스텀 시그널은 쓰는 법이 같고, 4.7.2 에서 `BaseButton` 에 시그널 33개가 달려 있음을 `ClassDB` 로 센다. Godot 4 에서 시그널은 문자열이 아니라 `Signal` 값이라 `hit.emit(10)`·`hit.connect(_on_hit)` 처럼 점을 찍고 오타가 그 자리에서 잡힌다. 에디터의 Signals 탭으로 연결하면 `.tscn` 의 `[connection]` 줄에 저장되어 스크립트만 봐서는 보이지 않는다는 함정과, 받는 함수의 공식 명칭이 Receiver Method 라는 점을 짚는다. 실측으로 연결한 순서대로 호출되고, 듣는 쪽이 없어도 오류가 아니며, 같은 함수를 두 번 연결하면 `31`(`ERR_INVALID_PARAMETER`)로 거부되므로 `is_connected()` 로 방어한다. `await` 와 "통지는 위로, 명령은 아래로" 방향 규칙으로 마친다.

> - 왜 필요한가 — 직접 호출과 비교
> - 시그널의 두 종류
> - 선언 — signal 키워드
> - 🔑 Godot 4 에서 시그널은 "값"이다
> - 발신 — emit()
> - 받기 — connect()
> - 이 함수를 뭐라고 부르는가
> - 실제 동작 — 엔진에서 확인한 것 (4.7.2)
> - await — 시그널이 올 때까지 기다리기
> - 방향 규칙 — 통지는 위로, 명령은 아래로
> - 더 깊이

### 6. [에디터 화면](basics/06-editor-screen.md)

`references/basics/06-editor-screen.md` · **274줄** · 소제목 3개

4개 독의 역할·단축키·res://·FileSystem 에서 파일 숨기기.

Godot 에디터를 처음 여는 입문자에게 화면의 뼈대를 세워 주는 파트다. 상단 `2D`·`3D`·`Script`·`AssetLib` 모드 전환 아래 `Scene`·`Inspector`·`FileSystem`·`Output` 독이 각각 무엇을 하는지와 `Cmd+A` 같은 단축키, `res://`와 `user://`의 뜻을 표로 정리한다. 3D 뷰포트 툴바의 압정 `Preserve Children Transform`(단축키 `P`)이 켜져 있으면 부모를 옮겨도 자식이 제자리에 남아 캐릭터가 늘어난 것처럼 보이므로 이것부터 확인하라고 경고한다. 새 프로젝트에 생기는 `.editorconfig`·`.gitattributes`·`.gitignore`는 외부 도구용이며, 4.7.2 확인 결과 내장 스크립트 에디터는 `.editorconfig`를 읽지 않는다. FileSystem 독에서 숨기려면 폴더는 빈 `.gdignore`(내용 무관, `.godotignore`는 무시됨), 파일은 `Editor > Editor Settings`에서 `Advanced Settings`를 켜고 `Textfile Extensions`의 `md`를 빼는 에디터 전역 설정을 쓰며, 제외된 것은 `res://`로 로드할 수 없음을 엔진 소스로 보인다. 라리엔에서는 `game-assets/`·`game-server/`에 `.gdignore`를 두고 `CLAUDE.md`는 `md`를 빼서 감춘다.

> - 3D 뷰포트 위의 툴바 — 파란 압정을 조심한다
> - 새 프로젝트를 만들면 이미 들어 있는 파일들
> - FileSystem 독에서 파일·폴더를 숨긴다

### 7. [에디터 조작을 손에 맞춘다](basics/07-editor-input.md)

`references/basics/07-editor-input.md` · **210줄** · 소제목 6개

궤도 회전과 프리룩·3버튼 없는 마우스·왼손 사용자 리바인딩.

오른손·3버튼 마우스 전제에서 벗어난 사람, 곧 Magic Mouse 사용자와 왼손잡이, macOS 사용자를 위한 파트다. 먼저 한 점을 중심으로 도는 궤도 회전과 제자리에서 방향만 바꾸는 프리룩, 평행 이동인 팬을 구분한 뒤, 궤도 회전과 팬이 가운데 버튼에 묶여 있어 Magic Mouse에서는 아예 동작하지 않는다는 점을 짚는다. 해법은 `Editor > Editor Settings > Editors > 3D > Navigation`에서 `Emulate 3 Button Mouse`를 켜고 `Navigation Scheme`을 Maya로 두는 것이며, 4.7.2에 `orbit_mouse_button` 등 다섯 설정 키가 실제로 있음을 확인했다. 프리룩 `WASD`는 `Shortcuts` 탭에서 `freelook`을 검색해 기존 키를 지우고 `IJKL`로 교체하고, macOS는 보조 클릭을 켜야 우클릭으로 프리룩에 들어간다. 에디터 설정은 게임 조작과 무관하므로 게임은 `InputMap` 액션과 `physical_keycode`로 정의하고 `InputMap.action_add_event()` 같은 리바인딩 API를 쓴다.

> - 먼저 용어 — 궤도 회전과 프리룩은 다르다
> - 3D 뷰포트의 기본 조작
> - 🖱 가운데 버튼이 없는 마우스 — Magic Mouse 등
> - ⌨ 프리룩 키를 왼손잡이에 맞춘다
> - macOS 에서 먼저 확인할 것
> - 게임 안의 조작은 별개다 — InputMap

### 8. [동영상 강좌](basics/08-video.md)

`references/basics/08-video.md` · **147줄** · 소제목 4개

손으로 한 번 따라 만들어 보는 강좌 4개.

개념을 손으로 한 번 따라 만들어 보고 싶은 입문자에게 강좌 넷을 골라 주는 파트다. ① Visual Coding Hub의 3시간 라이브 트레이닝은 비주얼 에디터만으로 첫 게임까지 가며 이 색인의 파트 1~7 과 거의 겹치고, ② GodotwithMe의 3D House 시리즈는 안드로이드 편집기로 바닥·카메라·조명·하늘과 CSG 문·창문을 만드는 3분대 영상이며, ③ 3D Beginner 재생목록은 에셋 임포트와 잔디·물·하늘을 거쳐 워킹 시뮬레이터를 완성하고, ④ CSG로 도로를 깔고 Blender에서 Shrinkwrap으로 지형을 만들어 재임포트하는 영상은 라리엔 3D와 가장 가까워 타임스탬프까지 적어 둔다. 강좌마다 어느 절과 맞닿는지 표로 잇되, 카메라 각도·조명·성능 예산은 SSOT가 최종 권위이고 스크립팅은 GDScript로 결정되어 있으며 3GB RAM 안드로이드 예산을 넘는 지형 물량은 따라가지 않는다고 못 박는다. 강좌는 엔진 조작을 익히는 용도로만 본다.

> - ① 3시간 만에 첫 게임 — 비주얼 에디터만으로
> - ② 모바일에서 만든다면 — 안드로이드 편집기로 집 짓기
> - ③ 3D 워킹 시뮬레이터 — 에셋 임포트부터 잔디·물·하늘까지
> - ④ CSG 로 도로를 깔고 Blender 로 지형을 만든다

### 9. [실전 — 캐릭터 컨트롤러](basics/09-controller.md)

`references/basics/09-controller.md` · **1,097줄** · 소제목 17개

3D 컨트롤러 전체 코드를 한 줄씩. 좌표 규약·중력·transform.basis.

노드·씬·인스턴싱·스크립트를 따로 익힌 초보자에게, Godot이 `CharacterBody3D`에 기본 템플릿으로 주는 3D 캐릭터 컨트롤러를 한 줄씩 읽히는 파트다. 코드보다 씬 구조를 먼저 보여 `MeshInstance3D`와 `CollisionShape3D`가 별개이고 스크립트가 `pc.tscn`이 아니라 `world.tscn`의 인스턴스에 붙어 있음을 짚은 뒤, 1단위=1m, −Z가 앞, 회전은 라디안이라는 좌표 규약을 못 박는다. 이어 `@export`, `@onready`와 `$`, 입력 콜백 다섯의 순서와 `_unhandled_input()`, 요는 몸통·피치는 카메라로 나눠 돌리고 `clamp()`로 자르는 이유, `_physics_process()`에 이동을 두는 이유, 땅에서 중력을 누적하면 바닥을 뚫는 함정, `Input.get_vector()`가 대각선 √2 문제를 없애는 것, `most_left` 오타, `transform.basis` 곱셈, 인자 없는 `move_and_slide()`, 마우스 캡처를 풀어낸다. 라리엔은 카메라 3축을 고정하므로 시점 회전은 참고만 하고 몸을 움직이는 법만 가져간다. 증상으로 원인을 찾는 표와 값을 바꿔 보는 실습 표로 마무리한다.

> - 9.1 먼저 씬 구조를 본다 — 코드보다 이게 먼저다
> - 9.2 extends CharacterBody3D — 어떤 "몸"을 고를 것인가
> - 9.3 Godot 의 3D 좌표 규약 — 왕초보가 가장 먼저 넘어지는 곳
> - 9.4 전체 코드
> - 9.5 @export — 코드를 고치지 않고 값을 바꾼다
> - 9.6 @onready 와 $ — 자식 노드를 붙잡는 두 도구
> - 9.7 입력 함수 4형제 — 어느 것을 언제 쓰나
> - 9.8 시점 회전 — 왜 몸통과 카메라를 나눠서 돌리나
> - 9.9 _physics_process() — 이동은 반드시 여기에 쓴다
> - 9.10 중력과 점프
> - 9.11 이동 입력 — Input.get_vector() 와 InputMap
> - 9.12 transform.basis — 이 스크립트에서 가장 어려운 한 줄
> - 9.13 속도를 정하고 실제로 움직인다
> - 9.14 마우스 캡처 — 편리하지만 위험한 한 줄
> - 9.15 이 예제가 3인칭인 이유와 1인칭으로 바꾸는 법
> - 9.16 자주 넘어지는 곳 — 증상으로 찾는 표
> - 9.17 직접 해 볼 것

### 10. [캐릭터 애니메이션](basics/10-animation.md)

`references/basics/10-animation.md` · **893줄** · 소제목 11개

.glb 애니메이션이 도는 원리. 화살표 키만 눌렀는데 왜 걷는가.

캡슐 대신 사람형 모델을 넣고 "키만 눌렀는데 왜 걷는가"를 묻는 사람에게 `.glb` 안쪽부터 화면까지 따라가는 파트다. 애니메이션은 그림이 아니라 뼈의 시간별 자세표이고, 캐릭터를 이동시키지 않으며, 엔진이 자동으로 고르지 않는다는 오해 셋을 먼저 지운다. `glb_peek.py`로 파일 안의 `idle`·`walk`·`run`·`attack`·`death`·`RESET`을 찍고, 임포트되면 `PackedScene`이 되어 `AnimationPlayer`·`Skeleton3D`·`MeshInstance3D`로 번역됨을 4.7.2 실측으로 보인다. 본 이름 `mixamorig:Hips`의 `:`가 `_`로 바뀌고, `remove_immutable_tracks` 기본값이 트랙을 66개에서 23개로 65% 버리며, `loop_mode` 기본이 0이라 idle이 2.03초에 얼어붙고, 임포트된 애니는 "Animation is read-only."로 편집이 막힌다. 그래서 `_ready()`에서 `LOOP_LINEAR`·`PHYSICS` 콜백·`animation_finished`를 설정하고, `_physics_process()`의 `if` 한 줄이 이동과 `_play()`를 잇는다. `play()`는 되감지 않으므로 `stop()`이 필요하고, 루트는 1mm도 움직이지 않아 foot sliding이 생기며, 막히면 추측하지 말고 `get_animation_list()`로 찍어 보고, 부족하면 `AnimationTree`로 간다.

> - 10.0 시작하기 전에 — 오해 세 가지를 먼저 지운다
> - 10.1 애니메이션은 .glb 파일 안에 들어 있다
> - 10.2 애니메이션 데이터의 실체 — "뼈의 시간별 자세표"
> - 10.3 Godot 이 .glb 를 씬으로 바꿔 준다
> - 10.4 코드가 AnimationPlayer 를 잡는다
> - 10.5 🛑 자동으로 재생되는 것이 아니다 — 코드가 매 프레임 고른다
> - 10.6 🛑 애니메이션은 캐릭터를 이동시키지 않는다
> - 10.7 전체 흐름 한 장
> - 10.8 직접 확인해 보는 법
> - 10.9 자주 막히는 곳
> - 10.10 여기서 부족해지면 — AnimationTree 로 간다

---

## 다음에 무엇을 읽나

| 하고 싶은 것 | 문서 |
|---|---|
| 용어 뜻만 빠르게 | [dictionary.md](dictionary.md) |
| GDScript 문법 | [gdscript.md](gdscript.md) |
| 노드·씬 깊이 있게 (참조·시그널·오토로드·풀링) | [nodes-scenes.md](nodes-scenes.md) |
| 3D 좌표·회전·카메라 | [3d-core.md](3d-core.md) |
| 캐릭터를 움직이고 부딪히게 | **[파트 9](basics/09-controller.md)** · [physics-3d.md](physics-3d.md) |
| **캐릭터에 걷기·공격 동작을 붙이기** | **[파트 10](basics/10-animation.md)** · [animation-3d.md](animation-3d.md) |
| 맵 만들기 | [level-design.md](level-design.md) |
| 에디터 없이 터미널로 작업 | [headless-workflow.md](headless-workflow.md) |
| 빈 프로젝트에서 캐릭터가 움직이기까지 손으로 만들어 보기 | [example.md](example.md) |

**막히면 추측하지 말고 확인한다.** 이 스킬의 문서들은 전부 그렇게 쓰였다.

```bash
godot --version                           # 엔진 버전
godot --headless --doctool /tmp/gddoc      # 클래스 정의 XML 전체 (기본값·시그니처 확인)
python3 .claude/skills/godot/scripts/gdscript_lsp.py hover res://a.gd 42 10   # 이 변수의 타입
```
