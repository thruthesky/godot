# 7. 6단계 — 스크립트 2개

> **[예제 — 빈 프로젝트에서 캐릭터가 움직이기까지](../example.md)** 의 파트 **8 / 14**
> [← 6. 5단계 — 카메라](06-step5-camera.md) · [7. 6단계 — 스크립트 2개 (b) →](07-step6-scriptsb.md)


## 목차

| 절 | 내용 |
|---|---|
| [·](#playergd--이동) | `player.gd` — 이동 |
| 　[·](#-코드를-읽기-전에--이름에는-세-종류가-있다) | 　🔑 코드를 읽기 전에 — 이름에는 **세 종류**가 있다 |
| 　[·](#한-줄씩) | 　한 줄씩 |
| 　[·](#-이제-하나씩-완전히-뜯어본다) | 　📚 이제 하나씩 완전히 뜯어본다 |
| 　[·](#-화살표-키가-이동으로-바뀌기까지--4단계) | 　⌨ 화살표 키가 이동으로 바뀌기까지 — 4단계 |
| 　[·](#-한-틱-동안-무슨-일이-일어나는가--전체-흐름) | 　⏱ 한 틱 동안 무슨 일이 일어나는가 — 전체 흐름 |

---

## `player.gd` — 이동

**`player.tscn` 을 열고 루트 `Player` 를 선택한 뒤** 스크립트를 붙인다.
경로는 `res://scenes/player.gd`.

```gdscript
extends CharacterBody3D

## 걷는 속도 (m/s)
const SPEED := 5.0
## 점프 시작 속도 (m/s)
const JUMP_VELOCITY := 4.5

@onready var _mesh: Node3D = $Mesh


func _physics_process(delta: float) -> void:
	# 바닥에 닿아 있지 않으면 중력을 받는다
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY

	# 화면 기준 입력을 월드 XZ 방향으로 옮긴다.
	# 카메라 yaw 가 0 이라 화면 위쪽이 그대로 월드 -Z 가 된다.
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var dir := Vector3(input.x, 0.0, input.y)

	if dir.is_zero_approx():
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
	else:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		# 몸통만 가는 쪽으로 돌린다. 본체는 돌리지 않는다
		_mesh.look_at(_mesh.global_position + dir, Vector3.UP)

	move_and_slide()
```

### 🔑 코드를 읽기 전에 — 이름에는 **세 종류**가 있다

**초보자가 가장 먼저 알아야 할 것은 "이 이름을 내가 바꿔도 되는가"** 이다.
GDScript 에 나오는 이름은 딱 세 종류이고, 규칙이 완전히 다르다.

| 종류 | 이 코드에서는 | 바꿔도 되나 |
|---|---|---|
| **① 엔진이 정한 이름** | `velocity` · `_physics_process` · `move_and_slide` · `is_on_floor` · `get_gravity` · `Input` · `Vector3` · `x`·`y`·`z` | 🛑 **절대 안 된다.** 바꾸면 엔진이 못 찾는다 |
| **② 내가 정하지만 엔진과 약속한 이름** | `"ui_left"` · `"ui_accept"` 같은 **액션 이름** | ✅ 새로 만들어 쓸 수 있다. 단 **양쪽 철자가 같아야** 한다 |
| **③ 순수하게 내가 지은 이름** | `SPEED` · `JUMP_VELOCITY` · `_mesh` · `input` · `dir` · `delta` | ✅ **마음대로.** `속도`·`abc` 여도 동작한다 |

세 종류를 가르는 기준은 하나다 — **"엔진이 이 이름을 찾는가, 내가 찾는가."**

```gdscript
velocity.x = dir.x * SPEED
# ↑         ↑       ↑
# ①엔진것   ③내것    ③내것
# 못 바꿈   바꿔도됨  바꿔도됨
```

`velocity` 를 `speed_vector` 로 바꾸면 **`move_and_slide()` 가 그 값을 읽지 못해
캐릭터가 움직이지 않는다.** 반면 `dir` 을 `방향` 으로 바꾸면 **아무 일도 일어나지 않는다** —
그 이름을 쓰는 건 나뿐이기 때문이다.

> 💡 **판별법** — 이름 위에 커서를 두고 **Ctrl+클릭**(macOS 는 Cmd+클릭)해 보면,
> 엔진 것이면 클래스 문서로 점프하고 내가 지은 것이면 선언한 줄로 점프한다.

### 한 줄씩

| 코드 | 뜻 |
|---|---|
| `extends CharacterBody3D` | 이 스크립트는 `CharacterBody3D` 노드에만 붙는다 |
| `@onready var _mesh` | 씬 트리에 들어간 **직후** 자식을 잡는다. 그냥 `var` 면 자식이 아직 없어 `null` |
| `if not is_on_floor()` | 땅에서도 중력을 누적하면 아래로 파고든다 |
| `get_gravity()` | `PhysicsBody3D` 의 메서드(doctool 확인). 프로젝트 설정의 중력을 읽는다 |
| `is_action_just_pressed` | `is_action_pressed` 를 쓰면 누르고 있는 동안 계속 점프해 날아간다 |
| `Input.get_vector(...)` | **대각선 정규화와 데드존을 알아서 처리**한다. 손으로 조합하면 대각선만 빨라진다 |
| `Vector3(input.x, 0, input.y)` | 화면 위쪽(`ui_up`) → `input.y = -1` → 월드 `-Z`. **forward 와 일치한다** |
| `velocity.x`·`.z` 만 대입 | `velocity` 를 통째로 대입하면 중력이 만든 `y` 가 지워져 공중에 뜬다 |
| `move_toward(..., SPEED)` | 키를 떼면 미끄러지지 않고 멈춘다 |
| `_mesh.look_at(...)` | 오일러(`rotation.y`) 대신 쓴다. 짐벌락·회전 순서 문제가 없다 |
| `move_and_slide()` | Godot 3 와 달리 **인자를 받지 않는다** |

---

### 📚 이제 하나씩 완전히 뜯어본다

#### `extends CharacterBody3D`

**이 스크립트가 어떤 노드에 붙을 것인지를 선언한다.** 동시에 **그 클래스의 기능을
전부 물려받는다**(상속).

```gdscript
extends CharacterBody3D
```

이 한 줄 덕분에 `velocity` · `move_and_slide()` · `is_on_floor()` 를
**아무 준비 없이 그냥 쓸 수 있다.** 전부 `CharacterBody3D` 가 가진 것이다.

| `extends` 를 무엇으로 쓰느냐에 따라 | 쓸 수 있는 것 |
|---|---|
| `extends Node` | 가장 기본. 위치도 없다 |
| `extends Node3D` | `position`·`rotation` 이 생긴다 |
| `extends CharacterBody3D` | 거기에 **`velocity`·`move_and_slide()`·`is_on_floor()`** 가 더해진다 |

🛑 **스크립트를 붙인 노드와 `extends` 가 맞지 않으면 오류가 난다.**
`Node3D` 에 이 스크립트를 붙이면 Godot 이 거부한다.

---

#### `const SPEED := 5.0` — ③ 내가 지은 이름

```gdscript
const SPEED := 5.0
const JUMP_VELOCITY := 4.5
```

`const` 는 **한 번 정하면 바뀌지 않는 값**이다. 이름은 **전적으로 내 자유**다 —
`WALK_SPEED`·`속도`·`S` 여도 동작한다. 대문자로 쓰는 건 **관습**일 뿐 문법이 아니다.

`:=` 는 **타입을 값에서 알아서 정하라**는 뜻이다. `5.0` 이니 `float` 이 된다.
`const SPEED: float = 5.0` 이라고 명시해도 완전히 같다.

**왜 숫자를 코드 중간에 직접 쓰지 않고 상수로 빼나** — 속도를 바꾸고 싶을 때
**한 곳만 고치면 되기 때문**이다. `5.0` 이 코드 세 군데에 흩어져 있으면 하나를 빠뜨린다.

> 💡 인스펙터에서 값을 조절하고 싶으면 `const` 대신 **`@export var SPEED := 5.0`**
> 을 쓴다. 그러면 씬마다 다른 값을 줄 수 있다 (→ [gdscript.md](../gdscript.md)).

---

#### `@onready var _mesh: Node3D = $Mesh`

```gdscript
@onready var _mesh: Node3D = $Mesh
```

한 줄에 네 가지가 들어 있다.

| 조각 | 뜻 |
|---|---|
| `@onready` | **이 노드가 씬 트리에 들어간 직후에 대입하라** |
| `var _mesh` | 변수 이름. **③ 내가 지은 것** — `body`·`몸통` 이어도 된다 |
| `: Node3D` | 타입을 못 박는다. 오타를 에디터가 잡아 준다 |
| `$Mesh` | **자식 노드를 이름으로 찾는다.** `get_node("Mesh")` 의 줄임 |

**`@onready` 가 없으면 `null` 이 된다.** 변수 초기화는 노드가 만들어지는 순간에
실행되는데, **그때는 자식 노드가 아직 트리에 붙기 전**이라 `$Mesh` 가 아무것도 못 찾는다.
**노드를 잡는 변수에는 사실상 항상 붙인다고 보면 된다.**

**`_` 로 시작하는 이유** — "이 스크립트 안에서만 쓰는 것"이라는 **관습**이다.
문법적 강제력은 없다. 엔진은 신경 쓰지 않는다.

##### 🛑 `$` 는 **이름으로** 찾는다 — 노드 이름을 바꾸면 코드가 깨진다

`$Mesh` 의 `Mesh` 는 **씬에 있는 노드 이름과 글자 하나까지 같아야 한다.**
대소문자도 구분한다.

**실제로 이 예제를 만들다 걸린 일이다.** `Player` 노드를 `PlayerCharacter` 로 이름만
바꿨더니 `main.gd` 가 이렇게 죽었다.

```
Invalid access to property or key 'global_position' on a base object of type 'null instance'.
```

`$Player` 가 그런 이름의 자식을 못 찾아 **`_player` 가 `null` 이 되었고**,
다음 줄에서 `null.global_position` 을 읽으려다 터진 것이다.

**오류 메시지가 `global_position` 을 가리켜서 좌표 문제처럼 보이지만, 진짜 원인은
그 앞줄의 노드 이름**이다. `null instance` 라는 말이 나오면 **`$` 경로부터 확인한다.**

##### 노드를 잡는 방법 세 가지

| 방법 | 이름을 바꾸면 | 언제 쓰나 |
|---|---|---|
| **`$Player`** | 🛑 **깨진다** | 같은 씬 안, 구조가 안 바뀔 때 |
| **`%Player`** (고유 이름) | 🛑 깨진다 | **깊은 곳**에 있어 경로가 길 때 |
| **`@export var player: Node3D`** | ✅ **안 깨진다** | 이름·위치가 바뀔 수 있을 때 |

```gdscript
# 인스펙터에 칸이 생긴다. 거기에 노드를 끌어다 놓는다.
@export var player: Node3D
```

`@export` 는 **씬 데이터에 저장되어 에디터가 관리**하므로 나중에 이름을 바꾸거나
다른 부모 밑으로 옮겨도 연결이 유지된다(`.tscn` 에 `node_paths=` 표시와 함께
`NodePath` 로 저장되고, 에디터가 그 값을 추적해 갱신한다 —
근거는 [basics/01-world.md](../basics/01-world.md) 의 "다른 노드를 가리키는 세 가지 방법"). 대신 **씬에서 한 번 지정해 줘야** 하고,
잊으면 역시 `null` 이 된다.

> 💡 **`%` 고유 이름**은 Scene 독에서 노드 우클릭 → `Access as Unique Name` 으로 켠다.
> 경로가 아무리 깊어도 `%Player` 한 번으로 잡히지만, **이름을 바꾸면 똑같이 깨진다.**

이 예제는 구조가 단순하고 노드가 바로 아래에 있으므로 `$` 를 쓴다.
**대신 노드 이름을 바꿀 때는 코드도 같이 바꾼다는 것을 기억한다.**

---

#### `func _physics_process(delta: float) -> void` — 엔진이 **불러 주는** 함수

**이 예제에서 가장 중요한 개념이다.**

##### 내가 부르지 않는다

보통 함수는 내가 쓴 코드가 부른다. 그런데 이 함수는 **어디에서도 부르지 않는데
저절로 실행된다.** 엔진이 **매 물리 틱마다 자동으로 불러 주기** 때문이다.

이런 함수를 **콜백(callback)** 또는 **생명주기 함수**라고 한다.
**이름이 약속이다** — 엔진은 `_physics_process` 라는 **정확한 이름**을 찾는다.

```gdscript
func _physics_process(delta: float) -> void:   # ✅ 엔진이 찾아서 부른다
func _physics_proces(delta: float) -> void:    # 🛑 오타 → 영원히 안 불린다
func my_physics(delta: float) -> void:         # 🛑 내가 직접 부르지 않으면 안 불린다
```

**오류도 경고도 나지 않는다.** 그냥 조용히 아무 일도 일어나지 않는다.
**"캐릭터가 꿈쩍도 안 한다"의 흔한 원인 중 하나**가 이 오타다.

`_` 로 시작하는 것도 **"엔진이 부르는 함수"라는 표시**다.

##### 엔진이 불러 주는 대표적인 함수들

| 함수 | 언제 불리나 |
|---|---|
| `_ready()` | 노드와 그 자식이 트리에 다 들어간 **직후 한 번** |
| `_process(delta)` | **매 화면 프레임** — 주사율에 따라 달라진다 |
| **`_physics_process(delta)`** | **매 물리 틱 — 기본 초당 60번 고정** |
| `_input(event)` | 입력이 들어왔을 때만 |
| `_exit_tree()` | 트리에서 빠질 때 |

##### `_process` 와 `_physics_process` 의 차이 — 왜 물리는 여기에 두나

| | `_process` | `_physics_process` |
|---|---|---|
| 호출 주기 | **화면 주사율** (60Hz·120Hz·144Hz…) | **고정 60Hz** (설정 가능) |
| `delta` 값 | 매번 조금씩 다르다 | **거의 일정** |
| 프레임이 떨어지면 | 호출 횟수도 줄어든다 | **횟수를 맞춰 따라잡는다** |
| 여기 둘 것 | 카메라·UI·시각 효과 | **이동·중력·충돌** |

**이동을 `_process` 에 두면 안 되는 이유 두 가지.**

1. **모니터마다 캐릭터 속도가 달라진다.** 144Hz 모니터에서는 초당 144번 움직이고
   60Hz 에서는 60번 움직인다.
2. **물리 서버와 어긋난다.** 충돌 판정은 물리 틱에 돌아가는데 이동을 다른 주기로 하면
   **떨림(지터)** 이나 **벽 뚫림(터널링)** 이 생긴다.

> 🛑 이 스킬의 **절대 규칙** — 물리 관련 코드는 `_physics_process` 에만 쓴다.

##### `delta` 는 무엇인가

**직전 호출로부터 흐른 시간(초)** 이다. `_physics_process` 에서는 기본 설정 기준
**항상 약 `0.01667`**(= 1 ÷ 60)이다.

`delta` 라는 이름은 **③ 내가 지은 것**이다. `dt`·`시간` 이어도 된다 —
**엔진은 첫 번째 인자에 값을 넣어 줄 뿐 이름은 보지 않는다.**

**왜 곱해야 하나** — `속도 × 시간 = 거리` 이기 때문이다.

```gdscript
velocity += get_gravity() * delta
#                           ↑ 이게 없으면 "1초에 9.8m/s 씩" 이 아니라
#                             "한 틱에 9.8m/s 씩" 빨라져 60배로 추락한다
```

`-> void` 는 **이 함수가 값을 돌려주지 않는다**는 표시다. 생략해도 되지만
적어 두면 에디터가 실수를 잡아 준다.

---

#### `is_on_floor()` — 언제 참이 되고, 언제 쓸 수 없나

```gdscript
if not is_on_floor():
	velocity += get_gravity() * delta
```

**"지금 바닥에 닿아 있는가"** 를 `true`/`false` 로 돌려준다.
`CharacterBody3D` 가 제공하는 함수다(① 엔진 이름).

##### ⚠️ 값이 갱신되는 시점이 중요하다

**`is_on_floor()` 는 스스로 검사하지 않는다.** `move_and_slide()` 가 실제로 몸을 밀어 보고
**그 결과를 기록해 둔 것을 읽을 뿐**이다.

```gdscript
func _physics_process(delta):
	if not is_on_floor():        # ← 이 시점의 값은 "지난 틱 move_and_slide() 의 결과"
		...
	move_and_slide()             # ← 여기서 비로소 갱신된다
```

그래서 이런 규칙이 나온다.

| 상황 | `is_on_floor()` 를 쓸 수 있나 |
|---|---|
| `_physics_process` 안, `move_and_slide()` 호출 후 | ✅ **가장 정확하다** |
| `_physics_process` 안, 호출 전 | ✅ 쓸 수 있다 — **한 틱 전 값**이라 실무상 문제없다 |
| `_ready()` 안 | 🛑 **항상 `false`.** 아직 한 번도 안 움직였다 |
| `_process` 안 | ⚠️ 물리 틱과 어긋나 값이 튄다 |
| **`move_and_slide()` 를 한 번도 안 부른 노드** | 🛑 **영원히 `false`** |

##### 🛑 "땅속으로 꺼져 떨어지는 경우"에는 쓸 수 없다

**답은 "쓸 수 없다"** 이다.

바닥에 콜리전이 없거나(§9 의 CSG 사슬 문제), 맵 밖으로 나갔거나, 아주 빠른 속도로
얇은 바닥을 뚫고 지나간 경우 — **캐릭터는 아무것도 안 닿은 채 계속 떨어진다.**
닿은 게 없으니 **`is_on_floor()` 는 계속 `false`** 이고, **"떨어지고 있다"와
"공중에서 점프 중이다"를 구분해 주지 않는다.**

**떨어지는 것을 감지하려면 `y` 좌표를 직접 본다.**

```gdscript
## 맵 아래로 이 값보다 내려가면 떨어진 것으로 본다.
const FALL_LIMIT_Y := -10.0
## 되살릴 위치.
const RESPAWN_POSITION := Vector3(0, 2, 0)

func _physics_process(delta: float) -> void:
	# … 이동 처리 …
	move_and_slide()

	if global_position.y < FALL_LIMIT_Y:
		global_position = RESPAWN_POSITION
		velocity = Vector3.ZERO        # 🛑 속도를 지우지 않으면 되살아나도 빠르게 떨어진다
```

**낙사·리스폰은 거의 모든 게임이 이 방식으로 처리한다.** 물리에 묻지 않고
**좌표를 직접 검사하는 것이 확실하고 싸다.**

> 💡 근본 원인을 먼저 고친다. 떨어지는 이유가 **콜리전이 없어서**라면
> 리스폰 코드는 증상만 가린다. §9 의 `Debug > Visible Collision Shapes` 로 확인한다.

##### 형제 함수들

| 함수 | 뜻 |
|---|---|
| `is_on_floor()` | 바닥(위를 향한 면)에 닿았나 |
| `is_on_wall()` | 벽(수직에 가까운 면)에 닿았나 |
| `is_on_ceiling()` | 천장에 닿았나 |
| `is_on_floor_only()` | **바닥에만** 닿았나 (벽에는 안 닿음) |

**바닥과 벽을 가르는 기준은 `floor_max_angle`** 이고 기본값은
**`0.7853982` 라디안 = 45도**다(doctool 확인). 45도보다 가파른 면은 벽으로 친다.

---

#### `velocity` — 이 값은 어디서 오는가

```gdscript
velocity += get_gravity() * delta
velocity.x = dir.x * SPEED
move_and_slide()
```

##### 정체

**`CharacterBody3D` 가 가진 프로퍼티**다(① 엔진 이름). 엔진에서 확인한 정의는 이렇다.

```
<member name="velocity" type="Vector3" default="Vector3(0, 0, 0)">
```

- 타입은 **`Vector3`** — 숫자 세 개(`x`, `y`, `z`)를 묶은 값
- 초기값은 **`(0, 0, 0)`** — 가만히 있음
- 뜻은 **"1초에 각 축으로 몇 미터 갈 것인가"**

##### 🛑 위치가 아니다 — 가장 흔한 오해

**`velocity` 는 "지금 어디 있는가"가 아니라 "어느 쪽으로 얼마나 빨리 가는가"다.**
위치는 **`position` / `global_position`** 이라는 **별개의 프로퍼티**다.

| | 단위 | 뜻 | 비유 |
|---|---|---|---|
| **`position`** | **m** (미터) | 지금 **어디 있는가** | 지도 위의 **점** |
| **`velocity`** | **m/s** (초당 미터) | 어느 쪽으로 **얼마나 빨리** | 그 점을 미는 **화살표** |

자동차로 치면 `position` 은 현재 위치, `velocity` 는 **속도계 + 방향**이다.
속도계가 60을 가리킨다고 차가 60km 지점에 있는 것은 아니다.

둘은 매 틱 `move_and_slide()` 안에서 이렇게 이어진다.

```
position += velocity × delta
```

##### 실측 — `velocity` 를 고정해 두면 `position` 만 변한다

`velocity` 를 `(0, 0, -5)` 로 **고정**하고 4틱 돌렸다.

| 틱 | `velocity` | `position.z` |
|---|---|---|
| 1 | `(0, 0, **-5.0**)` | **-0.08** |
| 2 | `(0, 0, **-5.0**)` | **-0.17** |
| 3 | `(0, 0, **-5.0**)` | **-0.25** |
| 4 | `(0, 0, **-5.0**)` | **-0.33** |

**`velocity` 는 하나도 변하지 않는데 `position` 은 계속 변한다.**
매 틱 `0.083m` 씩이고, 이는 `5.0 m/s × 1/60초` 다.
`velocity` 를 `0` 으로 되돌리면 `position` 이 `-0.33` 에서 **그대로 멈춘다**(실측).

##### 위치를 바꾸고 싶으면

`velocity` 가 아니라 **`global_position` 에 직접 대입**한다. **순간이동**한다.

```gdscript
global_position = Vector3(3, 1, 3)   # 즉시 그 자리로 (실측 확인)
velocity = Vector3.ZERO              # 남아 있던 속도도 지운다
```

낙사 리스폰이 이 방식이다. `velocity` 를 안 지우면 되살아난 직후에도
떨어지던 속도가 남아 있어 다시 빠르게 추락한다.

##### 🛑 좌표처럼 큰 값을 넣으면 날아간다

*"z 를 -100 으로 옮기고 싶다"* 는 뜻으로 `velocity.z = -100` 을 넣으면
**"1초에 100미터씩 북으로 가라"** 가 되어 총알처럼 날아간다.

| 틱 | `velocity.z` | `position.z` |
|---|---|---|
| 1 | `-100.0` | **-1.67** |
| 2 | `-100.0` | **-3.33** |
| 3 | `-100.0` | **-5.00** |

매 틱 `1.67m` — `100 m/s × 1/60초` 다(실측).

`extends CharacterBody3D` 를 했기 때문에 **선언하지 않고 그냥 쓸 수 있다.**
`var velocity` 를 따로 쓰지 않는 이유가 이것이다.

##### 🛑 이름을 바꿀 수 없는 이유

**`move_and_slide()` 가 이 이름의 프로퍼티를 읽어서 몸을 민다.**

```gdscript
my_speed = Vector3(5, 0, 0)   # 🛑 내가 만든 변수
move_and_slide()              # → velocity 는 그대로 (0,0,0) 이라 안 움직인다
```

**엔진과의 약속이므로 철자 하나도 바꿀 수 없다.** 반대로 말하면
**`velocity` 에 값을 넣는 것이 곧 "이렇게 움직여라"라고 지시하는 방법**이다.

##### `x` · `y` · `z` 는 어디서 오나

**`Vector3` 라는 타입이 가진 성분 이름**이다. 이것도 엔진이 정했다.

```gdscript
velocity.x    # 동서 (＋가 동쪽)
velocity.y    # 상하 (＋가 위)
velocity.z    # 남북 (－가 북 = 앞)
```

`Vector3` 는 어디에나 쓰인다 — `position`·`scale`·`dir` 전부 `Vector3` 이고
**전부 `.x`·`.y`·`.z` 로 접근한다.** 한 번 익히면 계속 쓴다.

##### 축을 나눠 다루는 이유

```gdscript
# ✅ 수평만 바꾸고 수직(중력)은 건드리지 않는다
velocity.x = dir.x * SPEED
velocity.z = dir.z * SPEED

# 🛑 통째로 대입하면 중력이 만든 y 가 지워진다
velocity = Vector3(dir.x * SPEED, 0, dir.z * SPEED)
```

**수평 이동은 입력이, 수직은 중력과 점프가 담당한다.** 셋을 따로 관리하면
서로 간섭하지 않는다. 통째로 대입하면 **공중에 뜬 채 영원히 안 떨어지는 캐릭터**가 된다.

##### `+=` 와 `=` 의 차이

```gdscript
velocity += get_gravity() * delta    # 더한다 → 떨어질수록 점점 빨라진다 (가속)
velocity.x = dir.x * SPEED           # 덮어쓴다 → 항상 일정한 속도 (등속)
```

중력은 **쌓여야** 자연스럽고(가속도), 걷기는 **일정해야** 조작감이 좋다.
그래서 하나는 `+=`, 하나는 `=` 다.

---

#### `get_gravity()`

```gdscript
velocity += get_gravity() * delta
```

**`PhysicsBody3D` 의 메서드**다(doctool 확인 — `Vector3` 를 돌려준다).
`CharacterBody3D` 가 `PhysicsBody3D` 를 상속하므로 그냥 쓸 수 있다.

`Project > Project Settings > Physics > 3D > Default Gravity` 값을 읽어 온다
(기본 `9.8`, 방향은 아래). **숫자를 코드에 박지 않는 이유**는 물속·저중력 구역처럼
중력이 달라지는 상황에서 그대로 따라가기 위해서다.

---

#### `Input` — 무엇인가

```gdscript
Input.is_action_just_pressed("ui_accept")
Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
```

**엔진이 항상 하나만 만들어 두는 전역 객체(싱글턴)** 다.
클래스 계층은 `Input` → `Object` 이고(doctool 확인), **어느 스크립트에서든
`Input.` 으로 바로 접근**할 수 있다. 만들 필요도, 참조를 넘겨받을 필요도 없다.

**하는 일은 하나다 — "지금 이 순간 무엇이 눌려 있는지"를 알려준다.**

| 자주 쓰는 함수 | 뜻 |
|---|---|
| `is_action_pressed("x")` | **누르고 있는 동안 계속** `true` |
| `is_action_just_pressed("x")` | **누른 그 순간 한 번만** `true` |
| `is_action_just_released("x")` | **뗀 그 순간 한 번만** `true` |
| `get_axis(음, 양)` | 두 액션을 `-1 ~ +1` 하나의 값으로 |
| `get_vector(좌, 우, 상, 하)` | 네 액션을 `Vector2` 로 (**정규화 포함**) |

##### `is_action_pressed` 와 `just_pressed` 를 헷갈리면 안 된다

```gdscript
if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
	velocity.y = JUMP_VELOCITY
```

`just_` 를 빼면 **스페이스를 누르고 있는 내내 매 틱 점프 속도가 다시 꽂혀
캐릭터가 하늘로 날아간다.** 점프처럼 **한 번만 일어나야 하는 일**에는 반드시 `just_` 를 쓴다.

##### 폴링 방식이다

`Input` 은 **"지금 상태를 물어보는"** 방식이다(폴링). 반대로 `_input(event)` 는
**"입력이 들어오면 알려주는"** 방식이다(이벤트).

이동처럼 **매 틱 상태를 알아야 하는 것**은 `Input` 이 맞고,
채팅 입력처럼 **들어온 순간만 처리하면 되는 것**은 `_input` 이 맞다.

---

#### `"ui_accept"` · `"ui_left"` — 액션이란 무엇인가

##### 키 이름이 아니라 **액션 이름**이다

```gdscript
Input.is_action_just_pressed("ui_accept")
#                             ↑ 스페이스 키가 아니라 "확인" 이라는 이름의 액션
```

**코드는 어떤 키인지 모른다.** `"ui_accept"` 라는 **이름**만 안다.
그 이름에 어떤 키가 묶여 있는지는 **InputMap** 이 관리한다.

```
   키보드 Space ┐
   Enter        ├→  "ui_accept"  →  코드는 이 이름만 본다
   키패드 Enter ┘
```

**이 구조 덕분에** 나중에 게임패드를 붙이거나 키를 바꿀 때
**코드를 한 글자도 고치지 않아도 된다.** 리바인딩 기능도 이래서 만들 수 있다.

##### `ui_` 로 시작하는 것은 엔진이 미리 만들어 둔 것이다

Godot 은 새 프로젝트에 **70개가 넘는 `ui_*` 액션**을 기본 등록해 둔다.
그래서 설정을 하나도 안 해도 화살표와 스페이스가 바로 동작한다.

**이 예제가 쓰는 것들의 실제 키 바인딩**(엔진 소스에서 확인):

| 액션 | 묶인 입력 |
|---|---|
| `ui_up` | **↑** · 게임패드 D-Pad Up |
| `ui_down` | **↓** · 게임패드 D-Pad Down |
| `ui_left` | **←** · 게임패드 D-Pad Left |
| `ui_right` | **→** · 게임패드 D-Pad Right |
| `ui_accept` | **Enter** · **키패드 Enter** · **Space** |

> ⚠️ `ui_*` 는 원래 **UI 조작용**이다. 버튼 포커스 이동 등에도 쓰이므로,
> 본격적인 게임에서는 `move_left`·`jump` 처럼 **내 액션을 따로 만드는 것**이 정석이다.
> 연습 단계에서는 설정 없이 바로 되는 편이 낫기 때문에 그대로 쓴다.

##### 내 액션을 만드는 법

`Project > Project Settings > Input Map` 탭에서:

1. 위 칸에 이름을 넣고 **`Add`** (예: `move_forward`)
2. 오른쪽 **`+`** 를 눌러 키를 등록 (W 키, 게임패드 스틱 등)
3. 코드에서 `Input.get_vector("move_left", "move_right", "move_forward", "move_back")`

**이름은 ② 종류다 — 내가 정하지만 양쪽 철자가 같아야 한다.**
`Project Settings` 에 `move_forward` 로 넣고 코드에 `move_forwrad` 라고 쓰면
**실행 중에 오류가 난다**(등록되지 않은 액션).

> 💡 키를 등록할 때 **`Physical Keycode`** 를 쓴다. 자판 배열이 달라도(QWERTY/AZERTY)
> **같은 자리**를 가리킨다 (→ [input-ui.md](../input-ui.md)).

---

#### `dir` — ③ 순수하게 내가 지은 이름

```gdscript
var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
var dir := Vector3(input.x, 0.0, input.y)
```

**`input` 과 `dir` 은 둘 다 내가 만든 지역 변수다.** 엔진은 이 이름을 모른다.
`방향`·`move_direction`·`d` 로 바꿔도 **완전히 똑같이 동작한다.**
(`direction` 의 줄임으로 쓴 관습적인 이름일 뿐이다.)

| 변수 | 타입 | 담긴 것 |
|---|---|---|
| `input` | **`Vector2`** | 화면 기준 방향 — `x`(좌우) · `y`(상하) |
| `dir` | **`Vector3`** | 월드 기준 방향 — `x`(동서) · `y`(상하) · `z`(남북) |

`Vector2` 를 `Vector3` 로 옮기면서 **축이 하나 늘어난다.** 그래서 가운데에 `0.0` 이 들어간다.

```gdscript
Vector3( input.x , 0.0 , input.y )
#          ↓        ↓       ↓
#          x        y       z
#        동서    상하없음   남북
```

**`dir.y = 0` 인 이유** — 위아래 이동은 **중력과 점프가 담당**한다.
여기서 값을 넣으면 걸어다니다 하늘로 뜬다.

**`dir` 의 길이는 항상 0 또는 1 이다.** `get_vector()` 가 정규화해 주기 때문이고,
그래서 `dir * SPEED` 가 **정확히 `SPEED` m/s** 가 된다 (실측은 바로 아래 ⌨ 절).

##### `dir.is_zero_approx()` 가 왜 "이동 입력이 없는 경우"가 되나

**이 함수는 키를 전혀 모른다.** 묻는 것은 오직 **"`dir` 이 `(0,0,0)` 인가"** 뿐이다.
그런데 `dir` 은 바로 위에서 **입력으로부터 만들어진 값**이라, 값이 0 이라는 것이
곧 **"갈 방향이 없다"** 는 뜻이 된다.

```
키를 안 누름  →  get_vector() = (0, 0)   →  dir = (0, 0, 0)   →  is_zero_approx() = true
↑ 를 누름     →  get_vector() = (0, -1)  →  dir = (0, 0, -1)  →  is_zero_approx() = false
```

⚠️ **정확히는 "키를 안 누른 경우"가 아니라 "이동 방향이 없는 경우"다.**
반대 방향 키를 동시에 누르면 **서로 상쇄되어 `dir` 이 0 이 된다**(실측).

| 누른 키 | `input` | `dir` | `is_zero_approx()` |
|---|---|---|---|
| 없음 | `(0.00, 0.00)` | `(0, 0, 0)` | **`true`** |
| ↑ | `(0.00, -1.00)` | `(0, 0, -1)` | `false` |
| → | `(1.00, 0.00)` | `(1, 0, 0)` | `false` |
| ↑ + → | `(0.71, -0.71)` | `(0.71, 0, -0.71)` | `false` (길이 1.0) |
| **← + →** | `(0.00, 0.00)` | `(0, 0, 0)` | **`true`** |
| **↑ + ↓** | `(0.00, 0.00)` | `(0, 0, 0)` | **`true`** |
| **네 방향 전부** | `(0.00, 0.00)` | `(0, 0, 0)` | **`true`** |

**양쪽으로 동시에 밀면 안 움직이는 것이 맞으므로 의도된 동작이다.**

##### 왜 `== Vector3.ZERO` 를 쓰지 않나

`is_zero_approx()` 는 **"정확히 0"이 아니라 "거의 0"** 을 본다.
실측한 판정 경계는 **`0.00001`**(`CMP_EPSILON`)이다.

| 값 | `is_zero_approx()` | `== Vector3.ZERO` |
|---|---|---|
| `Vector3(0.00001, 0, 0)` | `false` | `false` |
| **`Vector3(0.000001, 0, 0)`** | **`true`** | **`false`** ← 갈린다 |

**키보드만 쓰면 값이 정확히 0 이라 둘의 결과가 같다**(위 표에서 확인).
차이가 나는 것은 **게임패드 아날로그 스틱**이다. 스틱은 손을 떼도 미세한 값이 남아
정확히 0 으로 돌아오지 않는 경우가 있고, 그때 `== Vector3.ZERO` 는 `false` 가 되어
**손을 뗐는데 계속 걷는** 상태가 된다.

> 🔑 **부동소수점을 다룰 때는 `==` 대신 `approx` 계열을 쓴다.**
> `is_zero_approx()` · `is_equal_approx()` 가 있고, 이는 GDScript 전반의 원칙이다.

`var` 와 `const` 의 차이는 **바뀔 수 있느냐**다. `dir` 은 매 틱 새로 계산되므로 `var` 다.

---

#### `move_toward(현재, 목표, 최대변화량)`

```gdscript
velocity.x = move_toward(velocity.x, 0.0, SPEED)
```

**현재 값을 목표 쪽으로 정해진 양만큼만 움직인다.** GDScript 의 내장 함수다.

```
move_toward(5.0, 0.0, 5.0)  →  0.0    (한 번에 도착)
move_toward(5.0, 0.0, 1.0)  →  4.0    (조금씩)
move_toward(0.5, 0.0, 5.0)  →  0.0    (목표를 지나치지 않는다)
```

**목표를 지나치지 않는 것**이 핵심이다. 그냥 빼면 `-4.5` 처럼 반대로 튀어 버린다.

키를 뗐을 때 이걸 쓰는 이유는 **자연스럽게 멈추기 위해서**다.
세 번째 인자를 작게 주면(`SPEED * delta * 3.0`) **얼음판처럼 미끄러진다.**

---

#### `look_at(대상위치, 위쪽방향)`

```gdscript
_mesh.look_at(_mesh.global_position + dir, Vector3.UP)
```

**`Node3D` 의 메서드로, 자기 `-Z`(앞)가 대상을 향하도록 회전시킨다.**

`대상위치` 에 **`현재위치 + 방향`** 을 넣는 것이 요령이다 — 그러면
"그 방향으로 조금 간 지점"을 바라보게 되어 **결국 그 방향을 향한다.**

**왜 `rotation.y` 대신 이걸 쓰나** — 오일러 각(`rotation`)은 짐벌락과 회전 순서
문제가 있어 3D 회전에는 쓰지 않는 것이 이 스킬의 **절대 규칙**이다.

🛑 **두 번째 인자(up)와 방향이 나란하면 오류가 난다.** 여기서는 `dir` 이 항상
수평(XZ)이라 `Vector3.UP` 과 나란해질 일이 없어 안전하다.

---

#### `move_and_slide()`

```gdscript
move_and_slide()
```

**`velocity` 를 읽어 실제로 몸을 밀고, 부딪히면 멈추고, 벽에서는 미끄러지게 한다.**
`CharacterBody3D` 의 핵심 메서드다.

이 한 줄이 하는 일:

| | 하는 일 |
|---|---|
| ① | `velocity × delta` 만큼 이동을 **시도**한다 |
| ② | 부딪히면 멈추고, **벽을 따라 미끄러진다**(slide) |
| ③ | **`velocity` 를 실제 결과로 고쳐 쓴다** — 벽에 막히면 그 축이 `0` 이 된다 |
| ④ | `is_on_floor()`·`is_on_wall()`·`is_on_ceiling()` 의 값을 **갱신한다** |

③ 때문에 **벽에 붙어서 계속 밀면 `velocity` 가 `0` 으로 읽힌다.** 정상이다
(§9 의 실측에서 실제로 그렇게 나왔다).

🛑 **Godot 3 에서는 `move_and_slide(velocity)` 처럼 인자를 넘겼다.**
Godot 4 에서는 **인자를 받지 않는다.** 오래된 강좌를 따라 하다 여기서 오류가 난다.

**`delta` 를 넘기지 않아도 되는 이유** — 엔진이 물리 틱 간격을 이미 알고 있어서
내부에서 곱한다. 그래서 `velocity` 는 **"1초당" 이동량**으로 적으면 된다.

---

#### `global_position` — 월드 기준 절대 좌표

```gdscript
_mesh.look_at(_mesh.global_position + dir, Vector3.UP)
_camera.global_position = _player.global_position + CAMERA_OFFSET
```

**`Node3D` 가 가진 프로퍼티**다(① 엔진 이름). 타입은 **`Vector3`** 이고
**"월드 원점 `(0,0,0)` 에서 얼마나 떨어져 있는가"** 를 담는다.

##### `position` 과 무엇이 다른가

**기준점이 다르다.** 이것 하나뿐이지만 결과는 크게 갈린다.

| | 기준 | 뜻 |
|---|---|---|
| `position` | **부모 노드** | "부모로부터 얼마나 떨어져 있나" (로컬 좌표) |
| `global_position` | **월드 원점** | "월드에서 실제로 어디 있나" (전역 좌표) |

```
Main                     (월드 원점 0,0,0)
└─ Player                position = (10, 0, 0)   global_position = (10, 0, 0)
   └─ CapsuleMesh        position = ( 0, 1, 0)   global_position = (10, 1, 0)
      └─ NoseMesh        position = ( 0, 0,-0.6) global_position = (10, 1,-0.6)
```

**자식의 `position` 은 부모 위치를 모른다.** `NoseMesh` 의 `position` 은
`(0, 0, -0.6)` 이지만 실제로 월드에서는 `(10, 1, -0.6)` 에 있다.
**부모가 움직이면 `global_position` 은 따라 바뀌고 `position` 은 그대로다.**

##### 왜 이 예제는 `global_position` 을 쓰나

`look_at()` 은 **월드 좌표**를 받는다. 여기에 로컬 `position` 을 넣으면
엉뚱한 곳을 바라본다.

```gdscript
_mesh.look_at(_mesh.global_position + dir, Vector3.UP)   # ✅ 월드 기준
_mesh.look_at(_mesh.position + dir, Vector3.UP)          # 🛑 부모가 원점이 아니면 틀린다
```

카메라 쪽도 마찬가지다. `Camera3D` 와 `Player` 가 지금은 **둘 다 `Main` 의 자식**이라
우연히 결과가 같지만, **플레이어를 다른 노드 아래로 옮기는 순간 어긋난다.**

> 🔑 **판단 기준** — 서로 **다른 부모**를 가진 노드의 위치를 비교하거나 더할 때는
> **반드시 `global_position`** 을 쓴다. 같은 부모 안에서만 다룰 때는 `position` 이 편하다.

##### 형제 프로퍼티들

| 로컬 (부모 기준) | 전역 (월드 기준) |
|---|---|
| `position` | `global_position` |
| `rotation` | `global_rotation` |
| `transform` | `global_transform` |
| `basis` | `global_basis` |

**대입도 된다.** `global_position` 에 값을 넣으면 엔진이 부모 변환을 역산해
`position` 을 알아서 맞춰 준다. `main.gd` 의 카메라 추적이 그 방식이다.

> 💡 2D 에서는 같은 이름이 **`Vector2`** 다. 개념은 완전히 같다.

---

#### `_mesh` — 이름 앞의 밑줄은 무슨 뜻인가

```gdscript
@onready var _mesh: Node3D = $Mesh
```

**밑줄은 문법이 아니라 관습이다.** 떼어도 코드는 똑같이 동작한다.
`var mesh` 로 써도, `var 몸통` 으로 써도 된다.

##### 뜻은 "이 스크립트 안에서만 쓰는 것"

다른 스크립트에서 `player._mesh` 처럼 건드리지 말라는 **사람끼리의 표시**다.
GDScript 에는 `private` 키워드가 없어서 **이름으로 약속**한다.

**엔진은 이 표시를 강제하지 않는다.** 밖에서 `player._mesh` 라고 쓰면 그냥 동작한다.
그래도 붙이는 이유는 **코드를 읽는 사람이 "이건 내부용이구나" 하고 바로 알기 때문**이다.

##### 🔑 밑줄이 붙는 자리가 **세 군데**인데 뜻이 전부 다르다

**겉모습이 같아서 가장 헷갈리는 지점이다.**

| 코드 | 밑줄의 뜻 | 종류 |
|---|---|---|
| `var _mesh` | **"내부용 변수"** — 사람끼리의 관습 | ③ 내가 지은 이름 |
| `func _physics_process()` | **"엔진이 부르는 콜백"** — 엔진이 정한 이름 | ① 엔진 이름 |
| `func _process(_delta)` | **"이 인자를 안 쓴다"** — 경고를 끄는 표시 | ③ 내가 지은 이름 |

- 첫째는 **떼어도 된다**(그냥 관습).
- 둘째는 **떼면 안 된다**(떼면 엔진이 못 찾아 영원히 안 불린다).
- 셋째는 **떼면 경고가 뜬다**(동작에는 지장 없다).

##### 밑줄을 붙이는 실용적인 이유 하나 더

**엔진이 이미 쓰고 있는 이름과 부딪히지 않는다.**

```gdscript
var position = $Mesh     # 🛑 Node3D 의 position 을 가려 버린다
var _position = $Mesh    # ✅ 안전
```

🛑 이 스킬의 **절대 규칙** — `name`·`position`·`rotation`·`scale`·`visible`·`seed`
같은 엔진 멤버 이름을 변수명으로 쓰지 않는다. 가려 버리면 **예측 불가능한 동작**이 된다.
밑줄을 습관적으로 붙이면 이 사고를 자연히 피한다.

##### `_mesh` 와 `$Mesh` 는 다른 것이다

**같은 줄에 나란히 있어서 헷갈리기 쉽다.**

```gdscript
@onready var _mesh: Node3D = $Mesh
#             ↑              ↑
#        ③ 내가 지은        ② 씬의 노드 이름
#        변수 이름          — 씬과 철자가 같아야 한다
```

**왼쪽은 마음대로 바꿔도 되고, 오른쪽은 씬을 따라가야 한다.**
노드 이름을 `CapsuleMesh` 로 바꿨다면 **오른쪽만** `$CapsuleMesh` 로 고치면 된다.
왼쪽 `_mesh` 는 그대로 둬도 아무 문제 없다.

---

### ⌨ 화살표 키가 이동으로 바뀌기까지 — 4단계

키를 누르면 캐릭터가 움직이기까지 **네 번 모습을 바꾼다.** 한 단계씩 따라간다.

```
  ①  ↑ 키          물리적인 키 입력
       ↓
  ②  "ui_up"       InputMap 액션 이름
       ↓           Input.get_vector()
  ③  Vector2(0, -1)   화면 기준 방향
       ↓           Vector3(input.x, 0, input.y)
  ④  Vector3(0, 0, -1)  월드 기준 방향  →  × SPEED  →  velocity  →  move_and_slide()
```

#### ① 키 → 액션 이름

`ui_left` · `ui_right` · `ui_up` · `ui_down` · `ui_accept` 는 **Godot 이 새 프로젝트에
기본으로 넣어 두는 InputMap 액션**이고, 각각 화살표 키와 스페이스에 묶여 있다.
그래서 설정을 하나도 안 해도 바로 동작한다.

**코드는 키를 모른다.** `"ui_up"` 이라는 이름만 안다. 그래서 나중에 W 키를 추가하거나
게임패드를 붙여도 **코드는 한 글자도 바뀌지 않는다.**

#### ② 액션 → `Vector2`

```gdscript
var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
```

인자 순서는 **`(negative_x, positive_x, negative_y, positive_y)`** 다.

| 자리 | 넣은 액션 | 눌렀을 때 |
|---|---|---|
| `negative_x` | `ui_left` | `x = -1` |
| `positive_x` | `ui_right` | `x = +1` |
| **`negative_y`** | **`ui_up`** | **`y = -1`** |
| `positive_y` | `ui_down` | `y = +1` |

> 🔑 **`ui_up` 이 "negative" 자리인 것이 헷갈리는 지점**이다.
> 화면 좌표계는 **위쪽이 음수**다(2D 의 오랜 관습 — 화면 맨 위가 `y=0`, 아래로 갈수록 증가).
> 위로 가려면 `y` 가 줄어야 한다.

#### ③ 화면 방향 → 월드 방향

```gdscript
var dir := Vector3(input.x, 0.0, input.y)
```

`Vector2` 의 두 성분을 `Vector3` 의 **X 와 Z** 에 꽂는다. `y` 는 `0` 이다 —
**위아래 이동은 중력과 점프가 따로 담당**하므로 여기서 건드리면 안 된다.

**왜 `input.y` 가 월드 `z` 로 그대로 들어가도 되나** — §3 의 방향표를 다시 보면
**`-Z` 가 앞(북)** 이고, 카메라는 **yaw 0 으로 `-Z` 를 향해** 내려다보고 있다.
그래서 **화면 위쪽 = 월드 `-Z`** 다.

```
↑ 키  →  input.y = -1  →  dir.z = -1  →  월드 -Z  →  화면 위쪽
        (화면 위 = 음수)     (앞 = 음수)         두 규약이 맞아떨어진다
```

> 🛑 **이건 카메라 yaw 가 0 이라서 성립한다.**
> 카메라를 좌우로 돌리면 "화면 위쪽"과 "월드 `-Z`" 가 어긋나고,
> 그때는 **`transform.basis` 로 카메라 기준 변환**이 필요해진다
> (→ [basics/09-controller.md](../basics/09-controller.md) §9.12). 라리엔 3D 는 **yaw 를 고정**하므로 이 변환이
> 영원히 필요 없다 — 카메라를 고정해서 얻는 이득 중 하나다.

#### ④ 방향 → 속도 → 실제 이동

```gdscript
velocity.x = dir.x * SPEED     # dir 은 길이 1 이므로, 곱하면 그대로 m/s 가 된다
velocity.z = dir.z * SPEED
move_and_slide()               # 엔진이 velocity 만큼 밀어 보고 충돌을 처리한다
```

`velocity` 는 **1초에 몇 미터 갈 것인가**를 담는 값이다. `SPEED = 5.0` 이므로
`velocity.z = -5.0` 은 **1초에 북쪽으로 5m** 를 뜻한다.

#### 키별 전체 대응표

| 누른 키 | `input` (Vector2) | `dir` (Vector3) | `velocity` | 화면에서 |
|---|---|---|---|---|
| ↑ | `(0, -1)` | `(0, 0, -1)` | `z = -5.0` | 위로 |
| ↓ | `(0, +1)` | `(0, 0, +1)` | `z = +5.0` | 아래로 |
| ← | `(-1, 0)` | `(-1, 0, 0)` | `x = -5.0` | 왼쪽으로 |
| → | `(+1, 0)` | `(+1, 0, 0)` | `x = +5.0` | 오른쪽으로 |
| ↑ + → | `(0.707, -0.707)` | `(0.707, 0, -0.707)` | `(3.54, -3.54)` | 오른쪽 위 대각선 |
| 아무것도 | `(0, 0)` | `(0, 0, 0)` | `move_toward` 로 0 에 수렴 | 멈춤 |

#### 실측 — 대각선도 정확히 같은 속도다

실제로 실행해서 잰 값이다.

| 입력 | `velocity (x, z)` | **속력** | 1초 이동 거리 |
|---|---|---|---|
| ↓ | `(0.00, 5.00)` | **5.000 m/s** | 5.000 m |
| ← | `(-5.00, 0.00)` | **5.000 m/s** | 5.000 m |
| → | `(5.00, 0.00)` | **5.000 m/s** | 5.000 m |
| **↑ + → (대각선)** | `(3.54, -3.54)` | **5.000 m/s** | **5.000 m** |

`3.54` 는 `5 ÷ √2 = 3.5355…` 다. **`Input.get_vector()` 가 대각선을 정규화**하기 때문에
속력이 정확히 유지된다.

**손으로 조합하면 이렇게 안 된다.**

```gdscript
# 🛑 이렇게 하면 대각선이 √2 배(≈1.41배) 빨라진다
var x := Input.get_axis("ui_left", "ui_right")
var z := Input.get_axis("ui_up", "ui_down")
var dir := Vector3(x, 0, z)          # ↑+→ 이면 길이가 √2 = 1.414
```

`get_vector()` 는 **정규화와 데드존 처리를 함께** 해 준다. 그래서 이것을 쓴다.

#### `velocity.x` 와 `.z` 만 대입하는 이유

```gdscript
velocity = Vector3(dir.x * SPEED, 0, dir.z * SPEED)   # 🛑 이렇게 하면 안 된다
```

`velocity` 를 **통째로 대입하면** 바로 위에서 중력이 더해 놓은 `velocity.y` 가
**0 으로 지워진다.** 결과는 **공중에 뜬 채 절대 안 떨어지는 캐릭터**다.

수평은 `.x`·`.z`, 수직은 `.y` — **각자 따로 관리한다.**

#### 키를 뗐을 때

```gdscript
velocity.x = move_toward(velocity.x, 0.0, SPEED)
```

`move_toward(현재값, 목표값, 최대변화량)` 은 현재 값을 목표 쪽으로 **정해진 양만큼만**
움직인다. 여기서는 한 물리 틱에 `SPEED` 만큼 줄이므로 **거의 즉시 멈춘다.**

미끄러지는 느낌을 원하면 세 번째 인자를 작게 준다 — `SPEED * delta * 3.0` 처럼.

#### 벽에 닿으면

`move_and_slide()` 는 부딪히면 멈추고, 벽에는 **미끄러지게(slide)** 해 준다.
실측에서 **벽에 붙은 채 키를 누르고 있으면 `velocity` 가 `0` 으로 나온다** —
엔진이 "더 못 간다"고 판단해 그 방향 속도를 지운 것이다. 정상 동작이다.

---


---

### ⏱ 한 틱 동안 무슨 일이 일어나는가 — 전체 흐름

요소를 하나씩 봤으니 이제 **위에서 아래로 흐르는 순서**를 본다.
`_physics_process` 는 **1초에 60번** 이 다섯 단계를 반복한다.

```gdscript
func _physics_process(delta: float) -> void:
	# ┌── ① 중력 ──────────────────────────────────────────
	if not is_on_floor():
		velocity += get_gravity() * delta

	# ├── ② 점프 ──────────────────────────────────────────
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY

	# ├── ③ 입력을 방향으로 ────────────────────────────────
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var dir := Vector3(input.x, 0.0, input.y)

	# ├── ④ 방향을 수평 속도로 ──────────────────────────────
	if dir.is_zero_approx():
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
	else:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		_mesh.look_at(_mesh.global_position + dir, Vector3.UP)

	# └── ⑤ 실제로 움직인다 ────────────────────────────────
	move_and_slide()
```

| 단계 | 하는 일 | 건드리는 축 |
|---|---|---|
| ① 중력 | 공중이면 아래로 당긴다 | **`velocity.y`** |
| ② 점프 | 바닥에서 스페이스를 누른 순간 위로 튕긴다 | **`velocity.y`** |
| ③ 입력 | 키 → `Vector2` → `Vector3` 방향 | (읽기만) |
| ④ 수평 속도 | 방향 × 속도, 그리고 몸통 회전 | **`velocity.x`·`.z`** |
| ⑤ 이동 | 실제로 밀고, 충돌 처리하고, 상태 갱신 | **전부** |

**①②는 `y` 만, ④는 `x`·`z` 만 건드린다.** 서로 다른 축을 맡고 있어 간섭하지 않는다.
그래서 순서를 신경 쓰지 않아도 되고, 이것이 **축을 나눠 다루는 이유**다.

#### 🛑 순서를 바꾸면 안 되는 곳은 딱 하나 — `move_and_slide()` 는 **맨 마지막**

```gdscript
move_and_slide()              # 🛑 이렇게 먼저 부르면
velocity.x = dir.x * SPEED    #    이 값은 다음 틱에나 반영된다
```

`move_and_slide()` 는 **그 시점의 `velocity` 를 읽어** 몸을 민다.
**모든 속도 계산이 끝난 뒤**에 불러야 그 틱에 반영된다.

나머지 ①~④ 는 서로 순서를 바꿔도 결과가 같다. 다만 **읽기 좋은 순서**로 두는 것이
관습이다 — 수직(중력·점프) 먼저, 수평(입력·이동) 나중.

#### 실측 — 시나리오 세 가지

같은 코드가 상황에 따라 어떻게 다르게 흐르는지, 틱마다 값을 찍었다.

**A. 공중에서 떨어지는 중** (키를 안 누름)

| 틱 | `is_on_floor()` | `velocity` | `position.y` |
|---|---|---|---|
| 1 | `false` | `(0.00, **-0.16**, 0.00)` | 5.00 |
| 2 | `false` | `(0.00, **-0.33**, 0.00)` | 4.99 |
| 3 | `false` | `(0.00, **-0.49**, 0.00)` | 4.98 |
| 4 | `false` | `(0.00, **-0.65**, 0.00)` | 4.97 |

**`velocity.y` 가 매 틱 `0.163` 씩 쌓인다.** `9.8 × 0.0167 = 0.163` 이다 —
①의 `+=` 가 **가속도**를 만들고 있다. 떨어질수록 빨라진다.

**B. 바닥에 서서 ↑ 로 걷는 중**

| 틱 | `is_on_floor()` | `velocity` | `position.z` |
|---|---|---|---|
| 1 | `true` | `(0.00, 0.00, 0.00)` | 0.00 |
| 2 | `true` | `(0.00, 0.00, **-5.00**)` | -0.08 |
| 3 | `true` | `(0.00, 0.00, **-5.00**)` | -0.17 |
| 4 | `true` | `(0.00, 0.00, **-5.00**)` | -0.25 |

**`velocity.z` 가 `-5.00` 으로 일정하다.** ④의 `=` 가 **등속**을 만든다.
`velocity.y` 는 `0` 이다 — 바닥에 닿아 있어 ①이 실행되지 않는다.
위치는 매 틱 `0.083` 씩 움직인다(`5.0 × 0.0167`).

**C. 벽에 붙어서 계속 ↑ 를 누르는 중**

| 틱 | `is_on_floor()` | `velocity` | `position.z` |
|---|---|---|---|
| 1 | `true` | `(0.00, 0.00, **0.00**)` | -5.00 |
| 2 | `true` | `(0.00, 0.00, **0.00**)` | -5.00 |
| 3 | `true` | `(0.00, 0.00, **0.00**)` | -5.00 |
| 4 | `true` | `(0.00, 0.00, **0.00**)` | -5.00 |

**키를 계속 누르고 있는데 `velocity` 가 `0` 이다.**
④에서 매 틱 `-5.0` 을 넣지만, ⑤의 `move_and_slide()` 가 **벽에 막혀 더 못 간다고
판단하고 그 축의 속도를 지운다.** 위치도 그대로다.

> 🔑 **`velocity` 는 "내가 원하는 속도"를 쓰는 칸이자 엔진이 "실제 결과"를 돌려주는 칸이다.**
> 매 틱 내가 쓰고, `move_and_slide()` 가 고쳐 쓴다. C 가 그 증거다.

#### 두 스크립트는 한 프레임 안에서 어떻게 만나나

```
   물리 틱 (60Hz 고정)              렌더 프레임 (주사율)
   ─────────────────────           ─────────────────────
   player.gd::_physics_process
     → velocity 계산
     → move_and_slide()
     → 플레이어 위치가 바뀐다
                          ─────→   main.gd::_process
                                     → 바뀐 위치를 읽어 카메라를 옮긴다
                                     → 화면에 그린다
```

**`player.gd` 가 위치를 바꾸고, `main.gd` 가 그것을 읽는다.** 둘은 직접 대화하지 않고
**플레이어의 `global_position` 이라는 공통 지점**을 통해 이어진다.

두 함수의 호출 횟수는 다르다 — 144Hz 모니터라면 `_process` 가 `_physics_process` 보다
**2.4배 자주** 불린다. 물리 틱 사이에 카메라만 여러 번 갱신되는 것이고,
**같은 위치를 다시 읽을 뿐이라 문제가 없다.**

반대로 **이동을 `_process` 에 뒀다면** 모니터마다 초당 이동 횟수가 달라져
**속도 자체가 달라진다.** 이것이 ①~⑤ 를 `_physics_process` 에 두는 이유다.

---

**왜 몸통(`_mesh`)만 돌리고 `Player` 본체는 안 돌리나** — 본체를 돌리면
`CollisionShape3D` 도 같이 돌고, 이동 방향 계산에도 영향을 준다. 보이는 것만 돌리는 편이
단순하고 예측 가능하다.
