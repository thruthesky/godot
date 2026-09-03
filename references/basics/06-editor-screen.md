# 6. 에디터 화면 — 어디에 무엇이 있나

> **[Godot 기본](../basics.md)** 의 파트 **7 / 11**
> [← 5. 시그널(Signal) — 노드끼리 대화하는 방법](05-signal.md) · [7. 에디터 조작을 내 손에 맞춘다 — 마우스와 단축키 →](07-editor-input.md)

> 📄 **메뉴 항목 하나하나와 각 에디터 뷰의 화면은 별도 문서에 정리되어 있다.**
> → **[Godot 에디터 메뉴·화면 정리 (Google 문서)](https://docs.google.com/document/d/1b9LPX5Lp6AbaSfdsThvtci5HWcj3O3KQ6eFtJFXUvBw/edit?usp=sharing)**
>
> 이 절은 **어디에 무엇이 있는지 뼈대**만 세운다.
> `Scene`·`Project`·`Debug`·`Editor`·`Help` 메뉴 아래에 각각 무엇이 있는지,
> 2D·3D·Script·AssetLib **각 에디터 뷰가 실제로 어떤 화면인지**처럼
> **항목 단위로 찾을 때는 위 문서를 본다.**

```
┌──────────────────────────────────────────────────────────┐
│  [2D] [3D] [Script] [AssetLib]        ▶(실행)            │  ← 상단: 작업 모드 전환
├────────────┬──────────────────────────┬──────────────────┤
│ Scene 독   │                          │  Inspector 독    │
│            │        뷰포트            │                  │
│ 노드 트리  │   (지금 보고 있는 씬)     │  선택한 노드의    │
│ 구조       │                          │  프로퍼티 전부    │
├────────────┤                          │                  │
│ FileSystem │                          │                  │
│ 독         │                          │                  │
│ res:// 안의│                          │                  │
│ 파일 전부  │                          │                  │
├────────────┴──────────────────────────┴──────────────────┤
│  Output / Debugger / Audio  하단 패널                     │  ← print() 결과가 여기
└──────────────────────────────────────────────────────────┘
```

| 독 | 하는 일 | 자주 쓰는 조작 |
|---|---|---|
| **Scene** | 지금 씬의 노드 트리 | **Cmd+A** 자식 노드 추가 / **Cmd+Shift+A** 씬 인스턴싱 / **F2** 이름 변경 / **Cmd+D** 복제 |
| **Inspector** | 선택한 노드의 모든 프로퍼티 | 값 입력, 리소스 연결 |
| **FileSystem** | `res://` 안의 파일 | 드래그로 씬 인스턴싱·리소스 연결 |
| **Output** | `print()` 출력, 오류 | 게임을 돌린 뒤 여기부터 본다 |

`res://` 는 **프로젝트 폴더**를 가리키는 Godot 전용 경로다.
`user://` 는 세이브 파일이 저장되는 **사용자 데이터 폴더**다 (플랫폼마다 실제 위치가 다르다).

## 3D 뷰포트 위의 툴바 — 파란 압정을 조심한다

3D 편집 화면 상단에는 이동·회전·크기 도구가 줄지어 있다. 그중 **압정 모양 버튼이
`Preserve Children Transform`**(자식의 전역 변환 유지, 단축키 <kbd>P</kbd>)이다.
**켜져 있으면 부모를 옮겨도 자식은 화면의 원래 자리에 그대로 남는다.**

| 압정 | 부모를 위로 5m 옮기면 |
|---|---|
| **꺼짐(회색)** — 보통 이 상태 | 자식도 **함께 5m 올라간다.** 자식의 로컬 Position 은 그대로 |
| **켜짐(파랑)** | 자식은 **제자리에 남는다.** 대신 자식의 로컬 Y 가 자동으로 −5 로 바뀐다 |

> 🛑 **캐릭터가 길게 늘어난 것처럼 보이면 이것부터 확인한다.** 부모의 이동 기즈모만
> 위로 올라가고 `MeshInstance3D`·`CollisionShape3D` 는 아래에 남아, 원점과 자식
> 사이가 늘어진 것처럼 보인다.
>
> **고치는 법** — 3D 뷰포트를 클릭해 포커스를 준 뒤 <kbd>P</kbd> 를 누르거나 압정을
> 눌러 회색으로 만든다. 그다음 자식들의 Transform 을 초기화하고 부모 위치를 다시 잡는다.

**쓸 데가 있어서 있는 기능이다** — 자식들의 배치는 건드리지 않고 **부모의 원점(피벗)만
옮길 때**, 또는 계층 구조를 정리할 때 쓴다. 평소에는 꺼 둔다.

> ⚠️ **버튼은 에디터 옵션이지만 결과는 씬에 남는다.** 켠 채로 부모를 옮기면 자식의
> 로컬 Transform 이 실제로 바뀌고, 저장하면 `.tscn` 에 그대로 기록된다.
> 노드에 저장되는 속성인 **`top_level`**(부모의 변환을 아예 상속하지 않음)과는 성격이
> 다르다 — 이쪽은 편집 중에만 작동하는 보정이다.

*(엔진 4.7.2 의 툴팁 원문: "When enabled, transforming a node will preserve the
global transform of its children." 단축키 경로는 `spatial_editor/preserve_children_transform`
이며 [공식 문서](https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html)
에도 <kbd>P</kbd> 로 명시되어 있다.)*

## 새 프로젝트를 만들면 이미 들어 있는 파일들

Godot 이 프로젝트를 만들 때 **자동으로 넣어 주는 파일**이 셋 있다. 씬도 스크립트도
아니라 용도가 잘 안 보이는데, **셋 다 Godot 자신이 아니라 바깥 도구를 위한 것**이다.

| 파일 | 누가 읽나 | 하는 일 |
|---|---|---|
| **`.editorconfig`** | **외부 에디터·IDE** (VS Code 등) | 코드 스타일 규약 — 인코딩·들여쓰기를 통일 |
| `.gitattributes` | git | `* text=auto eol=lf` — 개행을 LF 로 통일해 OS 가 섞여도 diff 가 깨지지 않게 |
| `.gitignore` | git | `.godot/`(임포트 캐시)·`/android/` 를 커밋에서 뺀다 |

**`.editorconfig` 는 [EditorConfig](https://editorconfig.org) 규약을 따르는 파일이다.**
"이 프로젝트의 코드는 이렇게 저장한다"를 적어 두면 **VS Code·Sublime·JetBrains 등
어떤 에디터로 열어도 같은 규칙이 적용된다.** 사람마다 인코딩·들여쓰기가 달라
**고치지도 않은 줄까지 diff 에 뜨는 일**을 막는 것이 목적이다.

Godot 이 넣어 주는 내용은 두 줄뿐이다.

```ini
root = true       # 여기가 최상위 — 상위 폴더의 .editorconfig 를 더 찾지 않는다

[*]               # 모든 파일에 적용 (glob 패턴)
charset = utf-8   # UTF-8 로 저장한다
```

`root = true` 가 필요한 이유는 **EditorConfig 가 파일이 있는 폴더에서 위로 계속
거슬러 올라가며 설정을 찾기 때문**이다. 이 줄이 없으면 홈 디렉터리에 있는 다른 설정까지
끌어온다. `charset = utf-8` 은 **한글 주석이 깨지지 않게** 한다 — Godot 은 `.gd`·`.tscn`
을 UTF-8 로 다루므로 외부 에디터가 다른 인코딩으로 저장하면 글자가 깨진다.

> 🛑 **정작 Godot 내장 스크립트 에디터는 이 파일을 읽지 않는다 — 만들어 주기만 하고
> 자기는 쓰지 않는다.** *(엔진 확인 4.7.2 — 바이너리에 생성 실패 메시지
> `Couldn't create .editorconfig in project path.` 는 있지만, `indent_style`·`end_of_line`
> 같은 EditorConfig 표준 키를 읽는 코드는 없다.)* 내장 에디터의 들여쓰기·인코딩은
> `Editor Settings > Text Editor > Behavior` 가 따로 정한다.
> **즉 이 파일은 순전히 외부 에디터를 위한 배려다.**

## FileSystem 독에서 파일·폴더를 숨긴다

위 표의 `.editorconfig`·`.gitignore` 는 **분명히 프로젝트 폴더에 있는데 FileSystem
독에는 보이지 않는다.** 점(`.`)으로 시작하는 이름이라 에디터가 아예 스캔하지 않기
때문이다. 같은 원리로 **보고 싶지 않은 것을 독에서 치울 수 있다.**

> 🛑 **"가려 준다"가 아니라 "에디터가 없는 것으로 친다"이다.**
> 독에서 사라지는 것은 결과일 뿐이고, 실제로는 **스캔·임포트 대상에서 빠진다.**
> 그래서 제외한 것은 **`res://` 로 로드할 수 없다.** 게임이 실제로 읽어야 하는
> 파일에는 절대 쓰지 않는다.

**수단은 폴더냐 파일이냐에 따라 완전히 다르다.** 하나로 둘 다 처리할 수 없다.

| 대상 | 수단 | 어디에 두나 | 범위 |
|---|---|---|---|
| **폴더** | 빈 **`.gdignore`** 파일 | **숨길 폴더 안에** | 그 프로젝트만 |
| **개별 파일** | 확장자를 **화이트리스트에서 뺀다** | `Editor Settings` | 🛑 **에디터 전역** |
| 개별 파일 (이름을 바꿔도 되면) | 이름을 **`.` 으로 시작**하게 | 그 파일 | 그 파일만 |

### 폴더 — 빈 `.gdignore` 를 폴더 **안에** 넣는다

```bash
touch game-assets/.gdignore     # 폴더 안에. 내용은 비운다
```

🛑 **틀리기 쉬운 두 가지**

| 흔한 착각 | 사실 |
|---|---|
| 이름이 `.godotignore` 다 | **아니다. `.gdignore` 다.** 4.7.2 바이너리에 `.godotignore` 라는 문자열 자체가 없다 (`strings` 확인). 그 이름으로 만들면 **아무 일도 일어나지 않는다** |
| `.gitignore` 처럼 **목록을 적는다** | **아니다.** 엔진은 내용을 읽지 않는다. **파일이 거기 있다는 사실**만 본다. 프로젝트 루트에 하나 두고 경로를 나열하는 방식은 **동작하지 않는다** |

엔진 소스가 그렇게 생겼다.

```cpp
// editor/file_system/editor_file_system.cpp:3502 (4.7)
if (FileAccess::exists(p_path.path_join(".gdignore"))) {
	// Skip if a `.gdignore` file is inside this.
	return true;
}
```

`FileAccess::exists()` — **존재만 검사하고 열지도 않는다.** 실측도 같다.

| 폴더에 넣은 것 | 임포트 |
|---|---|
| 없음 | ✅ 됨 |
| **빈** `.gdignore` | 🚫 제외 |
| 경로를 적은 `.gdignore` | 🚫 제외 (**내용 무관**) |
| 빈 `.godotignore` | ✅ **됨** — 이름이 틀려 무시 |

**하위 폴더까지 통째로** 걸린다. `deep/` 에 하나 넣으면 `deep/sub/deeper/` 까지 사라진다.
위 함수가 `true` 를 내면 `_scan_new_dir()` 이 **그 폴더로 재귀하지 않기** 때문이다.

같은 함수(`_should_skip_directory()`)가 검사하는 조건은 셋이고, 나머지 둘은 **저절로** 걸린다.

| 조건 | 뜻 |
|---|---|
| `.godot/` (프로젝트 데이터 경로) | 임포트 캐시는 항상 제외 |
| 폴더 안에 **`project.godot` 이 있다** | *"Detected another project.godot at %s. The folder will be ignored."* 경고와 함께 제외 |
| **`.gdignore` 가 있다** | 위에서 설명한 것 |

### 개별 파일 — 확장자 화이트리스트가 정한다

`.gdignore` 는 폴더 전용이라 **파일 하나만 골라 숨길 수 없다.** 개별 파일이 독에
뜨느냐 마느냐는 **확장자**가 정한다.

```cpp
// editor/file_system/editor_file_system.cpp:1242
String ext = scan_file.get_extension().to_lower();
if (!valid_extensions.has(ext)) {
	p_progress.increment();
	continue; //invalid
}
```

`valid_extensions` 는 셋을 합친 것이다 — ① 엔진이 리소스로 인식하는 확장자
② `docks/filesystem/textfile_extensions` ③ `docks/filesystem/other_file_extensions`.
뒤의 둘은 **에디터 설정**이고 기본값은 이렇다.

```cpp
// editor/settings/editor_settings.cpp:717 (4.7)
_initial_set("docks/filesystem/textfile_extensions", "txt,md,cfg,ini,log,json,yml,yaml,toml,xml");
_initial_set("docks/filesystem/other_file_extensions", "ico,icns");
```

**`md` 가 여기 있어서 `README.md`·`CLAUDE.md` 같은 문서가 독에 뜬다.** 리소스로
임포트되는 것이 아니라 **에디터에서 열어 볼 수 있게 해 주는 편의 기능**이고,
에디터 캐시에 `TextFile` 로 기록된다.

```
$ cat .godot/editor/filesystem_cache10
CLAUDE.md::TextFile::-1::1787889411::0::1::…
```

**빼는 경로** — `Editor > Editor Settings...` → 우측 상단 **`Advanced Settings` 를 켠다**
→ `Docks > FileSystem` → `Textfile Extensions`

```
txt,md,cfg,ini,log,json,yml,yaml,toml,xml     ← 기본값
txt,cfg,ini,log,json,yml,yaml,toml,xml        ← md 를 뺀 값
```

> 🛑 **`Advanced Settings` 를 켜지 않으면 항목이 보이지 않는다.** 소스에서
> `_initial_set(...)` 의 세 번째 인자 `p_basic` 을 주지 않아 기본값 `false` —
> 고급 항목으로 분류된다.

| | |
|---|---|
| **얻는 것** | 프로젝트 안의 **모든 `.md` 가 한 번에 사라진다** |
| **대가** | **에디터 전역 설정이라 다른 프로젝트에도 적용된다.** 그리고 Godot 에디터로 `.md` 를 열 수 없게 된다 |

실측 — 파일 5개를 루트에 두고 스캔시킨 결과다.

| 파일 | 독에 보이나 | 이유 |
|---|---|---|
| `NOTE.md` · `NOTE.txt` | ✅ 보임 | 화이트리스트에 있는 확장자 |
| `NOTE.xyz` | 🚫 안 보임 | 목록에 없는 확장자 |
| `NOTE` (확장자 없음) | 🚫 안 보임 | 확장자가 없다 |
| `.HIDDEN.md` | 🚫 안 보임 | **점으로 시작** |

다섯 개 다 디스크에는 그대로 있다. 에디터만 안 볼 뿐이다.

### 라리엔 3D 에서는

| 대상 | 방법 |
|---|---|
| `game-assets/` · `game-server/` (서버 코드·원본 에셋) | 각 폴더 안에 빈 `.gdignore` |
| `CLAUDE.md` | **이름을 바꿀 수 없다** — Claude Code 가 그 이름으로 읽는다. `md` 를 화이트리스트에서 뺀다 |
| 이름이 자유로운 메모·치트시트 | 앞에 `.` 을 붙여도 된다 |

⚠️ `game-server/` 는 **git 서브모듈**이라 `.gdignore` 를 만들면 그쪽 working tree 에
untracked 파일이 생긴다. 커밋에 섞이지 않게 막아 둔다.

```bash
echo ".gdignore" >> .git/modules/game-server/info/exclude
```

**빌드 산출물이 `res://` 안에 있을 때는 `.gdignore` 만으로 부족하다** —
게임 패키지에서 빼는 것은 `exclude_filter` 로 따로 해야 한다.
→ [headless-workflow.md](../headless-workflow.md) §6

---
