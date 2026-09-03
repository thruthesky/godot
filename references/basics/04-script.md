# 4. 스크립트 — 노드에 붙는 것

> **[Godot 기본](../basics.md)** 의 파트 **5 / 11**
> [← 3. 인스턴싱(Instancing) — 설계도로 실체를 찍어낸다](03-instancing.md) · [5. 시그널(Signal) — 노드끼리 대화하는 방법 →](05-signal.md)

GDScript 파일은 혼자 돌지 않는다. **노드에 붙어야** 실행된다.

```gdscript
extends CharacterBody3D    # ← "이 스크립트는 CharacterBody3D 노드에 붙는다"는 선언
```

`extends` 가 정하는 것은 **이 스크립트가 어떤 노드의 기능을 물려받는가**다.
`CharacterBody3D` 를 상속했으므로 `velocity`·`move_and_slide()` 를 그냥 쓸 수 있다.

**스크립트는 씬과 같은 폴더에 둔다** — 엔진의 Attach Script 기본 경로가 그 구조를
전제하기 때문이다. 근거는 [nodes-scenes.md](../nodes-scenes.md) §11.

## GDScript 문법의 기초 — 왕초보가 가장 먼저 막히는 것들

**코드가 무엇을 하는지 이전에, 코드가 어떻게 생겼는지부터** 알아야 한다.
여기 나오는 값은 전부 **엔진에 직접 넣어 돌려 본 결과**다.

### 🔑 블록은 **들여쓰기로만** 정해진다 — 중괄호가 없다

C·Java·JavaScript 는 `{ }` 로 묶는다. **GDScript 에는 그것이 없다.**

```gdscript
if dir.is_zero_approx():
	velocity.x = 0.0        # ← 들여쓴 줄이 if 안쪽
	velocity.z = 0.0        # ← 이것도 안쪽
move_and_slide()            # ← 들여쓰기를 뺐으므로 if 바깥
```

**같은 깊이로 들여쓴 연속된 줄들이 하나의 블록**이다.
들여쓰기를 한 칸 빼는 순간 그 블록은 끝난다.

#### 줄 끝의 `:` 은 "이제 블록이 시작된다"는 표시

```gdscript
func _physics_process(delta: float) -> void:    # ← 콜론
	if not is_on_floor():                       # ← 콜론
		velocity += get_gravity() * delta
```

`func`·`if`·`else`·`for`·`while` 뒤에는 **반드시 `:` 을 찍고 다음 줄부터 들여쓴다.**
`:` 을 빼면 오류가 나고, `:` 만 찍고 들여쓰지 않아도 오류가 난다(엔진 확인).

```
Expected indented block after function declaration.
```

> 💡 아무것도 안 할 블록에는 **`pass`** 를 넣는다. 빈 블록은 문법 오류이기 때문이다.

### 들여쓰기를 개발자 마음대로 해도 되나 — **크기와 문자는 자유, 일관성은 필수**

**결론부터** — 탭이든 스페이스든, 1칸이든 8칸이든 **내 마음대로 고를 수 있다.**
**단 한 파일 안에서는 끝까지 같아야 한다.**

엔진에서 직접 확인한 결과다.

| 들여쓰기 방식 | 결과 |
|---|---|
| **탭** | ✅ 통과 |
| **스페이스 4칸** | ✅ 통과 |
| **스페이스 2칸** | ✅ 통과 |
| **스페이스 1칸** | ✅ 통과 |
| **한 파일에서 탭과 스페이스를 섞음** | 🛑 **오류** |
| 같은 블록인데 어떤 줄만 더 깊게 | 🛑 **오류** |
| 블록인데 들여쓰기를 안 함 | 🛑 **오류** |

섞었을 때 나오는 메시지는 이렇다.

```
Parse Error: Used space character for indentation instead of tab as used before in the file.
```

**"앞에서는 탭을 쓰더니 여기서는 스페이스를 썼다"** 고 정확히 알려준다.

같은 블록인데 깊이가 다르면 이렇게 나온다.

```
Parse Error: Expected statement, found "Indent" instead.
```

#### 그래서 실제로는 무엇을 쓰나 — **탭**

**Godot 에디터의 기본값이 탭이고, 공식 스타일 가이드도 탭**이다.
에디터에서 Tab 키를 누르면 탭 문자가 들어가므로 **그냥 쓰면 자동으로 맞는다.**

**문제는 인터넷에서 코드를 복사해 붙일 때** 생긴다. 웹 페이지의 코드는
스페이스인 경우가 많아 **붙이는 순간 탭과 섞인다.**
위 오류가 나면 **복사해 온 줄의 들여쓰기를 지우고 Tab 키로 다시 넣는다.**

> 💡 Godot 에디터에서 **`Edit > Indentation > Convert Indent to Tabs`** 로
> 파일 전체를 한 번에 바꿀 수 있다.

### `:=` 가 무엇인가 — 변수를 선언하는 **세 가지 방법**

```gdscript
var a = 1              # ① 타입 없이
var b := 1             # ② 타입 추론  ← 이 스킬의 기본
var c: int = 1         # ③ 타입 명시
```

세 개가 다 동작한다. 차이는 **"이 변수에 나중에 다른 타입을 넣을 수 있는가"** 다.

| | 쓰는 법 | 타입이 | 다른 타입을 넣으면 |
|---|---|---|---|
| ① | `var a = 1` | **고정되지 않는다** | ✅ 된다 — 나중에 문자열도 담긴다 |
| ② | `var b := 1` | **`int` 으로 고정** | 🛑 **오류** |
| ③ | `var c: int = 1` | **`int` 으로 고정** | 🛑 오류 |

**②와 ③은 결과가 같다.** `:=` 는 **"타입을 값에서 알아서 정하라"** 는 뜻이고,
③은 **"타입을 내가 직접 적겠다"** 는 뜻이다.

#### `:=` 가 실제로 정하는 타입 (엔진에서 확인)

| 코드 | 정해지는 타입 |
|---|---|
| `var a := 1` | **`int`** |
| `var b := 1.0` | **`float`** |
| `var c := "글자"` | **`String`** |
| `var d := Vector3(1,2,3)` | **`Vector3`** |

**소수점 하나로 타입이 갈린다.** `1` 은 `int`, `1.0` 은 `float` 이다.

#### 타입을 고정하면 무엇이 좋은가

```gdscript
var b := 1
b = "문자열"      # 🛑 게임을 실행하기 전에 에디터가 잡아 준다
```

```
Parse Error: Cannot assign a value of type "String" as "int".
```

**실수를 실행 전에 잡는다.** 타입 없이 선언하면 이 실수가 통과해 버리고,
게임을 한참 돌리다 엉뚱한 곳에서 터진다.
**그래서 이 스킬은 `:=` 또는 `: 타입 =` 을 쓰는 것을 규범으로 한다.**

#### 🛑 `var a: int := 1` 은 문법 오류다

```
Parse Error: Expected end of statement after variable declaration, found ":" instead.
```

**`:` 과 `:=` 를 함께 쓸 수 없다.** 둘 중 하나만 쓴다.

#### ⚠️ `int` 변수에 실수를 넣으면 **조용히 잘린다**

```gdscript
var f := 1        # int 로 고정
f = 2.7           # 오류가 나지 않는다
print(f)          # → 2
```

엔진에서 확인한 결과 **`2`** 가 나온다. 소수점이 버려진 것이다.
**오류도 경고도 없다.** 소수를 다룰 값이면 처음부터 `1.0` 으로 써서 `float` 이 되게 한다.

#### `const` 는 `var` 와 무엇이 다른가

```gdscript
const SPEED := 5.0     # 한 번 정하면 바꿀 수 없다
var velocity_x := 0.0  # 언제든 바꿀 수 있다
```

`const` 에 나중에 대입하면 오류가 난다. **바뀌면 안 되는 값에 `const` 를 쓰면
실수로 고치는 사고를 막을 수 있다.** 대문자로 쓰는 것은 관습이다.

### `@` 로 시작하는 것 — 어노테이션(annotation)

```gdscript
@onready var _mesh: Node3D = $Mesh
@export var speed := 5.0
@tool
```

**`@` 로 시작하는 것을 어노테이션이라고 한다.** 변수도 함수도 아니고,
**바로 아래(또는 같은 줄)에 오는 것을 엔진이 어떻게 다룰지 지시하는 표시**다.

`@onready` 는 **"이 변수의 대입을 노드가 씬 트리에 들어간 뒤로 미뤄라"** 는 지시다.
코드가 하는 일이 아니라 **엔진에게 시키는 일**이라서 `@` 를 붙여 구분한다.

#### 🛑 개발자가 마음대로 만들 수 없다

**엔진이 제공하는 고정 목록에서 골라 쓰는 것**이고, 새로 만들 수 없다.
없는 이름을 쓰면 그 자리에서 막힌다(엔진 확인).

```gdscript
@my_annotation
var a := 1
```
```
Parse Error: Unrecognized annotation: "@my_annotation".
```

**변수·함수 이름은 내가 짓지만, 어노테이션은 고를 수만 있다.**
이 점이 다른 이름들과 결정적으로 다르다.

#### 붙일 수 있는 자리도 정해져 있다

`@onready` 하나만 놓고 잘못된 자리에 붙여 봤다. 전부 막힌다(엔진 확인).

| 잘못 쓴 예 | 엔진이 내는 오류 |
|---|---|
| 함수 안 **지역 변수**에 | `Annotation "@onready" is not allowed in this level.` |
| **`Node` 를 상속하지 않는** 클래스에서 | `"@onready" can only be used in classes that inherit "Node".` |
| **함수**에 붙임 | `Annotation "@onready" cannot be applied to a function.` |
| `@export` 와 **함께** 씀 | `"@onready" will set the default value after "@export" takes effect and will override it.` |

**마지막 것이 이 스킬의 절대 규칙 중 하나**다 — `@export` 와 `@onready` 를 함께 쓰면
인스펙터에서 넣은 값이 `@onready` 대입에 덮여 버린다. 엔진이 직접 경고한다.

#### 어떤 것들이 있나 (엔진에서 추출한 전체 목록 · 37개)

| 분류 | 어노테이션 |
|---|---|
| **노드·씬** | `@onready` · `@tool` · `@icon` |
| **인스펙터 노출** | `@export` 와 그 변형 **24개** — `@export_range` · `@export_enum` · `@export_file` · `@export_dir` · `@export_multiline` · `@export_color_no_alpha` · `@export_node_path` · `@export_flags` · `@export_group` · `@export_subgroup` · `@export_category` · `@export_placeholder` · `@export_custom` · `@export_storage` · `@export_tool_button` · `@export_exp_easing` · `@export_global_file` · `@export_global_dir` · `@export_file_path` · `@export_flags_2d_*` / `_3d_*` / `_avoidance` |
| **네트워크** | `@rpc` |
| **클래스** | `@abstract` · `@static_unload` |
| **경고 제어** | `@warning_ignore` · `@warning_ignore_start` · `@warning_ignore_restore` |

**절반 이상이 `@export` 계열**이다. 인스펙터에 값을 어떤 모습으로 띄울지
(슬라이더로? 드롭다운으로? 파일 선택 버튼으로?) 정하는 것들이다.

#### 초보가 실제로 쓰게 되는 것은 셋뿐이다

| 어노테이션 | 언제 |
|---|---|
| **`@onready`** | 자식 노드를 변수에 잡을 때 — **가장 자주 쓴다** |
| **`@export`** | 인스펙터에서 값을 조절하고 싶을 때 |
| `@tool` | 에디터에서도 스크립트를 돌리고 싶을 때 — **바로 아래 절** |

```gdscript
@export var speed := 5.0        # 인스펙터에 "Speed" 칸이 생긴다
@export_range(1.0, 20.0) var jump := 4.5   # 슬라이더로 나온다
```

**`@export` 를 쓰면 코드를 고치지 않고 씬마다 다른 값**을 줄 수 있다.
`const` 로 박아 둔 `SPEED` 를 `@export var` 로 바꾸면 인스펙터에서 바로 조절된다.

전체 어노테이션의 상세와 인스펙터 표시 방법은 [gdscript.md](../gdscript.md) 에 있다.

### `@tool` — 스크립트를 **에디터에서도** 돌린다

**기본적으로 스크립트는 게임을 실행할 때만 돕니다.** 에디터에서 씬을 편집하는 동안에는
`_ready()` 도 `_process()` 도 불리지 않는다. 첫 줄에 `@tool` 을 붙이면 그것이 바뀐다.

```gdscript
@tool
extends Node3D
```

**이 한 줄이 "에디터에서도 이 코드를 실행하라"는 뜻**이다.

#### 언제 쓰나 — 에디터에서 **결과를 미리 보고 싶을 때**

| 예 | `@tool` 없이 | `@tool` 로 |
|---|---|---|
| 원형으로 스폰 지점 8개 배치 | 실행해야 보인다 | **인스펙터에서 개수를 바꾸면 즉시 배치가 갱신된다** |
| 절차적으로 만든 지형·나무 | 실행해야 보인다 | 에디터에서 모양을 보며 값을 조절한다 |
| 설정이 빠졌다고 경고 표시 | 알 수 없다 | 씬 독에 ⚠️ 아이콘을 띄운다 |

**값을 바꿀 때마다 게임을 실행해 확인하는 왕복을 없애는 것**이 목적이다.

#### 🛑 절대 규칙 — `Engine.is_editor_hint()` 로 갈라라

`@tool` 을 붙이면 **게임 로직이 에디터에서도 실행된다.** 이것이 사고의 원인이다.

```gdscript
@tool
extends Node3D

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_editor_preview()      # 에디터에서만
		return
	_game_logic(delta)         # 게임에서만
```

`Engine.is_editor_hint()` 는 **에디터 안에서 돌고 있으면 `true`** 를 돌려준다.
**엔진에서 확인** — 게임을 실행하면 `false` 다.

```
게임 실행 중 Engine.is_editor_hint() = false
```

이 분기를 빠뜨리면 이런 일이 벌어진다.

| 빠뜨리면 | 무슨 일이 |
|---|---|
| 무한 루프·긴 계산 | **에디터가 응답 없음**이 된다 |
| `queue_free()` 로 노드 삭제 | **편집 중인 씬이 지워진다** — 작업 내용 소실 |
| 파일 쓰기 | 프로젝트 파일이 손상된다 |
| 물리·입력 처리 | 의미 없는 부하만 생긴다 |

**게임에서는 잘 돌던 코드가 에디터를 망가뜨린다.** 그래서 `@tool` 은
"편리한 기능"이 아니라 **책임이 따르는 스위치**다.

#### 에디터에서 만든 노드는 `owner` 를 지정한다

```gdscript
var node := Node3D.new()
add_child(node)
if Engine.is_editor_hint():
	node.owner = get_tree().edited_scene_root   # 이게 없으면 저장되지 않는다
```

`owner` 가 없으면 **`.tscn` 에 저장되지 않아** 에디터를 껐다 켜면 사라진다.

#### 초보라면 — **당분간 쓰지 않아도 된다**

캐릭터를 움직이고 맵을 만드는 데는 `@tool` 이 전혀 필요 없다.
**"에디터에서 미리 보고 싶다"는 요구가 실제로 생겼을 때** 그때 붙이면 된다.

다만 **남의 코드에서 첫 줄에 `@tool` 을 보면** "이건 에디터에서도 도는 스크립트구나"
라고 읽을 수 있어야 한다. 그것이 이 절의 목적이다.

#### `@tool` 과 `EditorPlugin` 은 다르다

| | `@tool` 스크립트 | `EditorPlugin` |
|---|---|---|
| 무엇 | **씬의 노드**가 에디터에서도 도는 것 | **에디터 자체**를 확장하는 것 |
| 예 | 배치 미리보기, 설정 경고 | 새 독·툴바·메뉴·임포터 추가 |
| 등록 | 첫 줄에 `@tool` | `addons/*/plugin.cfg` + Plugins 탭에서 활성화 |

깊이 들어가려면 [editor-plugin.md](../editor-plugin.md) 를 본다.

### 그 밖에 먼저 알아 둘 것

| 문법 | 뜻 |
|---|---|
| `# 주석` | 이 줄은 실행되지 않는다 |
| `## 문서 주석` | 인스펙터·자동완성에 설명으로 뜬다 |
| `func 이름():` | 함수 선언 |
| `-> void` | **반환 타입** — 값을 돌려주지 않는다는 표시 |
| `and` · `or` · `not` | **`&&`·`||`·`!` 가 아니다** |
| 줄 끝 `;` | **필요 없다** (써도 되지만 관습이 아니다) |
| `_` 로 시작하는 이름 | 내부용이라는 **관습**(변수) 또는 엔진 콜백(함수) |

```gdscript
## 걷는 속도 (m/s)          ← 이 설명이 자동완성에 뜬다
const SPEED := 5.0

# 아래는 그냥 메모다          ← 이건 안 뜬다
func _physics_process(delta: float) -> void:
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
```

문법 전체 목록과 심화는 [gdscript.md](../gdscript.md) 에 있다.
실제 코드에 이 문법이 어떻게 쓰이는지는 [example.md](../example.md) §7 을 본다.


## 값을 바꾸는 것과 **실제로 일어나는 것**은 다르다

**초보가 가장 크게 오해하는 지점**이다. 예를 들어 이런 코드를 보면
`velocity` 가 캐릭터의 **위치**라고 생각하기 쉽다.

```gdscript
velocity.z = -5.0
move_and_slide()
# → 캐릭터가 앞으로 걸어간다
```

**둘 다 틀렸다.** `velocity` 는 위치가 아니고, 값을 바꾼다고 저절로 움직이지도 않는다.

### ① `velocity` 는 위치가 아니라 **속도**다

| | 단위 | 뜻 | 비유 |
|---|---|---|---|
| **`position` / `global_position`** | **m** (미터) | 지금 **어디 있는가** | 지도 위의 **점** |
| **`velocity`** | **m/s** (초당 미터) | 어느 쪽으로 **얼마나 빨리** | 그 점을 미는 **화살표** |

자동차로 치면 `position` 은 현재 위치, `velocity` 는 **속도계 + 방향**이다.
속도계가 60을 가리킨다고 차가 60km 지점에 있는 것은 아니다.

**엔진에서 확인** — `velocity` 를 `(0, 0, -5)` 로 **고정**하고 4틱 돌렸다.

| 틱 | `velocity.z` | `position.z` |
|---|---|---|
| 1 | **-5.0** (그대로) | -0.08 |
| 2 | **-5.0** (그대로) | -0.17 |
| 3 | **-5.0** (그대로) | -0.25 |
| 4 | **-5.0** (그대로) | -0.33 |

**`velocity` 는 하나도 변하지 않는데 `position` 은 계속 변한다.**
매 틱 `0.083m` 씩이고 이는 `5.0 m/s × 1/60초` 다.
`velocity` 를 `0` 으로 되돌리면 `position` 이 그 자리에서 **멈춘다**(원점으로 돌아가지 않는다).

**위치를 직접 바꾸고 싶으면** `global_position` 에 대입한다 — 순간이동한다.

```gdscript
global_position = Vector3(3, 1, 3)   # 즉시 그 자리로
velocity = Vector3.ZERO              # 남아 있던 속도도 지운다
```

> 🛑 좌표를 옮기려고 `velocity.z = -100` 을 넣으면 **"1초에 100미터씩 가라"** 가 되어
> 총알처럼 날아간다(실측 — 매 틱 1.67m 이동).

### ② `velocity` 를 바꾸는 것만으로는 **아무 일도 일어나지 않는다**

**이것이 빠진 조각이다.** 값을 넣어 두는 것과 엔진이 그것을 실행하는 것은 별개다.

**엔진에서 확인** — 같은 코드에서 `move_and_slide()` 한 줄만 뺐다 넣었다.

| 코드 | 틱1 | 틱2 | 틱3 |
|---|---|---|---|
| `velocity = (0,0,-5)` **만** | `position.z = 0.000` | `0.000` | `0.000` |
| `velocity = (0,0,-5)` + **`move_and_slide()`** | **-0.083** | **-0.167** | **-0.250** |

**`velocity` 는 위에서 똑같이 `-5.0` 이었다.** 그런데 위쪽은 꿈쩍도 하지 않는다.

```
velocity          =  주문서에 "북쪽으로 시속 5미터" 라고 적는 것
move_and_slide()  =  그 주문서를 들고 실제로 몸을 미는 것
```

**주문서만 쓰고 아무도 밀지 않으면 제자리에 서 있다.**
`move_and_slide()` 가 매 틱 `velocity` 를 **읽어서** `position` 을 옮기는
**실행자**이고, `velocity` 는 그에게 건네는 **지시서**다.

### ③ 프로퍼티는 **노드마다 따로** 있다

*"`velocity` 를 바꿨는데 왜 저 캐릭터가 움직이지?"* 라는 의문의 답이다.

스크립트 안에서 그냥 쓴 `velocity` 는 사실 **`self.velocity`** 의 줄임이고,
`self` 는 **이 스크립트가 붙어 있는 바로 그 노드**다.

```gdscript
extends CharacterBody3D          # ← 이 스크립트는 CharacterBody3D 노드에 붙는다

func _physics_process(delta):
	velocity.z = -5.0            # ← self.velocity, 즉 "이 노드 자신"의 속도
	move_and_slide()             # ← self.move_and_slide(), 이 노드를 민다
```

그래서 **같은 스크립트를 두 캐릭터에 붙여도 서로 간섭하지 않는다.**
각자 자기 `velocity` 를 갖기 때문이다.

**엔진에서 확인** — `CharacterBody3D` 두 개(A·B)에 서로 다른 속도를 넣었다.

| 틱 | `A.velocity.z` | `A.position.z` | `B.velocity.z` | `B.position.z` |
|---|---|---|---|---|
| 1 | **-5.0** | -0.08 | **+10.0** | +0.17 |
| 2 | **-5.0** | -0.17 | **+10.0** | +0.33 |
| 3 | **-5.0** | -0.25 | **+10.0** | +0.50 |

**이름은 똑같이 `velocity` 인데 값도 결과도 완전히 따로 논다.**
A 는 북으로 초당 5m, B 는 남으로 초당 10m 씩 간다.

### 정리 — 캐릭터가 움직이는 전체 사슬

```
① extends CharacterBody3D
     → 이 스크립트는 그 노드 자신이 된다(self). velocity 를 물려받는다.
②  velocity.z = -5.0
     → self(= 이 캐릭터)의 "속도 지시서"에 값을 쓴다. 아직 아무 일도 없다.
③  move_and_slide()
     → 엔진이 그 지시서를 읽어 position += velocity × delta 를 실행한다.
     → 부딪히면 멈추고, velocity 를 실제 결과로 고쳐 쓴다.
④ 화면에 옮겨진 위치가 그려진다
```

**②만 있고 ③이 없으면 캐릭터는 영원히 제자리다**(위 실측).
반대로 ③만 있고 ②가 없으면 `velocity` 가 `(0,0,0)` 이라 역시 제자리다.

실제 코드와 줄별 해설은 [example.md](../example.md) §7 에 있다.


## 생명주기 — 언제 불리는가

```
_init()            객체 생성 시. 아직 트리 밖, 자식도 없다
_enter_tree()      트리에 들어갈 때
_ready()           자식까지 전부 준비된 뒤 한 번   ← 초기화는 보통 여기서
_process(delta)    매 프레임 (프레임레이트에 따라 간격이 다름)
_physics_process() 고정 틱 (기본 60Hz)             ← 물리·이동은 반드시 여기서
_exit_tree()       트리에서 나갈 때
```

**부모보다 자식의 `_ready()` 가 먼저 불린다.** 자식이 다 준비된 뒤에 부모가 준비되는
순서라, 부모의 `_ready()` 에서는 자식을 안심하고 만질 수 있다.

## `_ready()` 가 실행되지 않는다 — 파일이 있다고 실행되는 게 아니다

**초보자가 가장 많이 겪는 혼란이다.** `.gd` 파일 여러 개에 `_ready()` 를 써 놨는데
실행하면 그중 하나의 `print` 만 찍힌다.

**원인은 하나다 — `_ready()` 는 "파일이 존재하면" 불리는 게 아니라,
그 스크립트가 붙은 노드가 실행 중인 씬 트리(SceneTree)에 들어갈 때 불린다.**

프로젝트 폴더에 `.gd` 나 `.tscn` 이 놓여 있는 것과, 그것이 게임 안에서
**살아 있는 노드로 존재하는 것**은 완전히 별개다. 존재하지 않는 노드의 `_ready()` 는
불릴 이유가 없다.

### 실제 사례 — 두 개의 씬, 네 개의 스크립트

```
project.godot     run/main_scene="uid://ekov44a2ii3w"   ← demo.tscn 의 UID

demo.tscn         Demo (Node3D)
                  └── TheBox (StaticBody3D)   ← the_box.gd

light_scene.tscn  LightScene (Node3D)         ← light_scene.gd
                  └── StaticBody3D            ← static_body_3d.gd
                      └── MeshInstance3D      ← mesh_instance_3d.gd
```

| 스크립트 | 붙은 노드가 있는 씬 | 실행되나 |
|---|---|---|
| `the_box.gd` | **demo.tscn** = 메인 씬 | ✅ |
| `light_scene.gd` | light_scene.tscn | ❌ |
| `static_body_3d.gd` | light_scene.tscn | ❌ |
| `mesh_instance_3d.gd` | light_scene.tscn | ❌ |

`light_scene.tscn` 은 **demo.tscn 어디에서도 인스턴싱되어 있지 않다.**
디스크에 놓인 파일일 뿐이라 실행 중인 게임 안에는 존재하지 않는다.
스크립트가 세 개나 붙어 있어도 결과는 같다 — **노드가 없으면 `_ready()` 도 없다.**

### 확인하는 법 — 씬이 인스턴싱되었는지 본다

`.tscn` 을 텍스트로 열어 `ext_resource` 와 `PackedScene` 을 본다.
부모 씬이 자식 씬을 품고 있으면 이런 줄이 있어야 한다.

```
[ext_resource type="PackedScene" uid="uid://c73oplm6ylkw8" path="res://light_scene.tscn" id="2_xxxxx"]
...
[node name="LightScene" parent="." instance=ExtResource("2_xxxxx")]
```

이 두 줄이 없으면 그 씬은 **실행되지 않는다.**

### 해결 — 셋 중 하나를 고른다

| 원하는 것 | 방법 |
|---|---|
| **두 씬을 함께 돌린다** | 메인 씬 안에 다른 씬을 **인스턴싱**한다 (아래 ①) |
| **그 씬만 돌린다** | 메인 씬을 바꾸거나 **현재 씬 실행**(macOS <kbd>Cmd</kbd>+<kbd>R</kbd> · Windows·Linux <kbd>F6</kbd>) (아래 ②③) |
| **항상 살아 있어야 한다** | **오토로드(Autoload)** 로 등록 (아래 ④) |

**① 메인 씬 안에 인스턴싱한다 (가장 흔한 정답)**

씬 독에서 부모가 될 노드를 선택하고 **Instantiate Child Scene**
(체인 모양 아이콘, <kbd>Cmd</kbd>+<kbd>Shift</kbd>+<kbd>A</kbd> · Windows·Linux 는 `Ctrl+Shift+A`) 으로 `.tscn` 을 고른다.
파일 독에서 씬 트리로 **드래그 앤 드롭** 해도 같다. 코드로 넣는 방법은 §3 참고.

### 🛑 실행 단축키는 macOS 에서 다르다 — F5·F6 이 아니다

**Godot 은 macOS 에서 실행 단축키를 재정의한다.** 문서·튜토리얼이 F5/F6 으로 적혀 있어도
Mac 에서는 그 키가 아니다.

| 동작 | Windows · Linux | **macOS** |
|---|---|---|
| Run Project (메인 씬) | <kbd>F5</kbd> | **<kbd>Cmd</kbd>+<kbd>B</kbd>** |
| **Run Current Scene** | <kbd>F6</kbd> | **<kbd>Cmd</kbd>+<kbd>R</kbd>** |
| Stop | <kbd>F8</kbd> | **<kbd>Cmd</kbd>+<kbd>.</kbd>** |

⚠️ **Magic Keyboard 는 F1~F12 가 기본이 미디어 키다.** F 키를 쓰려면 <kbd>fn</kbd> 을
함께 눌러야 한다(`fn`+`F6`). 그래서 Mac 에서는 위 표의 Cmd 조합을 쓰는 편이 낫다.

**마우스만으로 실행하려면** — 에디터 **오른쪽 위** 재생 버튼 묶음에서
**필름 슬레이트 아이콘(🎬)** 이 "현재 씬 실행" 이다(▶ 는 메인 씬 실행).
아이콘에 커서를 올리면 그 환경의 실제 단축키가 툴팁에 나온다.

**터미널에서 특정 씬만 실행** — 단축키·에디터와 무관하게 가장 확실하다:

```bash
godot --path . scenes/demo/player_demo.tscn
```

**② 메인 씬 자체를 바꾼다**

`Project > Project Settings > Application > Run > Main Scene`

단, 이러면 **원래 메인 씬 쪽 `_ready()` 가 반대로 안 불린다.** 교체이지 추가가 아니다.

**③ 지금 열어 둔 씬만 단독 실행 — <kbd>F6</kbd>**

메인 씬 설정을 건드리지 않고 확인만 할 때 쓴다.
<kbd>F5</kbd> 는 **메인 씬**, <kbd>F6</kbd> 는 **지금 열려 있는 씬**을 실행한다.
이 둘을 헷갈려서 "왜 내가 편집 중인 씬이 안 뜨지" 하는 경우가 많다.

**④ 오토로드로 등록한다**

`Project > Project Settings > Globals > Autoload`

씬이나 스크립트를 등록하면 엔진이 **루트(`/root`) 바로 아래에 붙여** 게임 내내
살려 둔다. 씬을 바꿔도 죽지 않으므로 사운드 매니저·세이브 매니저처럼
**전역으로 하나만 있어야 하는 것**에 쓴다. 일반 게임 오브젝트에는 쓰지 않는다.

### `_ready()` 가 안 불리는 다른 원인들

씬 인스턴싱이 압도적으로 흔하지만, 다음도 확인한다.

| 원인 | 증상 | 확인 |
|---|---|---|
| **스크립트를 노드에 안 붙였다** | 파일만 만들고 Attach 를 안 함 | 인스펙터 맨 아래 `Script` 칸이 비었는지 |
| **함수 이름 오타** | `_Ready`, `ready`, `_redy` | GDScript 는 **`_ready` 정확히** 소문자·언더스코어 하나 |
| **`extends` 가 노드 타입과 불일치** | 스크립트가 아예 안 붙는다 | `extends Node3D` 인데 `MeshInstance3D` 에 붙이려 함 |
| **부모가 `_ready()` 를 오버라이드하고 `super()` 안 부름** | 상속받은 클래스에서만 발생 | 부모 클래스의 `_ready()` 를 부르려면 `super()` |
| **`add_child()` 를 안 했다** | 코드로 `.new()`/`instantiate()` 만 함 | §3 "메모리에 올린다가 무슨 뜻인가" 4단계 |

> **`_ready()` 는 노드당 평생 한 번이다.** `remove_child()` 로 뺐다가 다시 붙이면
> `_enter_tree()` 는 다시 불리지만 `_ready()` 는 불리지 않는다.
> 다시 붙을 때마다 실행할 초기화는 `_enter_tree()` 에 둔다.

## `pass` 는 무엇인가 — 스크립트를 붙이면 처음 보게 되는 것

노드에 스크립트를 붙이면 에디터가 이런 뼈대를 만들어 준다.

```gdscript
extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.
```

**`pass` 는 "아무 일도 하지 않는 문장"이다.**

`return` 과 헷갈리기 쉬운데 **완전히 다르다. `pass` 는 함수를 끝내지 않는다.**

```gdscript
func with_pass() -> String:
    pass
    print("실행된다")          # ← pass 뒤의 줄은 그대로 실행된다
    return "값"

func with_return() -> String:
    return "값"
    print("실행되지 않는다")    # ← return 뒤는 죽은 코드다
```

| | `pass` | `return` |
|---|---|---|
| 함수를 끝내나 | 🛑 **아니다** | ✅ 그렇다 |
| 뒤의 줄은 | **실행된다** | 실행되지 않는다 |
| 하는 일 | **없다** | 값을 돌려주며 빠져나온다 |

> **엔진에서 확인 (4.7.2)** — `pass` 를 지나간 함수는 뒤 줄을 실행했고
> (`["pass 다음 줄이 실행되었다"]`), `return` 뒤의 줄은 실행되지 않았다 (`[]`).

**그럼 왜 있는가 — GDScript 는 함수 몸통이 비면 문법 오류이기 때문이다.**

```
pass 없이 몸통을 비우면
  Parse Error: Expected indented block after function declaration.
pass 를 넣으면
  통과
```

**즉 `pass` 는 "여기 아직 코드가 없다"는 자리를 채우는 문장**이다.
템플릿에 함께 붙는 주석 `# Replace with function body.` 가 그 뜻이다 —
**지우고 여기에 코드를 쓰라**는 말이다.

```gdscript
func _ready() -> void:
    pass                 # ← 코드를 쓸 때는 지운다

func _ready() -> void:
    print("시작")        # ← 이렇게
```

남겨 두어도 동작에는 영향이 없지만 의미가 없다.

> **`pass` 만 있는 함수의 반환값은 `null` 이다.** `pass` 가 돌려준 것이 아니라
> **함수가 마지막 줄까지 도달해 그냥 끝났기 때문**이다. 반환값이 없는 함수는
> 자동으로 `null` 을 돌려준다 *(엔진 확인: 타입 `Nil`)*.

**`pass` 는 함수뿐 아니라 모든 빈 블록에 쓴다** — `if`, `for`, `while`,
`match` 의 분기도 마찬가지다.

---
