# 8. 동영상 강좌 — 손으로 한 번 따라 만들어 본다

> **[Godot 기본](../basics.md)** 의 파트 **9 / 11**
> [← 7. 에디터 조작을 내 손에 맞춘다 — 마우스와 단축키](07-editor-input.md) · [9. 실전 — 3D 캐릭터 컨트롤러를 한 줄씩 읽는다 →](09-controller.md)

**개념은 한 번 따라 만들어 봐야 손에 붙는다.** 아래 넷은 처음부터 끝까지 따라갈 수
있는 강좌이고, 이 문서의 어느 절과 맞닿는지를 함께 적어 둔다.

> 🛑 **강좌의 값·구조를 그대로 라리엔 3D 에 옮기지 않는다.** 카메라 각도·조명·성능
> 예산은 [SSOT.md](../../../game/references/SSOT.md) 가 최종 권위다. 강좌는 **엔진 조작을
> 익히는 용도**로 본다.

| | 강좌 | 무엇에 좋은가 |
|---|---|---|
| ① | [Godot 4.7 완전 초보 라이브 트레이닝](https://www.youtube.com/watch?v=QntG8plRY1M) | **에디터만으로 첫 게임까지** — 전체 흐름 잡기 |
| ② | Build a 3D House in Godot 4.7 (GodotwithMe) | **안드로이드 편집기**로 만드는 짧은 시리즈 |
| ③ | [Godot 3D Beginner — Walking Simulator](https://www.youtube.com/watch?v=d2i00O4bfDk&list=PLPdCd0OwI4tarX0u6ukZkMruBQ5AtAMQ0&index=2) | **3D 에셋 임포트·잔디·물·하늘** |
| ④ | [CSG 로 도로 프로토타입 → Blender → 지형](https://www.youtube.com/watch?v=3JH5fP4MjuE) | **블록아웃과 Blender 왕복** 실전 |

## 목차

| 절 | 내용 |
|---|---|
| [·](#①-3시간-만에-첫-게임--비주얼-에디터만으로) | ① 3시간 만에 첫 게임 — 비주얼 에디터만으로 |
| [·](#②-모바일에서-만든다면--안드로이드-편집기로-집-짓기) | ② 모바일에서 만든다면 — 안드로이드 편집기로 집 짓기 |
| [·](#③-3d-워킹-시뮬레이터--에셋-임포트부터-잔디물하늘까지) | ③ 3D 워킹 시뮬레이터 — 에셋 임포트부터 잔디·물·하늘까지 |
| [·](#④-csg-로-도로를-깔고-blender-로-지형을-만든다) | ④ CSG 로 도로를 깔고 Blender 로 지형을 만든다 |

---

---

## ① 3시간 만에 첫 게임 — 비주얼 에디터만으로

**Complete Beginners Live Training for Godot 4.7** · Visual Coding Hub

- 영상: <https://www.youtube.com/watch?v=QntG8plRY1M> — 3시간 라이브 빌드 풀버전
- 게임 플레이·다운로드, 소스코드·프로젝트 파일: 영상 설명란의 `visualcodinghub.itch.io` 링크
- 결과물 플레이 영상: *Simple 3d Game I made in 3 Hours on a YouTube Live*

> "In this Complete Beginners Live Training for Godot 4.7, I will take you from zero to
> your first playable game using only the visual editor. No prior experience needed."

**사전 지식이 전혀 없어도 되고, 비주얼 에디터만으로** 플레이 가능한 게임까지 간다.
다루는 항목이 이 문서 §1~§7 과 거의 그대로 겹친다.

| 강좌가 다루는 것 | 이 문서에서는 |
|---|---|
| Godot 엔진 소개 | §1 |
| 에디터 인터페이스 소개 | §6 |
| 알아 두면 좋은 에디터 기능 | §6 · §7 |
| 노드 소개 | §1 |
| 유용한 애드온 소개 | [asset-store.md](../asset-store.md) |
| 스크립팅 경로 선택 — GDScript 인가 비주얼 스크립팅인가 | §4 · [gdscript.md](../gdscript.md) |
| 빠른 코드 팁 | [gdscript.md](../gdscript.md) |
| 인디 게임 개발자를 위한 조언 | — |

> **라리엔 3D 는 GDScript 로 간다.** 강좌의 "스크립팅 경로 선택" 부분은 이미 판단이
> 끝난 항목이니 비교 설명만 참고하고 결론은 따르지 않는다.

---

## ② 모바일에서 만든다면 — 안드로이드 편집기로 집 짓기

**Build a 3D House in Godot 4.7 — Part 1** · GodotwithMe · 2026-07-10 · 3분 13초

새 프로젝트 생성부터 **바닥·카메라·조명·하늘**을 설정하고 집을 만들어 가는
왕초보 시리즈다. 한 편이 3분대라 부담이 없다.

| 편 | 내용 | 관련 문서 |
|---|---|---|
| 1편 | 새 프로젝트, 바닥·카메라·조명·하늘 | §6 · [3d-core.md](../3d-core.md) · [rendering-3d.md](../rendering-3d.md) |
| 2편 | `BoxMesh` 로 벽 만들기 | [level-design.md](../level-design.md) |
| 3편 | CSG 로 문과 창문 뚫기 | [level-design.md](../level-design.md) |
| 4편 | 박공지붕 만들기 | [level-design.md](../level-design.md) |

> 🛑 **이 시리즈는 안드로이드용 Godot 편집기를 쓴다.** 데스크톱 에디터와 화면 배치와
> 조작이 다르다. **모바일에서 제작할 때** 보고, 데스크톱으로 작업 중이라면 ①·③ 을 본다.

---

## ③ 3D 워킹 시뮬레이터 — 에셋 임포트부터 잔디·물·하늘까지

**Godot 3D Beginner Tutorial series** · 재생목록 전체

- 영상: <https://www.youtube.com/watch?v=d2i00O4bfDk&list=PLPdCd0OwI4tarX0u6ukZkMruBQ5AtAMQ0&index=2>

**완전 초보 대상**이며 Godot 경험도 게임 개발 경험도 필요 없다. 시리즈를 끝내면
걸어 다닐 수 있는 3D 워킹 시뮬레이터 하나가 남는다.

| 배우는 것 | 이 문서·다른 문서에서는 |
|---|---|
| 에디터 안에서 움직이는 법 | §6 · §7 |
| 프로젝트에 에셋 임포트 | [resources-assets.md](../resources-assets.md) |
| 잔디·물·하늘 넣기 | [rendering-3d.md](../rendering-3d.md) · [shaders-3d.md](../shaders-3d.md) |
| 걸어 다닐 수 있는 3D 만들기 | [physics-3d.md](../physics-3d.md) |

**코드가 많은 주제는 뒤로 미루고 에디터에 익숙해지는 것을 먼저 둔다** — 한 단계씩
직접 만들어 보며 배우는 구성이라, 이 문서 §0 의 1단계와 병행하기 좋다.

---

## ④ CSG 로 도로를 깔고 Blender 로 지형을 만든다

- 영상: <https://www.youtube.com/watch?v=3JH5fP4MjuE>

**CSG 로 게임플레이용 도로를 프로토타이핑한 뒤 Blender 로 내보내 지형을 만들고
다시 Godot 으로 가져오는** 실제 작업 과정을 처음부터 끝까지 보여 준다. 대본 없이
작업하며 말하는 영상이라 정돈되어 있지는 않지만, **블록아웃 → 지형 → 재임포트**
왕복이 실제로 어떻게 굴러가는지 보기에는 이만한 게 없다.

| 시각 | 내용 |
|---|---|
| 0:00 | 미리보기 |
| 0:44 | 첫 번째 도로 프로토타이핑 |
| 1:55 | 첫 번째 도로 테스트와 수정 |
| 3:05 | 두 번째 도로 |
| 4:25 | 세 번째 도로 |
| 6:03 | 아스팔트 |
| 6:40 | 레벨 전체 테스트 |
| 7:49 | Blender 로 내보내기 |
| 8:36 | Shrinkwrap 설정 |
| 10:26 | 안쪽 지형 타임랩스 |
| 13:36 | Godot 으로 임포트 |
| 14:19 | 안쪽 지형 테스트 |
| 14:52 | 바깥쪽 지형 타임랩스 |
| 18:10 | Blender 작업 완료 |
| 18:49 | 마무리 |
| 20:17 | 완성 |

**라리엔 3D 와 가장 가까운 강좌다.** CSG 블록아웃은 [level-design.md](../level-design.md),
Blender 왕복과 임포트 설정은 [resources-assets.md](../resources-assets.md) 에 있다.

> 🛑 **지형 물량은 그대로 따라가지 않는다.** 최소 지원 사양은 **3GB RAM 안드로이드**이고
> 드로우콜·정점 예산은 [performance-mobile.md](../performance-mobile.md) §0 과
> [lowend-3gb-60fps.md](../lowend-3gb-60fps.md) 가 정한다.

---
