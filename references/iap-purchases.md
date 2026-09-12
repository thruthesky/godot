# 인앱 결제 — Google Play · App Store · 서버 검증

> **이 문서로 오는 상황** — 게임 안에서 돈을 받는다. 상품 진열·가격 표시·결제창·영수증 검증·지급·복구.
> 🛑 **돈이 오가는 코드**다. "화면에 보이니 된 것 같다" 로 넘어가면 **돈만 받고 물건을 안 주는** 사고가 난다.

Godot 4 에서 인앱 결제를 붙이는 전 과정. 빌드·서명은 [export-build-android.md](export-build-android.md) ·
[export-build-ios.md](export-build-ios.md) 를 먼저 볼 것.

## 목차

1. [먼저 정하는 것 — 누가 영수증을 검증하나](#1-먼저-정하는-것--누가-영수증을-검증하나)
2. [전체 흐름 — 여덟 단계](#2-전체-흐름--여덟-단계)
3. [Android — 플러그인 설치](#3-android--플러그인-설치)
4. [Android — 연결과 상품 조회](#4-android--연결과-상품-조회)
5. [Android — 결제창 띄우기](#5-android--결제창-띄우기)
6. [Android — 소비와 확인, 그리고 자동 환불](#6-android--소비와-확인-그리고-자동-환불)
7. [놓친 결제를 되찾는다 — 두 겹의 그물](#7-놓친-결제를-되찾는다--두-겹의-그물)
8. [서버 검증](#8-서버-검증)
9. [iOS — StoreKit 2](#9-ios--storekit-2)
10. [실기기에서만 드러난다 — 검증 방법](#10-실기기에서만-드러난다--검증-방법)
11. [자주 막히는 지점](#11-자주-막히는-지점)

---

## 1. 먼저 정하는 것 — 누가 영수증을 검증하나

**클라이언트를 믿으면 안 된다.** "샀다" 는 신호만으로 지급하면 메모리 조작·리플레이로 무한히 받아 간다.
영수증은 반드시 **서버가 스토어에 직접 물어** 확인한다.

| 방식 | 검증 주체 | 언제 고르나 |
|---|---|---|
| **게임 서버 직접 검증** | 내 서버 → Google/Apple API | 이미 서버가 있다. 지급도 서버가 한다 |
| **BaaS 내장 검증** | Nakama·PlayFab 등 | 그 백엔드를 이미 쓴다. 영수증 검증기를 새로 안 짜도 된다 |
| **결제 중개 SDK** | RevenueCat 등 | 구독이 많고 여러 스토어를 한 번에 다룬다 |

🛑 **어느 쪽이든 "지급" 은 서버가 한다.** 클라이언트는 영수증을 전달만 하고, 수량은 서버가 내려 준다.
클라이언트가 자기 인벤토리를 더하면 지급이 두 번 되거나(재시도) 안 되거나(유실) 한다.

---

## 2. 전체 흐름 — 여덟 단계

```
① 스토어에 상품 등록          (콘솔 작업 — 상품 id 가 코드와 정확히 같아야 한다)
② 결제 가능 여부 판정          (플랫폼·로그인·계정 종류)
③ 스토어 연결                 (BillingClient / StoreKit)
④ 상품 조회 → 가격 표시        (🛑 가격은 스토어가 준 문자열을 그대로 쓴다)
⑤ 결제창                      (사용자가 확정)
⑥ 영수증 수신
⑦ 서버에 제출 → 검증 → 지급
⑧ 소비(consume) — 지급이 끝난 뒤에만
```

**⑧ 의 순서가 핵심이다.** 소비를 먼저 하면 영수증이 사라져, 지급이 실패했을 때 재시도할 근거가 없다.
반대로 소비를 빠뜨리면 같은 상품을 다시 못 사고, 스토어가 며칠 뒤 **자동 환불**한다.

---

## 3. Android — 플러그인 설치

Godot Foundation 이 관리하는 [godot-google-play-billing](https://github.com/godot-sdk-integrations/godot-google-play-billing)
을 쓴다. 엔진에 내장돼 있지 않으므로 **Android 플러그인으로 넣는다.**

```
addons/GodotGooglePlayBilling/
├── BillingClient.gd          ← GDScript 래퍼. 이것만 쓰면 된다
├── plugin.cfg
├── export_plugin.gd
└── bin/{debug,release}/*.aar
```

- 프리셋에서 **Gradle 빌드를 켜야** 플러그인 aar 이 들어간다(`gradle_build/use_gradle_build=true`).
- 래퍼는 `BillingClient.new()` 로 만들어 **씬 트리에 붙인다** — 시그널을 받으려면 트리에 있어야 한다.

```gdscript
var script := load("res://addons/GodotGooglePlayBilling/BillingClient.gd")
var billing: Node = script.new()
get_tree().root.add_child(billing)
```

🛑 **BillingClient 는 앱 전체에서 하나만 만든다.** 래퍼는 `_init()` 에서 플러그인 싱글톤의 시그널에
연결하는데, 인스턴스를 여러 개 만들면 **같은 신호가 중복으로 연결**되고 옛 인스턴스가 트리에 남아
계속 신호를 퍼뜨린다. 화면을 열 때마다 서비스 객체를 새로 만드는 구조라면 `static var` 로 공유하라.

---

## 4. Android — 연결과 상품 조회

### 🛑 요청은 시그널을 건 **다음에** 보낸다

플러그인 API 는 전부 "요청 → 시그널로 응답" 이다. 요청을 먼저 보내면 **응답이 연결보다 빨리 도착해
영영 놓친다.** 조회라면 화면이 비는 정도지만, 결제에서는 **돈만 나가고 지급이 0** 이 된다.

```gdscript
# ✅ 옳다 — 걸고 나서 보낸다
var watch := _watch(billing, "query_product_details_response")
billing.query_product_details(PackedStringArray(ids), 0)   # 0 = INAPP
var got: Array = await _wait(watch, 15_000)

# 🛑 틀렸다 — 보내고 나서 건다
billing.query_product_details(...)
var got := await _await_signal(billing, "query_product_details_response", 15_000)
```

`_watch`(연결) / `_wait`(대기)로 나눠 두면 순서를 지키기 쉽다.

### 🛑 인자 없는 시그널을 실패로 읽지 마라

| 시그널 | 인자 |
|---|---|
| `connected` · `disconnected` | **없음** |
| `connect_error` | `(response_code, debug_message)` |
| `query_product_details_response` · `query_purchases_response` | `(response: Dictionary)` |
| `on_purchase_updated` · `consume_purchase_response` · `acknowledge_purchase_response` | `(response: Dictionary)` |

받은 인자를 배열에 모아 돌려주는 헬퍼를 쓴다면, **인자가 없는 `connected` 는 빈 배열**이 된다.
그것을 `is_empty()` 로 실패라고 읽으면 **연결에 성공해도 언제나 "연결 실패"** 가 되어 그 다음이 통째로
막힌다. 빈손으로 온 시그널은 `[true]` 같은 표시로 바꿔 돌려줄 것.

### 응답 키 이름 — 바깥은 `_list` 가 없다

```gdscript
var res: Dictionary = got[0]
if int(res.get("response_code", -1)) != 0:      # 0 = BILLING_OK
    return {}
for d in res.get("product_details", []):        # 🛑 product_details_list 가 아니다
    var pid := String(d.get("product_id", ""))
    var offers = d.get("one_time_purchase_offer_details_list")   # 🛑 안쪽은 _list 가 맞다
    if offers is Array and not offers.is_empty():
        var first: Dictionary = offers[0]
        out[pid] = String(first.get("formatted_price", ""))       # "₩3,000" · "$1.99" · "₱139.00"
```

바깥은 `product_details`, 안쪽 제안 목록은 `one_time_purchase_offer_details_list`. **한 글자 차이로
가격이 전부 사라지고 화면에는 "불러오는 중" 만 남는다.** 응답 코드는 정상이라 더 헷갈린다.

응답의 `unfetched_products` 에는 **스토어가 모른다고 돌려보낸 상품 id** 가 담긴다. 오타·미게시·미활성을
가르는 단서이므로 로그로 남겨 둘 것.

### 🛑 가격을 지어내지 마라

`formatted_price` 를 **그대로** 쓴다. 통화 기호·자릿수·소수점 표기는 나라마다 다르고
(₩3,000 · $1.99 · Rs 165.00 · ₱139.00), 직접 조립하면 반드시 어딘가 틀린다.
받지 못했으면 **팔지 않는다** — 버튼을 잠그고 이유를 보여 주고 다시 받을 길을 준다.

---

## 5. Android — 결제창 띄우기

```gdscript
var watch := _watch(billing, "on_purchase_updated")   # 먼저 건다
var launch = billing.purchase(product_id, option_id)  # 즉시 반환 = "요청이 접수됐나" 일 뿐
if launch is Dictionary and int(launch.get("response_code", 0)) != 0:
    # code 7 = ITEM_ALREADY_OWNED → 소비되지 않은 지난 구매가 있다(§7)
    # code 1 = USER_CANCELED
    push_warning("결제창 실패: %s" % launch.get("debug_message", ""))
var updated: Array = await _wait(watch, 90_000)       # 카드 입력 시간까지 넉넉히
```

### 🛑 신형 일회성 상품은 `purchase_option_id` 가 필요하다

Play Console 의 상품이 `purchaseOptions[].purchaseOptionId` 를 가지는 **신형 구조**라면, 그 값을 함께
넘겨야 한다. 빈 문자열로 부르면 플러그인이
`"Invalid purchase_option_id or offer_id. Make sure purchase_option_id exists"` 로 거절하고
**결제창이 아예 열리지 않는다** — 사용자에게는 "눌러도 아무 일이 없는 버튼" 으로 보인다.

옵션 id 는 §4 의 가격 응답 안에 `purchase_option_id` 로 들어 있다. 가격을 받을 때 함께 챙겨 둘 것.

### 결제 결과 Dictionary

| 키 | 뜻 |
|---|---|
| `original_json` | **영수증 원문.** 서버 검증에 이것을 보낸다 |
| `signature` | 서명 |
| `purchase_token` | 소비·확인에 쓰는 토큰 |
| `purchase_state` | `1` = PURCHASED, `2` = PENDING |
| `order_id` · `product_ids` · `is_acknowledged` | 참고 |

🛑 **`purchase_state == PENDING` 은 아직 돈이 오지 않았다.** 지급하지 말고, 승인되면 다음 조회에서
회수한다(가족 승인·계좌이체가 이 상태를 만든다).

---

## 6. Android — 소비와 확인, 그리고 자동 환불

| 상품 종류 | 해야 할 일 | 안 하면 |
|---|---|---|
| 소모품(consumable) | `consume_purchase(token)` | 같은 상품을 다시 못 산다. **며칠 뒤 자동 환불** |
| 비소모품·구독 | `acknowledge_purchase(token)` | **3일 뒤 자동 환불** |

```gdscript
# 서버 지급이 성공한 뒤에만 소비한다
var res: Dictionary = await server_grant(receipt, product_id, character_id)
if not res.get("ok", false):
    return fail(res)          # 🛑 소비하지 않는다 — 영수증이 남아야 재시도할 수 있다
billing.consume_purchase(token)
```

🛑 **서버가 거부해도 스토어에서는 돈이 나갔을 수 있다.** 그때 소비해 버리면 재시도할 근거가 사라진다.
"다시 결제하세요" 를 권하면 **이중 결제**가 된다.

---

## 7. 놓친 결제를 되찾는다 — 두 겹의 그물

결제는 성공했는데 **결과 신호를 못 받는 일이 실제로 일어난다.** 앱이 죽거나, 통신이 끊기거나,
결제창에서 돌아오며 신호를 놓치거나. 그대로 두면 **소비하지 못해 스토어가 자동 환불**하고,
사용자는 "돈은 나갔는데 물건이 없다" 를 겪는다.

**① 그 자리에서** — 결과 대기가 타임아웃되면 곧바로 구매 목록을 확인한다. 스토어는 소비 전까지
구매를 들고 있으므로, 같은 흐름 안에서 지급을 마칠 수 있다.

```gdscript
if updated.is_empty():
    return await _recover_unconsumed(billing, product_id, character_id)
```

**② 다음 기회에** — 상점을 열 때(또는 앱을 켤 때) `query_purchases` 로 미소비 구매를 훑어 회수한다.
앱이 죽은 경우처럼 그 자리에서 손쓸 수 없었던 결제의 마지막 그물이다.

```gdscript
var watch := _watch(billing, "query_purchases_response")
billing.query_purchases(0)                       # 0 = INAPP
var got: Array = await _wait(watch, 15_000)
for entry in (got[0] as Dictionary).get("purchases", []):
    # 서버에 제출 → 성공하면 소비
```

🛑 **이 회수 코드를 써 놓고 부르지 않는 실수가 잦다.** 평소에는 아무 일도 없어서 죽어 있어도
모른다. "호출부가 존재하는가" 를 정적 검사로 못박아 둘 것.

---

## 8. 서버 검증

서버는 영수증을 **스토어에 직접 물어** 확인한다. 직접 짤 때의 최소 요건:

| 항목 | 이유 |
|---|---|
| **멱등 처리** | 같은 `purchase_token` 이 두 번 와도 한 번만 지급. 재시도·복구 경로가 반드시 중복을 만든다 |
| **환불 확인** | 환불된 영수증으로 지급하면 안 된다 |
| **상품 id 대조** | 영수증의 상품과 요청한 상품이 같은지 |
| **지급 대상 소유권** | 그 계정이 그 캐릭터를 가졌는지 |
| **원장 기록** | 언제 누구에게 무엇을 줬는지. 분쟁·재지급의 근거 |

Nakama 를 쓴다면 런타임에 검증기가 내장돼 있다 — `purchaseValidateGoogle` /
`purchaseValidateApple` 이 `seenBefore`(멱등)와 `refundTime` 까지 돌려준다. 서버 설정에
서비스 계정 키(Google) · 공유 비밀(Apple)을 넣어야 동작한다.

🛑 **PEM 개인키를 YAML 한 줄에 넣지 마라.** 큰따옴표 안의 실제 개행은 공백으로 접혀 키가 깨진다.
`\n` 으로 이스케이프해도 sed 류가 다시 실제 개행으로 되돌린다. **CLI 인자로 넘기는 편이 안전하다.**

---

## 9. iOS — StoreKit 2

Godot 4 는 iOS 인앱결제를 **엔진에 내장하고 있지 않다.** 플러그인을 넣는다.

| 방법 | 상태(2026-09) |
|---|---|
| **OpenIAP `godot-iap`** ([hyodotdev/openiap](https://github.com/hyodotdev/openiap)) | ✅ StoreKit 2 · GDExtension · Godot 4.3+ · 사전 빌드 프레임워크 포함 · 활발히 유지 |
| `godot-ios-plugins` 의 InAppStore | StoreKit 1 기반. 유지보수가 느리다 |
| `godot-store-kit` 등 | StoreKit 2 이지만 GDScript API 문서가 없는 미완성 |

### OpenIAP godot-iap 설치 — 🛑 함정 둘

1. **Android 결제를 다른 플러그인으로 이미 하고 있다면 `android/` 를 넣지 말고, 내보내기 플러그인도 손봐야 한다.**
   원본 `godot_iap_plugin.gd` 는 `_supports_platform()` 이 Android 에도 `true` 를 돌려주고
   `_get_android_libraries()` 가 `android/GodotIap.*.aar` 을 **무조건** 요구한다. 폴더만 빼면 Android
   내보내기가 깨지고, 둘 다 넣으면 Play Billing 의존성이 겹친다. → Android 판정을 `false` 로 바꾸고,
   iOS 가 아닌 프리셋의 `exclude_filter` 에 `addons/godot-iap/*` 를 넣는다(Android AAB 에 파일 0개인지 확인).
2. **자동 로드를 쓰지 않는 편이 낫다.** 원본은 `GodotIap` 이라는 싱글톤을 모든 플랫폼에 띄운다(네이티브
   클래스 이름과도 같다). 결제 코드에서 iOS 일 때만 `godot_iap.gd` 를 만들어 트리에 붙여 쓴다.

`.gdextension` 에 macOS 라이브러리가 없어서 **에디터·헤드리스 실행마다**
`ERROR: No GDExtension library found for current OS … godot_iap.gdextension` 이 찍힌다. 무해하지만,
로그 게이트가 `ERROR: .*\.gd` 같은 패턴을 쓰면 `.gdextension` 의 `.gd` 에 **거짓 일치**한다
(`\.gd([^a-zA-Z]|$)` 로 좁힐 것).

### 흐름

```gdscript
var iap = load("res://addons/godot-iap/godot_iap.gd").new()
get_tree().root.add_child(iap)                        # _ready 에서 네이티브 클래스(ClassDB "GodotIap")를 붙인다
var ok: bool = await iap.init_connection()            # 🛑 코루틴 — await 필수

var types = load("res://addons/godot-iap/types.gd")
var req = types.ProductRequest.new()
req.skus = ["potion_hp"] as Array[String]
for p in await iap.fetch_products(req):               # ProductIOS 객체
    prices[p.id] = p.display_price                    # 스토어 문자열 그대로

# 🛑 결과·오류 시그널을 요청 **전에** 건다(Android 와 같은 이유)
var ok_watch := _watch(iap, "purchase_updated")
var err_watch := _watch(iap, "purchase_error")
await iap.request_purchase({"requestPurchase": {"apple": {
    "sku": "potion_hp",
    "appAccountToken": server_user_uuid,             # 서버가 "누구의 구매인가" 를 대조한다
}}, "type": "in-app"})
# 결과 dict: productId · transactionId · purchaseToken(= StoreKit 2 JWS) · purchaseState
# 서버 지급이 성공한 뒤에만:
await iap.finish_transaction_dict(purchase, true)     # 소모품. 실패하면 마무리하지 않는다 → 다음 회수에서 재제출
# 놓친 결제 회수: await iap.get_available_purchases()
```

### 서버 검증 — StoreKit 2 는 영수증이 **JWS** 다

| 방법 | 조건 |
|---|---|
| Nakama `purchaseValidateApple` | 🛑 **3.37.0 이상**에서만 JWS 를 받는다. 그 아래는 구형 base64 앱 영수증뿐 |
| App Store Server API 조회 | ES256 JWT(App Store Connect `.p8` 키)가 필요. 🛑 Nakama JS 런타임 `jwtGenerate` 는 **HS256·RS256 만** 지원해 만들 수 없다 |
| **JWS 오프라인 검증** | 키 없이 가능. 서버 언어에 x509·ECDSA 가 있으면 된다(Go 표준 라이브러리로 충분) |

오프라인 검증 절차:

1. 헤더 `alg` 는 `ES256`, `x5c` 에 [leaf, intermediate, root] 인증서(표준 base64 DER)
2. leaf → **Apple Root CA - G3** 체인 검증. 루트는 앱에 내장하고 **SHA-256 지문을 고정**한다
   (`63:34:3A:BF:…:91:79`). 체인 시각은 payload 의 `signedDate` — 오래된 거래 회수가 인증서 만료로 막히지 않게
3. Apple 전용 OID 확장 확인 — leaf `1.2.840.113635.100.6.11.1`, intermediate `1.2.840.113635.100.6.2.1`
   (아무 Apple 인증서로 서명한 JWS 를 받지 않기 위해)
4. leaf 공개키로 서명 검증 — JWS 서명은 **R‖S 64바이트 원시값**이다(DER 아님)
5. payload 해석 — `transactionId` · `productId` · `bundleId` · `environment` · `appAccountToken` ·
   **`revocationDate`(0 이 아니면 환불)**

그 뒤 **bundleId 는 우리 앱인지, appAccountToken 은 제출한 계정인지** 대조한다. 서명이 진짜여도
남의 앱이나 남의 계정 거래를 재제출할 수 있다.

### 실기기 검증

iOS 는 `adb input` 같은 화면 조작 수단이 없고, iOS 17+ 에서는 `idevicescreenshot` 도 막혀 상점 UI 까지
자동으로 가기 어렵다. 대신 **디버그 빌드 + 앱 데이터 컨테이너의 표시 파일**로 부팅 시 상품 조회만 돌려 본다.

```bash
xcrun devicectl device install app --device <ID> Game.ipa
xcrun devicectl device copy to --device <ID> --source ./flag --destination Documents/iap_probe \
  --domain-type appDataContainer --domain-identifier <bundle id>
idevicesyslog -u <UDID> > syslog.txt &            # Godot print 는 devicectl --console 에 안 나온다
xcrun devicectl device process launch --device <ID> --terminate-existing <bundle id>
```

- 🛑 **기기가 네트워크로만 붙어 있으면 `idevice_id -l` 이 비고 syslog 가 텅 빈다.** `idevice_id -n` 으로 UDID 를
  얻고 `idevicesyslog -n -u <UDID>` 로 받는다. 그대로 받으면 80초에 50MB 가 넘으니 `-m IAP` 처럼 걸러 받는다.
- iOS 의 `user://` 는 **앱 Documents** 다(`devicectl … copy to --destination Documents/…` 가 그대로 닿는다).
- 모바일은 Godot 파일 로그가 기본 꺼져 있어 `Documents/logs/godot.log` 가 없다 — 시스템 로그가 정본이다.
- 실측(2026-09): 디버그 서명 빌드에서 OpenIAP `init_connection()` → `true`, `fetch_products` 가 등록된 소모품을
  `display_price` 와 함께 돌려줬다. **상품 조회에는 샌드박스 계정 로그인이 필요 없다.**
- 🛑 스토어에 상품이 있는지 **다른 기록(결제 중개 대시보드 등)으로 추정하지 말고** 기기에서 조회해 볼 것 —
  중개 서비스에 등록 안 된 상품도 스토어에는 있을 수 있다.

- 소모품은 `finishTransaction` 을 **지급 뒤에** 부른다(Android 의 consume 과 같은 자리).
- 샌드박스 계정으로만 테스트한다. 실계정으로 하면 실제로 청구된다.
- App Store Connect 에 상품이 등록·승인 대기 상태여야 `fetch_products` 가 돌려준다.
- 가족 공유·환불 알림(App Store Server Notifications)을 서버가 받도록 해 두면 사후 정산이 쉽다.

---

## 10. 실기기에서만 드러난다 — 검증 방법

**헤드리스로는 결제 버그가 하나도 드러나지 않는다.** 결제 플러그인이 없고, 주입한 터치는 GUI 에
닿지 않는다(닫기 버튼 같은 대조군으로 확인해 보면 안다). 실기기 + 로그가 유일한 길이다.

### 진단 로그를 먼저 넣는다

결제 코드에 로그가 없으면 **어느 단계에서 막혔는지 알 방법이 전혀 없다.** 다음 지점은 반드시 남길 것.

```
[IAP] 연결됨 / 연결 실패(타임아웃)
[IAP] 가격 4/4 — {...}          ← 요청 수 대비 받은 수
[IAP] 스토어가 모르는 상품: [...]
[IAP] 구매 눌림 <상품> (대상=<캐릭터>)
[IAP] 결제창 요청 <상품> option=<...> → code=<n> msg=<...>
[IAP] 결제 결과 도착 code=<n> 개수=<n>
[IAP] 미소비 구매 조회 code=<n> 개수=<n>
```

민감한 값(구매 토큰·영수증 원문)은 남기지 않는다.

### 사이드로드로는 검증할 수 없다

Play Billing 은 패키지명 + **서명**으로 앱을 식별한다. Play 앱 서명(Play App Signing)을 쓰면
배포본 서명 ≠ 업로드 키 서명이라, 로컬 빌드를 사이드로드하면 상품 조회 자체가 안 된다
(Play 가 Update 버튼을 보여 주더라도 설치는 `Can't install` 로 거부된다).
**내부 테스트 트랙에 올리고 그 링크로 옵트인한 계정으로 설치**해야 한다.

### 테스트 결제

라이선스 테스터로 등록한 계정이면 결제창에 이렇게 뜬다.

```
Test card, always approves
This is a test order, you will not be charged.
```

실제 청구는 없다. 다만 **소비하지 않으면 그대로 자동 환불**되므로, 지급까지 완주하는지 확인할 것.
주문 기록은 Play 스토어 앱 → 계정 → 예산 및 주문 기록에서 볼 수 있다.

---

## 11. 자주 막히는 지점

| 증상 | 원인 | 확인 |
|---|---|---|
| 전원이 "손님은 살 수 없다" | 계정 종류 판정 함수가 **코루틴**인데 `await` 없이 불렀다. 반환된 코루틴 객체는 계정과 무관하다 | 그 함수 본문에 `await` 가 있는지 |
| 처음 여는 사람만 실패 | 위와 같다. 값이 캐시된 뒤에는 즉시 반환돼 증상이 사라진다 | 캐시를 비우고 재현 |
| 연결됐는데 "연결 실패" | `connected` 는 **인자 없는 시그널** | 대기 헬퍼가 빈 배열을 실패로 읽는지 |
| 가격이 0개 · 버튼 영구 잠김 | 응답 키가 `product_details` 인데 `product_details_list` 를 읽었다 | 응답 코드는 정상인지, 키 철자 |
| 눌러도 결제창이 안 뜸 | 신형 상품인데 `purchase_option_id` 를 안 넘겼다 | `launch.debug_message` |
| 조용히 거부 | 지급 대상 id 가 빈 문자열 | 그 값을 어디서 채우는지 **실제로** 대입하는 코드가 있는지 |
| 주문은 생겼는데 물건이 안 옴 | 결과 신호를 놓쳐 소비하지 못했다 → 자동 환불 | 주문 기록에 `Refunded` |
| 같은 신호가 여러 번 | BillingClient 를 여러 개 만들었다 | 인스턴스가 몇 개인지 |
| 재구매가 막힘(code 7) | 지난 구매를 소비하지 않았다 | 미소비 회수 경로가 실제로 불리는지 |
| 주문은 생겼는데 항목을 못 고름 | 구매의 `product_ids` 가 **`PackedStringArray`** 인데 `is Array` 로 검사했다 — 둘은 다른 타입 | 원소를 문자열로 비교하는지 |
| 서버 저장이 `value too long` | **Google 구매 토큰은 ~150자.** 스토리지 key 한계(Nakama 는 128)를 넘는다. 자르면 다른 거래가 같은 키가 된다 | 원장·대기열 삭제·영수증이 **같은 접힌 키**(해시)를 쓰는지 |

### 🛑 응답 키가 의심스러우면 플러그인에서 직접 확인한다

문서보다 빌드된 플러그인이 정본이다. aar 안의 클래스 상수 풀에서 키 이름을 뽑을 수 있다.

```bash
unzip -o -q plugin.aar -d /tmp/aar && cd /tmp/aar && unzip -o -q classes.jar
javap -v -p org/.../Utils.class | grep -oE 'String +[a-z_]+' | awk '{print $2}' | sort -u
```

코드가 읽는 키(`.get("...")`)를 이 목록과 대조하면 오타를 한 번에 찾는다.

## 함께 보기

- [export-build-android.md](export-build-android.md) — AAB 빌드·서명·Play 업로드
- [export-build-ios.md](export-build-ios.md) — iOS 빌드·서명
- [networking-lowlevel.md](networking-lowlevel.md) — 서버 통신
