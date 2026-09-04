#!/usr/bin/env python3
"""씬·에셋의 삼각형 수를 센다 — 두 가지 모드. 표준 라이브러리만 쓴다.

보통은 이 파일을 직접 부르지 않는다 — 프로젝트 루트의 scripts/triangles.sh 가 감싸고 있다.
직접 부를 때는 현재 폴더에서 위로 project.godot 을 찾는다.

  ① 씬 모드 (Godot 을 헤드리스로 부른다) — .tscn 안의 모든 메시 노드를 합산한다
      scripts/triangles.sh scenes/main/main.tscn
      python3 .claude/skills/godot/scripts/count_triangles.py res://scenes/main/main.tscn
      python3 .claude/skills/godot/scripts/count_triangles.py --all --budget 150000 --csv out.csv

  ② 에셋 모드 (Godot 없이 파이썬만으로 .glb/.gltf 를 직접 읽는다)
      scripts/triangles.sh --glb assets/actor/pc/female/claudy/claudy.glb
      scripts/triangles.sh --glb assets            # 폴더를 주면 재귀로 전부

🛑 이 값은 "씬 안에 존재하는 삼각형"이다. 실행 중 화면에 실제로 그려지는 수가 아니다.
   그쪽은 `scripts/triangles.sh --frame` 으로 재거나, 게임을 켜고 디버그 패널의 `tris` 를 본다 — 컬링·LOD 가 반영된 값이라 보통 더 작다.

②가 필요한 이유 — 에셋이 프로젝트에 들어오기 전에(CI·검수 단계) 무게를 재려면 Godot 임포트가 아직 없다.
GLB 는 헤더 12바이트 + JSON 청크 + BIN 청크라, JSON 만 읽어도 삼각형 수를 알 수 있다.
"""
import argparse
import csv
import json
import os
import struct
import subprocess
import tempfile
import sys
from pathlib import Path

# 프로젝트 루트와 GDScript 위치는 실행 시 정해진다 — 이 파일이 스킬 안(.claude/skills/godot/scripts/)에
# 있어서 "부모의 부모"가 프로젝트 루트라는 가정을 쓸 수 없다. triangles.sh 가 --project/--gd 로 넘겨 주고,
# 직접 실행할 때는 현재 폴더에서 위로 project.godot 을 찾는다.
ROOT = Path.cwd()
GD_SCRIPT = "res://.claude/skills/godot/scripts/count_triangles.gd"


def find_project_root(start: Path) -> Path:
    """project.godot 이 있는 폴더를 위로 올라가며 찾는다. 못 찾으면 시작 폴더를 그대로 쓴다."""
    d = start.resolve()
    while d != d.parent:
        if (d / "project.godot").exists():
            return d
        d = d.parent
    return start.resolve()


# ── ② 에셋 모드 — Godot 없이 glTF 를 직접 읽는다 ──────────────────────────

def gltf_json(path: Path) -> dict:
    """.glb(바이너리) 와 .gltf(텍스트) 양쪽에서 glTF JSON 을 꺼낸다."""
    raw = path.read_bytes()
    if raw[:4] != b"glTF":                       # .gltf 는 그냥 JSON 파일이다
        return json.loads(raw.decode("utf-8"))
    # GLB — magic(4) version(4) length(4) 뒤로 [chunkLength(4) chunkType(4) data] 가 이어진다
    _, version, _ = struct.unpack("<III", raw[:12])
    if version != 2:
        raise ValueError(f"glTF {version} 은 다루지 않는다 (2만 지원)")
    off = 12
    while off < len(raw):
        clen, ctype = struct.unpack("<II", raw[off:off + 8])
        data = raw[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:                  # 'JSON'
            return json.loads(data.decode("utf-8"))
        off += 8 + clen + (-clen % 4)            # 4바이트 정렬 패딩
    raise ValueError("JSON 청크를 찾지 못했다")


def count_gltf(path: Path) -> dict:
    """mesh 별 삼각형·정점 수를 센다. mode 4(TRIANGLES) 만 삼각형으로 본다."""
    g = gltf_json(path)
    accessors = g.get("accessors", [])
    tris = verts = prims = non_tri = 0
    per_mesh = []
    for m in g.get("meshes", []):
        mt = mv = 0
        for p in m.get("primitives", []):
            mode = p.get("mode", 4)              # 생략되면 4 = TRIANGLES
            if mode != 4:
                non_tri += 1
                continue
            prims += 1
            pos = p.get("attributes", {}).get("POSITION")
            if pos is not None:
                mv += accessors[pos].get("count", 0)
            if "indices" in p:
                mt += accessors[p["indices"]].get("count", 0) // 3
            elif pos is not None:
                mt += accessors[pos].get("count", 0) // 3
        tris += mt
        verts += mv
        per_mesh.append({"name": m.get("name", "(이름 없음)"), "triangles": mt, "vertices": mv})
    return {
        "file": str(path.relative_to(ROOT)) if str(path).startswith(str(ROOT)) else str(path),
        "triangles": tris, "vertices": verts, "primitives": prims,
        "non_triangle_primitives": non_tri,
        "meshes": per_mesh,
        "nodes": len(g.get("nodes", [])),
        "materials": len(g.get("materials", [])),
        "images": len(g.get("images", [])),
        "bones": sum(len(s.get("joints", [])) for s in g.get("skins", [])),
        "animations": len(g.get("animations", [])),
        "size_mb": path.stat().st_size / 1024 / 1024,
    }


def run_asset_mode(targets, budget, as_json, csv_path):
    files = []
    for t in targets:
        p = Path(t)
        if not p.is_absolute():
            p = ROOT / p
        if p.is_dir():
            files += sorted(x for x in p.rglob("*") if x.suffix.lower() in (".glb", ".gltf"))
        elif p.exists():
            files.append(p)
        else:
            print(f"🛑 없는 경로: {t}", file=sys.stderr)
    if not files:
        print("셀 파일이 없다.", file=sys.stderr)
        return 1

    rows = []
    for f in files:
        try:
            rows.append(count_gltf(f))
        except Exception as e:                    # 깨진 파일 하나가 전체를 멈추지 않게 한다
            print(f"🛑 {f}: {e}", file=sys.stderr)
    rows.sort(key=lambda r: -r["triangles"])

    if as_json:
        print(json.dumps(rows, ensure_ascii=False, indent=2))
        return 0

    print(f"{'삼각형':>10}  {'정점':>9}  {'본':>4}  {'애니':>4}  {'MB':>6}  파일")
    print("─" * 88)
    total = 0
    over = []
    for r in rows:
        total += r["triangles"]
        mark = ""
        if budget and r["triangles"] > budget:
            mark = "  🛑 예산 초과"
            over.append(r)
        print(f"{r['triangles']:>10,}  {r['vertices']:>9,}  {r['bones']:>4}  "
              f"{r['animations']:>4}  {r['size_mb']:>6.1f}  {r['file']}{mark}")
    print("─" * 88)
    print(f"{total:>10,}  합계 · 파일 {len(rows)}개")
    if budget:
        print(f"\n예산 {budget:,} 삼각형 · 초과 {len(over)}개")

    if csv_path:
        with open(csv_path, "w", encoding="utf-8", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(["file", "triangles", "vertices", "bones", "animations", "size_mb"])
            for r in rows:
                w.writerow([r["file"], r["triangles"], r["vertices"], r["bones"],
                            r["animations"], f"{r['size_mb']:.3f}"])
        print(f"CSV 저장: {csv_path}")
    return 1 if (budget and over) else 0


# ── ① 씬 모드 — Godot 헤드리스를 부른다 ────────────────────────────────────

def run_scene_mode(scenes, all_scenes, budget, godot, as_json, csv_path, top, gd_script):
    # 🛑 임시 파일을 프로젝트 안에 만들지 않는다 — 실패했을 때 git status 를 더럽히고,
    #    Godot 이 다음 실행에서 새 파일로 인식해 임포트를 다시 돈다.
    fd, tmp_name = tempfile.mkstemp(prefix="count_triangles_", suffix=".json")
    os.close(fd)
    out_json = Path(tmp_name)
    args = [godot, "--headless", "--path", str(ROOT), "-s", gd_script, "--"]
    if all_scenes:
        args.append("--all")
    for s in scenes:
        args.append(s if s.startswith("res://") else "res://" + os.path.relpath(Path(s).resolve(), ROOT))
    args += ["--json", str(out_json), "--top", str(top)]

    proc = subprocess.run(args, capture_output=True, text=True)
    if proc.returncode != 0 and not out_json.exists():
        print(proc.stdout)
        print(proc.stderr, file=sys.stderr)
        print("🛑 Godot 실행이 실패했다. --godot 으로 실행 파일 경로를 지정해 본다.", file=sys.stderr)
        return 1

    if not out_json.exists() or out_json.stat().st_size == 0:
        print(proc.stdout)
        out_json.unlink(missing_ok=True)
        return proc.returncode
    report = json.loads(out_json.read_text(encoding="utf-8"))
    out_json.unlink(missing_ok=True)

    # GDScript 가 찍은 "JSON 저장: /tmp/…" 는 내부 사정이라 보이지 않게 한다
    stdout = "\n".join(l for l in proc.stdout.splitlines() if not l.startswith("JSON 저장:")).strip()

    if as_json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0

    if not as_json and not csv_path and len(report["scenes"]) == 1:
        print(stdout)                             # 씬 하나면 GDScript 쪽 상세 표가 더 읽기 좋다
        s = report["scenes"][0]
        if budget:
            _verdict(s["triangles"], budget)
        return 0

    print(f"Godot {report['godot']}")
    print(f"{'삼각형':>10}  {'서피스':>7}  {'노드':>5}  씬")
    print("─" * 84)
    total = 0
    over = []
    for s in sorted(report["scenes"], key=lambda x: -x["triangles"]):
        total += s["triangles"]
        mark = ""
        if budget and s["triangles"] > budget:
            mark = "  🛑 예산 초과"
            over.append(s)
        print(f"{s['triangles']:>10,}  {s['surfaces']:>7,}  {s['mesh_nodes']:>5}  {s['scene']}{mark}")
    print("─" * 84)
    print(f"{total:>10,}  합계 · 씬 {len(report['scenes'])}개")
    print("           (씬끼리 겹치는 에셋도 각각 세므로 '한 화면의 부하'가 아니라 '만들어 둔 총량'이다)")
    if budget:
        print(f"\n씬당 예산 {budget:,} 삼각형 · 초과 {len(over)}개")

    if csv_path:
        with open(csv_path, "w", encoding="utf-8", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(["scene", "triangles", "surfaces", "mesh_nodes"])
            for s in report["scenes"]:
                w.writerow([s["scene"], s["triangles"], s["surfaces"], s["mesh_nodes"]])
        print(f"CSV 저장: {csv_path}")
    return 1 if (budget and over) else 0


def _verdict(tris, budget):
    ratio = tris / budget * 100
    state = "✅ 여유" if ratio < 80 else ("⚠️ 임박" if ratio <= 100 else "🛑 초과")
    print(f"\n예산 {budget:,} 대비 {ratio:.1f}%  {state}")


# ── 진입점 ────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(
        description="씬(.tscn) 또는 에셋(.glb/.gltf)의 삼각형 수를 센다",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__)
    ap.add_argument("targets", nargs="*", help="씬 경로(.tscn) 또는 --glb 일 때 파일·폴더")
    ap.add_argument("--glb", action="store_true", help="Godot 없이 glTF/GLB 를 직접 읽는다")
    ap.add_argument("--all", action="store_true", help="scenes/ 아래 .tscn 을 전부 센다 (씬 모드)")
    ap.add_argument("--budget", type=int, default=0, help="예산(삼각형). 넘으면 종료 코드 1")
    ap.add_argument("--godot", default=os.environ.get("GODOT", "godot"), help="Godot 실행 파일 (기본: godot)")
    ap.add_argument("--json", action="store_true", help="JSON 으로 출력")
    ap.add_argument("--csv", help="CSV 로도 저장할 경로")
    ap.add_argument("--top", type=int, default=12, help="무거운 노드 상위 N (씬 모드)")
    ap.add_argument("--project", help="Godot 프로젝트 루트 (기본: 현재 폴더에서 위로 탐색)")
    ap.add_argument("--gd", default=GD_SCRIPT, help="집계 GDScript 의 res:// 경로")
    a = ap.parse_args()

    global ROOT
    ROOT = Path(a.project).resolve() if a.project else find_project_root(Path.cwd())

    if a.glb:
        return run_asset_mode(a.targets or ["assets"], a.budget, a.json, a.csv)
    # 씬을 지정하지 않으면 GDScript 쪽이 project.godot 의 main_scene 을 센다 (인자를 그대로 비워 넘긴다)
    return run_scene_mode(a.targets, a.all, a.budget, a.godot, a.json, a.csv, a.top, a.gd)


if __name__ == "__main__":
    sys.exit(main())
