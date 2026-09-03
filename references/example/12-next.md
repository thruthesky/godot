# 12. 다음에 할 것

> **[예제 — 빈 프로젝트에서 캐릭터가 움직이기까지](../example.md)** 의 파트 **14 / 14**
> [← 11. 증상별 진단표](11-troubleshooting.md) · [색인 →](../example.md)


## 이 예제를 늘려 보기

| 해 볼 것 | 방법 | 배우는 것 |
|---|---|---|
| 속도 바꾸기 | `SPEED` 를 `8.0` 으로 | 상수 하나로 감이 얼마나 달라지는지 |
| 점프 높이 | `JUMP_VELOCITY` 를 `10.0` 으로 | 최고 높이 = `10² ÷ (2×9.8)` ≈ **5.1m** |
| `Nose` 지우기 | 노드 삭제 후 실행 | **회전이 전혀 안 보인다** — 왜 넣었는지 |
| `look_at` 지우기 | 그 줄을 주석 처리 | 항상 같은 쪽만 보고 게걸음한다 |
| 상자 놓기 | `Geometry` 에 `CSGBox3D` 추가 | 충돌이 자동으로 붙는다 |
| 문 만들기 | §9 의 `Doorway` | Subtraction 이 하는 일 |
| WASD | Input Map 에 액션 등록 | **코드를 안 고쳐도 된다** |
| 카메라 줌아웃 | `CAMERA_OFFSET` 을 `(0, 20, 20)` 으로 (이 예제의 원근 카메라) · 🛑 본체 직교 카메라는 `_camera.size` 를 키운다 | `y`·`z` 를 같게 = 각도 유지 |

## 읽을 문서

| 하고 싶은 것 | 문서 |
|---|---|
| 노드·씬·리소스를 제대로 | [basics.md](../basics.md) |
| 용어 뜻만 빠르게 | [dictionary.md](../dictionary.md) |
| GDScript 문법 전체 | [gdscript.md](../gdscript.md) |
| 좌표·회전·카메라 심화 | [3d-core.md](../3d-core.md) |
| 충돌·물리 심화 | [physics-3d.md](../physics-3d.md) |
| 맵 제작 방식 선택 | [level-design.md](../level-design.md) |
| **저사양 폰에서 60fps** | [lowend-3gb-60fps.md](../lowend-3gb-60fps.md) |
| 넓은 야외 맵 | [openworld-3d.md](../openworld-3d.md) |

## 블록아웃 다음 단계

이 예제의 CSG 는 **최종물이 아니다.** 확정되면 이렇게 넘어간다.

```
① CSG 블록아웃          ← 지금 여기
   ↓ 동선·크기 확정
② bake_static_mesh()    CSG → ArrayMesh 로 굳히고 CSG 노드 삭제
   ↓
③ 정점 색 굽기          개발 PC 헤드리스에서 밝기를 계산해 색으로 저장
   ↓
④ 런타임                UNSHADED + vertex_color_use_as_albedo 로 그냥 읽기
                        이때 Environment 를 단색 + ambient DISABLED 로
```

**모든 단계에서 씬의 광원은 0개다.** ③에서 쓰는 "태양"도 노드가 아니라
굽기 스크립트 안의 **상수 네 줄**(방향·색·하늘빛·땅빛)이다.
상세는 [lowend-3gb-60fps.md](../lowend-3gb-60fps.md) §4·§5.

## 공식 문서

- Your first 3D game: https://docs.godotengine.org/en/stable/getting_started/first_3d_game/index.html
- Step by step (Nodes and Scenes · Creating instances · Creating your first script · Listening to player input · Using signals): https://docs.godotengine.org/en/stable/getting_started/step_by_step/index.html
- Prototyping levels with CSG: https://docs.godotengine.org/en/stable/tutorials/3d/csg_tools.html
- Using CharacterBody2D/3D: https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
