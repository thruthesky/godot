# 5. 4단계 — 플레이어 씬

> **[예제 — 빈 프로젝트에서 캐릭터가 움직이기까지](../example.md)** 의 파트 **6 / 14**
> [← 4. 3단계 — 바닥](04-step3-floor.md) · [6. 5단계 — 카메라 →](06-step5-camera.md)


**플레이어는 `main.tscn` 안이 아니라 별도 씬 파일로 만든다.**
나중에 다른 맵에도 놓아야 하고, 몬스터·NPC 도 같은 구조로 늘어나기 때문이다.

## 조작

1. `Scene > New Scene` → **`Other Node`** → `CharacterBody3D` 검색해 선택
2. **F2** → `Player`
3. **Cmd+S** → `res://scenes/player.tscn`

그 아래에 세 개를 붙인다.

| 부모 | 추가할 노드 | 이름 | 설정 |
|---|---|---|---|
| `Player` | `CollisionShape3D` | 그대로 | `Shape` → **New CapsuleShape3D** |
| `Player` | `MeshInstance3D` | **F2** → `Mesh` | `Mesh` → **New CapsuleMesh** |
| `Mesh` | `MeshInstance3D` | **F2** → `Nose` | `Mesh` → **New BoxMesh** |

`CapsuleShape3D` 와 `CapsuleMesh` 는 **기본값이 그대로 맞다** — 둘 다
`height = 2.0`, `radius = 0.5` 다(doctool 확인). 건드리지 않는다.

`Nose` 에만 값을 넣는다.

| 항목 | 값 | 어디에 |
|---|---|---|
| `Size` | `0.25, 0.25, 0.5` | **`BoxMesh` 리소스 안** (아래 참고) |
| `Transform > Position` | `0, 0.3, -0.6` | 노드의 Transform |

## `Nose` 는 왜 필요한가

**캡슐만 있으면 어느 쪽을 보고 있는지 전혀 알 수 없다.** 회전이 눈에 보이지 않는다.
작은 상자를 앞에 붙이면 방향이 바로 읽힌다.

`-Z` 쪽에 붙이는 건 **Godot 3D 의 forward 가 `-Z`** 이기 때문이다.
(`+Y` 가 위, `+X` 가 오른쪽. 오른손 좌표계다.)

## 🔍 `Size` 가 인스펙터에 없다면 — 정상이다

`Nose` 를 선택하면 인스펙터에 **`Size` 가 안 보이고 `Scale` 만 보인다.**
버그가 아니다. **`Size` 는 노드가 아니라 리소스의 프로퍼티**다.

`MeshInstance3D` 가 가진 프로퍼티는 `mesh` · `skeleton` · `skin` **셋뿐**이고(doctool 확인),
`Scale` 은 그 위의 `Node3D` 에서 물려받은 것이다.

**찾는 법** — 인스펙터의 **`Mesh` 슬롯에 있는 `BoxMesh` 썸네일을 클릭한다.**
인스펙터 아래쪽이 펼쳐지며 `Size` · `Subdivide *` · `Material` 이 나온다.
다시 클릭하면 접힌다. `Shape` · `Material` · `Texture` 슬롯도 전부 같은 방식이다.

### 왜 `Floor` 에서는 바로 보였나

같은 `Size` 인데 **소속이 다르다**(엔진에서 확인한 상속).

| 만지는 값 | 소속 | 상속 | 인스펙터 |
|---|---|---|---|
| `CSGBox3D` 의 `Size` | **노드** | `CSGBox3D` → `CSGPrimitive3D` | 바로 보인다 |
| `BoxMesh` 의 `Size` | **리소스** | `BoxMesh` → `PrimitiveMesh` | `Mesh` 를 클릭해 펼친다 |
| `CapsuleMesh` 의 `Height`·`Radius` | **리소스** | `CapsuleMesh` → `PrimitiveMesh` | `Mesh` 를 클릭해 펼친다 |
| `CapsuleShape3D` 의 `Height`·`Radius` | **리소스** | `CapsuleShape3D` → `Shape3D` | `Shape` 를 클릭해 펼친다 |
| `Scale` | **노드** | `Node3D` | 바로 보인다 |

`CSGBox3D` 는 **노드 자체가 `size` 를 갖는** 경우다. 그래서 CSG 로 바닥을 만들 때는
바로 보이다가 `MeshInstance3D` + `BoxMesh` 로 넘어가는 순간 안 보여서 걸린다.

### 🛑 크기를 `Scale` 로 대신하지 않는다

`Size` 를 `1, 1, 1` 로 두고 `Scale` 에 `0.25, 0.25, 0.5` 를 넣어도 화면상 결과는 같다.
그래도 `Size` 를 쓴다.

| `Scale` 로 크기를 주면 | 무슨 일이 생기나 |
|---|---|
| **자식에게 전파된다** | 아래 달린 노드가 전부 같이 찌그러진다 |
| **비균등 스케일이 노멀을 왜곡한다** | 면이 향한 방향이 틀어져 조명 계산이 어긋난다 |
| **콜리전·물리에서 문제가 된다** | 셰이프에 스케일을 주면 엔진에 따라 동작이 달라진다 |

**메시의 크기는 메시에서, 노드의 배치는 Transform 에서.**
자세한 개념은 [basics/01-world.md](../basics/01-world.md) 의 "노드와 리소스는 다르다".

## `main.tscn` 에 플레이어 놓기

1. `main.tscn` 탭으로 돌아간다
2. `Main` 을 선택한다
3. Scene 독 위쪽의 **체인 버튼**(`Instantiate Child Scene`) 또는 **Cmd+Shift+A**
   → `player.tscn` 선택
   (FileSystem 독에서 `player.tscn` 을 `Main` 위로 **드래그**해도 같다)
4. 생긴 `Player` 인스턴스의 `Transform > Position` 을 **`0, 2, 0`** 으로

**`y = 2` 로 띄워 두는 이유** — 공중에서 시작해 떨어지게 하면
**중력이 실제로 도는지 한눈에 확인된다.** 스크립트가 안 붙어 있으면 공중에 그대로 떠 있다.

---
