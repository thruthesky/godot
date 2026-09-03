# 예제 — 빈 프로젝트에서 캐릭터가 움직이기까지

> **이 문서로 오는 상황** — 손으로 첫 씬을 만들 때 — 빈 프로젝트 → 바닥·벽·플레이어 → 화살표 키 이동, 8단계 + 증상별 진단표. 맨 앞 "빠른 길" 카드부터

**Godot 을 처음 만지는 사람이 빈 프로젝트에서 시작해, 바닥 위를 걸어다니는 캐릭터까지
직접 만들어 보는 예제다.** 조작 하나하나를 에디터 기준으로 적었고,
**왜 그렇게 하는지**와 **틀리면 어떤 화면이 나오는지**를 함께 담았다.

> 📌 **이 문서의 값은 전부 엔진에서 확인한 것이다.**
> 기본값은 `godot --headless --doctool` 로 추출했고, 화면 비교는 **Godot 4.7.2.stable ·
> Mobile 렌더러**로 실제 렌더해 PNG 로 비교했으며, 이동 수치는 실행해서 좌표를 찍었다.
> 성능 수치는 **Galaxy A12(SM-A125N)** 실기기 측정값이다.

---

## 📖 목차

| 절 | 내용 |
|---|---|
| [§0](example/00-what-you-learn.md#0-이-예제로-무엇을-배우나) | 이 예제로 무엇을 배우나 |
| [§1](example/01-scene-structure.md#1-완성-모습과-씬-구조) | 완성 모습과 씬 구조 |
| [§2](example/02-step1-scene.md#2-1단계--씬-만들고-저장) | **1단계** 씬 만들고 저장 |
| [§3](example/03-step2-environment.md#3-2단계--환경-태양은-만들지-않는다) | **2단계** 환경 — 🛑 태양은 만들지 않는다 |
| [§4](example/04-step3-floor.md#4-3단계--바닥) | **3단계** 바닥 |
| [§5](example/05-step4-player.md#5-4단계--플레이어-씬) | **4단계** 플레이어 씬 |
| [§6](example/06-step5-camera.md#6-5단계--카메라) | **5단계** 카메라 |
| [§7](example/07-step6-scriptsa.md#7-6단계--스크립트-2개) | **6단계** 스크립트 2개 — ★ **코드를 한 줄씩 100% 뜯어본다 + 📜 주석 완전판** |
| [§8](example/08-step7-run.md#8-7단계--메인-씬-지정과-실행) | **7단계** 메인 씬 지정과 실행 |
| [§9](example/09-step8-walls.md#9-8단계--벽-추가) | **8단계** 벽 추가 — ★ **충돌은 씬 트리와 무관하다** |
| [§10](example/10-verify.md#10-검증--이-값이-나와야-정상이다) | 검증 — 이 값이 나와야 정상이다 |
| [§11](example/11-troubleshooting.md#11-증상별-진단표) | **증상별 진단표** ★ 막혔을 때 |
| [§12](example/12-next.md#12-다음에-할-것) | 다음에 할 것 |

---

# 0-A. 빠른 길 — 이 8개 조작만 따라 하면 캐릭터가 움직인다

**아래 완전판은 3,000줄이다.** 처음이면 이 카드만 따라 하고, 막히는 단계에서만 해당 절(§2~§9)로 내려간다.
**전제**: 빈 3D 프로젝트가 열려 있다 — 아직이면 [getting-started.md §3](getting-started.md).

| # | 누를 곳 | 예상 화면 | 실패하면 볼 것 |
|---|---|---|---|
| 1 | `Scene › New Scene › 3D Scene` → 루트 이름 `Main` → **Cmd+S** `res://scenes/main.tscn` | Scene 독에 `Main (Node3D)` | [§2](example/02-step1-scene.md#2-1단계--씬-만들고-저장) |
| 2 | 뷰포트 툴바 ☀🌐 옆 **⋮ › Add Environment to Scene** — 🛑 **Add Sun 은 누르지 않는다** | `WorldEnvironment` 가 생기고 하늘이 밝다 | [§3](example/03-step2-environment.md#3-2단계--환경-태양은-만들지-않는다) |
| 3 | `Main` 선택 → **Cmd+A** `CSGBox3D` → 인스펙터 `Size` `12, 1, 12` · `Position` `0, -0.5, 0` · **Use Collision 켬** | 회색 바닥 | [§4](example/04-step3-floor.md#4-3단계--바닥) |
| 4 | `Scene › New Scene › Other Node › CharacterBody3D` → 이름 `Player` → 자식 `CollisionShape3D`(Shape: Capsule) + `MeshInstance3D`(Mesh: Capsule) → **Cmd+S** `res://scenes/player.tscn` | 캡슐 하나 | [§5](example/05-step4-player.md#5-4단계--플레이어-씬) |
| 5 | `main.tscn` 으로 돌아가 `Main` 선택 → **Cmd+Shift+A** `player.tscn` → `Position` `0, 1, 0` | 바닥 위에 캡슐 | [§5](example/05-step4-player.md#5-4단계--플레이어-씬) |
| 6 | `Main` 선택 → **Cmd+A** `Camera3D` → `Position` `0, 12, 12` · `Rotation` `-45, 0, 0` | 뷰포트 오른쪽 위 **Preview** 로 확인 | [§6](example/06-step5-camera.md#6-5단계--카메라) |
| 7 | `Player` 루트에 스크립트 붙이기(우클릭 › Attach Script) → [§7 의 `player.gd`](example/07-step6-scriptsa.md#7-6단계--스크립트-2개) 붙여넣기. 🛑 **인스턴스가 아니라 `player.tscn` 의 루트에** | 스크립트 아이콘 | [§7 "스크립트를 어느 노드에 붙이는가"](example/07-step6-scriptsa.md#7-6단계--스크립트-2개) |
| 8 | `Project › Project Settings › Application › Run › Main Scene` = `main.tscn` → **F5** | 화살표 키로 캡슐이 움직인다 | [§11 증상별 진단표](example/11-troubleshooting.md#11-증상별-진단표) |

# 0-B. 공식 예제와 다른 점 세 가지

공식 튜토리얼이나 유튜브 강좌를 같이 보면 **세 곳에서 이 예제와 다르다.** 어느 쪽이 틀린 것이 아니라 **라리엔 3D 의 규범**이다.

| | 공식·일반 예제 | 이 예제 · 라리엔 3D | 왜 |
|---|---|---|---|
| **조명** | `DirectionalLight3D`(태양) 를 놓는다 | 🛑 **광원 0개.** 하늘(`WorldEnvironment`)만 | 3GB 폰에서 실시간 조명 22fps·라이트맵 1fps 실측 — SKILL.md 저사양 규범 |
| **카메라 투영** | 원근(`fov=75`) — 이 예제의 §6 계산도 학습용으로 원근을 쓴다 | 🛑 **본체는 직교** — `Camera3D › Projection = Orthogonal`, `Size = 22.5`(실제 씬 `scenes/main/main.tscn`) | 임포스터·LOD·컬링이 고정 각도를 전제 — `game` 스킬 SSOT §1 |
| **줌** | 카메라를 멀리 보낸다 | 🛑 **`size` 를 바꾼다.** 직교는 거리를 바꿔도 크기가 안 변한다 — 잘림(near/far)만 생긴다 | SSOT §1. 🛑 `size` 기본값이 `1.0` 이라 투영만 바꾸면 세로 1m 만 보인다 |
| 카메라 회전 | 마우스로 돌린다 | **피치 −45°·yaw 0°·roll 0° 고정.** 회전 입력 없음 | 모바일 엄지 하나·전술 가독성 — `CLAUDE.md` |
| 실내 | 방·복도를 만든다 | **실내로 들어가는 건물 없음.** 던전은 별도 야외형 맵 | `game` 스킬 design.md 결정 1 |

**이 예제가 원근 카메라를 쓰는 이유** — "카메라가 어디를 보는가·왜 45°인가" 를 원근에서 배우는 편이 직관적이고,
직교의 `size` 함정은 [3d-core.md §9](3d-core.md) 와 SSOT 에서 따로 다룬다. **본체 코드를 쓸 때는 위 표의 오른쪽을 따른다.**


> 🗂️ **이 문서는 색인이다 — 본문은 `example/` 아래 13개 파트에 있다.** (2026-09-03, `basics/` 와 같은 방식으로 나눴다. 한 글자도 지우지 않았다.)

| 파트 | 제목 | 줄 |
|---|---|---|
| **0** | **[0. 이 예제로 무엇을 배우나](example/00-what-you-learn.md)** | 36 |
| **1** | **[1. 완성 모습과 씬 구조](example/01-scene-structure.md)** | 60 |
| **2** | **[2. 1단계 — 씬 만들고 저장](example/02-step1-scene.md)** | 28 |
| **3** | **[3. 2단계 — 환경 (태양은 만들지 않는다)](example/03-step2-environment.md)** | 106 |
| **4** | **[4. 3단계 — 바닥](example/04-step3-floor.md)** | 134 |
| **5** | **[5. 4단계 — 플레이어 씬](example/05-step4-player.md)** | 96 |
| **6** | **[6. 5단계 — 카메라](example/06-step5-camera.md)** | 84 |
| **7** | **[7. 6단계 — 스크립트 2개](example/07-step6-scriptsa.md)** | 1149 |
| **8** | **[7. 6단계 — 스크립트 2개 (b)](example/07-step6-scriptsb.md)** | 666 |
| **9** | **[8. 7단계 — 메인 씬 지정과 실행](example/08-step7-run.md)** | 36 |
| **10** | **[9. 8단계 — 벽 추가](example/09-step8-walls.md)** | 523 |
| **11** | **[10. 검증 — 이 값이 나와야 정상이다](example/10-verify.md)** | 34 |
| **12** | **[11. 증상별 진단표](example/11-troubleshooting.md)** | 38 |
| **13** | **[12. 다음에 할 것](example/12-next.md)** | 58 |
