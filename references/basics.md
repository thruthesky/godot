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

(줄 수는 표시 줄 기준 — 마지막 줄에 개행이 없으면 `wc -l` 이 1 작게 나온다)

| # | 파트 | 다루는 것 | 줄 |
|---|---|---|---|
| **0** | **[무엇부터 공부해야 하나](basics/00-study-list.md)** | 6단계 체크리스트 — 엔진 구조부터 캐릭터 애니메이션까지 | 81 |
| **1** | **[Godot 의 세계관](basics/01-world.md)** | 노드 → 씬 → 씬 속의 씬. 씬 트리·충돌·인스펙터 상속 사슬·리소스 | 984 |
| **2** | **[씬 — 파일인가 객체인가](basics/02-scene.md)** | 같은 "씬"이 가리키는 세 가지와 루트 노드 | 142 |
| **3** | **[인스턴싱](basics/03-instancing.md)** | 설계도로 실체를 찍어낸다. load → instantiate → add_child 4단계 | 304 |
| **4** | **[스크립트](basics/04-script.md)** | 노드에 붙는 것. GDScript 기초 문법·들여쓰기·`:=`·어노테이션·`@tool` | 677 |
| **5** | **[시그널](basics/05-signal.md)** | 노드끼리 대화하는 방법. 연결이 `.tscn` 에 저장되는 함정 | 279 |
| **6** | **[에디터 화면](basics/06-editor-screen.md)** | 4개 독의 역할·단축키·`res://`·FileSystem 에서 파일 숨기기 | 253 |
| **7** | **[에디터 조작을 손에 맞춘다](basics/07-editor-input.md)** | 궤도 회전과 프리룩·3버튼 없는 마우스·왼손 사용자 리바인딩 | 187 |
| **8** | **[동영상 강좌](basics/08-video.md)** | 손으로 한 번 따라 만들어 보는 강좌 4개 | 128 |
| **9** | **[실전 — 캐릭터 컨트롤러](basics/09-controller.md)** | 3D 컨트롤러 전체 코드를 한 줄씩. 좌표 규약·중력·`transform.basis` | 1,055 |
| **10** | **[캐릭터 애니메이션](basics/10-animation.md)** | `.glb` 애니메이션이 도는 원리. 화살표 키만 눌렀는데 왜 걷는가 | 863 |
| | | **합계** | **4,953** |

> 💡 **처음 배우는 사람은 0 → 1 → 2 → 3 → 4 순서로 읽는다.**
> 5~8 은 필요할 때 찾아보면 되고, **9·10 은 앞을 읽은 뒤에 본다** —
> 앞 파트의 개념을 전제로 코드를 한 줄씩 뜯는 실전 파트다.

---

## 📑 파트별 상세 목차

### 0. [무엇부터 공부해야 하나](basics/00-study-list.md)

`references/basics/00-study-list.md` · **81줄** · 소제목 6개

6단계 체크리스트 — 엔진 구조부터 캐릭터 애니메이션까지.

> - 1단계 — 엔진 구조 (이 문서 §1~§5)
> - 2단계 — GDScript 문법 ([gdscript.md](gdscript.md))
> - 3단계 — 3D 기초 ([3d-core.md](3d-core.md))
> - 4단계 — 움직임과 충돌 ([physics-3d.md](physics-3d.md))
> - 5단계 — 만들어 보기 ([level-design.md](level-design.md))
> - 6단계 — 캐릭터를 살아 움직이게 (이 문서 §10)

### 1. [Godot 의 세계관](basics/01-world.md)

`references/basics/01-world.md` · **984줄** · 소제목 8개

노드 → 씬 → 씬 속의 씬. 씬 트리·충돌·인스펙터 상속 사슬·리소스.

> - 노드란 무엇인가
> - 씬 트리가 정하는 것과 정하지 않는 것
> - 인스펙터는 상속 사슬을 그대로 세로로 펼친 것이다
> - 다른 노드를 가리키는 세 가지 방법 — @export 를 쓴다
> - 같은 높이에 두 면을 겹치지 않는다 — z-fighting
> - 노드와 리소스는 다르다
> - 3D 게임에서 실제로 만나는 노드들 — 몸 · 모양 · 그림
> - 해 보기 — 플레이어 캐릭터를 만든다 (노드 4개)

### 2. [씬 — 파일인가 객체인가](basics/02-scene.md)

`references/basics/02-scene.md` · **142줄** · 소제목 1개

같은 "씬"이 가리키는 세 가지와 루트 노드.

> - 트리 맨 위의 그것은 "씬"이 아니라 루트 노드다

### 3. [인스턴싱](basics/03-instancing.md)

`references/basics/03-instancing.md` · **304줄** · 소제목 8개

설계도로 실체를 찍어낸다. load → instantiate → add_child 4단계.

> - 왜 필요한가
> - 방법 1 — 에디터에서
> - 방법 2 — 코드에서
> - "메모리에 올린다"가 무슨 뜻인가 — 4단계
> - 한 장으로 보는 4단계
> - 엔진에서 확인한 실제 동작 (4.7.2)
> - preload 와 load 의 차이
> - 반대 방향 — Save Branch as Scene... (만들어 놓은 묶음을 씬으로 떼어낸다)

### 4. [스크립트](basics/04-script.md)

`references/basics/04-script.md` · **677줄** · 소제목 5개

노드에 붙는 것. GDScript 기초 문법·들여쓰기·`:=`·어노테이션·`@tool`.

> - GDScript 문법의 기초 — 왕초보가 가장 먼저 막히는 것들
> - 값을 바꾸는 것과 실제로 일어나는 것은 다르다
> - 생명주기 — 언제 불리는가
> - _ready() 가 실행되지 않는다 — 파일이 있다고 실행되는 게 아니다
> - pass 는 무엇인가 — 스크립트를 붙이면 처음 보게 되는 것

### 5. [시그널](basics/05-signal.md)

`references/basics/05-signal.md` · **279줄** · 소제목 11개

노드끼리 대화하는 방법. 연결이 `.tscn` 에 저장되는 함정.

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

`references/basics/06-editor-screen.md` · **253줄** · 소제목 3개

4개 독의 역할·단축키·`res://`·FileSystem 에서 파일 숨기기.

> - 3D 뷰포트 위의 툴바 — 파란 압정을 조심한다
> - 새 프로젝트를 만들면 이미 들어 있는 파일들
> - FileSystem 독에서 파일·폴더를 숨긴다

### 7. [에디터 조작을 손에 맞춘다](basics/07-editor-input.md)

`references/basics/07-editor-input.md` · **187줄** · 소제목 6개

궤도 회전과 프리룩·3버튼 없는 마우스·왼손 사용자 리바인딩.

> - 먼저 용어 — 궤도 회전과 프리룩은 다르다
> - 3D 뷰포트의 기본 조작
> - 🖱 가운데 버튼이 없는 마우스 — Magic Mouse 등
> - ⌨ 프리룩 키를 왼손잡이에 맞춘다
> - macOS 에서 먼저 확인할 것
> - 게임 안의 조작은 별개다 — InputMap

### 8. [동영상 강좌](basics/08-video.md)

`references/basics/08-video.md` · **128줄** · 소제목 4개

손으로 한 번 따라 만들어 보는 강좌 4개.

> - ① 3시간 만에 첫 게임 — 비주얼 에디터만으로
> - ② 모바일에서 만든다면 — 안드로이드 편집기로 집 짓기
> - ③ 3D 워킹 시뮬레이터 — 에셋 임포트부터 잔디·물·하늘까지
> - ④ CSG 로 도로를 깔고 Blender 로 지형을 만든다

### 9. [실전 — 캐릭터 컨트롤러](basics/09-controller.md)

`references/basics/09-controller.md` · **1,055줄** · 소제목 17개

3D 컨트롤러 전체 코드를 한 줄씩. 좌표 규약·중력·`transform.basis`.

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

`references/basics/10-animation.md` · **863줄** · 소제목 11개

`.glb` 애니메이션이 도는 원리. 화살표 키만 눌렀는데 왜 걷는가.

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
