# 저수준 네트워킹 — 외부 서버와 통신하는 엔진 API

**이 문서는 "Godot 이 아닌 서버" 와 통신하는 법**을 담는다. 라리엔 3D 의 서버는 Go 로 짠
UDP Zone 서버와 Nakama 이고, 둘 다 Godot 이 아니다. 그래서 [multiplayer.md](multiplayer.md) 가
다루는 **고수준 멀티플레이어 API(`ENetMultiplayerPeer`·`@rpc`·`MultiplayerSpawner`·
`MultiplayerSynchronizer`)는 라리엔의 실시간 통신에 쓰지 않는다** — 그것은 양쪽이 Godot 일 때의 도구다.

> ### 🛑 경계 — 이 문서와 `game` 스킬의 역할이 다르다
>
> | 여기(엔진 API) | `game` 스킬(라리엔 프로토콜) |
> |---|---|
> | `PacketPeerUDP` 로 패킷을 보내고 받는 법 | HELLO/WELCOME 흐름·SNAP 레이아웃·opcode → [server-protocol.md](../../game/references/server-protocol.md) |
> | `StreamPeerBuffer` 로 바이트를 읽는 법과 **엔디안** | BigEndian 고정이라는 **결정**과 디코더 전체 구현 → [server-protocol.md §6~7](../../game/references/server-protocol.md) |
> | `HTTPRequest`·`WebSocketPeer` 사용법 | Nakama 인증·RPC·소켓·파티 → [nakama-godot.md](../../game/references/nakama-godot.md) |
>
> **프로토콜 값(포트·매직·헤더 길이·opcode)은 여기 적지 않는다.** `game` 스킬이 정본이다.

값·시그니처는 **4.7.2.stable 의 `doctool` 과 헤드리스 실측**으로 확인한 것이다.
공식 문서 Manual → **Networking** 6편(High-level multiplayer · Making HTTP requests · HTTP client class ·
TLS/SSL certificates · Using WebSockets · WebRTC) 중 고수준 멀티플레이어와 WebRTC 를 뺀 넷에 대응한다.

## 목차

| 절 | 내용 |
|---|---|
| [§1](#1-핵심-개념--네-가지-통신-방식과-라리엔의-대응) | 핵심 개념 — 네 가지 통신 방식과 라리엔의 대응 |
| [§2](#2-packetpeerudp--메시지-단위비신뢰-통신) | `PacketPeerUDP` — 메시지 단위·비신뢰 통신 ★ Zone 서버 |
| [§3](#3-streampeerbuffer-와-엔디안--바이트를-숫자로-읽는다) | `StreamPeerBuffer` 와 엔디안 — 바이트를 숫자로 읽는다 ★ 실측 |
| [§4](#4-httprequest--요청-하나-응답-하나) | `HTTPRequest` — 요청 하나, 응답 하나 |
| [§5](#5-httpclient--httprequest-아래의-저수준) | `HTTPClient` — `HTTPRequest` 아래의 저수준 |
| [§6](#6-websocketpeer--양방향-메시지tcp) | `WebSocketPeer` — 양방향 메시지(TCP) |
| [§7](#7-tls--wsshttps-가-그냥-되는-이유) | TLS — `wss://`·`https://` 가 그냥 되는 이유 |
| [§8](#8-모바일에서-반드시-할-것) | 모바일에서 반드시 할 것 — INTERNET 권한·백그라운드 |
| [§9](#9-자주-하는-실수) | 자주 하는 실수 |
| [공식 문서](#공식-문서) | |

---

## 1. 핵심 개념 — 네 가지 통신 방식과 라리엔의 대응

Godot 의 네트워크 클래스는 **"무엇을 단위로 주고받는가"** 로 갈린다.

| 클래스 | 단위 | 전송 | 보장 | 라리엔에서 |
|---|---|---|---|---|
| **`PacketPeerUDP`** | **패킷**(바이트 덩어리 하나) | UDP | 🛑 **없음** — 잃어버리거나 순서가 바뀔 수 있다 | **Zone 서버** — 위치·전투 SNAP. 빠름이 보장보다 중요하다 |
| `StreamPeerTCP` | **바이트 흐름** | TCP | 순서·도착 보장 | 직접 쓰지 않는다 (아래 둘이 이것 위에 있다) |
| **`HTTPRequest`** | **요청 → 응답** 한 쌍 | TCP(HTTP) | 보장 | Nakama REST(로그인·RPC) — Nakama SDK 가 안에서 쓴다 |
| **`WebSocketPeer`** | **메시지**(텍스트 또는 바이너리) | TCP(WebSocket) | 보장 | Nakama 실시간 소켓(파티·채팅) — SDK 가 안에서 쓴다 |

**공통 규칙 셋**

1. **아무것도 스스로 돌지 않는다.** `_process()` 나 `_physics_process()` 에서 **매 프레임 `poll()` 하거나 패킷을 꺼내야** 데이터가 움직인다(`HTTPRequest` 노드만 예외 — 노드라서 알아서 돈다).
2. **블로킹 함수는 부르지 않는다.** `PacketPeerUDP.wait()` 처럼 "올 때까지 기다리는" 함수는 **게임 전체를 멈춘다.**
3. **받은 것은 `PackedByteArray` 다.** 숫자로 바꾸려면 §3 의 `StreamPeerBuffer` 또는 `decode_*` 를 쓰고, **엔디안을 서버와 맞춘다.**

```
서버가 보낸 바이트 ──(UDP)──▶ PacketPeerUDP.get_packet() ──▶ PackedByteArray
                                                                │
                                              StreamPeerBuffer.data_array = 그것
                                              big_endian = true   ← 🛑 서버가 BigEndian 이면
                                              get_u16() / get_float() … 순서대로 읽는다
```

---

## 2. `PacketPeerUDP` — 메시지 단위·비신뢰 통신

`PacketPeerUDP` 는 `PacketPeer` 를 상속한다. **한 번의 `put_packet()` 이 UDP 데이터그램 하나**다.

### 시그니처 (doctool 4.7.2)

| 메서드 | 뜻 |
|---|---|
| `bind(port: int, bind_address: String = "*", recv_buf_size: int = 65536) -> Error` | 내 쪽 포트를 연다. **서버 역할이거나, 받을 포트를 고정할 때**만. 클라이언트는 대개 필요 없다 |
| `connect_to_host(host: String, port: int) -> Error` | 상대를 고정한다. 이후 `put_packet()`/`get_packet()` 이 그 상대와만 오간다. **UDP 는 연결이 없으므로 이 호출은 실패하지 않는다** — 상대가 죽어 있어도 `OK` 다 |
| `set_dest_address(host: String, port: int) -> Error` | `connect_to_host` 없이 보낼 곳만 정한다. 여러 상대와 오갈 때 |
| `put_packet(buffer: PackedByteArray) -> Error` | 보낸다 |
| `get_available_packet_count() -> int` | 도착해 있는 패킷 수. **0 이면 `get_packet()` 을 부르지 않는다** |
| `get_packet() -> PackedByteArray` | 하나 꺼낸다 |
| `get_packet_ip() -> String` · `get_packet_port() -> int` | 방금 꺼낸 패킷이 어디서 왔나 |
| `is_socket_connected() -> bool` · `is_bound() -> bool` | 상태 |
| `close() -> void` | 닫는다. `_exit_tree()` 에서 부른다 |
| 🛑 `wait() -> Error` | **패킷이 올 때까지 블로킹** — 게임에서 쓰지 않는다 |

`PacketPeer` 에서 물려받는 `put_var()`/`get_var()` 는 **Godot 끼리** Variant 를 주고받을 때 쓰는 것이다.
**Go 서버는 Variant 를 모르므로 쓰지 않는다.** 바이너리는 `put_packet`/`get_packet` 뿐이다.

### 최소 클라이언트 — 붙고, 보내고, 매 프레임 받는다

```gdscript
## UDP 클라이언트의 뼈대. 어느 노드에든 붙는다.
## 🛑 실제 포트·매직·패킷 형식은 game 스킬 server-protocol.md 가 정본이다 — 여기 숫자는 자리표시자다.
extends Node

var udp := PacketPeerUDP.new()

func _ready() -> void:
	# 상대를 고정한다. UDP 라 "연결" 이 아니라 "이제부터 이 주소와만 오간다" 는 뜻이다.
	var err := udp.connect_to_host("127.0.0.1", 8002)
	if err != OK:
		push_error("UDP 소켓을 열지 못했다: %s" % error_string(err))
		return
	# 첫 패킷을 보낸다. 무엇을 보내는지는 프로토콜 문서가 정한다.
	udp.put_packet("HELLO".to_utf8_buffer())

func _physics_process(_delta: float) -> void:
	# 🔑 매 틱, 도착한 패킷을 전부 꺼낸다. 하나만 꺼내면 나머지가 버퍼에 쌓여 지연이 커진다.
	while udp.get_available_packet_count() > 0:
		var bytes: PackedByteArray = udp.get_packet()
		_handle(bytes)

func _handle(bytes: PackedByteArray) -> void:
	if bytes.is_empty():
		return
	# 첫 바이트로 종류를 가른다 — 텍스트 제어 패킷과 바이너리 패킷을 나누는 흔한 방식
	match bytes[0]:
		0x53:   # 'S' — 예시. 바이너리 스냅샷이면 §3 으로 디코딩한다
			_decode_binary(bytes)
		_:
			print(bytes.get_string_from_utf8())   # 텍스트 패킷

func _decode_binary(_bytes: PackedByteArray) -> void:
	pass   # §3

func _exit_tree() -> void:
	udp.close()
```

**왜 `_physics_process` 인가** — Zone 서버는 고정 틱(30Hz)으로 돌고 클라이언트도 고정 틱에서
읽어야 지터가 적다. 화면 갱신(`_process`)에 묶으면 프레임이 떨어질 때 패킷 처리도 늦어진다.

**UDP 는 잃어버린다.** 중요한 패킷(입장·거래)은 **ACK 와 재전송**을 얹어야 하고, 그것은 프로토콜의
일이다 → [server-protocol.md §10 신뢰 채널](../../game/references/server-protocol.md).

### 서버 쪽이 필요하면 — `UDPServer`

로컬 테스트용 가짜 서버를 Godot 으로 만들 때만 쓴다. `listen(port)` → 매 프레임 `poll()` →
`is_connection_available()` 이면 `take_connection() -> PacketPeerUDP`. 실제 라리엔 서버는 Go 다.

---

## 3. `StreamPeerBuffer` 와 엔디안 — 바이트를 숫자로 읽는다

### 엔디안 — 4.7.2 실측 결과

같은 두 바이트 `[0x01, 0x02]` 를 16비트 정수로 읽을 때 **어느 쪽이 상위 바이트냐**가 엔디안이다.

| 방법 | 결과 | 뜻 |
|---|---|---|
| `PackedByteArray([1,2,3,4]).decode_u16(0)` | **513** (= 0x0201) | 🛑 **리틀 엔디안 고정.** 바꿀 수 없다 |
| `StreamPeerBuffer.new().put_u16(0x0102)` → `data_array` | **`[2, 1]`** | 기본 `big_endian = false` → 리틀 |
| `big_endian = true` 로 `put_u16(0x0102)` | **`[1, 2]`** | 빅 |
| `big_endian = true` 로 `[1,2,…]` 를 `get_u16()` | **258** (= 0x0102) | 빅으로 읽힘. `get_position()` 은 2 로 전진 |

> 🛑 **라리엔 Zone 의 SNAP 은 BigEndian 이다**([server-protocol.md](../../game/references/server-protocol.md) 절대 규칙).
> 따라서 **`PackedByteArray.decode_*` 는 쓸 수 없고**, `StreamPeerBuffer` 에 **`big_endian = true` 를 반드시 켠 뒤** 읽는다.
> 한 줄을 빠뜨리면 오류 없이 **좌표가 전부 뒤집힌다**(x=1 이 256 으로 읽힌다).

### `StreamPeer` 읽기·쓰기 (상속)

| 읽기 | 쓰기 | 크기 |
|---|---|---|
| `get_u8()` / `get_8()` | `put_u8(v)` / `put_8(v)` | 1바이트 (부호 없음 / 있음) |
| `get_u16()` / `get_16()` | `put_u16(v)` / `put_16(v)` | 2 |
| `get_u32()` / `get_32()` | `put_u32(v)` / `put_32(v)` | 4 |
| `get_u64()` / `get_64()` | `put_u64(v)` / `put_64(v)` | 8 |
| `get_float()` / `get_double()` / `get_half()` | `put_float(v)` … | 4 / 8 / 2 |
| `get_string(bytes)` · `get_utf8_string(bytes)` | `put_string(v)` · `put_utf8_string(v)` | 🛑 **길이 접두(4바이트)를 붙인다** — 서버 형식과 다를 수 있다. 서버가 길이 없이 보내면 `get_data(n)` 으로 읽어 `get_string_from_utf8()` |
| `get_data(bytes) -> [Error, PackedByteArray]` | `put_data(data) -> Error` | 원시 바이트 |
| `get_available_bytes()` | | 남은 바이트 |

`StreamPeerBuffer` 고유: `data_array`(바이트 전체) · `seek(pos)` · `get_position()` · `get_size()` · `clear()` · `resize(n)`.

### 디코딩 뼈대

```gdscript
## 바이너리 패킷을 읽는 뼈대. 필드 순서·크기는 프로토콜 문서가 정한다.
func _decode_binary(bytes: PackedByteArray) -> void:
	var buf := StreamPeerBuffer.new()
	buf.data_array = bytes
	buf.big_endian = true            # 🛑 이 줄이 없으면 전부 뒤집힌다 (실측 — 위 표)

	if buf.get_available_bytes() < 4:   # 헤더도 못 채우면 버린다 (graceful drop)
		return
	var magic := buf.get_u8()
	var count := buf.get_u16()
	for i in count:
		if buf.get_available_bytes() < 6:   # 항목 하나에 필요한 바이트 — 길이 검사를 매번 한다
			break
		var id := buf.get_u16()
		var x := buf.get_16()             # 서버가 int16 cm 로 보낸다면 부호 있는 16비트
		var y := buf.get_16()
		_apply(id, x, y)
```

**왜 매번 길이를 검사하나** — UDP 패킷은 잘려서 올 수 있고, 잘못된 패킷도 온다. 길이가 모자란 채
`get_u16()` 을 부르면 오류 메시지를 찍고 0 을 돌려주지만 **그 0 이 좌표가 되어 캐릭터가 원점으로 튄다.**

**부호** — `get_16()` 은 −32768~32767, `get_u16()` 은 0~65535. 좌표처럼 음수가 있는 값은 부호 있는 쪽이다.
잘못 고르면 **−1 이 65535 가 된다.**

---

## 4. `HTTPRequest` — 요청 하나, 응답 하나

**노드**다(`Node` 상속). 씬에 자식으로 두거나 코드로 `add_child()` 한다. 노드라서 `poll()` 이 필요 없다.

### 시그니처 (doctool 4.7.2)

| | |
|---|---|
| `request(url: String, custom_headers: PackedStringArray = [], method: HTTPClient.Method = METHOD_GET, request_data: String = "") -> Error` | 보낸다. `Error` 는 **보내기 시작했는지**이지 성공이 아니다 |
| `request_raw(url, custom_headers, method, request_data_raw: PackedByteArray) -> Error` | 본문이 바이너리일 때 |
| `cancel_request() -> void` | 취소 |
| **시그널 `request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray)`** | 끝나면 온다. **`result == HTTPRequest.RESULT_SUCCESS`(0) 와 `response_code == 200` 을 둘 다 확인한다** |
| `timeout: float = 0.0` | 초. **0 은 무제한** — 모바일에서는 반드시 준다(10~30) |
| `use_threads: bool = false` | 큰 다운로드면 `true` |
| `download_file: String = ""` | 지정하면 본문을 파일로 저장한다(에셋 다운로드) |
| `max_redirects: int = 8` · `accept_gzip: bool = true` · `body_size_limit: int = -1` | |

`result` 의 값 — `RESULT_SUCCESS=0` · `RESULT_CANT_CONNECT=2` · `RESULT_CANT_RESOLVE=3` · `RESULT_CONNECTION_ERROR=4` ·
`RESULT_TLS_HANDSHAKE_ERROR=5` · `RESULT_TIMEOUT=13` … (전체 14개, doctool).

### GET 으로 JSON 받기

```gdscript
extends Node

@onready var http: HTTPRequest = $HTTPRequest   # 씬에 HTTPRequest 자식을 하나 둔다

func _ready() -> void:
	http.timeout = 15.0                            # 🛑 기본 0 = 무제한. 폰에서 영원히 기다린다
	http.request_completed.connect(_on_completed)
	var err := http.request("https://example.com/api/version")
	if err != OK:
		push_error("요청을 시작하지 못했다: %s" % error_string(err))

func _on_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("네트워크 실패: result=%d" % result)     # 연결·DNS·TLS·타임아웃
		return
	if code != 200:
		push_error("서버 오류: HTTP %d" % code)              # 서버가 응답은 했다
		return
	var json: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		push_error("JSON 이 아니다: %s" % body.get_string_from_utf8().left(200))
		return
	print(json["version"])
```

### POST 로 JSON 보내기

```gdscript
var payload := JSON.stringify({"name": "laryen", "level": 3})
var headers := PackedStringArray(["Content-Type: application/json"])
http.request(url, headers, HTTPClient.METHOD_POST, payload)
```

**규칙**

- 🛑 **한 노드는 한 번에 한 요청만.** 진행 중에 다시 `request()` 하면 `ERR_BUSY` 다. 동시에 여러 개면 노드를 여러 개 두거나 그때그때 만들고 `queue_free()` 한다.
- 🛑 **토큰·비밀번호를 코드에 박지 않는다.** 내보낸 앱은 누구나 뜯어볼 수 있다. Nakama 세션 토큰은 SDK 가 `user://` 에 보관한다 → [nakama-godot.md](../../game/references/nakama-godot.md).
- 헤더는 `"이름: 값"` 문자열 배열이다. `User-Agent` 도 여기서 바꾼다.

---

## 5. `HTTPClient` — `HTTPRequest` 아래의 저수준

`HTTPRequest` 가 안에서 쓰는 클래스다. **연결 → 요청 → 본문 읽기**를 상태 머신으로 직접 돌린다.

```
connect_to_host(host, port) → poll() 반복하며 STATUS_RESOLVING/CONNECTING 을 지나 STATUS_CONNECTED
→ request(METHOD_GET, "/path", headers) → poll() 반복하며 STATUS_REQUESTING
→ has_response() → get_response_code() · get_response_headers_as_dictionary()
→ STATUS_BODY 동안 read_response_body_chunk() 를 모아 PackedByteArray
```

**대개 필요 없다.** 커스텀 스트리밍·keep-alive 재사용·헤드리스 스크립트(`godot -s`)에서 노드 없이
쓸 때만 고른다. 예제는 공식 *HTTP client class* 페이지에 있다(`:article_outdated:` 표시가 붙어 있다 — 절차는 유효하나 예제 사이트가 옛것이다).

---

## 6. `WebSocketPeer` — 양방향 메시지(TCP)

`PacketPeer` 를 상속한다 — 그래서 `get_packet()`/`get_available_packet_count()` 가 UDP 와 같다.
차이는 **TCP 위라 순서·도착이 보장**되고, **텍스트/바이너리 메시지를 구분**한다는 것.

### 시그니처 (doctool 4.7.2 — `modules/websocket`)

| | |
|---|---|
| `connect_to_url(url: String, tls_client_options: TLSOptions = null) -> Error` | `ws://` 또는 `wss://`. **반환이 OK 여도 아직 연결 전**이다 |
| `poll() -> void` | 🛑 **매 프레임 부른다.** 안 부르면 연결도 수신도 진행되지 않는다 |
| `get_ready_state() -> State` | `STATE_CONNECTING=0` · `STATE_OPEN=1` · `STATE_CLOSING=2` · `STATE_CLOSED=3` |
| `send_text(message: String) -> Error` · `send(message: PackedByteArray, write_mode = WRITE_MODE_BINARY) -> Error` | 보낸다 |
| `get_packet() -> PackedByteArray` · `was_string_packet() -> bool` | 받는다. 텍스트였으면 `get_string_from_utf8()` |
| `close(code: int = 1000, reason: String = "") -> void` | 닫기 시작. **`STATE_CLOSED` 가 될 때까지 계속 `poll()` 해야** 깨끗이 닫힌다 |
| `get_close_code() -> int` · `get_close_reason() -> String` | 닫힌 뒤. **code 가 −1 이면 상대가 통보 없이 끊은 것** |
| `set_no_delay(enabled: bool)` | Nagle 끄기 — 작은 메시지가 잦으면 `true` |

### 최소 클라이언트

```gdscript
extends Node

var socket := WebSocketPeer.new()

func _ready() -> void:
	var err := socket.connect_to_url("wss://example.com/ws")   # wss = TLS (§7)
	if err != OK:
		push_error("연결 시작 실패: %s" % error_string(err))
		set_process(false)

func _process(_delta: float) -> void:
	socket.poll()                                   # 🛑 이 줄이 통신의 전부를 움직인다
	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			while socket.get_available_packet_count() > 0:
				var packet := socket.get_packet()
				if socket.was_string_packet():
					print("텍스트: ", packet.get_string_from_utf8())
				else:
					print("바이너리 %d 바이트" % packet.size())
		WebSocketPeer.STATE_CLOSING:
			pass                                    # 계속 poll 한다
		WebSocketPeer.STATE_CLOSED:
			var code := socket.get_close_code()
			print("닫힘 code=%d clean=%s" % [code, code != -1])
			set_process(false)                      # 재연결은 여기서 타이머를 걸어 시작한다
```

**Nakama 는 이것을 SDK 안에서 쓴다.** 라리엔 코드가 `WebSocketPeer` 를 직접 만들 일은 없고,
SDK 의 `NakamaSocket` 이 끊겼을 때 무엇을 하는지는 [nakama-godot.md §12](../../game/references/nakama-godot.md) 에 있다.
이 절은 **그 밑에서 무슨 일이 일어나는지** 를 알기 위한 것이다.

---

## 7. TLS — `wss://`·`https://` 가 그냥 되는 이유

`HTTPRequest`·`HTTPClient`·`WebSocketPeer` 는 `https://`·`wss://` 를 주면 **`StreamPeerTLS` 로 감싸서** 알아서 암호화한다.
인증서 검증은 **운영체제의 번들**을 쓰고, 없으면 **Godot 에 내장된 Mozilla 번들**로 대신한다.
Let's Encrypt 같은 공인 인증서면 **클라이언트에서 할 일이 없다.**

| 상황 | 할 일 |
|---|---|
| 공인 인증서(Let's Encrypt 등) | 없음 |
| 자체 서명 인증서(개발 서버) | `Project > Project Settings > Network > TLS > Certificate Bundle Override` 에 서버 공개키 `.crt`(PEM) 를 지정. 🛑 **이 파일이 OS 번들을 대체하므로** 공인 사이트도 그 파일에 있어야 한다 |
| 코드에서 개별 지정 | `TLSOptions.client(certs)` 를 만들어 `HTTPRequest.set_tls_options()` / `connect_to_url(url, tls_options)` |
| 개발 중 인증서 검증 끄기 | `TLSOptions.client_unsafe()` — 🛑 **릴리스에 남기지 않는다** |

**비밀키는 서버에만 둔다.** 클라이언트 번들에는 공개 인증서만 들어간다.

---

## 8. 모바일에서 반드시 할 것

| 항목 | 무엇 | 어디 |
|---|---|---|
| 🛑 **Android `INTERNET` 권한** | 없으면 **모든 네트워크가 OS 에서 막힌다.** 오류 메시지도 애매하다(`RESULT_CANT_CONNECT`) | Export preset → Permissions → Internet → [export-build-android.md §9](export-build-android.md) |
| **타임아웃** | `HTTPRequest.timeout` 기본 0 = 무제한. 지하철에서 앱이 영원히 기다린다 | 10~30초 |
| **백그라운드** | 폰이 앱을 백그라운드로 보내면 소켓이 끊길 수 있다. `NOTIFICATION_APPLICATION_PAUSED`/`RESUMED` 에서 상태를 저장하고 재연결한다 | [input-ui.md 종료·백그라운드 알림 절](input-ui.md) |
| **네트워크 전환**(Wi-Fi ↔ LTE) | IP 가 바뀌어 UDP 상대가 나를 못 알아본다. 프로토콜의 재HELLO 가 필요하다 | [server-protocol.md §4](../../game/references/server-protocol.md) |
| iOS | 별도 권한은 없다. 단 로컬 네트워크(같은 Wi-Fi 의 개발 서버)에 붙으면 첫 접근 때 **로컬 네트워크 권한 팝업**이 뜬다 | |

---

## 9. 자주 하는 실수

| 실수 | 증상 | 고침 |
|---|---|---|
| `ENetMultiplayerPeer`·`@rpc` 로 Zone 을 짠다 | 서버가 응답하지 않는다 — Go 서버는 ENet 을 모른다 | 이 문서 §2. 고수준 API 는 [multiplayer.md](multiplayer.md) 의 학습 범위 |
| `StreamPeerBuffer.big_endian` 을 안 켠다 | 오류 없이 좌표·ID 가 엉뚱하다 (256배·뒤집힘) | `big_endian = true` — §3 실측 |
| `PackedByteArray.decode_u16()` 으로 BigEndian 을 읽는다 | 위와 같음 — **리틀 고정**이다 | `StreamPeerBuffer` 로 |
| `get_16()` 과 `get_u16()` 을 바꿔 쓴다 | 음수가 65535 근처 값이 된다 | 서버 타입(int16/uint16)대로 |
| `poll()` 을 `_ready()` 에서 한 번만 부른다 | WebSocket 이 `STATE_CONNECTING` 에서 멈춘다 | 매 프레임 `_process()` 에서 |
| 패킷을 프레임당 하나만 꺼낸다 | 지연이 점점 커진다 (버퍼에 쌓임) | `while get_available_packet_count() > 0` |
| `PacketPeerUDP.wait()` 를 부른다 | 화면이 멈춘다 | 부르지 않는다. 폴링만 |
| `HTTPRequest` 하나로 연달아 요청한다 | 두 번째가 `ERR_BUSY` | 노드를 여러 개, 또는 완료 후 재요청 |
| `HTTPRequest.timeout` 을 두지 않는다 | 끊긴 네트워크에서 영원히 대기 | 10~30초 |
| Android 에서만 안 된다 | INTERNET 권한 누락 | §8 |
| 길이 검사 없이 `get_*()` 를 부른다 | 잘린 패킷에서 0 이 좌표가 되어 원점으로 튄다 | 필드마다 `get_available_bytes()` 확인 |
| `connect_to_host()` 가 OK 라서 연결됐다고 믿는다 | UDP 는 연결이 없다 — 상대가 죽어도 OK | 첫 응답(WELCOME)이 올 때까지는 미연결로 취급 |

---

## 관련 문서

- [multiplayer.md](multiplayer.md) — Godot 끼리의 고수준 멀티플레이어 (학습용 · 라리엔 실시간에는 쓰지 않는다)
- [server-protocol.md](../../game/references/server-protocol.md) — 🛑 Zone 프로토콜 정본 (HELLO/WELCOME · SNAP · BigEndian 디코더)
- [nakama-godot.md](../../game/references/nakama-godot.md) — Nakama SDK (인증·RPC·소켓·파티)
- [export-build-android.md](export-build-android.md) — INTERNET 권한
- [resources-assets.md](resources-assets.md) — `JSON`·`FileAccess` (응답 저장)

## 공식 문서

- Networking (목차): https://docs.godotengine.org/en/stable/tutorials/networking/index.html
- Making HTTP requests: https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html
- HTTP client class: https://docs.godotengine.org/en/stable/tutorials/networking/http_client_class.html
- Using WebSockets: https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html
- TLS/SSL certificates: https://docs.godotengine.org/en/stable/tutorials/networking/ssl_certificates.html
- 클래스: [PacketPeerUDP](https://docs.godotengine.org/en/stable/classes/class_packetpeerudp.html) · [StreamPeerBuffer](https://docs.godotengine.org/en/stable/classes/class_streampeerbuffer.html) · [StreamPeer](https://docs.godotengine.org/en/stable/classes/class_streampeer.html) · [HTTPRequest](https://docs.godotengine.org/en/stable/classes/class_httprequest.html) · [WebSocketPeer](https://docs.godotengine.org/en/stable/classes/class_websocketpeer.html) · [TLSOptions](https://docs.godotengine.org/en/stable/classes/class_tlsoptions.html)
