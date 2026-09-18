# 동적 다운로드 — 자산을 앱 밖에 두고 실행 중에 받는다

> **이 문서로 오는 상황** — 앱 용량이 스토어 한도를 넘는다 · **모바일만 서버에서 받고 데스크톱(Steam)은 전부 번들에 넣고 싶다** ·
> `ProjectSettings.load_resource_pack()` 을 실제 배포에 쓰려 한다 · 팩을 받았는데 화면에 안 붙는다 · 같은 파일이 번들에도 팩에도 들어갔다

> **형제 문서와의 경계**
> | 문서 | 무엇을 다루나 |
> |---|---|
> | [export-build.md §7](export-build.md#7-패치-배포와-델타-인코딩-patch-pck) | **이미 낸 앱을 고치는** 패치 PCK(델타 인코딩·`--export-patch`) |
> | **이 문서** | **처음부터 앱에 넣지 않은** 자산을 실행 중에 받아 쓰는 것 |
> | [export-build.md §6](export-build.md#6-export_presetscfg-포맷) | `exclude_filter` 문법 그 자체 |
> | [resources-assets.md](resources-assets.md) | 임포트 설정·`.import` 리맵이 무엇인가 |

이 문서의 숫자는 **Godot 4.7.2-stable 실측**이고, 운영 근거는 라리엔 3D(모바일 MMORPG · Android·iOS 배포 중 · 팩 1개 **974파일 / 181,973,692바이트**)의 실제 사고 기록이다.
추측으로 고쳐 쓰지 않는다.

## 목차

0. [세 줄 결론](#0-세-줄-결론)
1. [왜 나누나 — 스토어 한도와 왕복 비용](#1-왜-나누나--스토어-한도와-왕복-비용)
2. [핵심은 PCK 하나 — 경로가 그대로 `res://` 다](#2-핵심은-pck-하나--경로가-그대로-res-다)
3. [🛑 데스크톱은 받지 않는다 — 플랫폼으로 갈리는 빌드](#3--데스크톱은-받지-않는다--플랫폼으로-갈리는-빌드)
4. [무엇을 팩에 넣나 — 🛑 리맵(`.import`)이 빠지면 하나도 안 붙는다](#4-무엇을-팩에-넣나---리맵import이-빠지면-하나도-안-붙는다)
5. [서버에 무엇을 어떻게 놓나](#5-서버에-무엇을-어떻게-놓나)
6. [런타임 계약 10가지](#6-런타임-계약-10가지)
7. [Godot 고유의 함정 셋](#7-godot-고유의-함정-셋)
8. [검증 — 무엇을 어떻게 재나](#8-검증--무엇을-어떻게-재나)
9. [체크리스트](#9-체크리스트)

---

## 0. 세 줄 결론

1. **받는 코드는 어렵지 않다.** `load_resource_pack()` 이 `res://` 위에 팩을 통째로 겹치므로,
   마운트한 뒤에는 `load("res://…")` 가 **번들일 때와 똑같이** 성공한다. 로더를 두 벌 만들지 않는다.
2. **어려운 것은 "번들과 팩이 겹치지 않게 유지하는 일"이다.** 같은 파일이 양쪽에 있으면
   Godot 은 **오류 없이 번들 것을 계속 쓴다**(§4). 조용한 실패라 테스트도 통과한다.
3. 🛑 **플랫폼마다 다르게 낸다면 반드시 두 곳을 같이 바꾼다** — **런타임 게이트**와 **export 필터**.
   한쪽만 바꾸면 한쪽 플랫폼에서 자산이 **영영** 보이지 않는다(§3.1 — 실제로 났던 사고다).

---

## 1. 왜 나누나 — 스토어 한도와 왕복 비용

| 플랫폼 | 한도 | 넘으면 |
|---|---|---|
| Google Play (AAB) | **다운로드 크기 200MB** (실무 안전선 160MB) | 업로드 거부 |
| App Store | 셀룰러 다운로드 경고선 | 설치 이탈 |
| Steam·itch.io (데스크톱) | **사실상 없다** | — |

> 🔑 **그래서 데스크톱은 나눌 이유가 없다.** 한도가 없는 쪽까지 나누면 이득 없이 **오프라인 실패 경로만** 생긴다.
> 이것이 §3 의 전부다.

### 나눌 때는 파일 단위가 아니라 묶음 단위로 나눈다 (실측)

| 측정 | 값 | 무엇이 정해지나 |
|---|---|---|
| 파일 1개 왕복 지연 (CDN · APAC) | **235~509ms** — 33KB 와 1.7MB 가 **비슷하다** | 비용의 대부분이 전송이 아니라 **왕복**이다 |
| 25파일 22.94MiB | 개별 순차 **11.81초** vs 한 묶음 **1.95초** | **6배** |
| 동시 다운로드 수 | 순차 13.8Mbps → 4개 동시 **25.3Mbps** | 동시 4 |

🛑 **그래서 기물마다·청크마다 팩을 쪼개지 않는다.** 왕복만 늘어난다.
팩이 커지면 **지역(zone)·던전 단위**로 쪼갠다. 라리엔은 지금도 팩이 **하나**다.

### 🛑 걸어서 닿는 곳은 팩 경계가 될 수 없다

오픈월드에서 가장 자주 틀리는 판단이다.

| 팩 경계로 **써도 되는 것** | 팩 경계로 **쓰면 안 되는 것** |
|---|---|
| ✅ 텔레포트 · 존 전환 · 던전 입장 (로딩 화면이 있다) | 🛑 **청크 경계** — 걷다가 팩이 없으면 지면이 사라진다 |
| ✅ 레벨 게이트로 열리는 신규 권역 | 🛑 같은 맵 안의 인접 지역 |

---

## 2. 핵심은 PCK 하나 — 경로가 그대로 `res://` 다

```gdscript
# ① 받는다 (§6 이 이 한 줄을 감싼다)
# ② 얹는다 — 이 순간 팩 안의 파일이 res:// 트리에 나타난다
var ok := ProjectSettings.load_resource_pack("user://packs/props-<sha16>.pck")

# ③ 이후 코드는 번들일 때와 한 글자도 다르지 않다
var scene := load("res://maps/props/trees/pine/pine.tscn")
```

`load_resource_pack(pack: String, replace_files: bool = true, offset: int = 0)`

| 인자 | 의미 | 주의 |
|---|---|---|
| `replace_files` | `true`(기본)면 같은 경로의 기존 파일을 **팩 것으로 덮는다** | 🛑 **이미 메모리에 로드된 리소스는 교체되지 않는다** |
| 반환값 | 성공 `true` / 실패 `false` | 🛑 **예외가 아니라 `false`다** — 확인하지 않으면 조용히 지나간다 |

### 실측 — 마운트 전에 실패한 로드는 캐시에 남지 않는다

| 확인한 것 | 결과 |
|---|---|
| 마운트 **전** 없는 리소스를 `load()` | `null` · `ResourceLoader.exists()` = `false` |
| `load_resource_pack()` | `true` |
| 마운트 **후** **같은 경로**를 다시 `load()` | ✅ **성공** — 🛑 **실패가 캐시에 남지 않는다** |
| 트리에 이미 있는 노드의 리소스를 교체 | ✅ **재시작 없이 화면이 바뀐다** |

> 🔑 **그래서 "먼저 들어가고, 도착하면 바꾼다" 가 성립한다.** 팩을 기다리며 로딩 화면에 세워 둘 필요가 없다.
> 플레이스홀더로 먼저 그리고, 팩이 오면 **이미 화면에 서 있는 것까지** 교체한다.
> (Flutter/Flame 은 실패한 Future 를 캐시에 남겨 이것이 불가능했다 — 엔진 차이다.)

🛑 **그렇다고 아무 때나 `load()` 해도 된다는 뜻은 아니다.** "실패하면 나중에 다시" 라는 재시도 루프는 만들지 않는다.
`load()` 는 팩 확보 함수 뒤에 부른다.

### 원시 파일(PNG·JSON)을 올리면 로더가 두 벌이 된다

| 무엇을 올리나 | 데스크톱 | 모바일 | 코드 |
|---|---|---|---|
| ✅ **PCK** | `load("res://…")` | 마운트 뒤 `load("res://…")` | **한 벌** |
| 🛑 PNG·JSON 원시 파일 | `load()` | `Image.load_png_from_buffer()` … | **두 벌** |

PCK 로 올리면 분기가 **"받을까 말까" 한 곳뿐**이다. 원시 파일을 올려야 한다면 로더 함수 하나로 감싸 분기를 그 안에 숨긴다.

---

## 3. 🛑 데스크톱은 받지 않는다 — 플랫폼으로 갈리는 빌드

**모바일(Android·iOS)만 받고 데스크톱(Windows·macOS·Steam)은 전부 번들에 넣는** 구성이다.
가장 흔한 요구이고, **가장 자주 틀리는 곳**이다.

### 3.1 두 곳을 **같이** 바꾼다 — 한쪽만 바꾸면 나는 두 사고

```
 ┌── 런타임 게이트 ──────────┐        ┌── 빌드(export 필터) ─────┐
 │ 이 빌드가 팩을 받는가?     │   ×    │ 이 빌드의 번들에서 뺄까?  │
 └───────────────────────────┘        └──────────────────────────┘
```

| | 런타임: 받는다 | 런타임: 안 받는다 |
|---|---|---|
| **빌드: 번들에서 뺐다** | ✅ 모바일의 정상 동작 | 🛑 **사고 A — 자산이 영영 없다** |
| **빌드: 번들에 남겼다** | 🛑 **사고 B — 받고도 번들 것을 쓴다** | ✅ 데스크톱의 정상 동작 |

**🛑 사고 A — 데스크톱에서 기물이 영영 보이지 않는다** (라리엔 2026-09-12)
빌드 도구가 `re.subn()` 으로 **모든 프리셋**의 `exclude_filter` 를 고쳤다.
데스크톱 번들에서도 자산이 빠졌는데 런타임은 데스크톱에서 꺼져 있으니 **받지도 않는다.**
→ 고친 뒤: 프리셋을 **플랫폼으로 걸러** 모바일만 고친다.

**🛑 사고 B — 받았는데 번들 것을 계속 쓴다 (오류 0줄)**
같은 파일이 번들에도 팩에도 있으면, 그 리소스는 이미 번들에서 로드돼 있어
**팩이 덮지 못한다.** 로그에 `[팩 1개를 받았다]` 가 찍히는데 화면은 그대로다. 조용한 실패다.
→ 팩에 넣은 경로는 **반드시** 그 빌드의 번들에서 뺀다.

> 🔑 **두 사고의 교훈은 하나다** — 팩 목록·런타임 게이트·export 필터는 **한 소스에서 파생**시킨다.
> 사람이 두 곳에 손으로 적으면 반드시 어긋난다.

### 3.2 무엇으로 플랫폼을 가르나 — `OS.has_feature()`

```gdscript
## 다운로드가 켜져 있는가 — 모바일이고, 빌드가 주소를 심었는가.
static func enabled() -> bool:
    if not (OS.has_feature("android") or OS.has_feature("ios")):
        return false          # 🛑 Windows·macOS(Steam)는 전부 번들에 있다
    return not base_url().is_empty()
```

**기본 기능 문자열** — 별도 설정 없이 항상 참인 것들.

| 문자열 | 언제 참인가 |
|---|---|
| `android` · `ios` | 그 플랫폼으로 내보낸 앱 |
| `windows` · `macos` · `linux` | 데스크톱 |
| `mobile` · `pc` · `web` | 분류(모바일 전체 / 데스크톱 전체 / 웹) |
| `editor` | **에디터에서 실행 중** — 내보낸 앱에서는 거짓 |
| `debug` · `release` | 내보내기 모드 |

> 🔑 `OS.has_feature("mobile")` 한 줄로도 된다. 라리엔이 `android`·`ios` 를 따로 쓰는 것은
> 나중에 한쪽만 끄는 상황을 열어 두기 위해서다. 어느 쪽이든 **표현이 하나여야** 한다.

#### `custom_features` 는 언제 필요한가

프리셋의 `custom_features="r2"` 에 이름을 적으면 `OS.has_feature("r2")` 가 그 빌드에서만 참이 된다.

| | 플랫폼 기능(`android`/`ios`) | 커스텀 기능(`r2`) |
|---|---|---|
| 설정 | **없다** — 엔진이 준다 | 프리셋마다 사람이 적는다 |
| 프리셋을 새로 만들 때 | 저절로 맞는다 | 🛑 **적는 것을 잊으면 조용히 꺼진다** |
| 같은 플랫폼에서 켜고 끄기 | ❌ 안 된다 | ✅ 된다 |

**판단 한 줄** — 경계가 **플랫폼과 같으면** `OS.has_feature("android")`,
경계가 플랫폼을 **가로지르면**(예: 같은 Android 인데 스토어판은 받고 사내 QA 판은 다 넣는다) `custom_features`.
라리엔은 경계가 플랫폼과 정확히 같아서 `custom_features` 를 **비워 둔다** — 프리셋이 7개라 적어 넣는 자리가 7군데 생기고, 하나만 빠져도 조용히 꺼지기 때문이다.

### 3.3 🛑 `exclude_filter` 는 빌드 때만 넣고 **되돌린다**

`export_presets.cfg` 에 제외 목록을 **박아 두지 않는다.** 빌드 직전에 넣고 직후에 지운다.

```bash
python3 tools/apply_lazy_download.py --apply     # 빌드 직전 — 필터 주입 + 주소 심기
godot --headless --path . --export-release "Play AAB" build/app.aab
python3 tools/apply_lazy_download.py --restore   # 빌드 직후 (반드시)
python3 tools/apply_lazy_download.py --check     # 지금 상태 확인
```

| 이유 | 설명 |
|---|---|
| **에디터가 깨진다** | 박아 두면 개발 중에도 자산이 빠진 것처럼 다뤄야 한다. 저작자는 늘 **전부 있는** 트리에서 일한다 |
| **목록이 파생값이다** | 기물이 늘고 줄 때마다 사람이 `.cfg` 를 고칠 수는 없다 |
| **`.cfg` 는 사람이 에디터로 여는 파일** | 도구가 상시 고치면 diff 가 오염되고 충돌이 난다 |

**플랫폼으로 걸러 고치는 부분** — 프리셋 블록을 잘라 `platform=` 을 보고 판정한다.

```python
MOBILE_PLATFORMS = ("Android", "iOS")   # 🛑 Windows·macOS 는 넣지 않는다

heads = list(re.finditer(r'^\[preset\.(\d+)\]$', text, re.M))
for i in range(len(heads) - 1, -1, -1):          # 🔑 뒤에서부터 — 앞쪽 위치가 밀리지 않는다
    start = heads[i].start()
    end = heads[i + 1].start() if i + 1 < len(heads) else len(text)
    block = text[start:end]
    plat = re.search(r'^platform="([^"]*)"', block, re.M)
    if plat is None or plat.group(1) not in MOBILE_PLATFORMS:
        continue                                 # ← 데스크톱은 건너뛴다
    ...  # 이 블록의 exclude_filter 에만 추가
```

🛑 **`re.sub` 로 파일 전체를 한 번에 고치지 않는다.** 그것이 사고 A 였다.

### 3.4 배포 주소는 빌드가 심고, **비면 꺼진다**

```gdscript
const BASE_URL_SETTING := "laryen/asset_packs/base_url"   # [laryen] 절의 asset_packs/base_url

static func base_url() -> String:
    if not ProjectSettings.has_setting(BASE_URL_SETTING):
        return ""
    return String(ProjectSettings.get_setting(BASE_URL_SETTING, ""))
```

이 값이 **비면 동적 다운로드가 통째로 꺼진다.** 그래서 **에디터와 debug 빌드는 아무 설정 없이 저절로 꺼진 상태**가 되고,
릴리스 빌드만 주소를 심는다. 안전판이 게이트와 같은 값 하나로 통일된다.

> 🛑🛑 **`project.godot` 은 첫 `/` 앞이 절 이름이다.** `laryen/asset_packs/base_url` 은
> `[laryen]` 절의 `asset_packs/base_url` 로 써야 한다. 라리엔은 2026-09-10 까지 이 줄을
> `[application]` 절 끝에 붙여 런타임 키가 `application/laryen/asset_packs/base_url` 이 되었고,
> **모든 릴리스에서 다운로드가 한 번도 켜지지 않았다**(로그 0줄). 검증이 값을 스스로 덮어써서 몇 주 동안 가려졌다.

### 3.5 검사만 예외로 뚫는다

데스크톱 헤드리스 검사에서 "켜진 빌드" 를 검증하려면 게이트를 통과할 길이 필요하다.

```gdscript
## 🧪 검사 전용 — 데스크톱 헤드리스에서 모바일처럼 동작시킨다.
## 🛑 게임 코드는 이 값을 건드리지 않는다.
static var force_mobile := false
```

없으면 **켜진 빌드의 동작을 아예 검증할 수 없다**(CI 가 전부 데스크톱이므로).
🛑 이름에 `force_`·주석에 🧪 를 붙여 **제품 경로가 아님을 코드에서 읽히게** 한다.

### 3.6 폴더 규칙(`remote/`) 과 파생 목록 — 어느 쪽을 쓰나

| | 폴더 규칙 (`res://remote/**` 를 팩으로) | 파생 목록 (씬에서 읽어 만든다) |
|---|---|---|
| 필터 | `exclude_filter="remote/*"` **한 줄 고정** | 빌드마다 목록을 만들어 주입 |
| 저작자가 할 일 | 🛑 **파일을 옮겨 둬야 한다** | ✅ 없다 — 늘 하던 자리에 둔다 |
| 새 자산 | 폴더에 안 넣으면 번들에 남는다(조용히) | 저절로 따라온다 |
| 도구 | 거의 필요 없다 | 스캐너가 필요하다 |
| 맞는 곳 | 자산 구성이 단순·안정적일 때 | 저작자가 여럿이고 자산이 계속 느는 팀 |

라리엔은 **파생 목록**이다. 기물 씬의 시각 슬롯(`visual_path`)을 훑어 목록을 만들고,
`--print-exclude` 가 그 목록을 그대로 export 필터에 넘긴다. **사람이 목록을 쓰지 않는다.**

🛑 **폴더 규칙을 쓸 때 반드시 같이 해야 하는 것** — 데스크톱 프리셋의
`include_filter`(비리소스 파일)도 확인한다. `remote/` 안에 `.json`·`.txt` 가 있으면
`export_filter="all_resources"` 만으로는 들어가지 않는다 — `include_filter` 에 `remote/*.json` 을 더한다.

---

## 4. 무엇을 팩에 넣나 — 🛑 리맵(`.import`)이 빠지면 하나도 안 붙는다

### 4.1 팩에는 **원본이 아니라 "내보낸 앱이 읽는 모양"** 을 넣는다

내보낸 앱에는 `.glb`·`.png` **원본이 없다.** `res://…/x.glb` 를 열면 엔진은

```
x.glb.import 의 [remap] path=  →  .godot/imported/x.glb-<md5>.scn  을 연다
```

| 팩에 넣는 것 | 넣지 않는 것 |
|---|---|
| ✅ **리맵 파일**(`x.glb.import` 의 `[remap]` 절) | 🛑 원본 `.glb`·`.png` |
| ✅ 임포트 산출물(`.scn`·`.ctex` …) | |

🛑 **라리엔은 처음에 리맵을 빠뜨려 팩을 받고도 나무가 하나도 붙지 않았다**(2026-09-10 · iPhone).
에디터 검증은 디스크에 리맵이 이미 있어서 **이것을 못 잡는다.**
원본 `.glb` 를 뺀 것만으로 **팩 크기의 84%** 가 줄었다 — 쓰이지도 않으면서 자리만 차지하고 있었다.

> 🔑 내보낸 앱의 리맵은 **플랫폼 키를 유지한다**(AAB 의 `.import` 는 `path.etc2` 한 줄).
> 팩의 리맵도 같은 모양이어야 한다 — 플랫폼별로 팩을 따로 구울 이유가 여기서 생긴다.

### 4.2 🛑 "이 자산을 다른 곳에서 직접 쓰는가" 를 스캔해 판정한다

맵 저작자는 `.glb` 를 씬에 **직접 끌어다 놓기도 한다**(늘 하던 작업이다). 그 씬은

```
[ext_resource path="res://…/palmera.glb"]
```

로 원본을 **하드 의존**하므로, 그 파일을 번들에서 빼면 **씬이 통째로 로드되지 않는다.**
라리엔은 이것으로 청크 하나가 기기에서 통째로 사라졌다:

```
No loader found for resource: res://maps/props/trees/palmera/palmera.glb
```

**대응 — 저작자에게 규칙을 요구하지 않고 도구가 판단한다.**
팩 후보마다 프로젝트 전체에서 경로·UID 참조를 찾아, **지정된 슬롯 말고 한 군데라도 참조가 있으면 번들에 남긴다.**

### 4.3 🛑 콜리전(게임 로직이 의존하는 것)은 절대 넣지 않는다

서버 길찾기 격자가 저작 씬 기준으로 구워진다면, 콜리전이 팩에 있으면
**서버는 막혔다는데 클라는 통과하는** 역방향 어긋남이 난다 — 화면에 보이지도 않는다.

**구조로 끊는다** — 콜리전은 씬에 남기고, **시각만 런타임 슬롯이 꽂는다.**

```gdscript
# 기물 씬 안, 예전에 .glb 인스턴스가 있던 빈 Node3D
extends Node3D
## 🛑 uid:// 가 아니라 경로 문자열 — 없을 때 "팩 미도착" 과 "저작 실수" 를 구분해야 한다
@export var visual_path: String = ""

func _ready() -> void:
    _mount()

func _mount() -> void:
    if visual_path.is_empty() or not ResourceLoader.exists(visual_path):
        return                      # ← 조용히 넘어간다. 이것이 정상 경로다
    var packed := load(visual_path) as PackedScene
    if packed: add_child(packed.instantiate())

func remount() -> void:             # 팩이 도착하면 부른다
    for c in get_children(): c.queue_free()
    _mount()
```

🛑 **`uid://` 를 쓰지 않는 이유** — UID 는 없을 때 오류를 내며, "아직 안 받았다" 와 "경로를 잘못 적었다" 가 구분되지 않는다.

---

## 5. 서버에 무엇을 어떻게 놓나

```
https://assets.example.com/<환경>/
├── catalog.json                  ← no-cache. 클라의 유일한 진입점
└── packs/
    └── props-<sha16>.pck         ← immutable (max-age=31536000)
```

```json
{
  "generated": "2026-09-18T01:26:37+00:00",
  "minClientVersion": "1.0",
  "packs": [
    {
      "id": "props",
      "file": "props-a60da32e3c1045c9.pck",
      "sha256": "a60da32e3c1045c95bd07acfdf27c67aa75051bf50505e48d9a03a7b35ef7815",
      "bytes": 181973692,
      "files": 974
    }
  ]
}
```

### 발행 순서 — 🛑 **catalog 가 맨 마지막이다**

```
① PCK 업로드  →  ② 존재·크기·해시 대조  →  ③ (필요하면 manifest)  →  ④ catalog
```

반대로 하면 구 앱이 아직 없는 파일에 **404 를 받고, CDN 이 그 404 를 TTL 동안 서빙한다.**
catalog 만 `no-cache`, 팩은 **파일명에 해시가 들어가므로** 영구 캐시로 둔다.

### `minClientVersion` 은 사람이 정한다

자동 산출로 두면, 앱을 1.15 로 올린 트리에서 배포했을 때
**심사 중이라 아직 1.14 를 쓰는 사용자 전원이 자산을 통째로 못 받는다**(영구 결손 · 2.5D 실사고).
비교는 **major.minor 만** 한다(patch·빌드번호는 플랫폼마다 갈린다).

🛑 **앱 버전이 비면 게이트가 늘 열린다.** `application/config/version` 이 빈 문자열이면
`minClientVersion: "99.0"` 도 통과한다(실측). 빌드 도구가 **비어 있으면 빌드를 멈추게** 한다.

### 호스팅 — egress 가 비용을 정한다

| | 저장 | **Egress** |
|---|---|---|
| Cloudflare R2 | 10GB 무료 | **무제한 무료** ← 게임 자산 배포에서 결정적 |
| S3·GCS | 유사 | 유료(대역폭이 곧 비용) |

🛑 **세대는 immutable 이라 쌓인다.** 팩 합계 1GB × 세대 10개 = 10GB. **GC 를 처음부터 구성 요소로 둔다.**

---

## 6. 런타임 계약 10가지

받는 코드에서 **없어서 실제로 사고가 났던** 것들이다. 하나씩 이유가 있다.

| # | 계약 | 없으면 실제로 일어난 일 |
|---|---|---|
| 1 | **contentHash 세대 폴더 + immutable 캐시** | 앱을 올릴 때마다 **안 바뀐 팩까지 다시** 받는다 |
| 2 | **catalog 를 맨 마지막에 발행**(no-cache) | 구 앱이 404 를 받고 **CDN 이 그 404 를 캐시한다** |
| 3 | **READY 마커 + `.staging` → 원자 rename** | **절반만 받은 팩**이 로더에 노출된다 |
| 4 | **sha256 검증 후 rename** | 손상분이 캐시로 굳어 **영원히 실패** |
| 5 | **`.partial` + Range 이어받기** | 끊기면 처음부터 — 셀룰러에서 같은 용량을 반복 실패 |
| 6 | **스트림 기록**(메모리 통짜 금지) | 75MiB 를 RAM 에 → **저사양 기기 OOM** |
| 7 | **idle 타임아웃** | 서버가 조용히 멈추면 **영영 안 끝나고** 다음 단계가 시작조차 못 한다 |
| 8 | **재시도 5·20·60초 + 앱 복귀 1회. 🛑 catalog 부터 다시 돈다** | 재시도가 *팩* 만 대상이면 **catalog 실패는 커버 못 한다** |
| 9 | **`minClientVersion` 은 사람이 정한다** | 심사 중 구 앱 사용자 전원이 자산 결손 |
| 10 | 🛑 **셀룰러 허용 — Wi-Fi 전용 게이트 금지** | *"데이터를 아껴 주자"* 는 선의가 들어가면 **아무도 모르게 정책이 뒤집힌다.** 회귀 검사로 금칙어를 막는다 |

### 언제 시작하나 — **사건으로 연다, 계측으로 열지 않는다**

🛑 **fps·CPU 를 게이트로 쓰지 않는다.** 저사양 기기는 늘 목표 미달이라,
성능 게이트를 걸면 **그 기기는 영영 자산을 못 받는다.**

🛑 **접속 직후에 열지 않는다.** 로그인 직후는 클라가 초기 상태 동기화 요청을 몰아 보내는 구간이라
대역폭을 다툰다. 라리엔은 **첫 월드 스냅샷을 받은 다음 프레임**에 연다.

### 진행 로그는 "고치는 사람" 으로 나눠 찍는다

```
[Packs] 팩 1개를 받았다 · 기물 시각 12/12개가 붙었다
[Packs] 캐시 적중 — 받지 않았다 · 기물 시각 12/12개가 붙어 있다
[Packs] 새 세대 1개를 받아 두었다 — 다음 실행부터 보인다
[Packs] 팩 1개를 받지 못했다 — 번들에 있는 것으로 계속한다 (망 1 · 거부 0)
```

🔑 **"망" 과 "거부" 는 고치는 사람이 다르다.** 망은 사용자 회선이라 재시도가 답이고,
**거부(해시 불일치·마운트 실패)는 배포가 틀린 것**이라 사람이 서버를 고쳐야 한다.

🛑 **`N/N` 의 앞 숫자는 "실제로 붙은 수" 여야 한다.** 라리엔은 리맵이 빠져 하나도 안 붙었는데
"1개를 꽂았다" 가 찍혀 성공처럼 보였다(§4.1).

---

## 7. Godot 고유의 함정 셋

### 7.1 🛑 언마운트가 없다

```
ProjectSettings 의 pack 관련 메서드 = ["load_resource_pack"]     ← 이것뿐이다
```

**얹은 팩을 내릴 수 없다.** 그래서 세대 교체를 "포인터 갈아끼우기" 로 할 수 없다.

| 상황 | 해야 하는 일 |
|---|---|
| 첫 획득 | ✅ 받자마자 얹는다 |
| **이미 얹혀 있는 팩의 새 세대** | 🛑 디스크에만 두고 **다음 부팅에 반영**한다 |

🛑 게다가 `load_resource_pack(…, false)` 는 **이미 있는 경로를 덮지 않으므로**,
옛 세대가 올라 있는 세션에 새 세대를 올리면 **옛 모양이 계속 보인다.** 그래서

① 새 세대를 받으면 `active.json` 만 바꾸고, 이 세션에 옛 세대가 있으면 **올리지 않는다**
② 다음 부팅의 마운트 단계가 **마운트 전에** active 가 아닌 세대를 지우고 새 것만 올린다

### 7.2 🛑 `HTTPRequest` 가 Range 이어받기를 파괴한다

```
HTTPRequest.download_file  +  "Range: bytes=100000-"
   서버 응답 206(정상)  →  파일 크기 102400 → 2400      🛑 앞부분을 잘라 버렸다
   416 응답            →  파일이 아예 생기지 않는다
```

**정공법은 `HTTPClient` 다** — 실측으로 바이트·해시까지 확인한 형태:

```gdscript
# ① 이어받을 위치 = 이미 받아 둔 .part 의 크기
var have := 0
if FileAccess.file_exists(part):
    have = FileAccess.open(part, FileAccess.READ).get_length()

# ② HTTPClient 로 Range 요청 (HTTPRequest 가 아니다)
c.request(HTTPClient.METHOD_GET, path, PackedStringArray(["Range: bytes=%d-" % have]))

# ③ 청크를 append — seek_end() 가 이어붙이는 핵심
var f := FileAccess.open(part, FileAccess.READ_WRITE)
f.seek_end()
while c.get_status() == HTTPClient.STATUS_BODY:
    c.poll()
    var chunk := c.read_response_body_chunk()
    if chunk.size() > 0: f.store_buffer(chunk)
    else: await get_tree().process_frame

# ④ 검증은 엔진이 한 줄로 해 준다
if FileAccess.get_sha256(part) != expected:
    ...  # 폐기하고 다시
```

| 실측 | 값 |
|---|---|
| 1차 수신(중단 모사) | 65,536 bytes → 파일 65,536 |
| 2차 이어받기 | 36,864 bytes → 파일 102,400 |
| 이어붙인 sha256 vs 원본 | ✅ **일치** |
| 완성본에 재요청 | **416** |

🛑 **416 은 "이미 다 받았다" 는 뜻이다.** 해시를 검증해 통과하면 **완성본으로 승격**한다.

🛑 **`HTTPClient` 는 타임아웃이 없다** — 연결·응답·본문 정체를 **직접 재야 한다**(계약 ⑦).
라리엔은 연결 15초 · 본문 정체 20초를 쓰고, 리다이렉트는 3회까지 따라간다.

### 7.3 팩 용량은 원본 크기가 아니라 **임포트 설정**이 정한다

PCK 에 들어가는 것은 `.png` 가 아니라 `.ctex` 다.
**텍스처 압축 모드와 `size_limit` 이 용량을 정한다** — 원본을 줄이기 전에 임포트 설정부터 본다
([resources-assets.md](resources-assets.md) · [performance-mobile.md](performance-mobile.md)).

### 7.4 그 밖에 쉽게 걸리는 것들

| 함정 | 대응 |
|---|---|
| 큰 팩의 sha256 해시가 **한 프레임을 1초 잡아먹는다**(저사양 86MB 실측) | `HashingContext` 로 나눠 계산하거나 워커 스레드로 |
| 공개 CDN 도메인이 **Python 기본 User-Agent 를 403** 으로 막는다 | 검증 스크립트에 UA 를 명시한다(게임 클라·curl 은 200) |
| 받은 수백 MB 가 **iCloud·Google 백업에 올라간다** | 캐시 폴더를 백업 제외로 표시한다 |

---

## 8. 검증 — 무엇을 어떻게 재나

🛑 **에디터에서 도는 검사는 이 기능을 검증하지 못한다.** 에디터에는 원본·리맵이 디스크에 다 있어서
§4.1 의 사고가 **통과해 버린다.** 반드시 **내보낸 앱**으로 잰다.

| 검사 | 무엇을 잡나 |
|---|---|
| **번들만으로 전부 열리는가** | 팩이 안 와도 맵·씬이 로드되는가(§4.2·§4.3) |
| **받아서 실제로 붙은 수** | 🛑 "받았다" 가 아니라 **붙은 개수**를 센다(§4.1) |
| **캐시 적중 — 두 번째 실행에 네트워크 0회** | 계약 ① |
| **세대 교체** | 새 세대는 다음 부팅에 반영되는가(§7.1) |
| **버전 게이트** | `minClientVersion` 이 실제로 막는가 |
| **깨진 팩 거부** | 해시 불일치를 마운트하지 않는가(계약 ④) |
| **꺼진 빌드 게이트** | 데스크톱·debug 빌드가 캐시를 **올리지도 지우지도 않는가**(§3.1) |
| **통신 이상** | 리다이렉트·무응답·정체·404 에서 **반드시 끝나는가**(계약 ⑦) |
| **정책 회귀 가드** | 소스에 Wi-Fi 전용 게이트 0건 — 🛑 **금칙어 표가 실제로 잡는지 양성 대조까지**(계약 ⑩) |

> 🔑 **부정 판정에는 양성 대조를 짝지운다.** "Wi-Fi 게이트가 0건" 은 검사기가 고장나도 0건이다.
> 일부러 넣은 문자열을 잡는지 먼저 확인한다.

---

## 9. 체크리스트

**설계**
- [ ] 팩 경계가 **로딩 화면이 있는 곳**인가 (걸어서 닿는 경계가 아닌가 · §1)
- [ ] 팩을 파일 단위가 아니라 **묶음**으로 나눴는가 (§1)
- [ ] 게임 로직이 의존하는 것(콜리전·데이터)은 번들에 남겼는가 (§4.3)

**플랫폼 분기** 🛑
- [ ] 런타임 게이트와 export 필터를 **같이** 바꿨는가 (§3.1)
- [ ] 필터 주입이 **플랫폼으로 걸러지는가** — `re.sub` 로 전체를 고치지 않는가 (§3.3)
- [ ] 데스크톱 프리셋이 **손대지 않은 채** 남는가
- [ ] 주소가 비면 **저절로 꺼지는가** — 에디터·debug 는 설정 없이 꺼져야 한다 (§3.4)
- [ ] `project.godot` 설정 키의 **절 이름**이 맞는가 (§3.4 의 사고)

**팩 굽기**
- [ ] 팩에 **리맵(`.import` 의 `[remap]`)** 이 들어갔는가 (§4.1)
- [ ] 원본 `.glb`·`.png` 는 **빠졌는가** (§4.1)
- [ ] 팩에 넣은 경로가 **그 빌드의 번들에서 빠졌는가** (§3.1 사고 B)
- [ ] 다른 씬이 **직접 참조**하는 자산은 번들에 남겼는가 (§4.2)

**발행**
- [ ] **catalog 가 맨 마지막**인가 (§5)
- [ ] catalog `no-cache` · 팩 `immutable` 인가
- [ ] `minClientVersion` 을 **사람이** 정했는가
- [ ] 앱 버전이 비면 **빌드가 멈추는가**

**런타임**
- [ ] 해시 검증 → 원자 rename → READY 순인가 (계약 ③④)
- [ ] 이어받기를 **`HTTPClient`** 로 했는가 (§7.2)
- [ ] 타임아웃을 직접 재는가 (계약 ⑦)
- [ ] 재시도가 **catalog 부터** 도는가 (계약 ⑧)
- [ ] 셀룰러를 막지 않는가 (계약 ⑩)
- [ ] 새 세대를 **다음 부팅에** 반영하는가 (§7.1)

**검증**
- [ ] **내보낸 앱**으로 쟀는가 (에디터 검사는 §4.1 을 못 잡는다)
- [ ] "받았다" 가 아니라 **붙은 개수**를 세는가

---

## 관련 문서

| 문서 | 무엇을 |
|---|---|
| [export-build.md](export-build.md) | `export_presets.cfg` 포맷(§6) · **패치 PCK**(§7) · CLI |
| [export-build-android.md](export-build-android.md) · [export-build-ios.md](export-build-ios.md) | 플랫폼별 빌드 |
| [export-build-desktop.md](export-build-desktop.md) | Steam·공증 — **받지 않는 쪽** |
| [resources-assets.md](resources-assets.md) | 임포트 설정 · `.import` 리맵 · 텍스처 `size_limit` |
| [performance-mobile.md](performance-mobile.md) | 번들 줄이기 · 텍스처 압축 |
| [networking-lowlevel.md](networking-lowlevel.md) | `HTTPClient` · `HTTPRequest` 일반 |

## 공식 문서

- [Exporting packs, patches, and mods](https://docs.godotengine.org/en/stable/tutorials/export/exporting_pcks.html)
- [Feature tags](https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html)
- [ProjectSettings.load_resource_pack](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html#class-projectsettings-method-load-resource-pack)
- [HTTPClient](https://docs.godotengine.org/en/stable/classes/class_httpclient.html)
