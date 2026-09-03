# 10. 캐릭터 애니메이션 — 화살표 키만 눌렀는데 왜 걷는가

> **[Godot 기본](../basics.md)** 의 파트 **11 / 11**
> [← 9. 실전 — 3D 캐릭터 컨트롤러를 한 줄씩 읽는다](09-controller.md) · [← 색인으로 돌아가기](../basics.md)

§9 의 주인공은 **캡슐**이었다. 캡슐은 아무리 잘 움직여도 팔다리가 없다.
그 자리에 **사람 모양 3D 모델**을 넣으면 곧바로 다음 질문이 생긴다.

> **"애니메이션은 대체 어디서 오는 건가?
> 프로그램은 화살표 키로 위치만 바꾸는데, 어떻게 걷는 동작이 저절로 나오지?"**

이 절은 그 질문 하나를 **파일 안쪽부터 화면까지** 끝까지 따라간다.
`.glb` 파일을 실제로 열어서 무엇이 들어 있는지 보고, Godot 이 그것을 어떤 노드로
바꾸는지 보고, 코드의 어느 한 줄이 "키 입력"과 "걷는 동작"을 잇는지 짚는다.

> 이 절은 **개념과 최소 코드**만 다룬다. `AnimationTree`·상태 머신·블렌드
> 스페이스·Root Motion 같은 본격적인 도구는 [animation-3d.md](../animation-3d.md)
> 로 간다. **먼저 여기를 이해하고 그 문서로 넘어가는 순서를 권한다** —
> `AnimationTree` 는 결국 `AnimationPlayer` 를 자동으로 조종하는 장치이기 때문이다.

## 목차

| 절 | 내용 |
|---|---|
| [10.0](#100-시작하기-전에--오해-세-가지를-먼저-지운다) | 시작하기 전에 — 오해 세 가지를 먼저 지운다 |
| [10.1](#101-애니메이션은-glb-파일-안에-들어-있다) | 애니메이션은 `.glb` 파일 안에 들어 있다 |
| [10.2](#102-애니메이션-데이터의-실체--뼈의-시간별-자세표) | 애니메이션 데이터의 실체 — "뼈의 시간별 자세표" |
| [10.3](#103-godot-이-glb-를-씬으로-바꿔-준다) | Godot 이 `.glb` 를 **씬으로** 바꿔 준다 |
| [10.4](#104-코드가-animationplayer-를-잡는다) | 코드가 `AnimationPlayer` 를 잡는다 |
| [10.5](#105--자동으로-재생되는-것이-아니다--코드가-매-프레임-고른다) | 🛑 자동으로 재생되는 것이 아니다 — 코드가 매 프레임 고른다 |
| [10.6](#106--애니메이션은-캐릭터를-이동시키지-않는다) | 🛑 애니메이션은 캐릭터를 이동시키지 않는다 |
| [10.7](#107-전체-흐름-한-장) | 전체 흐름 한 장 |
| [10.8](#108-직접-확인해-보는-법) | 직접 확인해 보는 법 |
| [10.9](#109-자주-막히는-곳) | 자주 막히는 곳 |
| [10.10](#1010-여기서-부족해지면--animationtree-로-간다) | 여기서 부족해지면 — `AnimationTree` 로 간다 |

---

---

## 10.0 시작하기 전에 — 오해 세 가지를 먼저 지운다

이 셋을 그대로 두고 읽으면 나머지가 전부 어긋난다.

| | 흔한 오해 | 실제 |
|---|---|---|
| ① | 애니메이션은 **"움직이는 그림"** 이다 | **뼈의 시간별 자세를 적은 숫자표**다. 그림이 아니다 |
| ② | 애니메이션을 틀면 **캐릭터가 앞으로 나간다** | **제자리에서 걷는다.** 이동은 `move_and_slide()` 가 따로 시킨다 |
| ③ | 키를 누르면 **엔진이 알아서** 걷기 애니를 튼다 | **코드가 매 프레임 직접 고른다.** 자동인 것은 "고른 뒤 계속 돌리는 것"뿐이다 |

특히 ③ 이 중요하다. **이동 코드와 애니메이션 코드는 완전히 별개**이고,
`if` 문 몇 줄이 둘을 이어 준다. 그 줄을 지우면 캐릭터는 여전히 화살표 키로
잘 이동하지만 **차렷 자세 그대로 미끄러져 다닌다.**

---

## 10.1 애니메이션은 `.glb` 파일 안에 들어 있다

캐릭터를 씬에 넣을 때 우리는 보통 이렇게 쓴다.

```gdscript
[node name="character" parent="Player" instance=ExtResource("2_te5a3")]
```

여기서 `ExtResource("2_te5a3")` 가 가리키는 것이 `res://.../character.glb` 다.

**`.glb` 는 이미지 파일 같은 "그림 한 장"이 아니라, 캐릭터에 필요한 모든 것을
한 파일에 담은 상자다.**

| `.glb` 안에 들어 있는 것 | 뜻 |
|---|---|
| **메시(mesh)** | 눈에 보이는 형상. 정점과 삼각형 |
| **머티리얼·텍스처** | 그 형상에 입히는 색·무늬 |
| **스켈레톤(skeleton)** | 안에 든 **뼈대**. 사람이면 골반·척추·팔다리 |
| **스킨(skin)** | 메시의 각 정점이 **어느 뼈에 얼마나 붙어 있는지** |
| **애니메이션(animations)** | 🔑 **뼈를 시간에 따라 어떻게 움직일지 적은 표** |

`.gltf` 와 `.glb` 는 같은 규격이고 **`.gltf` 는 JSON 텍스트 + 별도 파일들,
`.glb` 는 그 전부를 하나로 묶은 바이너리**라는 차이뿐이다. 배포에는 `.glb` 를 쓴다.

### 실측 — 파일을 직접 열어서 확인한다

추측하지 않는다. 파이썬 몇 줄이면 `.glb` 안의 목록을 그대로 볼 수 있다.
(`.glb` 는 앞부분에 JSON 청크가 그대로 들어 있어 별도 라이브러리가 필요 없다.)

```python
# glb_peek.py — .glb 안에 무엇이 들어 있는지 찍어 본다
import json, struct, sys

with open(sys.argv[1], 'rb') as f:
    magic, ver, length = struct.unpack('<4sII', f.read(12))   # 헤더 12바이트
    clen, ctype = struct.unpack('<I4s', f.read(8))            # 첫 청크 = JSON
    js = json.loads(f.read(clen).decode('utf-8'))

print("애니메이션:", [a.get('name') for a in js.get('animations', [])])
print("스킨:", len(js.get('skins', [])),
      "| 본 개수:", [len(s['joints']) for s in js.get('skins', [])])
print("메시:", [m.get('name') for m in js.get('meshes', [])])
```

리깅과 애니메이션이 끝난 캐릭터 하나를 넣으면 이렇게 나온다.

```
애니메이션: ['idle', 'walk', 'run', 'attack', 'death', 'RESET']
스킨: 1 | 본 개수: [23]
메시: ['tripo_mesh_ddb4bdd0-...']
```

**`idle`·`walk`·`run` 같은 이름이 바로 코드에서 `play("walk")` 로 부르게 될 그 이름이다.**
`.glb` 안에 이 이름이 없으면 코드가 아무리 정확해도 캐릭터는 T-포즈로 서 있기만 한다.

> 🔑 **`RESET` 은 특별한 애니메이션이다.** "아무것도 하지 않은 기본 자세" 한 프레임을
> 담아 두는 관례적인 이름이고, 블렌딩의 기준점이 된다. 자세한 것은
> [animation-3d.md §3](../animation-3d.md) 을 본다.

### 이 파일은 어떻게 만들어지나

Godot 은 3D 모델을 **만드는** 도구가 아니다. `.glb` 는 바깥에서 구워 온다.

```
① 형상을 만든다        Blender · 또는 텍스트→3D 생성 도구
        ↓  (뼈가 없는 껍데기 상태)
② 리깅(rigging)        형상 안에 뼈대를 넣고, 정점을 뼈에 묶는다
        ↓  (움직일 수 있게 되었지만 아직 동작은 없다)
③ 애니메이션을 붙인다   Mixamo 등에서 idle·walk·run·attack·death 를 가져와 적용
        ↓
④ .glb 로 내보낸다      메시 + 뼈 + 애니 + 텍스처가 한 파일로
        ↓
⑤ Godot 의 res:// 안에 넣는다
```

> 🛑 **모델의 크기·원점·축이 잘못되었으면 Godot 에서 스케일·위치로 보정하지 않는다.**
> ②④ 단계로 돌아가 고친 뒤 다시 내보낸다. Godot 쪽 보정은 그 모델을 쓰는
> **모든 곳에서 반복**되지만, 원본을 고치면 한 번으로 끝난다.

---

## 10.2 애니메이션 데이터의 실체 — "뼈의 시간별 자세표"

여기가 이 절에서 가장 중요한 부분이다.

### 먼저 뼈대를 본다

앞의 `glb_peek.py` 를 조금 늘려 노드 목록을 찍어 보면, `.glb` 안의 뼈들이
**부모-자식으로 이어진 나무**라는 것이 보인다.

```
root
├─ tripo_node_...            ← 메시(피부). skin 으로 아래 뼈들에 묶여 있다
└─ mixamorig:Hips            ← 뿌리 뼈 (골반)
   ├─ mixamorig:LeftUpLeg  → LeftLeg  → LeftFoot  → LeftToeBase
   ├─ mixamorig:RightUpLeg → RightLeg → RightFoot → RightToeBase
   └─ mixamorig:Spine → Spine1 → Spine2
      ├─ LeftShoulder  → LeftArm  → LeftForeArm  → LeftHand
      ├─ Neck → Head
      └─ RightShoulder → RightArm → RightForeArm → RightHand
```

> ⚠️ **뼈 22개와 23개가 둘 다 나오는 이유** — 리깅 도구가 넣는 `neutral_bone` 이
> 하나 더 있어서 `Skeleton3D` 의 본은 **23개**지만, 실제로 움직이는 `mixamorig_*` 은
> **22개**라 애니메이션 채널은 22개 기준으로 만들어진다.

**부모가 움직이면 자식이 따라 움직인다.** 노드 트리(§1)와 완전히 같은 원리다.
골반을 돌리면 다리·척추·팔·머리가 통째로 따라간다. 그래서 애니메이션은
"모든 정점의 위치"를 저장할 필요 없이 **뼈 22개의 자세만** 저장하면 된다.

`mixamorig:` 라는 접두사는 Mixamo 규격 본 이름이다. 이름이 규격을 따르면
**다른 캐릭터의 애니메이션을 그대로 가져다 쓸 수 있다**(리타게팅).

### 애니메이션 하나 = 채널 수십 개

`idle` 애니메이션 하나를 열어 보면 이렇다.

```
[idle] 길이 2.03초
채널 66개 = 뼈 22개 × 3종류
   translation 22개    ← 뼈 22개의 위치가 시간에 따라 어떻게 변하는가
   rotation    22개    ← 뼈 22개의 회전이 시간에 따라 어떻게 변하는가
   scale       22개    ← 뼈 22개의 크기가 시간에 따라 어떻게 변하는가
대상 노드: mixamorig:Hips, mixamorig:LeftUpLeg, mixamorig:Spine, ...
```

**즉 `walk` 애니메이션이란 결국 이런 숫자표다.**

```
시각      LeftUpLeg 회전        RightUpLeg 회전       Spine 회전
0.000초   (-0.12, 0, 0, 0.99)   ( 0.15, 0, 0, 0.98)   (0.01, ...)
0.033초   (-0.09, 0, 0, 0.99)   ( 0.12, 0, 0, 0.99)   (0.01, ...)
0.066초   (-0.05, 0, 0, 1.00)   ( 0.08, 0, 0, 1.00)   (0.02, ...)
...
```

**엔진이 하는 일은 "현재 재생 시각에 해당하는 줄을 찾아 뼈에 써 넣는 것"뿐이다.**
표에 없는 중간 시각은 앞뒤 값을 **보간(interpolate)** 해서 채운다. 그래서
초당 30개 키프레임만 있어도 60fps·144fps 어디서든 부드럽게 나온다.

### 뼈가 움직이면 피부가 따라오는 이유 — 스키닝

메시의 각 정점은 **"나는 LeftForeArm 에 0.7, LeftArm 에 0.3 만큼 묶여 있다"**
같은 가중치를 갖고 있다. 이것이 `.glb` 안의 **skin** 이다.

```
뼈가 새 자세로 이동
        ↓
각 정점이 자기가 묶인 뼈들의 이동량을 가중 평균해서 따라 이동   ← 스키닝(skinning)
        ↓
팔꿈치가 접히면 그 주변 정점이 자연스럽게 딸려 접힌다
```

**스키닝은 GPU 가 매 프레임 자동으로 한다. 코드가 관여하지 않는다.**
우리가 신경 쓸 것은 그 앞 단계 — **"어느 애니메이션을, 언제 틀 것인가"** 뿐이다.

> 🔑 **이것이 저사양에서 본 개수를 줄이는 이유다.** 뼈가 많을수록 매 프레임
> 갱신할 행렬이 늘고, 정점마다 참조할 뼈도 늘어난다. 예제의 캐릭터도 리깅
> 원본의 본 52개를 **22개로 감축**해서 구운 것이다.

---

## 10.3 Godot 이 `.glb` 를 **씬으로** 바꿔 준다

`.glb` 를 `res://` 안에 넣으면 Godot 이 임포트하면서 **자기가 다룰 수 있는 노드들로
번역**한다. 이 번역 규칙을 알면 "애니메이션이 어디 있는지"가 바로 보인다.

`.glb` 옆에 자동 생성되는 `.import` 파일을 열어 보면 이렇게 되어 있다.

```ini
importer="scene"                 ← 🔑 "씬 임포터" 로 처리한다
type="PackedScene"               ← 🔑 결과물은 PackedScene, 즉 씬이다
path="res://.godot/imported/character.glb-....scn"

[params]
nodes/apply_root_scale=true
nodes/root_scale=1.0
animation/import=true            ← 🔑 애니메이션도 함께 가져온다
animation/fps=30                 ← 키프레임을 초당 몇 개로 굽는가
meshes/generate_lods=true        ← 거리별 저해상도 메시를 자동 생성
skins/use_named_skins=true
```

**`type="PackedScene"` — 이 한 줄이 핵심이다.** `.glb` 는 Godot 안에서
**이미지가 아니라 씬**이다. `.tscn` 과 똑같이 인스턴싱해서 쓴다(§3).

### 번역 결과 — 이런 노드 트리가 된다

**아래는 실제로 임포트해서 찍은 것이다**(Godot 4.7.2).

```
Player (CharacterBody3D)          ← 우리 스크립트가 붙은 곳
├─ CollisionShape3D               ← 부딪히는 몸 (§9)
└─ character (Node3D)             ← .glb 인스턴스. 여기서부터는 임포터가 만든 것
   ├─ root (Node3D)               ⚠️ 이 중간 노드의 이름은 .glb 마다 다르다
   │  └─ Skeleton3D               ★ .glb 의 뼈 23개가 여기로
   │     └─ MeshInstance3D        ★ 메시(피부)
   └─ AnimationPlayer             ★ .glb 의 animations 가 전부 여기로 들어온다
```

> 🛑 **`AnimationPlayer` 는 `Skeleton3D` 의 형제가 아니다.** 씬 루트의 직계 자식이고,
> 중간 노드(`root`)의 **형제**다. 그리고 **그 중간 노드의 이름은 파일마다 다르다** —
> Blender 의 오브젝트 이름이 그대로 넘어오기 때문에 `root` 일 수도 `Armature` 일
> 수도 있다. 10.4 에서 **고정 경로 대신 타입으로 찾는 이유**가 바로 이것이다.

| `.glb` 안의 것 | Godot 노드 |
|---|---|
| `animations: [idle, walk, run, ...]` | **`AnimationPlayer`** 하나 + 그 안의 `Animation` 리소스 여러 개 |
| `skins` 의 joints (뼈들) | **`Skeleton3D`** 하나 |
| `meshes` | **`MeshInstance3D`** |
| 머티리얼·텍스처 | `StandardMaterial3D` 등 |

**"애니메이션은 어디서 오나"의 답이 이것이다.**
`.glb` 안의 애니메이션 배열 → 임포트 → **`AnimationPlayer` 노드 하나.**

### 🛑 실측 — 본 이름의 `:` 가 `_` 로 바뀐다

**본을 코드로 찾을 때 반드시 걸리는 함정이다.**

| | 이름 |
|---|---|
| `.glb` 안 | `mixamorig:Hips` |
| **Godot 임포트 후** | **`mixamorig_Hips`** |

**왜 바뀌는가** — 애니메이션 트랙의 경로가 이런 형식이기 때문이다(실측).

```
root/Skeleton3D:mixamorig_Hips
└──── 노드 경로 ───┘│└─ 본 이름 ─┘
                   콜론이 구분자다
```

`:` 는 `NodePath` 에서 **"여기부터는 속성 이름"** 을 뜻하는 예약 문자라, 본 이름에
그대로 두면 경로가 깨진다. 그래서 임포터가 `_` 로 치환한다.

```gdscript
skel.find_bone("mixamorig:Hips")   # 🛑 -1 이 나온다
skel.find_bone("mixamorig_Hips")   # ✅
```

### 실측 — 임포터가 트랙을 65% 버린다

`.import` 의 `animation/remove_immutable_tracks` 는 **기본이 `true`** 라 모르는 사이에
적용되고 있다. 같은 파일을 두 설정으로 재임포트해 `idle` 의 트랙을 세어 봤다.

| 설정 | `idle` 의 트랙 수 | 내역 |
|---|---|---|
| `false` | **66개** | Position 22 + Rotation 22 + Scale 22 — **glTF 채널 수 그대로** |
| **`true`** (기본) | **23개** | **Position 1 + Rotation 22** — Scale 은 전부 사라졌다 |

트랙별 키 개수를 보면 이유가 드러난다.

```
mixamorig_Hips        Position  키 30개   ← 변한다  → 남는다
mixamorig_Hips        Scale     키  1개   ← 안 변한다 → 제거
mixamorig_LeftUpLeg   Position  키  1개   ← 안 변한다 → 제거
mixamorig_LeftUpLeg   Rotation  키 28개   ← 변한다  → 남는다
```

🔑 **뼈는 회전만 한다.** 관절은 길이가 변하지 않으니 위치·크기가 고정이고,
**골반(`Hips`) 하나만 위치가 변한다**(걸을 때의 체중 이동). 10.2 에서 "채널 66개"
라고 한 것은 **파일 안의 이야기**이고, **엔진에 올라온 뒤에는 23개**다.

### 실측 — 임포트 직후의 기본값

**10.4 의 `_ready()` 가 왜 그 세 줄을 쓰는지가 이 표에 있다.**

| 항목 | 임포트 직후 | 뜻 |
|---|---|---|
| `Animation.loop_mode` | **`0` (`LOOP_NONE`)** — 전부 | 🛑 안 켜면 idle 이 2.03초에 얼어붙는다 |
| `callback_mode_process` | **`1` (`..._IDLE`)** | 렌더 프레임 갱신 → 이동과 어긋난다 |
| `Animation.step` | **`0.0333`** (=1/30) | `.import` 의 `animation/fps=30` |

```
AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_  PHYSICS=0  IDLE=1  MANUAL=2
Animation.  LOOP_NONE=0   LOOP_LINEAR=1   LOOP_PINGPONG=2
```

### 🛑 씬 트리에 `AnimationPlayer` 가 보이지 않는다 — 정상이다

**여기서 대부분 한 번 막힌다.** 씬에 `.glb` 를 넣으면 Scene 독에는 이것만 보인다.

```
Player  (CharacterBody3D)
├─ CollisionShape3D
└─ character          🎬     ← 펼침 화살표(▶)조차 없다
```

이름 오른쪽의 **영화 슬레이트 아이콘(🎬)** 이 **"이 노드는 별도 씬 파일의 인스턴스"**
라는 표시다. 바로 위에서 본 대로 `.glb` 는 `PackedScene` — 즉 **씬 인스턴스**이고,
**Godot 은 인스턴스된 씬의 내부를 기본적으로 감춘다.** 내부 노드는 **그 파일의 소유**라
이쪽 씬에서 함부로 건드리지 못하게 막는 것이다.

**`.glb` 만의 특성이 아니다** — 직접 만든 `.tscn` 을 인스턴싱해도 똑같이 접힌다(§3).

> 🛑 **Inspector 에는 원래 나오지 않는다.** Inspector 는 **선택한 노드 하나의 속성**을
> 보여주는 곳이지 자식 목록을 보여주는 곳이 아니다. `character` 를 고르면 `Node3D` 의
> 속성(Transform · Visibility · Process …)만 나오는 것이 맞다.

**펼치는 법:**

```
Scene 독에서 character 우클릭 → "Editable Children"(자식 편집 가능) 체크
```

> ⚠️ 켜 두면 하위 노드의 변경이 **이쪽 씬 파일에 저장된다.** 구경만 할 거면
> 확인한 뒤 다시 끈다.

### 🛑 펼쳤는데도 애니메이션이 안 보인다

**여기서 두 번째로 막힌다.** `AnimationPlayer` 를 선택해도 Inspector 에는
`Current Animation`·`Speed Scale` 같은 **속성만** 나오고 목록이 없어 보인다.
**보는 방법은 세 가지다.**

**① 가장 빠르다 — Inspector 맨 첫 줄의 `Current Animation` 드롭다운**

```
Inspector
  AnimationPlayer
    Current Animation   [        ∨ ]   ← 여기를 클릭
```

누르면 `idle`·`walk`·`run`… 이 그대로 나오고, 고르면 **뷰포트의 캐릭터가 즉시 그
자세로 바뀐다.** T-포즈가 풀리면 `.glb` 가 정상이라는 뜻이다. 재생은 되지 않는다.

**② 재생·트랙까지 — 하단 Animation 패널**

**이 패널이 닫혀 있어서 "애니메이션이 없다"고 오해하는 경우가 대부분이다.**

```
화면 맨 아래 탭 줄:  Output │ Debugger │ Audio │ Animation │ Shader Editor
                                                 └─ 이것을 클릭
```

| 상황 | 대처 |
|---|---|
| 탭 줄이 안 보인다 | **뷰포트와 화면 아래 경계선을 위로 드래그**해 패널을 키운다 |
| `Animation` 탭이 없다 | `AnimationPlayer` 를 **먼저 선택**해야 생긴다 |
| 눌렀는데 비어 있다 | 고른 것이 `Skeleton3D` 가 아니라 `AnimationPlayer` 가 맞는지 |

열리면 왼쪽 위에서 `walk` 를 고르고 **▶**. 아래에 **트랙 23개**가 늘어선다.

```
root/Skeleton3D:mixamorig_Hips          ◆──◆──◆──◆──◆   ← 키프레임 점들
root/Skeleton3D:mixamorig_LeftUpLeg     ◆────◆────◆
root/Skeleton3D:mixamorig_Spine         ◆──◆────◆──◆
```

**§10.2 에서 말한 "뼈의 시간별 자세표"가 바로 이 화면이다.**

**③ 씬을 거치지 않고 — Advanced Import Settings**

`.glb` **파일 자체**를 들여다본다. 씬에 올리기 전에도 쓸 수 있다.

```
1. FileSystem 독에서 character.glb 를 한 번 클릭
2. Scene 독 위의 탭 중 "Import" 를 클릭
3. 패널 아래쪽 "Advanced..." 버튼          ← 엔진 확인된 라벨
4. "Advanced Import Settings for 'character.glb'" 창이 열린다
5. 왼쪽 트리에서 애니메이션을 고르면 미리보기와 설정이 나온다
```

**④ 코드로 찍는다 — 화면에서 못 찾겠을 때 가장 확실하다**

```gdscript
print("애니 목록: ", _anim.get_animation_list())
# → 애니 목록: ["RESET", "attack", "death", "idle", "run", "walk"]

for n in _anim.get_animation_list():
    var a := _anim.get_animation(n)
    print("  %-8s 길이 %.2f초  트랙 %d개  루프 %d" % [n, a.length, a.get_track_count(), a.loop_mode])
# →   idle     길이 2.03초  트랙 23개  루프 0
#     walk     길이 1.40초  트랙 23개  루프 0   …
```

**목록이 비어 있으면 코드 문제가 아니라 `.glb` 문제다.** 10.1 의 파이썬으로
파일 자체를 확인한다.

**⑤ 실제 동작 — 게임을 실행한다(F5 / macOS ⌘B)**

🛑 **에디터는 `_ready()` 를 실행하지 않는다.** ①②③ 은 어디까지나 **에디터가 미리보기로
자세를 씌워 주는 것**이고, `play("idle")` 이 진짜로 걸리는 것은 실행할 때다.
그래서 **에디터에서 캐릭터가 T-포즈로 서 있는 것도 정상이다** — 리깅된 기본
자세(rest pose)를 그대로 보여 주고 있을 뿐이다.

### 🛑 임포트된 애니는 에디터에서 **읽기 전용**이다

애니 패널을 열고 트랙을 고쳐 보려다 막히는 지점이다.
**엔진 바이너리에 들어 있는 안내 문구가 그대로 설명해 준다**(엔진 확인).

```
Animation is read-only.
Can't change loop mode on animation instanced from an imported scene.
To change this animation's loop mode, navigate to the scene's
Advanced Import settings and select the animation.
```

**임포트로 만들어진 애니메이션은 `.glb` 에 속한 자원이라 에디터가 편집을 막는다.**
파일을 다시 임포트하면 덮어써질 것이므로, 에디터에서 고쳐 봐야 남지 않기 때문이다.

**그래서 루프를 켜는 길이 둘로 갈린다.**

| | ⓐ Advanced Import Settings | ⓑ 코드 (`_ready()`) |
|---|---|---|
| 저장되는가 | ✅ **`.import` 에 남는다** | 🛑 **남지 않는다.** 실행할 때마다 다시 켠다 |
| 캐릭터가 늘어나면 | **파일마다 손으로** | **코드 한 벌로 전부** |

10.4 의 예제가 ⓑ 를 쓰는 이유는 **캐릭터가 여러 종류일 때 코드 한 벌로 끝나기**
때문이다. 캐릭터가 하나뿐이라면 ⓐ 가 더 깔끔하다.

**실측 — 코드로는 정말 바뀐다.**

```
Animation 리소스 경로 : res://character.glb::Animation_2o1u4
변경 전 loop_mode = 0  →  변경 후 loop_mode = 1               ✅
walk(1.40초) 를 3초간 재생 → 재생위치 0.200초, is_playing = true
                             animation_finished 신호 = []      ← 두 바퀴를 돌았다
```

🔑 **리소스 경로의 `::` 를 눈여겨본다.** `.glb` **안에 들어 있는** 내장 리소스라는
표시이며, 그래서 **바꿔도 파일에 저장되지 않는다.** 매번 `_ready()` 에서 다시
켜야 하는 이유가 이것이다.

---

## 10.4 코드가 `AnimationPlayer` 를 잡는다

이제부터가 우리가 쓰는 코드다.

```gdscript
extends CharacterBody3D

## 애니메이션 이름 — .glb 안의 이름과 정확히 같아야 한다.
## 🛑 이 이름이 어긋나면 캐릭터가 T-포즈로 서 있기만 한다.
const ANIM_IDLE   := "idle"
const ANIM_WALK   := "walk"
const ANIM_RUN    := "run"
const ANIM_ATTACK := "attack"
const ANIM_DEATH  := "death"

var _anim: AnimationPlayer


func _ready() -> void:
    _anim = _find_animation_player(self)
    if _anim == null:
        push_error("AnimationPlayer 를 찾지 못했다 — .glb 가 리깅되지 않았을 수 있다")
        set_physics_process(false)
        return

    # ① 🛑 .glb 로 들어온 애니메이션은 기본이 '루프 없음'이다.
    #    이걸 안 켜면 idle 이 2.03초 재생하고 그대로 얼어붙는다.
    for name in [ANIM_IDLE, ANIM_WALK, ANIM_RUN]:
        if _anim.has_animation(name):
            _anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR

    # ② 캐릭터 애니메이션은 물리 프레임에 맞춘다.
    #    렌더 프레임에 두면 이동과 발이 미묘하게 어긋난다.
    _anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS

    # ③ 1회성 애니(attack·death)가 끝난 시점을 알기 위한 신호 (§5)
    _anim.animation_finished.connect(_on_animation_finished)

    _play(ANIM_IDLE)
```

### `_find_animation_player` — 왜 고정 경로를 쓰지 않는가

```gdscript
## .glb 안 어디에 있든 AnimationPlayer 를 찾는다.
func _find_animation_player(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer:
        return node
    for child in node.get_children():
        var found := _find_animation_player(child)
        if found != null:
            return found
    return null
```

`$character/AnimationPlayer` 라고 써도 지금은 동작한다. 그런데 **캐릭터 모델을
다른 `.glb` 로 교체하는 순간 루트 노드 이름이 바뀌어** 그 경로가 조용히 깨진다.
`.glb` 는 우리가 손으로 만든 씬이 아니라 **바깥에서 구워 온 것**이라 내부 구조를
우리가 통제하지 못한다. 그래서 **이름이 아니라 타입으로 찾는다.**

> §4 의 "다른 노드를 가리키는 세 가지 방법"과 같은 문제다. 노드 경로는 **이름에
> 의존하는 약한 연결**이고, 이름이 우리 손에 없을 때는 더욱 그렇다.

### 위 ①②③ 이 각각 무엇을 막는가

| | 안 하면 생기는 증상 |
|---|---|
| ① `loop_mode = LOOP_LINEAR` | **idle 이 2초 재생되고 얼어붙는다.** 가장 흔히 겪는 첫 증상 |
| ② `..._MODE_PROCESS_PHYSICS` | 이동은 물리(60Hz), 애니는 렌더(가변) 로 돌아 **발이 미끄러져 보인다** |
| ③ `animation_finished` 연결 | 공격 애니가 끝난 걸 몰라 **공격 자세로 굳는다** |

> 🔑 **`attack`·`death` 는 일부러 루프 목록에서 뺐다.** 한 번만 재생돼야
> `animation_finished` 신호가 날아온다. 루프를 걸면 그 신호는 영영 오지 않는다.

---

## 10.5 🛑 자동으로 재생되는 것이 아니다 — 코드가 매 프레임 고른다

**여기가 "키를 눌렀는데 왜 걷는가"의 진짜 답이다.**

```gdscript
func _physics_process(delta: float) -> void:
    # ── ⓐ 이동 (§9 와 완전히 같다. 애니메이션과 무관하다) ──────────────
    var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var dir := Vector3(input.x, 0.0, input.y)

    var speed := run_speed if _running else walk_speed
    velocity.x = dir.x * speed
    velocity.z = dir.z * speed
    velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
    move_and_slide()                      # ← 캐릭터가 실제로 이동하는 것은 이 줄이다

    # 이동 방향으로 몸을 돌린다. Godot 의 정면은 -Z 이므로 yaw = atan2(-x, -z)
    if dir.length_squared() > 0.001:
        var target_yaw := atan2(-dir.x, -dir.z)
        rotation.y = rotate_toward(rotation.y, target_yaw, turn_speed * delta)

    # ── ⓑ 애니메이션 선택 ★ 이동과 애니를 잇는 유일한 지점 ───────────
    if _busy:
        return                            # 공격 재생 중이면 덮어쓰지 않는다
    if dir.length_squared() > 0.001:
        _play(ANIM_RUN if _running else ANIM_WALK)
    else:
        _play(ANIM_IDLE)
```

**ⓐ 와 ⓑ 는 서로 아무것도 공유하지 않는다.** `move_and_slide()` 는 애니메이션의
존재를 모르고, `_play()` 는 캐릭터가 어디 있는지 모른다.
**둘을 잇는 것은 `if dir.length_squared() > 0.001` 이라는 판단 한 줄뿐이다.**

> 🛑 **ⓑ 를 통째로 지워 보면 확실히 이해된다.** 캐릭터는 여전히 화살표 키로
> 잘 이동하지만 `idle` 자세 그대로 미끄러져 다닌다. 반대로 ⓐ 를 지우면
> 제자리에서 열심히 걷기만 한다.

### `_play()` 의 가드 — 실측으로 확인한 진짜 효과

```gdscript
## 같은 애니면 다시 걸지 않는다.
func _play(name: String) -> void:
    if _anim.current_animation == name:
        return
    if not _anim.has_animation(name):
        push_warning("애니메이션 없음: %s (있는 것: %s)" % [name, _anim.get_animation_list()])
        return
    _anim.play(name, blend_time)
```

`_physics_process` 는 **초당 60번** 돈다. 그러면 저 `return` 이 없을 때
`play("walk")` 가 초당 60번 불리는데 — **무슨 일이 일어나는가?**

**재 보면 아무 일도 일어나지 않는다**(4.7.2 실측).

```
가드 없이 매 프레임 play("walk", 0.15) × 30프레임 → 재생위치 0.5000초
가드 두고 같은 0.5초 진행                          → 재생위치 0.5000초
LeftUpLeg 자세 — 두 경우가 소수점까지 완전히 동일
```

🔑 **이미 재생 중인 것과 같은 이름이면 `play()` 는 아무것도 하지 않는다.**
"매 프레임 `play()` 하면 되감겨 얼어붙는다" 는 것은 **Godot 3 시절의 이야기이고
4 에서는 성립하지 않는다.**

**그래도 가드는 남긴다** — 매 프레임의 문자열 비교와 블렌드 준비를 건너뛰고,
"같은 애니면 손대지 않는다" 는 의도가 코드에 드러나기 때문이다.
**다만 없다고 화면이 깨지지는 않는다.**

### 🛑 진짜 함정은 정반대다 — `play()` 로는 되감기지 않는다

```
attack 을 0.6초까지 재생한 뒤 play("attack") 다시 호출
   → 재생위치 0.600초   🛑 처음부터 다시 재생되지 않는다
```

**공격 버튼을 연타해도 진행 중인 재생이 그대로 이어진다.** 1회성 애니를 확실히
처음부터 재생하려면 **명시적으로 되감아야 한다.**

| 방법 | 결과 |
|---|---|
| `play()` 만 | **0.600초 — 되감기지 않음** |
| `stop()` → `play()` | **0.000초** ✅ 대신 블렌드 출발 자세도 지워져 조금 딱딱해진다 |
| `seek(0.0, true)` | **0.000초** ✅ 블렌드를 살리고 싶을 때 |

**`play()` 는 "재생을 시작하라"는 명령이지 "처음부터 다시 틀어라"가 아니다.**
한 번 걸어 두면 `AnimationPlayer` 가 알아서 끝까지, 루프면 무한히 돌린다 —
**자동인 부분은 여기뿐이다.**

### `blend_time` — 자세가 툭 끊기지 않게

```gdscript
_anim.play(name, blend_time)      # blend_time = 0.15 (초)
```

두 번째 인자는 **크로스페이드 시간**이다. `idle` → `walk` 로 바꿀 때 0.15초 동안
두 자세를 섞어 준다. `0` 으로 두면 자세가 순간이동하듯 툭 바뀌어 어색하다.

| 값 | 느낌 |
|---|---|
| `0.0` | 딱딱하게 끊긴다 |
| **`0.1 ~ 0.2`** | **일반적인 캐릭터 이동에 적당하다** |
| `0.5` 이상 | 흐물거린다. 반응이 느리게 느껴진다 |

**실측 — 가중치는 `blend_time` 동안 선형으로 옮겨 간다.** `blend_time = 0.6` 으로
idle → run 전환하며, 같은 시각의 **순수 idle 자세**와 **순수 run 자세** 사이 어디에
있는지 쟀다(`LeftUpLeg` 기준).

```
 t=0.00초 → run 쪽으로   0%
 t=0.15초 → run 쪽으로  18%
 t=0.30초 → run 쪽으로  45%      ← 절반 지점에서 거의 정확히 절반
 t=0.45초 → run 쪽으로  73%
 t=0.60초 → run 쪽으로 100%      ← blend_time 에 정확히 도달
```

### 1회성 애니 — 시작과 끝을 코드가 관리한다

```gdscript
var _busy := false        # 공격 재생 중 — 이동 애니가 덮어쓰지 않게

func _on_attack_pressed() -> void:
    _busy = true
    _anim.stop()                            # 🛑 이게 없으면 연타가 무시된다(위 실측)
    _anim.play(ANIM_ATTACK, blend_time)     # 루프가 아니므로 한 번 재생하고 끝난다

func _on_animation_finished(anim_name: StringName) -> void:
    if anim_name == ANIM_DEATH:
        return                              # 쓰러진 채로 둔다
    if anim_name == ANIM_ATTACK:
        _busy = false                       # 다음 프레임에 이동/대기 애니로 자연히 돌아간다
```

**`_busy` 를 푸는 것만으로 복귀가 끝난다.** `_physics_process` 의 ⓑ 가 다음 프레임에
알아서 `walk` 또는 `idle` 을 고르기 때문이다. "공격이 끝났으니 idle 을 틀어라"라고
직접 쓸 필요가 없다 — **상태를 풀면 매 프레임 도는 판단이 알아서 메꾼다.**

### 실측 — `animation_finished` 는 루프 애니에서 영영 오지 않는다

```
attack (루프 없음) 1.5초 진행 → 받은 신호: ["attack"]   ✅
walk   (루프)      3.0초 진행 → 받은 신호: []           🛑 두 바퀴를 돌아도 안 온다
```

**그래서 10.4 에서 `attack`·`death` 를 루프 목록에 넣지 않은 것은 취향이 아니라 필수다.**
루프를 걸면 `_busy` 가 영원히 `true` 로 남아 **캐릭터가 공격 자세로 굳는다.**

### 실측 — 루프 없는 애니가 끝나면 마지막 자세로 멈춘다

```
death (2.43초) 를 3.3초까지 진행
   → is_playing() = false,  current_animation = ""   (빈 문자열)
   → 마지막 프레임 자세, 즉 쓰러진 채로 유지된다
```

🔑 **`current_animation` 이 빈 문자열이 되므로** 나중에 `_play(ANIM_IDLE)` 을 부르면
가드를 정상적으로 통과한다 — 부활 처리가 별도 초기화 없이 동작하는 이유다.

---

## 10.6 🛑 애니메이션은 캐릭터를 이동시키지 않는다

초보자가 가장 자주 헷갈리는 부분이라 따로 못 박는다.

| 무엇이 | 누가 담당하나 |
|---|---|
| 캐릭터가 **공간에서 이동**한다 | `velocity` + **`move_and_slide()`** — 물리 |
| 캐릭터가 **몸을 돌린다** | `rotation.y` — 우리 코드 |
| **팔다리가 움직인다** | **`AnimationPlayer`** — 뼈만 움직인다 |

Mixamo 같은 곳의 애니메이션은 **제자리(in-place)** 로 만들어져 있다.
`walk` 를 틀면 캐릭터는 **러닝머신 위에서처럼 그 자리에서 걷는 동작만** 한다.
실제 전진은 전적으로 `velocity` 와 `move_and_slide()` 의 몫이다.

**실측으로 확인한다.** `walk` 를 1.4초(한 바퀴) 재생하며 씬 루트와 골반 본을 함께 찍었다.

```
 t=0.0초   루트 (0,0,0)   Hips 본 Z = -0.0074
 t=0.2초   루트 (0,0,0)   Hips 본 Z = +0.0211
 t=0.4초   루트 (0,0,0)   Hips 본 Z = -0.0126
 t=0.8초   루트 (0,0,0)   Hips 본 Z = +0.0217
 t=1.2초   루트 (0,0,0)   Hips 본 Z = -0.0263
```

**루트는 1mm 도 움직이지 않고, 골반만 ±2.6cm 안에서 앞뒤로 흔들린다.**
"애니메이션이 캐릭터를 옮긴다"는 인상은 **그 자리에서 걷는 동작**과 **물리가 만드는
전진**이 겹쳐 보이기 때문에 생긴다.

### 그래서 발이 미끄러진다 — foot sliding

```gdscript
@export var walk_speed: float = 2.0     # 이 숫자와
                                        # walk 애니의 보폭·재생속도가 안 맞으면
                                        # 발이 지면에서 주르륵 미끄러진다
```

`walk_speed` 를 5.0 으로 올려 놓고 `walk` 애니를 그대로 두면 **스케이트를 타듯**
보인다. 맞추는 방법은 두 가지다.

| 방법 | 어떻게 |
|---|---|
| **속도를 애니에 맞춘다** (쉽다) | 애니가 자연스러워 보이는 속도값을 찾아 `walk_speed` 를 고정 |
| **애니 재생속도를 속도에 맞춘다** | `_anim.speed_scale = velocity.length() / 기준속도` |

> 🔑 **근본적으로 푸는 방법은 Root Motion 이다** — 애니메이션에 담긴 실제 이동량을
> 읽어 그만큼 캐릭터를 옮기는 방식이라 원리적으로 미끄러지지 않는다. 대신 이동을
> 애니가 지배하게 되어 네트워크 동기화·조작감이 까다로워진다.
> [animation-3d.md §9](../animation-3d.md) 에서 다룬다.

---

## 10.7 전체 흐름 한 장

```
[Blender · Mixamo]  뼈의 시간별 자세를 키프레임으로 구움
        ↓
   character.glb    메시 + 뼈 22개 + 애니 6종(idle·walk·run·attack·death·RESET)
        ↓            Godot 임포트 — .import 의 animation/import=true
   씬(PackedScene)   character ├─ AnimationPlayer   ← 애니 6종이 여기 들어온다
                              └─ Skeleton3D → MeshInstance3D
        ↓
┌─ 매 물리 프레임 (60Hz) ────────────────────────────────────────────┐
│  화살표 키 → Input.get_vector() → dir                              │
│      ├─ velocity 설정 → move_and_slide()  ······ 캐릭터가 실제 이동  │
│      ├─ rotation.y 보간 ························ 몸을 진행방향으로  │
│      └─ if dir 있음 → _play("walk")  ★ 이동과 애니를 잇는 유일한 줄 │
└────────────────────────────────────────────────────────────────────┘
        ↓  (여기서부터는 엔진이 자동으로 한다)
   AnimationPlayer   현재 재생 시각의 자세를 표에서 읽어 뼈 22개에 써 넣는다
        ↓
   Skeleton3D        뼈의 최종 자세 확정 (부모 → 자식 순으로 누적)
        ↓
   GPU 스키닝        각 정점이 자기가 묶인 뼈를 따라 변형
        ↓
      화면
```

---

## 10.8 직접 확인해 보는 법

**막히면 추측하지 않는다.** 애니메이션 문제는 확인 방법이 명확하다.

### ① 코드에 어떤 애니가 보이는지 찍어 본다

```gdscript
func _ready() -> void:
    var ap := _find_animation_player(self)
    print("찾은 AnimationPlayer: ", ap)
    print("가지고 있는 애니메이션: ", ap.get_animation_list())
    for n in ap.get_animation_list():
        var a := ap.get_animation(n)
        print("  %s — 길이 %.2f초, 트랙 %d개, 루프 %s"
            % [n, a.length, a.get_track_count(), a.loop_mode])
```

**이 출력이 비어 있으면 코드 문제가 아니라 `.glb` 문제다.** 10.1 의 파이썬으로
파일 자체를 확인한다.

### ② 에디터에서 눈으로 본다

```
Scene 독 → character 우클릭 → Editable Children
   → AnimationPlayer 선택 → 하단 애니메이션 패널에서 ▶ 재생
```

### ③ 파일 자체를 의심할 때

10.1 의 `glb_peek.py` 로 `.glb` 안의 `animations` 배열을 직접 본다.
**여기에 이름이 없으면 리깅·굽기 단계로 돌아가야 한다.** Godot 에서 할 수 있는 일이 없다.

---

## 10.9 자주 막히는 곳

| 증상 | 원인 | 해결 |
|---|---|---|
| **T-포즈로 서 있기만 한다** | 애니 이름이 `.glb` 안의 것과 다르다 | `get_animation_list()` 로 실제 이름 확인 후 상수 수정 |
| **idle 이 잠깐 나오고 얼어붙는다** | `loop_mode` 가 기본값(루프 없음) | `_ready` 에서 `LOOP_LINEAR` 로 설정 (10.4 ①) |
| **씬 트리에 `AnimationPlayer` 가 없다** | 인스턴스된 씬은 내부가 접힌다 (정상) | `.glb` 노드 우클릭 → **Editable Children** (10.3) |
| **펼쳤는데 애니 목록이 안 보인다** | 하단 **Animation 패널**이 닫혀 있다 | 아래 `Animation` 탭 · Inspector 의 `Current Animation` (10.3) |
| **에디터에서 T-포즈로 서 있다** | 에디터는 `_ready()` 를 실행하지 않는다 (정상) | 실행해서 확인한다 (10.3) |
| **애니 트랙을 고칠 수 없다 / 루프를 못 켠다** | 임포트된 애니는 에디터에서 **읽기 전용** | `Advanced...` 또는 코드로 켠다 (10.3) |
| **공격 버튼 연타가 무시된다** | 🛑 `play()` 는 같은 애니를 **되감지 않는다** | `stop()` 또는 `seek(0.0, true)` (10.5) |
| **`find_bone("mixamorig:Hips")` 가 −1** | 임포트하며 `:` 가 `_` 로 치환된다 | `mixamorig_Hips` 로 찾는다 (10.3) |
| **발이 지면에서 미끄러진다** | 이동 속도와 애니 보폭 불일치 | `walk_speed` 조정 · `speed_scale` · Root Motion (10.6) |
| **공격 자세로 굳는다** | `animation_finished` 미연결 또는 공격 애니에 루프가 걸림 | 신호 연결 확인 · 루프 목록에서 제외 (10.4 ③) |
| **이동은 되는데 자세가 안 바뀐다** | `_physics_process` 의 애니 선택 블록이 없다 | 10.5 ⓑ 를 추가 |
| **`AnimationPlayer` 를 못 찾는다** | `.glb` 에 애니가 없거나 리깅이 안 됨 | 10.8 ③ 으로 파일 확인 |
| **애니와 이동이 미묘하게 어긋난다** | 애니가 렌더 프레임에서 갱신됨 | `callback_mode_process` 를 PHYSICS 로 (10.4 ②) |

---

## 10.10 여기서 부족해지면 — `AnimationTree` 로 간다

지금까지의 방식(`AnimationPlayer` + `if` 문)은 **애니메이션이 5~6종이고 전환 규칙이
단순할 때** 충분하다. 데모·프로토타입은 대부분 여기서 끝난다.

**다음 요구가 생기면 손으로 관리하기 어려워진다.**

| 요구 | `if` 문으로는 |
|---|---|
| 걷기 ↔ 달리기를 **속도에 따라 연속적으로** 섞고 싶다 | 두 애니를 동시에 가중치로 섞을 방법이 없다 |
| 상체는 공격, 하체는 달리기를 **동시에** | 불가능 |
| 상태가 15개로 늘고 전이 규칙이 복잡해졌다 | `if` 가 걷잡을 수 없이 늘어난다 |
| 애니가 **실제 이동량을 결정**해야 한다 (Root Motion) | 지원되지 않는다 |

그때 **`AnimationTree`** 로 옮긴다. `AnimationPlayer` 를 없애는 것이 아니라,
**그 위에 얹어 자동으로 조종하는 층**을 하나 더 두는 것이다.

```
AnimationTree           ← 상태 머신 · 블렌드 스페이스로 "무엇을 얼마나 섞을지" 결정
      ↓  조종
AnimationPlayer         ← 애니메이션 창고 (지금까지 우리가 직접 다룬 것)
      ↓
  Skeleton3D → 화면
```

→ [animation-3d.md](../animation-3d.md) 로 간다.
**§1(3계층 구조) → §2(AnimationPlayer) → §5(상태 머신) → §6(블렌드 스페이스)** 순서를 권한다.

---
