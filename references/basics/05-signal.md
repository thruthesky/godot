# 5. 시그널(Signal) — 노드끼리 대화하는 방법

> **[Godot 기본](../basics.md)** 의 파트 **6 / 11**
> [← 4. 스크립트 — 노드에 붙는 것](04-script.md) · [6. 에디터 화면 — 어디에 무엇이 있나 →](06-editor-screen.md)

**노드가 어떤 사건(event)이 일어났음을 외부에 알리는 메커니즘**이다.

핵심은 **알리는 쪽이 받는 쪽을 모른다**는 것이다. 한 노드가 다른 노드의 함수를
직접 호출하지 않고 "이런 일이 있었다"고 방송만 하면, 관심 있는 노드들이 각자
받아서 처리한다. 이렇게 하면 **결합도(coupling)가 낮아진다.**

> 디자인 패턴의 **관찰자(Observer) 패턴**을 언어·엔진 차원에서 구현한 것이다.

## 목차

| 절 | 내용 |
|---|---|
| [·](#왜-필요한가--직접-호출과-비교) | 왜 필요한가 — 직접 호출과 비교 |
| [·](#시그널의-두-종류) | 시그널의 두 종류 |
| [·](#선언--signal-키워드) | 선언 — `signal` 키워드 |
| [·](#-godot-4-에서-시그널은-값이다) | 🔑 Godot 4 에서 시그널은 "값"이다 |
| [·](#발신--emit) | 발신 — `emit()` |
| [·](#받기--connect) | 받기 — `connect()` |
| [·](#이-함수를-뭐라고-부르는가) | 이 함수를 뭐라고 부르는가 |
| [·](#실제-동작--엔진에서-확인한-것-472) | 실제 동작 — 엔진에서 확인한 것 (4.7.2) |
| [·](#await--시그널이-올-때까지-기다리기) | `await` — 시그널이 올 때까지 기다리기 |
| [·](#방향-규칙--통지는-위로-명령은-아래로) | 방향 규칙 — 통지는 위로, 명령은 아래로 |
| [·](#더-깊이) | 더 깊이 |

---

## 왜 필요한가 — 직접 호출과 비교

적이 죽었을 때 UI 점수를 올리고, 사운드를 재생하고, 스포너에 알려야 한다고 하자.

```gdscript
# 🛑 직접 호출 — 적이 UI·사운드·스포너를 전부 알아야 한다
func die() -> void:
    get_node("/root/Main/UI/ScoreLabel").add_score(10)
    get_node("/root/Main/AudioManager").play("death")
    get_node("/root/Main/Spawner").on_enemy_died(self)
    queue_free()
```

이 코드의 문제는 **적이 씬 구조 전체를 알고 있다**는 것이다. UI 경로가 바뀌면
적 코드가 깨지고, 적을 다른 씬에서 재사용할 수 없으며, 적만 따로 테스트할 수 없다.

```gdscript
# ✅ 시그널 — 적은 "죽었다"는 사실만 알린다
signal died(score: int)

func die() -> void:
    died.emit(10)
    queue_free()
```

**적은 누가 듣는지 모른다.** 듣는 쪽이 알아서 연결한다. 수신자가 늘어나거나
줄어들어도 **적 코드는 한 글자도 바뀌지 않는다.**

## 시그널의 두 종류

| 종류 | 무엇 | 예 |
|---|---|---|
| **엔진(내장) 시그널** | 엔진이 이미 정의해 둔 것 | `Button.pressed`, `Area3D.body_entered`, `Node.ready` |
| **커스텀 시그널** | 내가 스크립트에서 `signal` 키워드로 선언한 것 | `signal died(score: int)` |

**둘은 사용 방법이 완전히 같다.** 선언만 엔진이 했느냐 내가 했느냐의 차이다.

> **엔진에서 확인 (4.7.2)** — 내장 시그널은 상속 계층을 따라 쌓인다.
> `ClassDB.class_get_signal_list()` 로 센 결과다.
>
> | 클래스 | 개수 | 그 클래스에서 새로 생긴 것 |
> |---|---|---|
> | `Node` | 13 | `ready` `renamed` `tree_entered` `tree_exiting` `tree_exited` `child_entered_tree` … |
> | `Area3D` | 25 | `body_entered` `body_exited` `area_entered` `area_exited` `input_event` `mouse_entered` … |
> | `BaseButton` | 33 | `pressed` `button_up` `button_down` `toggled` |
>
> **즉 버튼 하나에 33개의 시그널이 이미 달려 있다.** 무엇을 쓸 수 있는지는
> 인스펙터 옆 **Node 독 → Signals 탭**에서 전부 볼 수 있다.

## 선언 — `signal` 키워드

```gdscript
signal hit                          # 인자 없음
signal hit(damage: int)             # 인자 하나
signal item_picked(item: ItemData, count: int)   # 여러 개, 타입 자유
```

**인자 타입은 원하는 대로 지정한다.** 타입을 적어 두면 연결하는 함수의 시그니처가
맞는지 에디터와 LSP 가 검사해 준다. 적지 않아도 동작하지만 **적는 편이 좋다.**

## 🔑 Godot 4 에서 시그널은 "값"이다

**이것이 Godot 3 에서 넘어올 때 가장 헷갈리는 지점**이며, 왜 `hit.emit()` 처럼
점을 찍는지 설명해 준다.

`signal hit` 이라고 쓰면 **`hit` 이라는 `Signal` 타입의 값이 생긴다.**
문자열이 아니라 **객체**다.

```
엔진에서 확인 (4.7.2)
  typeof(hit) 의 이름   : Signal
  hit 를 출력하면        : SceneTree(test.gd)::[signal]hit
  hit is Signal         : true
  hit.get_object()      : 시그널을 가진 노드 자신
```

그래서 **점을 찍어 메서드를 부를 수 있다.**

| Godot 3 (문자열) | **Godot 4 (값)** |
|---|---|
| `emit_signal("hit", 10)` | **`hit.emit(10)`** |
| `connect("hit", self, "_on_hit")` | **`hit.connect(_on_hit)`** |
| 오타가 나도 **실행 전까지 모른다** | **오타 나면 그 자리에서 오류** |

**옛 방식도 아직 동작하지만 쓰지 않는다.** 문자열은 오타를 잡아 주지 못한다.

## 발신 — `emit()`

```gdscript
hit.emit()        # 인자 없는 시그널
hit.emit(10)      # 선언한 인자를 그대로 넘긴다
```

**"발산한다 / 방출한다(emit)"** 고 표현한다. 신호를 쏘아 보내는 것이지
누군가를 호출하는 것이 아니다 — **듣는 사람이 없어도 상관없다.**

## 받기 — `connect()`

**방법 1 — 코드에서**

```gdscript
func _ready() -> void:
    var enemy := $Enemy
    enemy.died.connect(_on_enemy_died)     # 함수 이름에 () 를 붙이지 않는다

func _on_enemy_died(score: int) -> void:
    total_score += score
```

`_on_enemy_died` 에 **괄호를 붙이지 않는 것**에 주의한다. 붙이면 함수를 *실행해서
그 결과*를 넘기게 된다. 붙이지 않아야 **함수 자체(`Callable`)** 가 넘어간다.

**방법 2 — 에디터에서**

1. **Scene 독**에서 시그널을 *보내는* 노드를 선택한다 (예: `Button`)
2. 오른쪽 **Inspector 옆의 Signals 탭**을 연다
3. 원하는 시그널을 **더블클릭**한다 (예: `button_down()`)
4. **Connect a Signal to a Method** 대화상자에서 *받을* 노드를 고르고 **Connect**
5. 받는 노드의 스크립트에 `_on_...` 함수가 **자동으로 생성**된다

**Signals 탭은 클래스 계층별로 묶여 있다.** 버튼을 선택하면
`BaseButton` / `Control` / `CanvasItem` / `Node` / `Object` 로 그룹이 나뉘는데,
**상속받은 모든 조상의 시그널이 쌓여서** 그렇다. `button_down()` 은 `BaseButton` 것이다.

**대화상자의 각 칸**

| 칸 | 뜻 |
|---|---|
| **From Signal** | **어떤 사건**을 받을 것인가 (`button_down()`) |
| **Connect to Script** | **누가 받을 것인가** — 받을 노드를 트리에서 고른다 |
| **Receiver Method** | **어느 함수가** 받을 것인가 (`_on_button_down`) |
| **Advanced** | 켜면 연결 플래그(`ONE_SHOT`·`DEFERRED`)와 추가 인자를 지정할 수 있다 |

**함수 이름은 에디터가 지어 준다.** 규칙은 `_on_` + **보내는 노드 이름** + `_` + 시그널 이름이다.

| 누가 받는가 | 자동 생성되는 이름 |
|---|---|
| **보내는 노드 자신** (버튼이 자기 시그널을 받음) | `_on_button_down` — **노드 이름이 빠진다** |
| 다른 노드 (`Main` 이 버튼 시그널을 받음) | `_on_button_button_down` |

> **`_on_` 접두사는 문법이 아니라 관례다.** 아무 이름이나 써도 동작한다.
> 다만 에디터가 이 이름을 지어 주고 모두가 그렇게 쓰므로 따르는 편이 좋다.

**🛑 연결은 코드가 아니라 씬 파일(`.tscn`)에 저장된다.**

```
[node name="Main" type="Node"]
[node name="Button" type="Button" parent="."]
[connection signal="button_down" from="Button" to="." method="_on_button_button_down"]
```

*(엔진에서 실제로 저장해 확인한 형식이다.)*

**이것이 에디터 연결의 가장 큰 함정이다.** 스크립트를 아무리 읽어도 **연결하는 코드가
없어서**, `_on_button_down()` 이 왜 불리는지 알 수 없다.

그래서 에디터가 표시해 준다 — **함수 왼쪽의 초록색 연결 아이콘**이 그것이고,
**"이 함수는 시그널에 연결되어 있다"** 는 뜻이다. 클릭하면 어느 연결인지 보여준다.
*(`_ready` 왼쪽에 붙는 다른 아이콘은 부모 메서드를 재정의했다는 표시로 성격이 다르다.)*

| | 에디터 연결 | 코드 연결 |
|---|---|---|
| 저장 위치 | `.tscn` | 스크립트 |
| 코드만 봐서 보이나 | 🛑 **안 보인다** | ✅ 보인다 |
| 동적으로 생성한 노드 | 불가 | ✅ 가능 |
| 언제 쓰나 | UI 버튼처럼 **씬에 고정된 것** | **그 외 대부분** |

> 코드로 연결한 것은 씬에 저장되지 않는다. `CONNECT_PERSIST` 플래그를 준 것만
> 저장되며, **에디터 연결이 바로 그 플래그를 쓴다** *(엔진 확인: 플래그 없이
> 저장하면 `[connection]` 줄이 생기지 않는다)*.

## 이 함수를 뭐라고 부르는가

시그널을 **받는 함수**를 부르는 말이 여럿이라 헷갈린다. Godot 기준으로 정리하면 이렇다.

| 부르는 말 | Godot 에서 | 비고 |
|---|---|---|
| **Receiver Method / 수신 메서드** | ✅ **에디터 UI 의 공식 명칭** | 연결 대화상자의 칸 이름이 그대로 `Receiver Method` 다 |
| **`Callable`** | ✅ **API 상의 정식 타입** | `connect()` 의 인자 이름이 `callable` 이다 |
| 콜백 (callback) | ⭕ 통용된다 | 일반 프로그래밍 용어. 뜻이 통하고 흔히 쓴다 |
| 이벤트 핸들러 | ⭕ 통용된다 | 다른 엔진·프레임워크 출신이 이렇게 부른다 |
| **"시그널 함수"** | 🛑 **권하지 않는다** | **시그널 자체**(`button_down`)와 **받는 함수**(`_on_button_down`)가 헷갈린다 |

> **엔진에서 확인 (4.7.2)** — `_on_ping` 의 타입은 `Callable` 이고,
> 연결 정보에도 `callable` 로 기록된다.

**실무에서 "콜백"이라고 해도 문제없다.** 다만 문서를 검색하거나 남에게 물을 때는
**"receiver method"** 또는 **"시그널을 받는 메서드"** 가 가장 정확하다.

## 실제 동작 — 엔진에서 확인한 것 (4.7.2)

| 질문 | 답 | 확인된 값 |
|---|---|---|
| **여러 개를 연결하면 순서는?** | **연결한 순서대로** 호출된다 | A → B 순으로 연결 후 emit → `["A", "B"]` |
| **듣는 사람이 없으면?** | **아무 일도 일어나지 않는다. 오류가 아니다** | 연결 0개에서 `emit()` → 정상 통과 |
| **같은 함수를 두 번 연결하면?** | 🛑 **거부되고 오류가 찍힌다** | 두 번째 `connect()` 반환값 `31` = `ERR_INVALID_PARAMETER`, 연결 수는 1 유지 |
| `connect()` 가 성공하면? | `0`(`OK`)을 반환한다 | |

**세 번째 항목이 실전에서 자주 걸린다.** `_ready()` 가 두 번 불리는 구조
(노드를 재사용하거나 풀링할 때)에서 같은 연결을 다시 시도하면 오류가 난다.
방어하려면 확인하고 연결한다.

```gdscript
if not enemy.died.is_connected(_on_enemy_died):
    enemy.died.connect(_on_enemy_died)
```

**한 번만 받고 자동으로 끊으려면** `CONNECT_ONE_SHOT` 을 쓴다.

```gdscript
enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)
```

> 엔진 확인 — 세 번 `emit()` 해도 **호출은 1회**, 그 뒤 **연결 수가 0** 이 된다.

## `await` — 시그널이 올 때까지 기다리기

시그널은 **함수를 멈춰 두는 용도로도 쓴다.**

```gdscript
func play_intro() -> void:
    print("시작")
    await animation_player.animation_finished    # 애니메이션이 끝날 때까지 멈춤
    print("애니메이션 끝난 뒤 실행")

    await get_tree().create_timer(2.0).timeout   # 2초 대기
    print("2초 뒤 실행")
```

**`emit()` 이 대기 중인 함수를 그 자리에서 재개시킨다.** 엔진에서 확인한 실행 순서다.

```
_waiter() 호출        → await 에서 멈춤
"호출 직후" 출력       ← 멈춰 있는 동안 다음 줄이 먼저 실행됨
done.emit(42)         → 멈춰 있던 _waiter 가 여기서 재개
"await 가 받은 값: 42" ← emit 문장이 끝나기 전에 출력된다
"emit 직후" 출력
```

`await` 로 받으면 **인자가 그대로 반환값이 된다** (`var v: int = await done`).

## 방향 규칙 — 통지는 위로, 명령은 아래로

시그널을 어디에 쓸지 헷갈릴 때의 기준이다.

| 방향 | 수단 | 예 |
|---|---|---|
| **자식 → 부모** (통지) | **시그널** | 체력 컴포넌트가 `died` 를 쏜다 |
| **부모 → 자식** (명령) | **직접 호출** | 부모가 `child.take_damage(10)` 을 부른다 |

**자식은 부모를 몰라야 한다.** 자식이 부모를 직접 부르면 그 자식은 그 부모
아래에서만 동작하게 되어 재사용할 수 없다.

## 더 깊이

| 알고 싶은 것 | 문서 |
|---|---|
| 연결 플래그 전체(`CONNECT_DEFERRED` 등), 인자 바인딩(`bind`), `await` 상세 | [gdscript.md](../gdscript.md) §10·§11 |
| 시그널로 컴포넌트를 조합하는 실전 구조, 이벤트 버스 | [nodes-scenes.md](../nodes-scenes.md) §10 |

> **물리 콜백 안에서 노드를 추가·삭제할 때는 `CONNECT_DEFERRED` 나
> `call_deferred()` 가 필요하다.** `body_entered` 같은 시그널은 물리 계산 도중에
> 불리므로, 그 안에서 씬 트리를 바꾸면 오류가 난다. → [gdscript.md](../gdscript.md) §10

---
