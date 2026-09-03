# 8. 7단계 — 메인 씬 지정과 실행

> **[예제 — 빈 프로젝트에서 캐릭터가 움직이기까지](../example.md)** 의 파트 **10 / 14**
> [← 7. 6단계 — 스크립트 2개 (b)](07-step6-scriptsb.md) · [9. 8단계 — 벽 추가 →](09-step8-walls.md)


## 메인 씬 지정

`Project > Project Settings > Application > Run > Main Scene` → `res://scenes/main.tscn`

또는 ▶ 를 처음 누를 때 뜨는 대화상자에서 **`Select Current`** 를 눌러도 같다.

지정하지 않으면 실행할 때 **"메인 씬이 지정되지 않았다"** 대화상자가 뜬다.

## 실행

**▶** (또는 **F5**)

- 캡슐이 **떨어져서 바닥에 선다**
- **화살표 키**로 움직인다
- **스페이스**로 점프한다
- 카메라가 따라온다

## 조작이 화살표인 이유

`ui_left` / `ui_right` / `ui_up` / `ui_down` / `ui_accept` 는 **Godot 이 기본 제공하는
InputMap 액션**이고 화살표 키·스페이스에 묶여 있다. 그래서 설정 없이 바로 동작한다.

**WASD 를 쓰려면** `Project Settings > Input Map` 에서 액션을 만들고 키를 등록한다.
`Input.get_vector()` 에 넘기는 액션 이름만 바꾸면 되고 **나머지 코드는 그대로**다.

> 💡 키를 등록할 때는 `keycode` 가 아니라 **`physical_keycode`** 를 쓴다.
> 자판 배열이 달라도 **같은 자리**를 가리킨다 (→ [input-ui.md](../input-ui.md)).

---
