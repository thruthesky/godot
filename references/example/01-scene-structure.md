# 1. 완성 모습과 씬 구조

> **[예제 — 빈 프로젝트에서 캐릭터가 움직이기까지](../example.md)** 의 파트 **2 / 14**
> [← 0. 이 예제로 무엇을 배우나](00-what-you-learn.md) · [2. 1단계 — 씬 만들고 저장 →](02-step1-scene.md)


## 만들 씬 트리

```
Main (Node3D)                        ← main.gd (카메라 추적)
├─ WorldEnvironment                  하늘 = 이 씬의 유일한 광원 역할
├─ Camera3D                          쿼터뷰 −45°
├─ Level (Node3D)                    맵 교체 지점
│  └─ Geometry (CSGCombiner3D)       🛑 Use Collision = ON
│     ├─ Floor (CSGBox3D)            12 × 1 × 12
│     ├─ WallNorth (CSGBox3D)        8단계에서 추가
│     ├─ WallSouth (CSGBox3D)
│     ├─ WallEast  (CSGBox3D)
│     └─ WallWest  (CSGBox3D)
└─ Player                            ← player.tscn 인스턴스
```

`player.tscn` 은 **별도 파일**로 만든다.

```
Player (CharacterBody3D)             ← player.gd (이동)
├─ CollisionShape3D                  CapsuleShape3D
└─ Mesh (MeshInstance3D)             CapsuleMesh
   └─ Nose (MeshInstance3D)          BoxMesh — 어디를 보는지 표시
```

## 만들 파일

```
res://
├─ scene/
│  ├─ main.tscn
│  ├─ main.gd          ← 씬 옆에 둔다
│  ├─ player.tscn
│  └─ player.gd        ← 씬 옆에 둔다
└─ project.godot
```

**스크립트를 씬과 같은 폴더에 두는 것이 Godot 의 관습이다.** 엔진의 Attach Script
기본 경로가 **현재 씬 폴더 + 노드 이름**이라, `scripts/` 로 따로 모으면 매번 손으로
고쳐야 하고 씬을 옮길 때 두 폴더를 동기화해야 한다
(→ [nodes-scenes.md](../nodes-scenes.md) §11).

## 각 노드를 왜 두는가

| 노드 | 없으면 | 왜 이 자리인가 |
|---|---|---|
| `WorldEnvironment` | **화면이 납작해진다** (§3 실측) | 맵이 바뀌어도 유지되어야 하므로 `Main` 아래 |
| `Camera3D` | **아무것도 안 보인다** (§6 실측) | 맵을 갈아끼울 때 같이 지워지면 안 되므로 `Main` 아래 |
| `Level` | 맵 교체가 번거로워진다 | 이 노드의 자식만 통째로 갈면 맵이 바뀐다 |
| `Geometry` | — | 블록아웃 CSG → 나중에 구운 메시로 갈아끼우는 자리 |
| `Player` | — | 맵의 일부가 아니므로 `Level` 밖 |

---
