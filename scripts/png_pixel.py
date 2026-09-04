#!/usr/bin/env python3
"""PNG 의 특정 픽셀 색을 읽어 Godot 의 Color 값으로 환산한다.

왜 필요한가 — 머티리얼을 UNSHADED 로 바꾸면 조명이 곱해지지 않으므로 **색이 변한다**.
수정 전 화면의 실제 픽셀 색을 재서 그 값을 albedo_color 에 넣어야 외관이 그대로다.
눈대중으로 맞추면 반드시 어긋난다 (perf-tuning-playbook.md §4.4).

의존성 없음 — Python 표준 라이브러리만 쓴다(Pillow 불필요).

사용법:
    python3 png_pixel.py <파일.png> [x y]...
    python3 png_pixel.py before.png 360 1000 120 900
    python3 png_pixel.py before.png            # 좌표를 안 주면 화면 9곳을 자동으로 샘플링

출력:
    before.png (360,1000)  RGB (80, 92, 110)  #505C6E  → Godot Color(0.313725, 0.360784, 0.431373)
"""

import sys
import zlib
import struct


def read_png(path):
    """PNG 를 디코드해 (width, height, channels, rows) 를 돌려준다.

    8비트 RGB/RGBA · 인터레이스 없음 만 지원한다 — 게임 스크린샷은 전부 이 형식이다.
    """
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"PNG 가 아니다: {path}")
    pos, width, height, ctype, bitdepth, idat = 8, 0, 0, 0, 0, b""
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        ctag = data[pos + 4:pos + 8]
        if ctag == b"IHDR":
            width, height, bitdepth, ctype = struct.unpack(">IIBB", data[pos + 8:pos + 18])
            interlace = data[pos + 20]
            if bitdepth != 8 or ctype not in (2, 6) or interlace != 0:
                raise SystemExit(f"지원하지 않는 PNG 형식 (bitdepth={bitdepth} colortype={ctype} interlace={interlace})")
        elif ctag == b"IDAT":
            idat += data[pos + 8:pos + 8 + length]
        elif ctag == b"IEND":
            break
        pos += 12 + length

    raw = zlib.decompress(idat)
    channels = 4 if ctype == 6 else 3
    stride = width * channels
    rows, prev = [], bytearray(stride)
    i = 0
    for _ in range(height):
        ftype = raw[i]
        i += 1
        line = bytearray(raw[i:i + stride])
        i += stride
        # PNG 행 필터 되돌리기 (0=None 1=Sub 2=Up 3=Average 4=Paeth)
        for x in range(stride):
            a = line[x - channels] if x >= channels else 0
            b = prev[x]
            c = prev[x - channels] if x >= channels else 0
            if ftype == 1:
                line[x] = (line[x] + a) & 255
            elif ftype == 2:
                line[x] = (line[x] + b) & 255
            elif ftype == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif ftype == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else (b if pb <= pc else c))) & 255
        rows.append(bytes(line))
        prev = line
    return width, height, channels, rows


def main(argv):
    if len(argv) < 2:
        raise SystemExit(__doc__)
    path = argv[1]
    width, height, channels, rows = read_png(path)

    coords = []
    rest = argv[2:]
    if rest:
        if len(rest) % 2:
            raise SystemExit("좌표는 x y 쌍으로 준다")
        coords = [(int(rest[i]), int(rest[i + 1])) for i in range(0, len(rest), 2)]
    else:
        # 좌표를 안 주면 화면을 3×3 으로 나눠 가운데를 찍는다
        coords = [(width * cx // 6, height * cy // 6)
                  for cy in (1, 3, 5) for cx in (1, 3, 5)]

    print(f"{path}  {width}x{height}")
    for x, y in coords:
        if not (0 <= x < width and 0 <= y < height):
            print(f"  ({x},{y})  범위 밖 (0~{width - 1}, 0~{height - 1})")
            continue
        r, g, b = rows[y][x * channels:x * channels + 3]
        print(f"  ({x},{y})  RGB ({r}, {g}, {b})  #{r:02X}{g:02X}{b:02X}"
              f"  → Godot Color({r / 255:.6f}, {g / 255:.6f}, {b / 255:.6f})")


if __name__ == "__main__":
    main(sys.argv)
