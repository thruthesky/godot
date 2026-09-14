# 앱 아이콘 · 스플래시 화면 · 앱 이름 — 모든 플랫폼

> **이 문서로 오는 상황** — 앱 아이콘을 바꾸고 싶다 · 앱을 켜면 Godot 로봇 로고가 나온다 · 시작 화면(스플래시)에 우리 로고를 넣고 싶다 ·
> 안드로이드에서 흰 화면 → 검은 화면 → 흰 화면으로 깜빡인다 · 런처 아이콘 가장자리가 잘린다 · iOS export 가 아이콘 때문에 막힌다 ·
> `boot_splash/fullsize` 를 넣었는데 아무 일도 안 일어난다 · 홈 화면 아이콘 아래 앱 이름을 언어별로 바꾸고 싶다

**스플래시(splash) 화면**은 앱을 켠 뒤 첫 화면이 뜰 때까지 잠깐 보이는 로고 화면이다.
이 문서의 규칙은 전부 Godot **4.7.2** 엔진 소스(`platform/*/export/export_plugin.cpp` · `editor/export/*` · `main/main.cpp`)로
확인했고, Android 는 **Galaxy A17 실기기 녹화**로 쟀다(2026-09-14 · 라리엔 3D 에 2.5D 앱의 아이콘·스플래시를 적용하며).

## 목차

0. [한눈에 보기](#0-한눈에-보기)
1. [원본 이미지 준비](#1-원본-이미지-준비)
2. [파일 배치와 임포트](#2-파일-배치와-임포트)
3. [공통 앱 아이콘](#3-공통-앱-아이콘)
4. [공통 부트 스플래시](#4-공통-부트-스플래시)
5. [Android 런처 아이콘](#5-android-런처-아이콘)
6. [Android 네이티브 스플래시와 창 배경](#6-android-네이티브-스플래시와-창-배경)
7. [iOS 아이콘과 런치 화면](#7-ios-아이콘과-런치-화면)
8. [macOS와 Windows 아이콘](#8-macos와-windows-아이콘)
9. [두 스플래시 이어 붙이기](#9-두-스플래시-이어-붙이기)
10. [확인하는 법](#10-확인하는-법)
11. [자주 막히는 지점](#11-자주-막히는-지점)
12. [앱 이름 — 홈 화면에 보이는 이름](#12-앱-이름--홈-화면에-보이는-이름)

---

## 0. 한눈에 보기

앱을 켜면 사용자는 이 순서로 본다.

```
아이콘 탭 → [모바일] OS 네이티브 스플래시 → [Android] 창 배경 → Godot 부트 스플래시 → 첫 씬
```

| 무엇 | 어디에 설정하나 | 비워 두면 |
|---|---|---|
| **앱 아이콘 기본값** (모든 플랫폼) | `project.godot` `application/config/icon` | 새 프로젝트의 `res://icon.svg` = **Godot 로봇** |
| **부트 스플래시** (모든 플랫폼) | `project.godot` `application/boot_splash/*` | Godot 로고 |
| Android 런처 아이콘 | 프리셋 `launcher_icons/*` | `config/icon` — 🛑 적응형 아이콘으로 늘어나 잘린다 |
| Android 네이티브 스플래시 | 프리셋 `splash_screen/*` | 적응형 전경 아이콘 |
| Android 창 배경 | 프리셋 `screen/background_color` | 🛑 **검정** |
| iOS 아이콘 | 프리셋 `icons/*` | `icons/icon_1024x1024` → `config/icon` |
| iOS 런치 화면 | 프리셋 `storyboard/*` | 부트 스플래시 이미지·배경색 |
| macOS 아이콘 | 프리셋 `application/icon` | `config/macos_native_icon` → `config/icon` |
| Windows 아이콘 | 프리셋 `application/icon` | `config/windows_native_icon` → `config/icon` |
| **앱 이름** (홈 화면 아이콘 아래) | 기본: Android 프리셋 `package/name` · iOS·macOS `config/name` / 언어별: `config/name_localized` | `config/name` · 🛑 iOS·macOS 언어별 이름은 번역 파일이 등록돼 있어야 생긴다 → [§12](#12-앱-이름--홈-화면에-보이는-이름) |

> **가장 짧은 길** — `config/icon` 과 `boot_splash/*` 두 곳만 채우면 **iOS·macOS·Windows 는 그대로 따라온다.**
> **Android 만** 프리셋을 따로 채운다. 적응형 아이콘이 잘리고, 창 배경이 검정이라 스플래시 사이가 깜빡이기 때문이다.

**에디터에서 여는 곳**

| 설정 | 메뉴 |
|---|---|
| `config/icon` · `boot_splash/*` | `Project > Project Settings > General > Application > Config`(Icon) · `Boot Splash` |
| 프리셋 옵션 | `Project > Export...` → 프리셋 선택 → `Options` 탭의 `Launcher Icons` · `Splash Screen` · `Screen`(Android) / `Icons` · `Storyboard`(iOS) / `Application`(macOS·Windows) |

에디터 없이 작업하면 `project.godot` 과 `export_presets.cfg` 를 직접 고친다. 아래 예시가 그 모양이다.

---

## 1. 원본 이미지 준비

| 원본 | 권장 크기 | 조건 |
|---|---|---|
| **앱 아이콘** | 1024×1024 (최소 512) | 🛑 **불투명**하게 만든다(알파 채널 없이). iOS App Store 아이콘은 투명을 허용하지 않는다. 모서리 둥글림·그림자는 넣지 않는다 — OS 가 모양을 씌운다 |
| **스플래시 로고** | 정사각형 PNG, 로고 둘레에 넉넉한 여백 | 🛑 부트 스플래시는 **PNG 만** 읽는다 |
| Android 적응형 아이콘 | 432×432 레이어 두 장 | [§5](#5-android-런처-아이콘) 에서 원본으로 만든다 |

아이콘 옵션이 받는 형식은 png·webp·svg 이고, Windows 는 `.ico`, macOS 는 `.icns` 도 그대로 받는다.
Android 네이티브 스플래시 아이콘은 벡터 드로어블 `.xml` 도 받는다.

알파 채널을 없애는 방법(모든 픽셀이 불투명한데 채널만 남아 있는 경우가 흔하다):

```python
# 알파 채널을 버리고 RGB 로 다시 저장한다
from PIL import Image
Image.open("design/app_icon.png").convert("RGB").save("assets/branding/app_icon.png", optimize=True)
```

---

## 2. 파일 배치와 임포트

### 런타임에 읽는 두 파일은 `keep` 으로

`config/icon` 과 `boot_splash/image` 는 엔진이 **텍스처가 아니라 원본 PNG** 를 `ImageLoader` 로 읽는다.
내보내기도 이 두 파일을 원본 그대로 강제로 넣는다(`EditorExportPlatform::get_forced_export_files`).
그러니 텍스처로 임포트하면 쓰지도 않는 `.ctex` 가 pck 에 한 벌 더 들어간다. `.import` 를 `keep` 으로 둔다.

```ini
[remap]

importer="keep"
```

🛑 **`.import` 를 PNG 보다 먼저 만든다.** PNG 가 먼저 있으면 에디터가 텍스처로 임포트해 `.import` 를 덮어쓴다.

### OS 가 쓰는 이미지는 `.gdignore` 폴더에

Android 적응형 레이어·네이티브 스플래시 아이콘처럼 **게임 실행 중에는 안 쓰는** 이미지는 `.gdignore` 폴더에 둔다.
내보내기의 `_load_icon_or_splash_image` 는 리소스로 못 찾으면 `ImageLoader` 로 원본 파일을 읽으므로, 임포트되지 않아도 된다.

### 🛑 원본 보관 폴더에도 `.gdignore`

스토어 그림·디자인 원본 폴더(`design/` 등)에 `.gdignore` 가 없으면 **내보내기 스캔이 전부 임포트**한다.
그 캐시(`.godot/imported/*.ctex`)는 `exclude_filter` 를 지나 APK 에 들어간다 — `exclude_filter` 는 원본 경로만 거른다.
라리엔 실측: 이미지 캐시 72개 **145MB** 가 딸려 들어가 A17 debug APK 가 200MB → 363MB.

### 배치 예 (라리엔 3D)

```
assets/branding/
├─ app_icon.png          512×512 RGB · keep — config/icon · Android main_192x192
├─ app_splash.png        804×804 흰 캔버스 · keep — 부트 스플래시 · iOS 런치 화면
└─ native/               .gdignore — pck 에 안 들어간다
   ├─ android_adaptive_background.png   432×432 — 원본을 가운데 320px 로
   ├─ android_adaptive_foreground.png   432×432 완전 투명
   └─ android_splash_icon.png           600×600 — 네이티브 스플래시 아이콘
```

---

## 3. 공통 앱 아이콘

```ini
[application]

config/icon="res://assets/branding/app_icon.png"
```

- 데스크톱 **창·작업 표시줄 아이콘**이고, 각 플랫폼 아이콘 옵션이 비었을 때의 **기본값**이다.
- 🛑 새 프로젝트의 `res://icon.svg` 는 Godot 로봇이다. 이 줄을 바꾸지 않으면 스토어·런처에 로봇이 나간다.
- 네이티브 형식 전용 설정도 있다 — `application/config/macos_native_icon`(.icns) · `application/config/windows_native_icon`(.ico).
  프리셋 `application/icon` 이 비었을 때 `config/icon` 보다 먼저 쓴다([§8](#8-macos와-windows-아이콘)).

---

## 4. 공통 부트 스플래시

**부트 스플래시**는 Godot 엔진이 초기화된 직후부터 첫 씬의 첫 프레임이 그려질 때까지 보인다. 데스크톱에는 이것 하나뿐이다.

```ini
[application]

boot_splash/show_image=true
boot_splash/image="res://assets/branding/app_splash.png"
boot_splash/bg_color=Color(1, 1, 1, 1)
boot_splash/stretch_mode=1
boot_splash/use_filter=true
```

| 옵션 | 뜻 |
|---|---|
| `show_image` | `false` 면 1×1 투명 이미지를 그린다 → 배경색만 보인다 |
| `image` | 🛑 **PNG 만**. 비우면 Godot 로고 |
| `bg_color` | 이미지 바깥 배경색. **창이 생기자마자 첫 clear 색**으로도 쓰인다(`set_early_window_clear_color_override`) |
| `stretch_mode` | `0` Disabled(원래 픽셀 크기) · `1` **Keep**(기본 · 비율 유지, 짧은 변에 맞춰 늘림) · `2` Keep Width · `3` Keep Height · `4` Cover · `5` Ignore |
| `use_filter` | 늘릴 때 선형 필터 |
| `minimum_display_time` | 최소 표시 시간(ms). 에디터에서 실행할 때는 0 으로 무시된다 |

- 🛑 **4.7 에는 `boot_splash/fullsize` 가 없다.** 옛 문서·AI 답에 자주 나오지만 `stretch_mode` 로 바뀌었다.
- 🛑 `image` 를 `uid://` 로 적으면, UID 캐시가 없는 실행에서 **경고 없이 기본 로고로 넘어간다**(`main.cpp`) → `res://` 경로로 적는다.
- 경로가 틀리거나 PNG 가 아니면 로그에 `Non-existing or invalid boot splash at '…'` 이 찍히고 기본 로고가 나온다.
- 비용: PNG 디코드 한 번 + 텍스처 한 장. 텍스처는 그린 직후 해제된다(GLES3 `texture_free`). 960×960 PNG 디코드는 맥 헤드리스 1.9ms.

**로고를 화면 크기에 비례해 보이게 하려면** `stretch_mode=1` 로 두고 이미지에 **여백을 붙여** 로고 크기를 정한다.
Keep 은 이미지 전체를 짧은 변에 맞추므로, 화면 속 로고 폭 = 원본 속 로고 폭 × 짧은 변 ÷ 이미지 폭이다.
`stretch_mode=0` 은 기기 해상도에 따라 로고 크기가 제각각이 된다(720px 폭 폰과 1080px 폭 폰에서 같은 픽셀).

---

## 5. Android 런처 아이콘

**적응형 아이콘(adaptive icon)** — Android 8 이상은 108dp 정사각 레이어 두 장(배경·전경)을 겹치고,
런처가 그 위에 모양 마스크(원·둥근 사각 등)를 씌운다. **보이는 곳은 가운데 72dp**(한 변의 2/3)뿐이다.
dp 는 화면 밀도와 무관한 길이 단위다(432px 레이어 = 108dp).

```ini
; export_presets.cfg — Android 프리셋마다 [preset.N.options] 안
launcher_icons/main_192x192="res://assets/branding/app_icon.png"
launcher_icons/adaptive_foreground_432x432="res://assets/branding/native/android_adaptive_foreground.png"
launcher_icons/adaptive_background_432x432="res://assets/branding/native/android_adaptive_background.png"
launcher_icons/adaptive_monochrome_432x432=""
```

| 옵션 | 쓰이는 곳 | 비우면 (4.7.2 `load_icon_refs`) |
|---|---|---|
| `main_192x192` | 적응형을 모르는 런처 · `mipmap-*/icon.webp` | `config/icon` |
| `adaptive_foreground_432x432` | 적응형 전경 레이어 | main 아이콘 — 🛑 **네모 그림이 108dp 전체로 늘어나 가운데 2/3 만 보인다** |
| `adaptive_background_432x432` | 적응형 배경 레이어 | 넣지 않는다(템플릿 기본) |
| `adaptive_monochrome_432x432` | Android 13+ 테마 아이콘(단색) | `icon.xml` 에 `<monochrome>` 태그를 **아예 넣지 않는다** → 테마 아이콘을 켜도 원래 색으로 나온다 |

Godot 이 밀도별 크기(108~432px)로 Lanczos 축소해 webp 로 굽는다. 🛑 **Android 프리셋이 여럿이면 전부에 채운다** — 새 프리셋은 빈칸으로 시작한다.

### 네모 일러스트 아이콘(게임 키 아트)을 넣는 법

그림 전체를 전경에 넣으면 가장자리가 1/6 씩 잘린다. **배경 레이어** 가운데에 80dp(320px)로 줄여 넣고 **전경은 완전 투명**으로 둔다.
보이는 72dp(288px)보다 조금 크게 넣었으므로 틈 없이 원본의 약 90% 가 보인다. 로고만 있는 아이콘이면 반대로 전경에 로고, 배경에 단색을 둔다.

```python
# 원본 일러스트 → 적응형 배경(가운데 320px) + 투명 전경
from PIL import Image

icon = Image.open("assets/branding/app_icon.png").convert("RGB")

# 배경: 432px 흰 판 가운데(여백 56px)에 원본을 320px 로 줄여 붙인다
bg = Image.new("RGB", (432, 432), (255, 255, 255))
bg.paste(icon.resize((320, 320), Image.LANCZOS), (56, 56))
bg.save("assets/branding/native/android_adaptive_background.png", optimize=True)

# 전경: 완전 투명 — 비워 두면 main 아이콘이 전경으로 들어가 확대·잘림이 생긴다
Image.new("RGBA", (432, 432), (0, 0, 0, 0)).save("assets/branding/native/android_adaptive_foreground.png", optimize=True)
```

라리엔 실측(Galaxy A17): 앱 서랍의 둥근 사각 아이콘·앱 정보 화면의 원형 아이콘 모두 두 인물 얼굴과 가운데 로고가 잘리지 않았다.

---

## 6. Android 네이티브 스플래시와 창 배경

**네이티브 스플래시**는 Android 12+ SplashScreen API 로 OS 가 그린다. 아이콘을 탭하는 즉시, **엔진이 뜨기 전에** 보인다.
4.7 부터 프리셋 옵션으로 설정한다(라리엔은 `gradle_build/use_gradle_build=true` 에서 실측).

```ini
splash_screen/icon="res://assets/branding/native/android_splash_icon.png"
splash_screen/background_color=Color(1, 1, 1, 1)
splash_screen/branding_image=""
splash_screen/disable_godot_boot_splash=false
screen/background_color=Color(1, 1, 1, 1)
```

| 옵션 | 뜻 | 비우면 |
|---|---|---|
| `splash_screen/icon` | 가운데 아이콘 — png·webp·svg·`.xml`(벡터 드로어블) | 적응형 전경 → main → `config/icon` |
| `splash_screen/background_color` | 스플래시 배경 | 🛑 **`Color()`(알파 0)일 때만 "비움"** → `@mipmap/icon_background`. `Color(0, 0, 0, 1)` 은 **검정으로 칠한다** |
| `splash_screen/branding_image` | 화면 아래쪽 브랜딩 이미지 | 넣지 않는다 |
| `splash_screen/disable_godot_boot_splash` | Godot 부트 스플래시를 끈다 | — |
| `screen/background_color` | 🛑 **스플래시가 끝난 뒤 보이는 본 테마 창 배경**(`windowBackground`) | **검정** |

- **아이콘 크기** — 아이콘 배경이 없으면 약 **288dp** 폭으로 그려지고 가장자리는 원형으로 잘린다.
  A17 실측: 600px 이미지 안의 로고 212px → 화면 285px. 로고는 이미지 가운데에, 둘레에 여백을 두고 넣는다.
- 🛑 **창 배경을 스플래시 색과 같게 한다.** 네이티브 스플래시는 엔진 첫 프레임을 기다리지 않고 사라진다.
  기본값 검정으로 두면 흰 스플래시 → **검정 0.48초** → 흰 부트 스플래시로 깜빡인다([§9](#9-두-스플래시-이어-붙이기)).
- 창 배경을 흰색으로 해도 게임 중에는 비치지 않았다 — A17 가로↔세로 회전 녹화 527프레임 중 흰색이 50% 넘는 프레임 0.

---

## 7. iOS 아이콘과 런치 화면

### 아이콘

```ini
icons/icon_1024x1024="res://assets/branding/app_icon.png"
icons/icon_1024x1024_dark=""
icons/icon_1024x1024_tinted=""
icons/app_store_1024x1024=""
```

- 개별 크기(`icons/iphone_180x180` 등)가 비면 `icons/icon_1024x1024` 를 줄여 쓰고, 그것도 비면 `config/icon` 을 줄여 쓴다.
  **`config/icon` 하나로도 모든 크기가 나온다.**
- `_dark` · `_tinted`(iOS 18 다크·틴트 아이콘)는 비우면 넣지 않는다.
- App Store 1024 아이콘은 불투명이어야 한다 — 알파가 있으면 **`boot_splash/bg_color` 로 채워** 굽는다.
  직접 지정한 파일에 알파가 있으면 `Icon (…) must be opaque.` 경고도 낸다.
- 크기가 틀린 파일은 자동으로 줄이고 경고한다. 🛑 이미지를 하나도 못 읽으면 **export 가 멈춘다**([export-build-ios.md](export-build-ios.md)).

### 런치 화면 (storyboard)

```ini
storyboard/image_scale_mode=0
storyboard/custom_image@2x=""
storyboard/custom_image@3x=""
storyboard/use_custom_bg_color=false
storyboard/custom_bg_color=Color(0, 0, 0, 1)
```

| 옵션 | 뜻 |
|---|---|
| `custom_image@2x` · `@3x` | **둘 다 채워야** 커스텀 이미지를 쓴다. 하나라도 비면 `boot_splash/image` 를 두 크기에 같이 쓴다(없으면 Godot 로고) |
| `image_scale_mode` | `0` Same as Logo — 부트 스플래시 `stretch_mode` 를 따른다(Disabled → `center` · Keep·Keep Width·Keep Height → `scaleAspectFit` · Cover → `scaleAspectFill` · Ignore → `scaleToFill`). `1` Center · `2` Scale to Fit · `3` Scale to Fill · `4` Scale |
| `use_custom_bg_color` | `false` 면 배경색은 `boot_splash/bg_color` |

→ **부트 스플래시를 제대로 만들어 두면 iOS 런치 화면은 비워 둬도 같은 모양이 된다.**
🛑 라리엔은 iOS 실기기에서 확인하지 않았다 — 위 규칙은 `platform/ios/export/export_plugin.cpp` 근거다.

---

## 8. macOS와 Windows 아이콘

데스크톱에는 네이티브 스플래시가 없다 — [§4](#4-공통-부트-스플래시) 부트 스플래시 하나뿐이다.

### macOS

```ini
application/icon=""
application/icon_interpolation=4
application/liquid_glass_icon=""
```

- 아이콘을 찾는 순서: `application/icon` → `config/macos_native_icon` → `config/icon`.
- `.icns` 면 그대로 복사하고, png·webp·svg 면 16~1024 크기 10장을 담은 `icon.icns` 를 만든다(`icon_interpolation` 4 = Lanczos).
  라리엔 실측: 512px PNG → `Contents/Resources/icon.icns` 3.4MB.
- `liquid_glass_icon` 은 macOS 26 Liquid Glass 아이콘(`.icon` 번들)이다. 채우면 `Info.plist` 에 `CFBundleIconName` 이 들어간다.

### Windows

```ini
application/modify_resources=true
application/icon=""
application/console_wrapper_icon=""
```

- 아이콘을 찾는 순서: `application/icon` → `config/windows_native_icon` → `config/icon`.
- png·webp·svg 면 **16·32·48·64·128·256** 크기로 `.ico` 를 만들어 실행 파일 리소스에 넣는다. 외부 도구(rcedit)는 필요 없다.
- 🛑 `modify_resources=false` 면 아이콘·버전 정보를 **아예 바꾸지 않는다.**
- `console_wrapper_icon` 은 `.console.exe` 의 아이콘이다(비우면 위 아이콘).

---

## 9. 두 스플래시 이어 붙이기

Android 는 스플래시가 둘이고 그 사이에 창 배경이 끼어 있다. **색 셋과 로고 크기**를 맞추지 않으면 사용자 눈에 두 번 깜빡인다.

### 색 셋을 같게 한다

`splash_screen/background_color` · `screen/background_color` · `boot_splash/bg_color`

| Galaxy A17 녹화 프레임 분석 (2026-09-14) | 네이티브 | 사이 | 부트 | 첫 씬 |
|---|---|---|---|---|
| `screen/background_color` 기본값(검정) | 흰+로고 0.8초 | 🛑 **검정 0.48초** | 흰+로고 1.9초 | 로그인 |
| 흰색으로 맞춤 | 흰+로고 0.8초 | 흰(로고 없음) 0.63초 | 흰+로고 1.9초 | 로그인 |

- 사이 구간에서 로고까지 이으려면 창 배경을 로고 drawable 로 바꿔야 한다 — `android/build/` 템플릿을 고치는 일이라 라리엔은 하지 않았다.
- `disable_godot_boot_splash=true` 로 부트 스플래시를 끄면 첫 씬이 뜰 때까지(A17 약 2.5초) 창 배경만 보인다.

### 로고 크기를 같게 한다

네이티브 아이콘은 **288dp** 폭([§6](#6-android-네이티브-스플래시와-창-배경)), 부트 스플래시는 Keep 이면 **짧은 변**에 맞춰 늘어난다([§4](#4-공통-부트-스플래시)).
그래서 네이티브에 쓴 S×S 이미지를 부트 스플래시에서는 더 큰 흰 캔버스 가운데에 붙인다.

```
부트 캔버스 한 변 = S × (기기 짧은 변 dp) ÷ 288
```

짧은 변 384dp(A17 1080px·450dpi)에 S=600 이면 **800px**. 두 값 모두 dp 비례라 짧은 변이 384dp 인 다른 기기에서도 같다.

| 부트 캔버스 | A17 부트 로고 | A17 네이티브 로고 | 차이 |
|---|---|---|---|
| 960px | 239px | 285px | −16% (전환 때 작아진다) |
| **804px** | **276px** | 280px | −1.4% |

```python
# 네이티브 스플래시 이미지(600px)를 804px 흰 캔버스 가운데에 붙여 부트 스플래시를 만든다
from PIL import Image

splash = Image.open("design/splash_screen/app_splash.png").convert("RGB")
canvas = 804                                   # = 600 × 384dp ÷ 288dp (A17 실측으로 보정)
boot = Image.new("RGB", (canvas, canvas), (255, 255, 255))
boot.paste(splash, ((canvas - 600) // 2, (canvas - 600) // 2))
boot.save("assets/branding/app_splash.png", optimize=True)
```

🛑 A12 등 다른 기기에서는 재지 않았다. 사용자가 화면 확대(디스플레이 크기)를 바꾸면 dp 가 달라져 크기가 어긋난다.

---

## 10. 확인하는 법

🛑 스플래시는 스크립트가 돌기 전에 끝나므로 **촬영 검사 스크립트로는 찍히지 않는다** → Android 는 실기기 녹화로 본다.

| 확인할 것 | 아래 명령 | 판정 |
|---|---|---|
| APK 에 아이콘·스플래시가 들어갔나 | ① | 꺼낸 webp 를 PNG 로 바꿔 **직접 열어 본다** |
| 테마 색 | ② | `GodotAppSplashTheme` 의 `0x0101062c`(windowSplashScreenBackground) · `GodotAppMainTheme` 의 `0x01010054`(windowBackground) 가 스플래시 색 |
| 앱 아이콘 등록 | ③ | `res/mipmap-anydpi-v26/icon.xml` 이면 적응형 |
| 부트 스플래시·`config/icon` 포함 | ④ | 크기가 원본 파일과 같다 |
| 원본 보관 폴더가 딸려 들어갔나 | ⑤ | 0 |
| 실기기 아이콘 모양 | ⑥ | 앱 정보 화면에 런처 마스크가 씌워진 모양이 나온다 |
| macOS 아이콘 | ⑦ | 512px 을 열어 본다 |
| 깜빡임·로고 크기 | 아래 녹화 | 프레임별 흰·검정 픽셀 비율과 가운데 로고 폭 |

```bash
# ① APK 안 아이콘·스플래시 리소스 → 꺼내서 PNG 로 (sips 는 macOS)
unzip -l app.apk | grep -E 'res/(mipmap|drawable)[^/]*/(icon|splash)'
unzip -o app.apk 'res/drawable/splash_icon.webp' 'res/mipmap-xxxhdpi-v4/*' -d out
sips -s format png out/res/drawable/splash_icon.webp --out splash_icon.png

# ② 테마 색 — 두 스타일 블록만
aapt2 dump resources app.apk | awk '/style\/GodotApp(Main|Splash)Theme/{p=1} /resource 0x/ && !/GodotApp/{p=0} p'

# ③ 앱 아이콘 등록
aapt2 dump badging app.apk | grep application-icon

# ④ 부트 스플래시·config/icon 원본
unzip -l app.apk | grep branding

# ⑤ 원본 보관 폴더(예: design/)
unzip -l app.apk | grep -c 'design/'

# ⑥ 실기기 앱 정보 화면
adb -s <시리얼> shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:<패키지>
adb -s <시리얼> exec-out screencap -p > icon.png

# ⑦ macOS 앱 번들의 아이콘
iconutil -c iconset <앱>.app/Contents/Resources/icon.icns -o icon.iconset
```

```bash
# 녹화를 켠 채 앱을 실행한다 (시리얼·패키지·액티비티는 자기 것으로)
adb -s <시리얼> shell screenrecord --time-limit 12 /sdcard/splash.mp4 &
python3 -c "import time; time.sleep(1.2)"
adb -s <시리얼> shell am start -W -n <패키지>/com.godot.game.GodotAppLauncher
wait
adb -s <시리얼> pull /sdcard/splash.mp4 . && adb -s <시리얼> shell rm /sdcard/splash.mp4

# 정지 화면은 프레임이 거의 안 생긴다 — passthrough 로 실제 프레임만 뽑고 시각은 ffprobe 로
ffmpeg -i splash.mp4 -fps_mode passthrough -vf scale=270:-1 f_%03d.png
ffprobe -v error -select_streams v -show_entries frame=pts_time -of csv=p=0 splash.mp4 > pts.txt
```

프레임마다 "흰(≥245) 픽셀 85% 이상 / 검정(≤15) 85% 이상 / 그 밖" 으로 나눠 구간을 잇고, 가운데 영역(가장자리·상태바 제외)에서
어두운 픽셀의 경계 상자로 로고 폭을 잰다. 앱이 열리는 애니메이션 프레임은 가장자리가 흰색이 아니므로 뺀다.

---

## 11. 자주 막히는 지점

| 증상 | 원인 | 해결 |
|---|---|---|
| 아이콘이 여전히 Godot 로봇 | `config/icon` 이 `res://icon.svg` | [§3](#3-공통-앱-아이콘) |
| Android 런처 아이콘이 확대돼 가장자리가 잘린다 | `adaptive_foreground_432x432` 빈칸 → main 아이콘이 108dp 로 늘어남 | [§5](#5-android-런처-아이콘) 배경 레이어 80dp + 투명 전경 |
| 프리셋 하나는 되는데 다른 프리셋 빌드는 로봇 | 프리셋마다 따로 채워야 한다 | 모든 Android 프리셋에 같은 값 |
| 흰 스플래시 뒤 검은 화면이 잠깐 | `screen/background_color` 가 기본값 검정 | [§6](#6-android-네이티브-스플래시와-창-배경) |
| 스플래시 배경을 "비웠는데" 검정 | `Color(0, 0, 0, 1)` 은 빈칸이 아니다 | 원하는 색을 넣거나 `Color()` |
| 스플래시가 넘어갈 때 로고가 커지거나 작아진다 | 부트 캔버스 크기 | [§9](#9-두-스플래시-이어-붙이기) |
| `boot_splash/fullsize` 가 안 먹는다 | 4.7 에 없는 옵션 | `boot_splash/stretch_mode` |
| 부트 스플래시에 Godot 로고가 나온다 | PNG 가 아님 · 경로 틀림 · `uid://` 경로 | 로그 `Non-existing or invalid boot splash` · `res://` 로 |
| APK 가 갑자기 백 MB 넘게 커졌다 | 원본 보관 폴더에 `.gdignore` 없음 | [§2](#2-파일-배치와-임포트) |
| iOS export 가 아이콘 오류로 멈춘다 | 아이콘 이미지를 하나도 못 읽음 | [§7](#7-ios-아이콘과-런치-화면) |
| App Store 아이콘 둘레가 이상한 색 | 알파가 있어 `boot_splash/bg_color` 로 채워졌다 | 원본을 RGB 로 |
| Windows exe 아이콘이 기본 | `application/modify_resources=false` | [§8](#8-macos와-windows-아이콘) |
| 앱 이름을 바꿨더니 데스크톱에서 로그인·설정이 사라졌다 | `config/name` 을 바꿔 `user://` 폴더가 달라졌다 | 되돌리고 모바일 이름은 [§12](#12-앱-이름--홈-화면에-보이는-이름) 방식으로 |
| iOS·macOS 에서 한국어 앱 이름이 안 나온다 | 그 언어의 번역 파일이 `locale/translations` 에 등록돼 있지 않다 | 번역 파일 하나 등록 → [§12](#12-앱-이름--홈-화면에-보이는-이름) |
| 앱 이름을 넣었더니 화면의 같은 글자까지 번역됐다 | 번역 CSV 키가 앱 이름 원문이다(방법 2) | `name_localized` 로 → [§12](#12-앱-이름--홈-화면에-보이는-이름) |

---

## 12. 앱 이름 — 홈 화면에 보이는 이름

홈 화면·앱 서랍에서 아이콘 아래에 보이는 이름이다. **기본 이름 하나 + 언어별 이름**을 정해 두면 기기 언어에 맞는 것이 뜬다.

> 🛑 **`application/config/name` 은 함부로 바꾸지 않는다.** 데스크톱(macOS·Windows·Linux)의 `user://` 저장 폴더가
> `app_userdata/<config/name>` 이라(`core/os/os.cpp` `get_user_data_dir` · `use_custom_user_dir=false` 일 때),
> 출시한 뒤에 바꾸면 저장된 로그인·설정을 못 찾는다. 모바일 이름은 아래 설정으로 따로 준다.

### 12-1. 무엇이 이름이 되나

| 플랫폼 | 기본 이름 | 언어별 이름이 들어가는 곳 | 언어별 이름이 생기는 조건 |
|---|---|---|---|
| **Android** | 프리셋 `package/name` (비우면 `config/name`) | `res/values-<언어>/godot_project_name_string.xml` | `config/name_localized` 만 채우면 된다 |
| **iOS** | `config/name` → Xcode `INFOPLIST_KEY_CFBundleDisplayName` | `<언어>.lproj/InfoPlist.strings` 의 `CFBundleDisplayName` | 🛑 **그 언어의 번역 파일이 `internationalization/locale/translations` 에 등록돼 있어야** 파일이 생긴다 |
| **macOS** | `config/name` | `Contents/Resources/<언어>.lproj/InfoPlist.strings` | iOS 와 같다 |
| Windows | 프리셋 `application/product_name`(파일 속성) | 없음 | — |

- 언어별 값을 고르는 규칙은 세 플랫폼이 같다 — `name_localized` 가 **있으면 그 값**(그 언어가 없으면 기본 이름),
  **비어 있으면 번역 파일에서 기본 이름 문자열을 키로 번역**한 값.
- iOS·macOS 의 **영어(`en.lproj`)는 항상 `config/name`** 이다 — `name_localized` 의 `"en"` 은 쓰지 않는다. Android 는 `values-en` 에 `"en"` 을 쓴다.

### 12-2. 방법 1 — `config/name_localized` (권장)

**① 기본 이름을 정한다**

```ini
; export_presets.cfg — Android 프리셋마다 [preset.N.options] 안
package/name="Laryen"
```

iOS·macOS 는 `config/name` 이 기본 이름이다. 저장 폴더 때문에 못 바꾸면 iOS 에만 기능 태그로 덮어쓴다(12-4).

**② 언어별 이름을 적는다**

```ini
; project.godot
[application]

config/name="Laryen 3D"
config/name_localized={
"ko": "라리엔",
"ja": "ラリエン"
}
```

에디터에서는 `Project > Project Settings > General` 오른쪽 위의 **Advanced Settings** 를 켜야 `Application > Config > Name Localized` 가 보인다
(`GLOBAL_DEF` 라 기본 목록에 없다). 키는 로케일 코드다 — `"ko"` · `"ja"` · `"zh_TW"`.

**③ iOS·macOS 까지 쓰려면 — 그 언어의 번역 파일을 하나 등록한다**

게임 번역(CSV·`.po`)을 이미 `locale/translations` 에 등록해 쓰고 있다면 **할 일이 없다** — 등록된 언어마다 이름 파일이 생긴다.
번역을 등록하지 않는 프로젝트면 앱 이름용 작은 CSV 를 만들어 임포트·등록한다([i18n.md §2](i18n.md)).
`name_localized` 가 있으면 번역 **값은 쓰지 않고 언어 목록만** 가져가므로 키는 아무것이나 된다.

```csv
keys,en,ko,ja
APP_NAME,Laryen,라리엔,ラリエン
```

```ini
; project.godot — 임포트한 뒤 등록한다
[internationalization]

locale/translations=PackedStringArray("res://i18n/app_name.en.translation", "res://i18n/app_name.ko.translation", "res://i18n/app_name.ja.translation")
```

- 🛑 등록한 번역은 **게임이 켜질 때 엔진이 로드한다.** 키 하나라 비용은 작지만, 번역을 직접(지연) 로드하도록 설계한 프로젝트면 그 설계와 맞는지 먼저 본다.
- 🛑 키를 화면 문구의 키와 겹치게 짓지 않는다 — 같은 키를 쓰는 Label 이 이 값으로 번역된다.

### 12-3. 방법 2 — 번역 파일만 (`name_localized` 비움)

`name_localized` 가 비어 있으면 **기본 이름 문자열 자체를 키로** 번역한다(Android 는 `package/name`, iOS·macOS 는 `config/name`).

```csv
keys,en,ko,ja
Laryen 3D,Laryen 3D,라리엔,ラリエン
```

- 🛑 키가 앱 이름 원문이라, 화면에 같은 글자를 자동 번역 Label 로 띄우면 **그것까지 바뀐다.**
- 🛑 Android `package/name` 과 `config/name` 이 다르면 키 행이 두 개 필요하다.

→ 특별한 이유가 없으면 방법 1 을 쓴다.

### 12-4. 플랫폼별 덮어쓰기와 주의

- **iOS 에만 기본 이름 바꾸기** — `config/name.ios="Laryen"` 처럼 **기능 태그**를 붙이면 내보내기가 그 값을 쓴다
  (`EditorExportPreset::get_project_setting` 이 플랫폼 기능 태그를 반영한다). iOS 저장 폴더는 앱 Documents 로 고정이라
  (`OS_AppleEmbedded::get_user_data_dir`) 저장 데이터가 안전하다. 🛑 `config/name.macos` · `.windows` 는 저장 폴더가 바뀌므로 하지 않는다.
- **Android Gradle 빌드** — 템플릿 `res/` 에 이미 있는 `values-*` 폴더(ko·ja·zh-rTW 등 약 40개)에만 넣는다(`gradle_export_util.cpp` `_create_project_name_strings_files`).
  폴더 이름에서 `values-` 를 떼고 `-r` 을 `_` 로 바꾼 것이 로케일 키다. 템플릿에 없는 언어는 새로 만들지 않는다.
  **레거시 빌드**(`use_gradle_build=false`)는 템플릿 매니페스트에 박힌 언어 목록을 쓰고, 값을 고르는 규칙은 같다.
- 🛑 Android 프리셋이 여럿이면 `package/name` 을 전부 바꾼다.
- `name_localized` 는 **게임 실행 중에는 아무도 읽지 않는다** — 엔진 소스에서 설정 정의·번역 템플릿·Android·Apple 내보내기에만 나온다.

### 12-5. 실측

**두 방법 비교 — 빈 프로젝트 (Godot 4.7.2 · 2026-09-14).** `config/name="Demo Game"` 에 CSV `Demo Game,Demo Game,데모B,デモB`(en·ko·ja)를
임포트·등록하고, 방법 1 은 `name_localized={"ko": "데모A", "ja": "デモA"}` 를 더했다.

| | iOS (Xcode 프로젝트만 내보내기) | macOS (.app) | Android 레거시 APK |
|---|---|---|---|
| 방법 1 | `ko.lproj` 데모A · `ja.lproj` デモA · `en.lproj` Demo Game · `project.pbxproj` 에 `en·ja·ko.lproj` 참조 | 같다 | `application-label-ko` 데모A · `-ja` デモA · 기본 Demo Game |
| 방법 2 | `ko.lproj` 데모B · `ja.lproj` デモB · `en.lproj` Demo Game | 같다 | `-ko` 데모B · `-ja` デモB · 기본 Demo Game |

→ `name_localized` 가 있으면 번역 값보다 먼저 쓰인다.

**라리엔 3D 적용 (2026-09-14)** — 번역을 등록하지 않고 직접 로드하는 구조라 Android 만 다국어이고, iOS 는 `config/name.ios` 로 영어 고정이다.

| 확인 | 결과 |
|---|---|
| A17 debug APK (Gradle) `aapt2 dump badging` | `application-label:'Laryen'` · `application-label-ko:'라리엔'` · 나머지 언어 모두 `Laryen` |
| Galaxy A17 (기기 언어 en-PH) | 앱 서랍·앱 정보 화면 모두 **Laryen** |
| iOS debug `.ipa` | `Info.plist` `CFBundleDisplayName = Laryen` · `en.lproj/InfoPlist.strings` 는 빈 사전 → 한국어 iPhone 에서도 **Laryen** |
| Galaxy A12 (기기 언어 ko-KR) | 🛑 미확인 — 다른 작업이 기기를 쓰고 있었다 |

### 12-6. 확인하는 법

```bash
# Android — 언어별 이름
aapt2 dump badging app.apk | grep -E '^application-label(-(ko|ja))?:'

# iOS — ipa 안 기본 이름과 언어별 이름
unzip -o -q app.ipa 'Payload/*.app/Info.plist' 'Payload/*.app/*.lproj/*'
plutil -p Payload/*.app/Info.plist | grep CFBundleDisplayName
plutil -p Payload/*.app/ko.lproj/InfoPlist.strings

# iOS — Xcode 프로젝트만 내보냈을 때(application/export_project_only=true): 언어 파일이 프로젝트에 등록됐나
grep -o '[a-zA-Z_]*\.lproj/InfoPlist.strings' <출력 폴더>/<이름>.xcodeproj/project.pbxproj | sort -u

# macOS
plutil -p <앱>.app/Contents/Resources/ko.lproj/InfoPlist.strings
```

실기기에서는 앱 정보 화면·앱 서랍을 캡처해 이름을 본다([§10](#10-확인하는-법) ⑥).

---

## 관련 문서

- [export-build-android.md](export-build-android.md) — APK·AAB 빌드 · §10 스플래시 요약
- [export-build-ios.md](export-build-ios.md) — Xcode 프로젝트·서명·아이콘 누락 시 export 중단
- [export-build-desktop.md](export-build-desktop.md) — macOS 공증·Windows 코드 서명
- [project-config.md](project-config.md) — `project.godot` 포맷
- [whats-new.md](whats-new.md) — 4.7 Android 네이티브 스플래시 신기능

## 공식 문서

- Godot — [Exporting for Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) · [Exporting for iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html) · [Exporting for macOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html) · [Changing application icon for Windows](https://docs.godotengine.org/en/stable/tutorials/export/changing_application_icon_for_windows.html) · [ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)
- Android — [Splash screens](https://developer.android.com/develop/ui/views/launch/splash-screen) · [Adaptive icons](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)
