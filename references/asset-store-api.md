# Asset Store API — 조회 자동화와 "업로드 API 는 없다"

> **이 문서로 오는 상황** — 애셋 등록·버전 올리기를 스크립트로 자동화하려 할 때, 내가 낸 애셋의
> 릴리스 상태를 감시하고 싶을 때, 애셋 목록·검색을 프로그램으로 긁을 때 — 🛑 **업로드 API 는
> 존재하지 않는다**(§1), 엔드포인트 전량(§4), 페이지네이션 두 방식(§6), 스펙과 실제가 다른 곳(§8)

`store.godotengine.org` 에는 **공개된 REST API 가 있다.** 사이트 어디에도 링크가 없어 찾기
어려울 뿐, 스펙·Swagger·ReDoc 이 모두 열려 있다.

확인 기준은 **API `1.1.0`** 이고, 이 문서의 모든 값은 2026-09-12 에 실제로 호출해 얻은 것이다.
API 는 스스로 **experimental** 이라고 밝히고 있으므로(§변경 이력) 값이 바뀔 수 있다 —
의심스러우면 `openapi.json` 을 다시 받아 대조한다.

## 목차

| 절 | 내용 |
|---|---|
| [1](#1-결론--무엇이-되고-무엇이-안-되나) | 🛑 결론 — 무엇이 되고 무엇이 안 되나 |
| [2](#2-진입점) | 진입점 |
| [3](#3-인증--api-키) | 인증 — API 키 |
| [4](#4-엔드포인트-전량-14개) | 엔드포인트 전량 (14개) |
| [5](#5-조회--애셋릴리스검색) | 조회 — 애셋·릴리스·검색 |
| [6](#6-페이지네이션-두-방식) | 페이지네이션 두 방식 |
| [7](#7-실전--내-애셋-감시) | 실전 — 내 애셋 감시 |
| [8](#8--함정) | 🛑 함정 |
| [9](#9-이-프로젝트에서--gohud) | 이 프로젝트에서 — gohud |
| [·](#변경-이력-api-가-스스로-밝히는-것) | 변경 이력 · 공식 문서 |

---

## 1. 결론 — 무엇이 되고 무엇이 안 되나

**쓰기 계열 엔드포인트는 단 두 개, 둘 다 API 키 자체를 만들고 지우는 것이다.**

```
POST   /api/v1/auth/token     ← API 키 발급
DELETE /api/v1/auth/token     ← API 키 폐기
```

애셋 생성·수정, 버전 등록, 파일 업로드, 미디어 업로드에 해당하는 경로는 **스펙에 존재하지
않는다.** 스펙 전체를 기계적으로 세어 확인한 결과다.

| 하고 싶은 것 | API | 방법 |
|---|---|---|
| 애셋 신규 등록 | ❌ 없다 | 웹 UI 수동 |
| 새 버전(릴리스) 올리기 | ❌ 없다 | 웹 UI 수동 |
| 스크린샷·썸네일 업로드 | ❌ 없다 | 웹 UI 수동 |
| 설명·태그 수정 | ❌ 없다 | 웹 UI 수동 |
| 내 애셋 상태·릴리스 조회 | ✅ 된다 | `GET /releases/...` |
| 애셋 목록·검색·태그·라이선스 조회 | ✅ 된다 | 인증 없이도 |
| 다운로드 URL 얻기 | ✅ 된다 | `GET /releases/...` |

> **API 키는 퍼블리싱용이 아니라 조회용이다.** 레이트 리밋 완화와 비공개 데이터 접근이 목적이지,
> 키가 있다고 업로드가 열리지 않는다.

**업로드 자동화는 로드맵의 "Asset store CLI" 가 나와야 가능하다.** 그전까지 CI 에서 할 수 있는
것은 "올린 뒤 올라갔는지 확인"까지다.

## 2. 진입점

| URL | 내용 |
|---|---|
| `https://store.godotengine.org/api/v1/` | 버전과 문서 링크 (JSON) |
| `https://store.godotengine.org/api/v1/openapi.json` | OpenAPI 스펙 (38KB) |
| `https://store.godotengine.org/api/v1/swagger` | Swagger UI |
| `https://store.godotengine.org/api/v1/redoc` | ReDoc |

```bash
curl -s https://store.godotengine.org/api/v1/
# {"docs_redoc":"...","docs_swagger":"...","openapi_spec":"...","version":"1.1.0"}
```

버전 문자열을 먼저 읽어 **이 문서가 쓰인 `1.1.0` 과 같은지** 확인하는 것이 습관으로 좋다.

## 3. 인증 — API 키

스킴은 **HTTP Bearer** 하나다(`securitySchemes: {"API Key": {type: http, scheme: bearer}}`).

```bash
curl -H "Authorization: Bearer <API_KEY>" \
     https://store.godotengine.org/api/v1/auth/introspection
```

키는 스토어 웹 UI 의 계정 설정에서 만들고, 만든 뒤에는 API 로도 추가 발급할 수 있다.

```bash
# 새 키 발급 — 기존 키로 인증해서 부른다. 토큰은 이때 한 번만 돌려준다.
curl -X POST -H "Authorization: Bearer <API_KEY>" -H "Content-Type: application/json" \
     -d '{"description":"ci-monitor","lifespan":2592000}' \
     https://store.godotengine.org/api/v1/auth/token

# 폐기 — id 또는 token 중 하나 (둘은 배타적)
curl -X DELETE -H "Authorization: Bearer <API_KEY>" -H "Content-Type: application/json" \
     -d '{"id":123}' \
     https://store.godotengine.org/api/v1/auth/token
```

`lifespan` 은 **초 단위 만료 기간**이다. 응답의 `token` 은 **다시 볼 수 없으니** 그 자리에서
저장한다.

> 🛑 **`introspection` 은 키가 없어도 200 을 돌려준다** — `{"authenticated":"False"}`.
> 키 유효성 검사를 HTTP 상태 코드로 하면 안 되고 **본문의 `authenticated` 를 봐야 한다**(§8).

## 4. 엔드포인트 전량 (14개)

스펙에 있는 전부다. `sec` 는 인증 요구 여부.

| Method | Path | sec | 용도 |
|---|---|---|---|
| GET | `/api/v1/` | — | API 버전·문서 링크 |
| GET | `/api/v1/auth/introspection` | ✅ | 내 연결 정보 |
| POST | `/api/v1/auth/token` | ✅ | API 키 발급 |
| DELETE | `/api/v1/auth/token` | ✅ | API 키 폐기 |
| GET | `/api/v1/assets/` | — | 애셋 목록 |
| GET | `/api/v1/assets/{publisher}/{asset}/` | — | 애셋 상세 |
| GET | `/api/v1/releases/{publisher}/{asset}/` | — | 릴리스(다운로드) 목록 |
| GET | `/api/v1/publishers/{publisher}/` | — | 퍼블리셔 상세 |
| GET | `/api/v1/search/query/` | — | 검색 |
| GET | `/api/v1/search/autocomplete/` | — | 검색어 자동완성 |
| GET | `/api/v1/asset-types/` | — | 애셋 타입 목록 |
| GET | `/api/v1/tags/` | — | 태그 목록 |
| GET | `/api/v1/licenses/` | — | 라이선스 필터 목록 |
| GET | `/api/v1/changelog/` | — | 스토어 자체 변경 이력 |

**조회는 전부 인증이 필요 없다.** 아래 두 줄이 그대로 돈다.

```bash
curl -s "https://store.godotengine.org/api/v1/assets/?page_size=2"
curl -s "https://store.godotengine.org/api/v1/releases/philip-drobar/cogito/"
```

## 5. 조회 — 애셋·릴리스·검색

### `GET /assets/` — 목록

| 파라미터 | 기본 | 뜻 |
|---|---|---|
| `type` | — | `0`=애드온, `1`=풀 프로젝트(템플릿·데모) |
| `featured_only` | `false` | 추천 애셋만 |
| `require_release` | **`true`** | 릴리스가 있는 것만 — **끄면 초안까지 들어온다** |
| `stable_only` | `false` | 안정 릴리스가 있는 것만 |
| `compatibility` | — | 그 Godot 버전용 다운로드가 있는 것만 (예: `4.7`) |
| `page` / `page_size` | `1` / `24` | 페이지 |

### `GET /assets/{publisher}/{asset}/` — 상세

슬러그는 스토어 URL 에서 그대로 읽는다 — `store.godotengine.org/asset/<publisher>/<asset>/`.

주요 필드: `slug` `name` `description` `type` `license_type` `license_url` `price_cent`(유로 센트)
`reviews_score`(업보트−다운보트) `tags[]` `body_html`/`body_bbcode`(상세 설명) `media[]`(스크린샷)
`source`(소스 저장소 URL) `thumbnail` `featured_thumbnail` `video_*` `created` `last_updated`
`featured` `publisher{}`.

### `GET /releases/{publisher}/{asset}/` — 릴리스

**여기가 자동화에서 가장 쓸모 있다.** 실제 응답 한 건:

```json
{
  "id": 1204, "version": "v1.1.6", "stable": true,
  "size": 43.8218,                        // MB (스펙에는 boolean 으로 잘못 적혀 있다 — §8)
  "created": "2026-04-23",
  "min_godot_version": "4.5.1", "max_godot_version": null,
  "notes": "...", "changes_html": "...", "changes_bbcode": "...",
  "download_url": "https://fra1.digitaloceanspaces.com/asset-store-prod/assets/1/Cogito-v1.1.6.zip?X-Amz-Algorithm=AWS4-HMAC-SHA256&..."
}
```

`download_url` 은 **서명된 임시 URL** 이다. 저장해 두고 나중에 쓰면 만료돼 있으니, 받을 때마다
새로 조회한다.

### `GET /search/query/` — 검색

| 파라미터 | 비고 |
|---|---|
| `query` | **필수**. `#tag` 문법으로 태그 지정 (`"hud #ui"`) |
| `sort` | `relevance`(기본) `updated_desc` `updated_asc` `reviews_desc` `reviews_asc` `created_desc` `created_asc` |
| `licenses` | 배열. `/licenses/` 가 주는 값 |
| `type` `featured_only` `require_release` `stable_only` `compatibility` | `/assets/` 와 동일 |
| `page` / `batch_size` | ⚠️ `page_size` 가 아니라 **`batch_size`** 다 |

응답 모양이 `/assets/` 와 **다르다**:

```json
{"count": 276, "hits": [{"asset": {...}, "highlights": {...}}], "scroll": "eyJvcmRlcl9ieV9zdHIi...", "tag_filters": [{"count": 38, "tag": {...}}]}
```

애셋은 `hits[].asset` 안에 한 겹 들어 있고, `tag_filters` 는 그 검색 결과의 태그별 개수다
(웹 UI 의 사이드바 필터가 이 값을 쓴다).

## 6. 페이지네이션 두 방식

**같은 API 안에서 두 방식이 섞여 있다.** 이걸 모르면 두 번째 페이지를 못 넘긴다.

| | `/assets/` 계열 | `/search/query/` |
|---|---|---|
| 요청 | `page` + `page_size` | `page` + `batch_size` |
| 전체 개수 | **응답 헤더** `x-pagination` | 본문 `count` |
| 이어받기 | `next_page` | `scroll` 커서 |

```bash
curl -s -D - -o /dev/null "https://store.godotengine.org/api/v1/assets/?page_size=1" | grep -i x-pagination
# x-pagination: {"total": 1387, "total_pages": 1387, "first_page": 1, "last_page": 1387, "page": 1, "next_page": 2}
```

🛑 **`/assets/` 의 본문은 그냥 배열이다.** 총 개수가 본문에 없으므로 **헤더를 버리면 안 된다**
(`curl -D -`, `requests` 의 `r.headers`).

## 7. 실전 — 내 애셋 감시

등록·업로드는 못 해도 **"올라갔는지, 어느 버전이 붙었는지"** 는 스크립트로 확인할 수 있다.
릴리스를 올린 뒤 검수 통과를 기다릴 때 쓴다.

```python
#!/usr/bin/env python3
"""내 애셋의 최신 릴리스를 확인한다. 인증 불필요."""
import json, sys, urllib.request

PUB, ASSET = "thruthesky", "gohud"
BASE = "https://store.godotengine.org/api/v1"

def get(path):
    req = urllib.request.Request(f"{BASE}{path}", headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)

try:
    rel = get(f"/releases/{PUB}/{ASSET}/")
except urllib.error.HTTPError as e:
    print(f"아직 공개되지 않았다 (HTTP {e.code})")   # 등록 전에는 404
    sys.exit(1)

for r in rel:
    flag = "stable" if r["stable"] else "pre"
    print(f'{r["version"]:10} {flag:7} {r["size"]:.1f}MB  '
          f'godot>={r["min_godot_version"]}  {r["created"]}')
```

등록 전에는 `publishers/<slug>/` 도 `/releases/` 도 **404** 다 — 이것으로 "아직 심사 중/미공개"를
구분한다.

## 8. 🛑 함정

1. **`introspection` 은 키가 틀려도 200 이다.** 본문 `authenticated` 를 봐야 한다.
   게다가 그 값은 boolean 이 아니라 **문자열 `"False"`/`"True"`** 다 — 파이썬에서
   `if data["authenticated"]:` 로 쓰면 `"False"` 도 참이다. `== "True"` 로 비교한다.
2. **`ReleaseData.size` 의 스펙 타입이 틀렸다.** 스펙은 `boolean`, 설명은 "Size in MB",
   실제 값은 `43.8218`(float). 스펙에서 생성한 클라이언트를 그대로 믿지 말 것.
3. **`/assets/` 의 총 개수는 본문에 없다.** `x-pagination` 헤더에만 있다(§6).
4. **검색만 `batch_size` 다.** `page_size` 를 보내면 조용히 무시되고 24개가 온다.
5. **AI 사용 공개 정보는 API 에 없다.** 스토어는 2025-10-30 에 애셋의 AI 공개 항목을 추가했지만
   (등록 화면의 *"This asset uses AI generated assets and/or code"*), 그 값은 **스펙에도 실제
   응답에도 나오지 않는다.** API 로 "AI 애셋 걸러내기"는 지금 불가능하다.
6. **`download_url` 은 서명된 임시 URL** 이라 만료된다. 캐시하지 말고 그때그때 조회한다.
7. **experimental 이다.** 스토어 스스로 changelog 에서 그렇게 부른다. 파이프라인에 넣을 때는
   `/api/v1/` 의 `version` 을 먼저 읽어 기대값과 다르면 경고를 띄우는 정도의 방어가 싸다.

## 9. 이 프로젝트에서 — gohud

라리엔 3D 의 공용 HUD/UI 는 **`gohud`** 라는 독립 애드온으로 분리돼 있다
([asset-store.md §5](asset-store.md#5-이-프로젝트에서-쓰는-애드온)).

| | 방법 |
|---|---|
| 개발·소비 | `addons/gohud` **git submodule** (`github.com/thruthesky/gohud`) — 라리엔과 동시에 고친다 |
| 배포 | Asset Store 에 **웹 UI 로 수동** 등록 · 새 버전도 수동 업로드 (API 없음 — §1) |
| 배포 후 확인 | 이 API 의 `GET /releases/thruthesky/gohud/` (§7 스크립트) |
| 남이 받는 경로 | Asset Store 다운로드 또는 `git submodule add` |

즉 **이 API 는 gohud 를 "올리는" 데는 못 쓰고, "올라간 것을 확인·감시"하는 데 쓴다.**
스토어 등록 화면에서 채우는 값들은 이 API 의 응답 필드와 그대로 대응하므로
(`description`=Summary, `body_*`=Detailed Description, `tags`, `license_type`, `source`),
등록 뒤 `GET /assets/thruthesky/gohud/` 한 번으로 **입력이 의도대로 들어갔는지 검증**할 수 있다.

## 변경 이력 (API 가 스스로 밝히는 것)

`GET /api/v1/changelog/` 로 직접 확인한 값이다.

| 날짜 | 내용 |
|---|---|
| 2025-09-05 | **"Added an experimental API"** — API 최초 공개 |
| 2025-10-30 | 애셋에 AI 공개 정보 추가 · **API 엔드포인트를 재작업해 더 많은 데이터 노출** |
| 2025-11-18 | 애셋 엔드포인트에 비디오 URL 추가 · 페이지네이션 추가 |
| 2026-03-11 | **changelog 엔드포인트 추가** |
| 2026-03-31 | 릴리스 changelog 를 API 에 추가 |
| 2026-08-26 | **"Implement API keys"** — API 키 도입 |

## 공식 문서

- API 스펙(비공개 링크): https://store.godotengine.org/api/v1/openapi.json · https://store.godotengine.org/api/v1/redoc
- Asset Store 일반: https://docs.godotengine.org/en/stable/community/asset_store/what_is_asset_store.html
- 설치·활성화·`plugin.cfg`: [asset-store.md](asset-store.md)
